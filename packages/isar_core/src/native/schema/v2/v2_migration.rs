use crate::{
    core::{
        data_type::DataType,
        error::{IsarError, Result},
        schema::{IsarSchema, PropertySchema},
    },
    native::{
        isar_serializer::IsarSerializer, mdbx::db::Db, native_txn::NativeTxn, schema::{schema_manager::SchemaManager, versioned_isar_schema::VersionedIsarSchema}
    },
};

use super::{v2_isar_object::V2IsarObject, v2_isar_schema::V2IsarSchema};

pub fn migrate_v2_to_v3(
    txn: &NativeTxn,
    info_db: Db,
    v2_schema: &V2IsarSchema,
    schemas: &[VersionedIsarSchema],
) -> Result<IsarSchema> {
    // Drop all links
    for link in &v2_schema.links {
        let db_name = format!("_l_{}_{}", v2_schema.name, link.name);
        let db = txn.open_db(&db_name, true, true)?;
        txn.drop_db(db)?;
    }

    // Drop all indexes
    for index in &v2_schema.indexes {
        let db_name = format!("_i_{}_{}", v2_schema.name, index.name);
        let db = txn.open_db(&db_name, false, !index.unique)?;
        txn.drop_db(db)?;
    }

    let v3_schema = v2_schema.to_v3_schema();
    let static_size: u32 = v3_schema
        .properties
        .iter()
        .map(|property| property.data_type.static_size() as u32)
        .sum();

    let db = txn.open_db(&v2_schema.name, true, false)?;
    let mut cursor = txn.get_cursor(db)?;
    while let Some((key, bytes)) = cursor.move_to_next()? {
        let v2_object = V2IsarObject::from_bytes(bytes);
        let mut v3_object = IsarSerializer::new(0, static_size);

        migrate_v2_object_to_v3(&v2_schema.properties, &v2_object, &mut v3_object, schemas)?;

        cursor.put(key, &v3_object.finish())?;
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
    let mut offset = 0u32;
    for property in properties {
        match property.data_type {
            DataType::Bool => {
                match v2_object.read_bool(offset as usize) {
                    Some(value) => v3_object.write_bool(offset, value),
                    None => v3_object.write_null(offset, DataType::Bool),
                };
            }
            DataType::Byte => v3_object.write_byte(offset, v2_object.read_byte(offset as usize)),
            DataType::Int => v3_object.write_int(offset, v2_object.read_int(offset as usize)),
            DataType::Long => v3_object.write_long(offset, v2_object.read_long(offset as usize)),
            DataType::Float => v3_object.write_float(offset, v2_object.read_float(offset as usize)),
            DataType::Double => {
                v3_object.write_double(offset, v2_object.read_double(offset as usize))
            }
            DataType::String => match v2_object.read_string(offset as usize) {
                Some(value) => v3_object.write_dynamic(offset, value.as_bytes()),
                None => v3_object.write_null(offset, DataType::String),
            },
            DataType::Object => {
                let nested_v2_object = match v2_object.read_object(offset as usize) {
                    Some(object) => object,
                    None => {
                        v3_object.write_null(offset, DataType::Object);
                        continue;
                    }
                };

                let nested_schema_properties =
                    get_object_property_target_collection_properties(property, schemas)?;
                let nested_static_size: u32 = nested_schema_properties
                    .iter()
                    .map(|property| property.data_type.static_size() as u32)
                    .sum();

                let mut nested_v3_object = v3_object.begin_nested(offset, nested_static_size);
                migrate_v2_object_to_v3(
                    nested_schema_properties,
                    &nested_v2_object,
                    &mut nested_v3_object,
                    schemas,
                )?;
                v3_object.end_nested(nested_v3_object);
            }
            DataType::BoolList => match v2_object.read_bool_list(offset as usize) {
                Some(values) => v3_object.write_value_or_null_list(
                    offset,
                    DataType::BoolList,
                    &values,
                    |writer, offset, &value| writer.write_bool(offset, value),
                ),
                None => v3_object.write_null(offset, DataType::BoolList),
            },
            DataType::ByteList => match v2_object.read_byte_list(offset as usize) {
                Some(values) => v3_object.write_list(
                    offset,
                    DataType::ByteList,
                    values.len(),
                    |writer, offset, index| writer.write_byte(offset, values[index]),
                ),
                None => v3_object.write_null(offset, DataType::BoolList),
            },
            DataType::IntList => match v2_object.read_int_or_null_list(offset as usize) {
                Some(values) => v3_object.write_value_or_null_list(
                    offset,
                    DataType::IntList,
                    &values,
                    |writer, offset, &value| writer.write_int(offset, value),
                ),
                None => v3_object.write_null(offset, DataType::BoolList),
            },
            DataType::LongList => match v2_object.read_long_or_null_list(offset as usize) {
                Some(values) => v3_object.write_value_or_null_list(
                    offset,
                    DataType::LongList,
                    &values,
                    |writer, offset, &value| writer.write_long(offset, value),
                ),
                None => v3_object.write_null(offset, DataType::BoolList),
            },
            DataType::FloatList => match v2_object.read_float_or_null_list(offset as usize) {
                Some(values) => v3_object.write_value_or_null_list(
                    offset,
                    DataType::FloatList,
                    &values,
                    |writer, offset, &value| writer.write_float(offset, value),
                ),
                None => v3_object.write_null(offset, DataType::BoolList),
            },
            DataType::DoubleList => match v2_object.read_double_or_null_list(offset as usize) {
                Some(values) => v3_object.write_value_or_null_list(
                    offset,
                    DataType::DoubleList,
                    &values,
                    |writer, offset, &value| writer.write_double(offset, value),
                ),
                None => v3_object.write_null(offset, DataType::BoolList),
            },
            DataType::StringList => match v2_object.read_string_list(offset as usize) {
                Some(values) => v3_object.write_value_or_null_list(
                    offset,
                    DataType::StringList,
                    &values,
                    |writer, offset, &value| writer.write_dynamic(offset, value.as_bytes()),
                ),
                None => v3_object.write_null(offset, DataType::BoolList),
            },
            DataType::ObjectList => {
                let nested_v2_objects = match v2_object.read_object_list(offset as usize) {
                    Some(objects) => objects,
                    None => {
                        v3_object.write_null(offset, DataType::ObjectList);
                        continue;
                    }
                };

                let nested_schema_properties =
                    get_object_property_target_collection_properties(property, schemas)?;
                let nested_static_size: u32 = nested_schema_properties
                    .iter()
                    .map(|property| property.data_type.static_size() as u32)
                    .sum();

                v3_object.try_write_list(
                    offset,
                    DataType::ObjectList,
                    nested_v2_objects.len(),
                    |writer, offset, index| {
                        let nested_v2_object = match nested_v2_objects[index] {
                            Some(object) => object,
                            None => {
                                writer.write_null(offset, DataType::ObjectList);
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
            data_type => {
                return Err(IsarError::SchemaError {
                    message: format!(
                        "Unsupported data type {:?} in v2 to v3 migration.",
                        data_type
                    ),
                })
            }
        }

        offset += property.data_type.static_size() as u32;
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
