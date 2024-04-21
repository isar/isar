use crate::core::error::{IsarError, Result};
use crate::core::schema::{IsarSchema, PropertySchema};
use crate::native::mdbx::db::Db;
use crate::native::mdbx::env::Env;
use crate::native::native_collection::{NativeCollection, NativeProperty};
use crate::native::native_index::NativeIndex;
use crate::native::native_txn::NativeTxn;
use std::borrow::Cow;
use std::sync::Arc;

use super::versioned_isar_schema::VersionedIsarSchema;

const ISAR_FILE_VERSION: u8 = 3;

pub(crate) struct SchemaManager;

impl SchemaManager {
    pub(crate) fn initialize_collections(
        instance_id: u32,
        env: &Arc<Env>,
        mut schemas: Vec<IsarSchema>,
    ) -> Result<Vec<NativeCollection>> {
        let txn = NativeTxn::new(instance_id, env, true)?;
        let info_db = Self::open_info_db(&txn)?;
        let existing_schemas = Self::get_schemas(&txn, info_db)?;
        txn.commit()?;

        let schema_names: Vec<_> = schemas.iter().map(|s| s.name.to_owned()).collect();

        let collections: Vec<_> = schemas
            .iter_mut()
            .enumerate()
            .map(|(index, schema)| {
                Self::initialize_collection(instance_id, env, schema, index, &schema_names)
            })
            .collect::<Result<_>>()?;

        let txn = NativeTxn::new(instance_id, env, true)?;
        existing_schemas
            .iter()
            .filter(|existing_schema| {
                !schemas
                    .iter()
                    .any(|schema| schema.name == existing_schema.name)
            })
            .map(|existing_schema| Self::delete_collection(&txn, info_db, &existing_schema))
            .collect::<Result<_>>()?;
        txn.commit()?;

        Ok(collections)
    }

    fn initialize_collection(
        instance_id: u32,
        env: &Arc<Env>,
        schema: &mut IsarSchema,
        schema_index: usize,
        schema_names: &[String],
    ) -> Result<NativeCollection> {
        let txn = NativeTxn::new(instance_id, env, true)?;
        let info_db = Self::open_info_db(&txn)?;
        let existing_schema = Self::find_schema(&txn, info_db, &schema.name)?;

        let merged_properties = match existing_schema {
            Some(existing_schema) => {
                let merged_properties = Self::migrate_collection(&txn, &schema, &existing_schema)?;
                Cow::Owned(merged_properties)
            }
            None => Cow::Borrowed(&schema.properties),
        };

        let mut properties = Self::build_properties(&merged_properties, schema_names);
        // sort properties by position in schema
        properties.sort_by_key(|(name, _)| {
            schema
                .properties
                .iter()
                .position(|p| p.name.as_ref() == Some(name))
                .unwrap()
        });

        if let Cow::Owned(merged_properties) = merged_properties {
            schema.properties = merged_properties;
        }
        schema.version = ISAR_FILE_VERSION;

        Self::save_schema(&txn, info_db, &schema)?;

        let db = match schema.embedded {
            true => None,
            false => Some(txn.open_db(&schema.name, true, false)?),
        };

        let mut indexes = Vec::with_capacity(schema.indexes.len());
        for index in &schema.indexes {
            let index_db = Self::open_index_db(&txn, &schema.name, &index.name)?;
            let properties = index
                .properties
                .iter()
                .map(|p| {
                    properties
                        .iter()
                        .find(|(name, _)| name == p)
                        .unwrap()
                        .1
                        .clone()
                })
                .collect();
            let index =
                NativeIndex::new(&index.name, index_db, properties, index.unique, index.hash);
            indexes.push(index);
        }

        let collection = NativeCollection::new(
            schema_index as u16,
            &schema.name,
            schema.id_name.as_deref(),
            properties,
            indexes,
            db,
        );

        if !collection.is_embedded() {
            collection.init_auto_increment(&txn)?;
        }
        txn.commit()?;

        Ok(collection)
    }

    fn open_info_db(txn: &NativeTxn) -> Result<Db> {
        txn.open_db("_info", false, false)
    }

