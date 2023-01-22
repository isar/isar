/*use crate::core::error::Result;
use crate::core::schema::{CollectionSchema, IndexSchema, PropertySchema};
use intmap::IntMap;
use once_cell::sync::Lazy;
use std::ops::Deref;
use xxhash_rust::xxh3::xxh3_64;

pub trait SchemaManager {
    type Txn;

    fn get_schema(txn: &Self::Txn, name: &str) -> Result<Option<CollectionSchema>>;

    fn save_schema(txn: &Self::Txn, schema: &CollectionSchema) -> Result<()>;

    fn delete_schema(txn: &Self::Txn, schema: &CollectionSchema) -> Result<()>;

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

    fn delete_collection(txn: &Self::Txn, col: &CollectionSchema);

    fn delete_index(txn: &Self::Txn, col: &CollectionSchema, index: &IndexSchema) -> Result<()>;

    fn merge_properties(
        schema: &mut CollectionSchema,
        existing_schema: &CollectionSchema,
    ) -> Result<Vec<PropertySchema>> {
        let mut properties = existing_schema.properties.clone();
        let mut removed_properties = vec![];

        for property in &mut properties {
            if property.name.is_some() && !schema.properties.contains(property) {
                removed_properties.push(property.name.take().unwrap());
            }
        }
        for property in &schema.properties {
            if !properties.contains(property) {
                properties.push(property.clone())
            }
        }

        schema.properties = properties;

        Ok(removed_properties)
    }

    fn perform_migration(
        txn: &Self::Txn,
        schema: &mut CollectionSchema,
        existing_schema: &CollectionSchema,
    ) -> Result<Vec<u64>> {
        let removed_properties = Self::merge_properties(schema, existing_schema)?;

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

        Ok(added_indexes.keys().copied().collect())
    }

    fn open_collection(
        &mut self,
        txn: &Txn,
        mut schema: CollectionSchema,
        schemas: &Schema,
    ) -> Result<IsarCollection> {
        let cursors = IsarCursors::new(txn, vec![]);

        let mut existing_schema = Self::get_schema(txn, schema.name)?;

        let added_indexes = if let Some(existing_schema) = &mut existing_schema {
            if existing_schema.version == 1 {
                migrate_v1(txn, existing_schema)?
            } else if existing_schema.version != Self::ISAR_FILE_VERSION {
                return Err(IsarError::VersionError {});
            }
            Self::perform_migration(txn, &mut schema, existing_schema)?
        } else {
            vec![]
        };
        let mut info_cursor = cursors.get_cursor(self.info_db)?;
        schema.version = Self::ISAR_FILE_VERSION;
        Self::save_schema(&mut info_cursor, &schema)?;
        let schema = schema; // no longer mutable beyond this point

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

    pub fn delete_unopened_collections(&self, txn: &Txn) -> Result<()> {
        let mut info_cursor = UnboundCursor::new().bind(txn, self.info_db)?;
        for col in &self.schemas {
            Self::delete_collection(txn, col)?;
            Self::delete_schema(&mut info_cursor, col)?;
        }
        Ok(())
    }
}
*/
