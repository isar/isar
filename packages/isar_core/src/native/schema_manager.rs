use super::index::index_key::IndexKey;
use super::mdbx::cursor::Cursor;
use super::mdbx::db::Db;
use super::native_collection::{NativeCollection, NativeProperty};
use super::native_txn::{NativeTxn, TxnCursor};
use crate::core::error::{IsarError, Result};
use crate::core::schema::{CollectionSchema, IsarSchema, PropertySchema};
use itertools::Itertools;
use std::borrow::Cow;
use std::ops::{Deref, DerefMut};

const ISAR_FILE_VERSION: u8 = 2;

pub fn perform_migration(txn: &NativeTxn, schema: &IsarSchema) -> Result<Vec<NativeCollection>> {
    let info_db = txn.open_db("_info", false, false)?;
    let existing_schemas = get_schemas(txn.get_cursor(info_db)?)?;

    let mut info_cursor = txn.get_cursor(info_db)?;
    let mut collections = vec![];
    for col_schema in schema.collections.iter() {
        let existing_schema_index = existing_schemas
            .iter()
            .position(|c| c.name == col_schema.name);
        let updated_schema = if let Some(existing_schema_index) = existing_schema_index {
            let existing_schema = &existing_schemas[existing_schema_index];

            let mut col_schema = col_schema.clone();
            migrate_collection(txn, &mut col_schema, existing_schema)?;
            save_schema(info_cursor.deref_mut(), &col_schema)?;
            Cow::Owned(col_schema)
        } else {
            Cow::Borrowed(col_schema)
        };

        let collection = open_collection(
            txn,
            collections.len(),
            updated_schema.deref(),
            &schema.collections,
        )?;
        collections.push(collection);
    }

    Ok(collections)
}

fn get_schemas(info_cursor: TxnCursor) -> Result<Vec<CollectionSchema>> {
    let mut schemas = vec![];
    for (_, bytes) in info_cursor.iter(true)? {
        let col = serde_json::from_slice::<CollectionSchema>(bytes).map_err(|_| {
            IsarError::DbCorrupted {
                message: "Could not deserialize existing schema.".to_string(),
            }
        })?;
        schemas.push(col);
    }
    Ok(schemas)
}

fn save_schema(info_cursor: &mut Cursor, schema: &CollectionSchema) -> Result<()> {
    let key = IndexKey::from_bytes(schema.name.as_bytes().to_vec());
    let bytes = serde_json::to_vec(schema).map_err(|_| IsarError::SchemaError {
        message: "Could not serialize schema.".to_string(),
    })?;
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

fn open_index_db(
    txn: &NativeTxn,
    col_name: &str,
    index_name: &str,
    index_unique: bool,
) -> Result<Db> {
    let db_name = format!("_{}_{}", col_name, index_name);
    txn.open_db(&db_name, false, !index_unique)
}

fn migrate_collection(
    txn: &NativeTxn,
    schema: &mut CollectionSchema,
    existing_schema: &CollectionSchema,
) -> Result<Vec<PropertySchema>> {
    if existing_schema.version != ISAR_FILE_VERSION {
        return Err(IsarError::VersionError {});
    }

    let (add_properties, drop_properties, add_indexes, drop_indexes) =
        schema.find_changes(&existing_schema);

    for (index, unique) in &drop_indexes {
        let db = open_index_db(txn, &schema.name, index, *unique)?;
        txn.drop_db(db)?;
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

    for property in &schema.properties {
        if add_properties.contains(&property) {
            merged_properties.push(property.clone());
        }
    }

    Ok(merged_properties)
}

fn open_collection(
    txn: &NativeTxn,
    collection_index: usize,
    schema: &CollectionSchema,
    all_schemas: &[CollectionSchema],
) -> Result<NativeCollection> {
    let mut properties = vec![];
    let mut offset = 0;
    for property_schema in &schema.properties {
        if let Some(name) = &property_schema.name {
            let embedded_collection_index = if let Some(collection) = &property_schema.collection {
                let index = all_schemas
                    .iter()
                    .position(|c| c.name == *collection)
                    .unwrap();
                Some(index as u16)
            } else {
                None
            };
            let property =
                NativeProperty::new(property_schema.data_type, offset, embedded_collection_index);
            properties.push((property, name));
        }
        offset += property_schema.data_type.static_size() as u32;
    }

    properties.sort_by(|(_, a), (_, b)| a.cmp(&b));
    let properties = properties.iter().map(|(p, _)| p).copied().collect_vec();

    let db = if !schema.embedded {
        Some(txn.open_db(&schema.name, true, false)?)
    } else {
        None
    };

    let col = NativeCollection::new(collection_index, properties, vec![], schema.embedded, db);
    col.init_largest_id(txn)?;

    Ok(col)
}