    fn find_schema(
        txn: &NativeTxn,
        info_db: Db,
        collection_name: &str,
    ) -> Result<Option<IsarSchema>> {
        let mut cursor = txn.get_cursor(info_db)?;

        match cursor.move_to(collection_name.as_bytes())? {
            Some((_, bytes)) => {
                let schema = serde_json::from_slice(bytes).map_err(|_| IsarError::SchemaError {
                    message: "Could not deserialize existing schema.".to_string(),
                })?;
                Ok(Some(schema))
            }
            None => Ok(None),
        }
    }

    fn get_schemas(txn: &NativeTxn, info_db: Db) -> Result<Vec<IsarSchema>> {
        txn.get_cursor(info_db)?
            .iter()?
            .map(|(_, bytes)| serde_json::from_slice(bytes))
            .collect::<serde_json::Result<Vec<_>>>()
            .map_err(|_| IsarError::SchemaError {
                message: "Could not deserialize existing schema.".to_string(),
            })
    }

    fn get_versioned_schemas(txn: &NativeTxn, info_db: Db) -> Result<Vec<VersionedIsarSchema>> {
        todo!()
    }

    pub fn open_index_db(txn: &NativeTxn, collection_name: &str, index_name: &str) -> Result<Db> {
        let db_name = format!("_{collection_name}_{index_name}");
        txn.open_db(&db_name, false, true)
    }

    fn build_properties(
        property_schemas: &[PropertySchema],
        schema_names: &[String],
    ) -> Vec<(String, NativeProperty)> {
        let mut properties = Vec::new();
        let mut offset = 0;

        for property_schema in property_schemas {
            if let Some(name) = &property_schema.name {
                let embedded_collection_index = property_schema
                    .collection
                    .as_ref()
                    .and_then(|collection| schema_names.iter().position(|n| n == collection))
                    .and_then(|index| Some(index as u16));
                let property = NativeProperty::new(
                    property_schema.data_type,
                    offset,
                    embedded_collection_index,
                );
                properties.push((name.to_owned(), property));
            }

            offset += property_schema.data_type.static_size() as u32;
        }

        properties
    }

    fn migrate_collection(
        txn: &NativeTxn,
        schema: &IsarSchema,
        existing_schema: &IsarSchema,
    ) -> Result<Vec<PropertySchema>> {
        if existing_schema.version != ISAR_FILE_VERSION {
            return Err(IsarError::VersionError {});
        }

        let changes = schema.find_changes(&existing_schema);

        for index_name in &changes.dropped_index_names {
            let index_db = Self::open_index_db(txn, &schema.name, index_name)?;
            txn.drop_db(index_db)?;
        }

        let mut merged_properties = existing_schema.properties.clone();

        for property_name in &changes.dropped_property_names {
            merged_properties
                .iter_mut()
                .find(|p| p.name.as_ref() == Some(property_name))
                .unwrap()
                .name
                .take();
        }

        for property in changes.added_properties {
            merged_properties.push(property.clone());
        }

        Ok(merged_properties)
    }

    fn save_schema(txn: &NativeTxn, info_db: Db, schema: &IsarSchema) -> Result<()> {
        let bytes = serde_json::to_vec(schema).map_err(|_| IsarError::SchemaError {
            message: "Could not serialize schema".to_string(),
        })?;

        txn.get_cursor(info_db)?.put(schema.name.as_bytes(), &bytes)
    }

    fn delete_collection(txn: &NativeTxn, info_db: Db, schema: &IsarSchema) -> Result<()> {
        let db = txn.open_db(&schema.name, true, false)?;
        txn.drop_db(db)?;

        for index in &schema.indexes {
            let index_db = Self::open_index_db(txn, &schema.name, &index.name)?;
            txn.drop_db(index_db)?;
        }

        let mut info_cursor = txn.get_cursor(info_db)?;
        if info_cursor.move_to(&schema.name.as_bytes())?.is_some() {
            info_cursor.delete_current()?;
        }

        Ok(())
    }
}
