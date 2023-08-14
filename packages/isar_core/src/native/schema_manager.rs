use super::mdbx::db::Db;
use super::mdbx::env::Env;
use super::native_collection::{NativeCollection, NativeProperty};
use super::native_index::NativeIndex;
use super::native_txn::NativeTxn;
use crate::core::error::{IsarError, Result};
use crate::core::schema::{IsarSchema, PropertySchema};
use itertools::Itertools;
use std::borrow::Cow;
use std::sync::Arc;

const ISAR_FILE_VERSION: u8 = 3;

pub(crate) fn perform_migration(
    instance_id: u32,
    env: &Arc<Env>,
    mut schemas: Vec<IsarSchema>,
) -> Result<Vec<NativeCollection>> {
    let txn = NativeTxn::new(instance_id, env, true)?;
    let info_db = open_info_db(&txn)?;
    let existing_schemas = get_schemas(&txn, info_db)?;
    txn.commit()?;

    let schema_names = schemas.iter().map(|c| c.name.to_string()).collect_vec();

    let mut collections = vec![];
    for schema in schemas.iter_mut() {
        let existing_schema_index = existing_schemas.iter().position(|c| c.name == schema.name);

        let txn = NativeTxn::new(instance_id, env, true)?;
        let merged_properties = if let Some(existing_schema_index) = existing_schema_index {
            let existing_schema = &existing_schemas[existing_schema_index];

            let merged_properties = migrate_collection(&txn, &schema, existing_schema)?;
            Cow::Owned(merged_properties)
        } else {
            Cow::Borrowed(&schema.properties)
        };

        let mut properties = get_properties(&merged_properties, &schema_names);
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
        save_schema(&txn, info_db, &schema)?;

        let db = if !schema.embedded {
            Some(txn.open_db(&schema.name, true, false)?)
        } else {
            None
        };

        let mut indexes = vec![];
        for index in &schema.indexes {
            let index_db = open_index_db(&txn, &schema.name, &index.name)?;
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
                .collect_vec();
            let index =
                NativeIndex::new(&index.name, index_db, properties, index.unique, index.hash);
            indexes.push(index);
        }

        let col = NativeCollection::new(
            collections.len() as u16,
            &schema.name,
            schema.id_name.as_deref(),
            properties,
            indexes,
            db,
        );

        if !col.is_embedded() {
            col.init_auto_increment(&txn)?;
        }
        txn.commit()?;

        collections.push(col);
    }

    let txn = NativeTxn::new(instance_id, env, true)?;
    for existing_schema in existing_schemas {
        if !schemas.iter().any(|c| c.name == existing_schema.name) {
            delete_collection(&txn, info_db, &existing_schema)?;
        }
    }
    txn.commit()?;

    Ok(collections)
}

fn get_schemas(txn: &NativeTxn, info_db: Db) -> Result<Vec<IsarSchema>> {
    let info_cursor = txn.get_cursor(info_db)?;
    let mut schemas = vec![];
    for (_, bytes) in info_cursor.iter()? {
        let col =
            serde_json::from_slice::<IsarSchema>(bytes).map_err(|_| IsarError::SchemaError {
                message: "Could not deserialize existing schema.".to_string(),
            })?;
        schemas.push(col);
    }
    Ok(schemas)
}

fn save_schema(txn: &NativeTxn, info_db: Db, schema: &IsarSchema) -> Result<()> {
    let mut info_cursor = txn.get_cursor(info_db)?;
    let bytes = serde_json::to_vec(schema).map_err(|_| IsarError::SchemaError {
        message: "Could not serialize schema.".to_string(),
    })?;
    info_cursor.put(&schema.name.as_bytes(), &bytes)?;
    Ok(())
}

fn open_info_db(txn: &NativeTxn) -> Result<Db> {
    txn.open_db("_info", false, false)
}

fn open_index_db(txn: &NativeTxn, col_name: &str, index_name: &str) -> Result<Db> {
    let db_name = format!("_{}_{}", col_name, index_name);
    txn.open_db(&db_name, false, true)
}

fn delete_collection(txn: &NativeTxn, info_db: Db, schema: &IsarSchema) -> Result<()> {
    let db = txn.open_db(&schema.name, true, false)?;
    txn.drop_db(db)?;
    for index in &schema.indexes {
        let index_db = open_index_db(txn, &schema.name, &index.name)?;
        txn.drop_db(index_db)?;
    }

    let mut info_cursor = txn.get_cursor(info_db)?;
    if info_cursor.move_to(&schema.name.as_bytes())?.is_some() {
        info_cursor.delete_current()?;
    }
    Ok(())
}

fn migrate_collection(
    txn: &NativeTxn,
    schema: &IsarSchema,
    existing_schema: &IsarSchema,
) -> Result<Vec<PropertySchema>> {
    if existing_schema.version != ISAR_FILE_VERSION {
        return Err(IsarError::VersionError {});
    }

    let (add_properties, drop_properties, add_indexes, drop_indexes) =
        schema.find_changes(&existing_schema);

    for index in &drop_indexes {
        let index_db = open_index_db(txn, &schema.name, index)?;
        txn.drop_db(index_db)?;
    }

    let mut merged_properties = existing_schema.properties.clone();

    for property in &drop_properties {
        merged_properties
            .iter_mut()
            .find(|p| p.name.as_ref() == Some(property))
            .unwrap()
            .name
            .take();
    }

    for property in add_properties {
        merged_properties.push(property.clone());
    }

    Ok(merged_properties)
}

fn get_properties(
    property_schemas: &[PropertySchema],
    schema_names: &[String],
) -> Vec<(String, NativeProperty)> {
    let mut properties = vec![];
    let mut offset = 0;
    for property_schema in property_schemas {
        if let Some(name) = &property_schema.name {
            let embedded_collection_index = if let Some(collection) = &property_schema.collection {
                let index = schema_names.iter().position(|n| n == collection).unwrap();
                Some(index as u16)
            } else {
                None
            };
            let property =
                NativeProperty::new(property_schema.data_type, offset, embedded_collection_index);
            properties.push((name.clone(), property));
        }
        offset += property_schema.data_type.static_size() as u32;
    }
    properties
}
