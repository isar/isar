use super::collection_schema::CollectionSchema;
use super::index_schema::IndexSchema;
use super::link_schema::LinkSchema;
use super::Schema;
use crate::collection::IsarCollection;
use crate::cursor::IsarCursors;
use crate::error::{schema_error, IsarError, Result};
use crate::index::index_key::IndexKey;
use crate::index::IsarIndex;
use crate::link::IsarLink;
use crate::mdbx::cursor::{Cursor, UnboundCursor};
use crate::mdbx::{db::Db, txn::Txn};
use crate::object::property::Property;
use crate::schema::migrate_v1::migrate_v1;
use intmap::IntMap;
use once_cell::sync::Lazy;
use std::ops::Deref;
use xxhash_rust::xxh3::xxh3_64;

static OLD_INFO_VERSION_KEY: Lazy<IndexKey> = Lazy::new(|| {
    let mut key = IndexKey::new();
    key.add_string(Some("version"), true);
    key
});

static OLD_INFO_SCHEMA_KEY: Lazy<IndexKey> = Lazy::new(|| {
    let mut key = IndexKey::new();
    key.add_string(Some("schema"), true);
    key
});

pub(crate) struct SchemaManager {
    instance_id: u64,
    info_db: Db,
    pub schemas: Vec<CollectionSchema>,
}

impl SchemaManager {
    pub const ISAR_FILE_VERSION: u8 = 2;

    pub fn create(instance_id: u64, txn: &Txn) -> Result<Self> {
        let info_db = Db::open(txn, Some("_info"), false, false, false)?;
        let mut info_cursor = UnboundCursor::new().bind(txn, info_db)?;

        Self::migrate_old_info(&mut info_cursor)?;

        let schemas = Self::get_schemas(&mut info_cursor)?;
        let manager = SchemaManager {
            instance_id,
            info_db,
            schemas,
        };
        Ok(manager)
    }

    fn migrate_old_info(info_cursor: &mut Cursor) -> Result<()> {
        let version = info_cursor.move_to(OLD_INFO_VERSION_KEY.deref())?;
        if let Some((_, version)) = version {
            let version_num = u64::from_le_bytes(version.try_into().unwrap());
            info_cursor.delete_current()?;

            let schema_bytes = info_cursor.move_to(OLD_INFO_SCHEMA_KEY.deref())?;
            let mut schema = if let Some((_, schema_bytes)) = schema_bytes {
                if let Ok(schema) = serde_json::from_slice::<Schema>(schema_bytes) {
                    Ok(schema)
                } else {
                    schema_error("Could not deserialize schema JSON")
                }
            } else {
                Schema::new(vec![])
            }?;
            info_cursor.delete_current()?;

            for col in &mut schema.collections {
                col.version = version_num as u8;
                Self::save_schema(info_cursor, col)?;
            }
        }
        Ok(())
    }

    fn get_schemas(info_cursor: &mut Cursor) -> Result<Vec<CollectionSchema>> {
        let mut schemas = vec![];
        info_cursor.iter_all(false, true, |_, _, bytes| {
            let col = serde_json::from_slice::<CollectionSchema>(bytes).map_err(|_| {
                IsarError::DbCorrupted {
                    message: "Could not deserialize existing schema.".to_string(),
                }
            })?;
            schemas.push(col);
            Ok(true)
        })?;
        Ok(schemas)
    }

    fn save_schema(info_cursor: &mut Cursor, schema: &CollectionSchema) -> Result<()> {
        let key = IndexKey::from_bytes(schema.name.as_bytes().to_vec());
        let bytes = schema.to_json_bytes()?;
        info_cursor.put(&key, &bytes)?;
        Ok(())
    }

    fn delete_schema(info_cursor: &mut Cursor, schema: &CollectionSchema) -> Result<()> {
        let key = IndexKey::from_bytes(schema.name.as_bytes().to_vec());
        if info_cursor.move_to(&key)?.is_some() {
            info_cursor.delete_current()?;
        }
        Ok(())
    }

