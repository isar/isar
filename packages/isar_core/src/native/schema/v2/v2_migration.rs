use crate::{
    core::{
        data_type::DataType,
        error::{IsarError, Result},
        schema::{IsarSchema, PropertySchema},
    },
    native::{
        isar_serializer::IsarSerializer,
        mdbx::db::Db,
        native_txn::NativeTxn,
        schema::{schema_manager::SchemaManager, versioned_isar_schema::VersionedIsarSchema},
    },
};

use super::{v2_isar_object::V2IsarObject, v2_isar_schema::V2IsarSchema};

pub fn migrate_v2_to_v3(
    txn: &NativeTxn,
    info_db: Db,
    v2_schema: &V2IsarSchema,
    schemas: &[VersionedIsarSchema],
) -> Result<IsarSchema> {
    let v3_schema = v2_schema.to_v3_schema();
    let db = txn.open_db(&v2_schema.name, true, false, false)?;

    if v3_schema.embedded {
        // Embedded schema is not directly linked to any databases.
        // The embedded objects will be converted when their parent collections are converted.
        SchemaManager::save_schema(txn, info_db, &v3_schema)?;
        txn.drop_db(db)?;
        return Ok(v3_schema);
    }

    // Drop all links
    for link in &v2_schema.links {
        let db_name = format!("_l_{}_{}", v2_schema.name, link.name);
        let db = txn.open_db(&db_name, true, true, true)?;
        txn.drop_db(db)?;

        let db_name = format!("_b_{}_{}", v2_schema.name, link.name);
        let db = txn.open_db(&db_name, true, true, true)?;
        txn.drop_db(db)?;
    }

    // Drop all indexes
    for index in &v2_schema.indexes {
        let db_name = format!("_i_{}_{}", v2_schema.name, index.name);
        let db = txn.open_db(&db_name, false, !index.unique, false)?;
        txn.drop_db(db)?;
    }

    let static_size: u32 = v3_schema
        .properties
        .iter()
        .map(|property| property.data_type.static_size() as u32)
        .sum();

    let mut cursor = txn.get_cursor(db)?;

    while let Some((key, bytes)) = cursor.move_to_next()? {
        let key = key.to_owned();
        let v2_object = V2IsarObject::from_bytes(bytes);

        let buffer = txn.take_buffer();
        let mut v3_object = IsarSerializer::with_buffer(buffer, 0, static_size);

        migrate_v2_object_to_v3(&v2_schema.properties, &v2_object, &mut v3_object, schemas)?;

        let bytes = v3_object.finish();
        cursor.put(&key, &bytes)?;
        txn.put_buffer(bytes);
    }

    SchemaManager::save_schema(txn, info_db, &v3_schema)?;

    Ok(v3_schema)
}

