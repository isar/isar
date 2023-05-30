use super::index::index_key::IndexKey;
use super::mdbx::cursor::Cursor;
use super::mdbx::db::Db;
use super::native_collection::{NativeCollection, NativeProperty};
use super::native_txn::{NativeTxn, TxnCursor};
use crate::core::error::{IsarError, Result};
use crate::core::schema::{CollectionSchema, IsarSchema, PropertySchema};
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
            let merged_properties = migrate_collection(txn, &mut col_schema, existing_schema)?;
            col_schema.properties = merged_properties;
            save_schema(info_cursor.deref_mut(), &col_schema)?;
            Cow::Owned(col_schema)
        } else {
            Cow::Borrowed(col_schema)
        };

        let collection = open_collection(
            txn,
            collections.len() as u16,
            updated_schema.deref(),
            &schema.collections,
        )?;
        collections.push(collection);
    }

    Ok(collections)
}

fn get_schemas(info_cursor: TxnCursor) -> Result<Vec<CollectionSchema>> {
    let mut schemas = vec![];
    let start = IndexKey::new();
    let mut end = IndexKey::new();
    end.add_long(i64::MAX);
    for (_, bytes) in info_cursor.iter_between(&start, &end, false, false)? {
        let col = serde_json::from_slice::<CollectionSchema>(bytes).map_err(|_| {
            IsarError::SchemaError {
                message: "Could not deserialize existing schema.".to_string(),
            }
        })?;
        schemas.push(col);
    }
    Ok(schemas)
}

fn save_schema(info_cursor: &mut Cursor, schema: &CollectionSchema) -> Result<()> {
    let bytes = serde_json::to_vec(schema).map_err(|_| IsarError::SchemaError {
        message: "Could not serialize schema.".to_string(),
    })?;
    info_cursor.put(&schema.name.as_bytes(), &bytes)?;
    Ok(())
}

fn delete_schema(info_cursor: &mut Cursor, schema: &CollectionSchema) -> Result<()> {
    if info_cursor.move_to(schema.name.as_bytes())?.is_some() {
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
    schema: &CollectionSchema,
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

    merged_properties.sort_by_key(|mp| {
        schema
            .properties
            .iter()
            .position(|p| p.name == mp.name)
            .unwrap_or(usize::MAX)
    });

    Ok(merged_properties)
}

fn open_collection(
    txn: &NativeTxn,
    collection_index: u16,
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
            properties.push((name.clone(), property));
        }
        offset += property_schema.data_type.static_size() as u32;
    }

    let db = if !schema.embedded {
        Some(txn.open_db(&schema.name, true, false)?)
    } else {
        None
    };

    let col = NativeCollection::new(collection_index, properties, vec![], db);
    Ok(col)
}