    pub fn open_collection_db(txn: &Txn, col: &CollectionSchema) -> Result<Db> {
        Db::open(txn, Some(&col.name), true, false, false)
    }

    pub fn open_index_db(txn: &Txn, col: &CollectionSchema, index: &IndexSchema) -> Result<Db> {
        let db_name = format!("_i_{}_{}", col.name, index.name);
        Db::open(txn, Some(&db_name), false, !index.unique, false)
    }

    pub fn open_link_dbs(txn: &Txn, col: &CollectionSchema, link: &LinkSchema) -> Result<(Db, Db)> {
        let link_db_name = format!("_l_{}_{}", col.name, link.name);
        let db = Db::open(txn, Some(&link_db_name), true, true, true)?;
        let backlink_db_name = format!("_b_{}_{}", col.name, link.name);
        let bl_db = Db::open(txn, Some(&backlink_db_name), true, true, true)?;
        Ok((db, bl_db))
    }

    fn delete_collection(txn: &Txn, col: &CollectionSchema) -> Result<()> {
        let db = Self::open_collection_db(txn, col)?;
        db.drop(txn)?;
        for index in &col.indexes {
            Self::delete_index(txn, col, index)?;
        }
        for link in &col.links {
            Self::delete_link(txn, col, link)?;
        }
        Ok(())
    }

    fn delete_index(txn: &Txn, col: &CollectionSchema, index: &IndexSchema) -> Result<()> {
        let db = Self::open_index_db(txn, col, index)?;
        db.drop(txn)
    }

    fn delete_link(txn: &Txn, col: &CollectionSchema, link: &LinkSchema) -> Result<()> {
        let (db, bl_db) = Self::open_link_dbs(txn, col, link)?;
        db.drop(txn)?;
        bl_db.drop(txn)
    }

    fn perform_migration(
        txn: &Txn,
        schema: &mut CollectionSchema,
        existing_schema: &CollectionSchema,
    ) -> Result<Vec<u64>> {
        let removed_properties = schema.merge_properties(existing_schema)?;

        let mut added_indexes = IntMap::new();
        for index in &schema.indexes {
            if !existing_schema.indexes.contains(index) {
                let index_id = xxh3_64(index.name.as_bytes());
                added_indexes.insert(index_id, ());
            }
        }

        for existing_index in &existing_schema.indexes {
            let removed_index = !schema.indexes.contains(existing_index);
            let changed_property = existing_index
                .properties
                .iter()
                .any(|p| removed_properties.contains(&p.name));

            if removed_index || changed_property {
                Self::delete_index(txn, existing_schema, existing_index)?;
            }

            if !removed_index && changed_property {
                let index_id = xxh3_64(existing_index.name.as_bytes());
                added_indexes.insert(index_id, ());
            }
        }

        for link in &existing_schema.links {
            if !schema.links.contains(link) {
                Self::delete_link(txn, existing_schema, link)?;
            }
        }

        Ok(added_indexes.keys().copied().collect())
    }

    pub fn migrate_schema(&mut self, txn: &Txn, schemas: &mut Schema) -> Result<IntMap<Vec<u64>>> {
        let cursors = IsarCursors::new(txn, vec![]);

        let mut added_indexes = IntMap::new();
        for col_schema in &mut schemas.collections {
            let mut existing_schema = self
                .schemas
                .iter()
                .position(|s| s.name == col_schema.name)
                .map(|index| self.schemas.remove(index));

            if let Some(existing_schema) = &mut existing_schema {
                if existing_schema.version == 1 {
                    migrate_v1(txn, existing_schema)?;
                } else if existing_schema.version != Self::ISAR_FILE_VERSION {
                    return Err(IsarError::VersionError {});
                }
                let ai = Self::perform_migration(txn, col_schema, existing_schema)?;
                if !ai.is_empty() {
                    added_indexes.insert(xxh3_64(col_schema.name.as_bytes()), ai);
                }
            }

            let mut info_cursor = cursors.get_cursor(self.info_db)?;
            col_schema.version = Self::ISAR_FILE_VERSION;
            Self::save_schema(&mut info_cursor, &col_schema)?;
        }
        Ok(added_indexes)
    }