fn migrate_v2_object_to_v3(
    properties: &[PropertySchema],
    v2_object: &V2IsarObject,
    v3_object: &mut IsarSerializer,
    schemas: &[VersionedIsarSchema],
) -> Result<()> {
    // v2 objects needs to have header size in offset, not v3
    // v2 and v3 have different types for offsets, so 2 numbers
    // instead of having to cast everywhere.
    let mut read_offset = 2usize;
    let mut write_offset = 0u32;

    for property in properties {
        match property.data_type {
            DataType::Bool => {
                match v2_object.read_bool(read_offset) {
                    Some(value) => v3_object.write_bool(write_offset, value),
                    None => v3_object.write_null(write_offset, DataType::Bool),
                };
            }
            DataType::Byte => v3_object.write_byte(write_offset, v2_object.read_byte(read_offset)),
            DataType::Int => v3_object.write_int(write_offset, v2_object.read_int(read_offset)),
            DataType::Long => v3_object.write_long(write_offset, v2_object.read_long(read_offset)),
            DataType::Float => {
                v3_object.write_float(write_offset, v2_object.read_float(read_offset))
            }
            DataType::Double => {
                v3_object.write_double(write_offset, v2_object.read_double(read_offset))
            }
            DataType::String => match v2_object.read_string(read_offset) {
                Some(value) => v3_object.write_dynamic(write_offset, value.as_bytes()),
                None => v3_object.write_null(write_offset, DataType::String),
            },
            DataType::Object => match v2_object.read_object(read_offset) {
                None => v3_object.write_null(write_offset, DataType::Object),
                Some(nested_v2_object) => {
                    let nested_schema_properties =
                        get_object_property_target_collection_properties(property, schemas)?;
                    let nested_static_size: u32 = nested_schema_properties
                        .iter()
                        .map(|property| property.data_type.static_size() as u32)
                        .sum();

                    let mut nested_v3_object =
                        v3_object.begin_nested(write_offset, nested_static_size);
                    migrate_v2_object_to_v3(
                        nested_schema_properties,
                        &nested_v2_object,
                        &mut nested_v3_object,
                        schemas,
                    )?;
                    v3_object.end_nested(nested_v3_object);
                }
            },
            DataType::BoolList => match v2_object.read_bool_list(read_offset) {
                Some(values) => v3_object.write_value_or_null_list(
                    write_offset,
                    DataType::Bool,
                    &values,
                    |writer, offset, &value| writer.write_bool(offset, value),
                ),
                None => v3_object.write_null(write_offset, DataType::BoolList),
            },
            DataType::ByteList => match v2_object.read_byte_list(read_offset) {
                Some(values) => v3_object.write_list(
                    write_offset,
                    DataType::Byte,
                    values.len(),
                    |writer, offset, index| writer.write_byte(offset, values[index]),
                ),
                None => v3_object.write_null(write_offset, DataType::BoolList),
            },
            DataType::IntList => match v2_object.read_int_or_null_list(read_offset) {
                Some(values) => v3_object.write_value_or_null_list(
                    write_offset,
                    DataType::Int,
                    &values,
                    |writer, offset, &value| writer.write_int(offset, value),
                ),
                None => v3_object.write_null(write_offset, DataType::BoolList),
            },
            DataType::LongList => match v2_object.read_long_or_null_list(read_offset) {
                Some(values) => v3_object.write_value_or_null_list(
                    write_offset,
                    DataType::Long,
                    &values,
                    |writer, offset, &value| writer.write_long(offset, value),
                ),
                None => v3_object.write_null(write_offset, DataType::BoolList),
            },
            DataType::FloatList => match v2_object.read_float_or_null_list(read_offset) {
                Some(values) => v3_object.write_value_or_null_list(
                    write_offset,
                    DataType::Float,
                    &values,
                    |writer, offset, &value| writer.write_float(offset, value),
                ),
                None => v3_object.write_null(write_offset, DataType::BoolList),
            },
            DataType::DoubleList => match v2_object.read_double_or_null_list(read_offset) {
                Some(values) => v3_object.write_value_or_null_list(
                    write_offset,
                    DataType::Double,
                    &values,
                    |writer, offset, &value| writer.write_double(offset, value),
                ),
                None => v3_object.write_null(write_offset, DataType::BoolList),
            },
            DataType::StringList => match v2_object.read_string_list(read_offset) {
                Some(values) => v3_object.write_value_or_null_list(
                    write_offset,
                    DataType::String,
                    &values,
                    |writer, offset, &value| writer.write_dynamic(offset, value.as_bytes()),
                ),
                None => v3_object.write_null(write_offset, DataType::BoolList),
            },
            DataType::ObjectList => match v2_object.read_object_list(read_offset) {
                None => v3_object.write_null(write_offset, DataType::ObjectList),
                Some(nested_v2_objects) => {
                    let nested_schema_properties =
                        get_object_property_target_collection_properties(property, schemas)?;
                    let nested_static_size: u32 = nested_schema_properties
                        .iter()
                        .map(|property| property.data_type.static_size() as u32)
                        .sum();

                    v3_object.try_write_list(
                        write_offset,
                        DataType::Object,
                        nested_v2_objects.len(),
                        |writer, offset, index| {
                            let nested_v2_object = match nested_v2_objects[index] {
                                Some(object) => object,
                                None => {
                                    writer.write_null(offset, DataType::Object);
                                    return Ok(());
                                }
                            };

                            let mut nested = writer.begin_nested(offset, nested_static_size);
                            migrate_v2_object_to_v3(
                                nested_schema_properties,
                                &nested_v2_object,
                                &mut nested,
                                schemas,
                            )?;
                            writer.end_nested(nested);

                            Ok(())
                        },
                    )?;
                }
            },
            data_type => {
                return Err(IsarError::SchemaError {
                    message: format!(
                        "Unsupported data type {:?} in v2 to v3 migration.",
                        data_type
                    ),
                })
            }
        }

        let property_static_size = property.data_type.static_size();
        read_offset += property_static_size as usize;
        write_offset += property_static_size as u32;
    }

    Ok(())
}

fn get_object_property_target_collection_properties<'a>(
    property: &PropertySchema,
    schemas: &'a [VersionedIsarSchema],
) -> Result<&'a [PropertySchema]> {
    let collection = match property.collection {
        Some(ref collection) => collection,
        None => {
            return Err(IsarError::SchemaError {
                message: format!(
                    "Object field '{:?}' did not have a target collection",
                    property.name
                ),
            })
        }
    };

    let schema = schemas
        .iter()
        .find(|schema| {
            let name = match schema {
                VersionedIsarSchema::V2(schema) => &schema.name,
                VersionedIsarSchema::V3(schema) => &schema.name,
            };

            name == collection
        })
        .ok_or_else(|| IsarError::SchemaError {
            message: format!("Could not find target collection '{collection}'"),
        })?;

    match schema {
        VersionedIsarSchema::V2(schema) => Ok(&schema.properties),
        VersionedIsarSchema::V3(schema) => Ok(&schema.properties),
    }
}