    pub fn open_collection(
        &mut self,
        txn: &Txn,
        schema: &CollectionSchema,
        schemas: &Schema,
        added_indexes: &[u64],
    ) -> Result<IsarCollection> {
        let cursors = IsarCursors::new(txn, vec![]);

        let db = Self::open_collection_db(txn, &schema)?;
        let properties = schema.get_properties();

        let mut embedded_properties = IntMap::new();
        Self::get_embedded_properties(schemas, &properties, &mut embedded_properties);

        let indexes = Self::open_indexes(txn, &schema, &properties)?;
        let links = Self::open_links(txn, db, &schema, schemas)?;
        let backlinks = Self::open_backlinks(txn, db, &schema, schemas)?;
        let col = IsarCollection::new(
            db,
            self.instance_id,
            &schema.name,
            properties,
            embedded_properties,
            indexes,
            links,
            backlinks,
        );

        col.init_auto_increment(&cursors)?;
        if !added_indexes.is_empty() {
            col.fill_indexes(&added_indexes, &cursors)?;
        }

        Ok(col)
    }

    fn get_embedded_properties(
        schemas: &Schema,
        properties: &[Property],
        embedded_properties: &mut IntMap<Vec<Property>>,
    ) {
        for property in properties {
            if let Some(target_id) = property.target_id {
                if !embedded_properties.contains_key(target_id) {
                    let embedded_col_schema = schemas
                        .collections
                        .iter()
                        .find(|c| xxh3_64(c.name.as_bytes()) == target_id)
                        .unwrap();
                    let properties = embedded_col_schema.get_properties();
                    embedded_properties.insert(target_id, properties.clone());
                    Self::get_embedded_properties(schemas, &properties, embedded_properties)
                }
            }
        }
    }

    fn open_indexes(
        txn: &Txn,
        schema: &CollectionSchema,
        properties: &[Property],
    ) -> Result<Vec<IsarIndex>> {
        let mut indexes = vec![];
        for index_schema in &schema.indexes {
            let db = Self::open_index_db(txn, schema, index_schema)?;
            let index = index_schema.as_index(db, &properties);
            indexes.push(index);
        }
        Ok(indexes)
    }

    fn open_links(
        txn: &Txn,
        db: Db,
        schema: &CollectionSchema,
        schemas: &Schema,
    ) -> Result<Vec<IsarLink>> {
        let mut links = vec![];
        for link_schema in &schema.links {
            let (link_db, backlink_db) = Self::open_link_dbs(txn, schema, link_schema)?;
            let target_col_schema = schemas
                .get_collection(&link_schema.target_col, false)
                .unwrap();
            let target_db = Self::open_collection_db(txn, target_col_schema)?;
            let link = IsarLink::new(
                &schema.name,
                &link_schema.name,
                false,
                link_db,
                backlink_db,
                db,
                target_db,
            );
            links.push(link);
        }
        Ok(links)
    }

    fn open_backlinks(
        txn: &Txn,
        db: Db,
        schema: &CollectionSchema,
        schemas: &Schema,
    ) -> Result<Vec<IsarLink>> {
        let mut backlinks = vec![];
        for other_col_schema in &schemas.collections {
            for link_schema in &other_col_schema.links {
                if link_schema.target_col == schema.name {
                    let other_col_db = Self::open_collection_db(txn, other_col_schema)?;
                    let (link_db, bl_db) = Self::open_link_dbs(txn, other_col_schema, link_schema)?;
                    let backlink = IsarLink::new(
                        &other_col_schema.name,
                        &link_schema.name,
                        true,
                        bl_db,
                        link_db,
                        db,
                        other_col_db,
                    );
                    backlinks.push(backlink);
                }
            }
        }
        Ok(backlinks)
    }

    pub fn delete_unopened_collections(&self, txn: &Txn) -> Result<()> {
        let mut info_cursor = UnboundCursor::new().bind(txn, self.info_db)?;
        for col in &self.schemas {
            Self::delete_collection(txn, col)?;
            Self::delete_schema(&mut info_cursor, col)?;
        }
        Ok(())
    }
}
