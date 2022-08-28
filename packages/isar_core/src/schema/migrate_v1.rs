use itertools::Itertools;

use crate::legacy::isar_object_v1::{LegacyIsarObject, LegacyProperty};
use crate::object::data_type::DataType;
use crate::object::id::BytesToId;
use crate::object::isar_object::IsarObject;
use crate::object::object_builder::ObjectBuilder;
use crate::schema::schema_manager::SchemaManager;
use crate::{cursor::IsarCursors, error::Result, mdbx::txn::Txn};

use super::collection_schema::CollectionSchema;

pub fn migrate_v1(txn: &Txn, schema: &mut CollectionSchema) -> Result<()> {
    let cursors = IsarCursors::new(txn, vec![]);
    let mut buffer = Some(vec![]);

    for index in &schema.indexes {
        let index_db = SchemaManager::open_index_db(txn, schema, index)?;
        index_db.clear(txn)?;
    }
    schema.indexes.clear();

    let props = schema.get_properties();

    let mut offset = 2;
    let legacy_props = schema
        .properties
        .iter()
        .map(|p| {
            let property = LegacyProperty::new(p.data_type, offset);
            offset += match p.data_type {
                DataType::Byte => 1,
                DataType::Int | DataType::Float => 4,
                _ => 8,
            };

            property
        })
        .collect_vec();

    let db = SchemaManager::open_collection_db(txn, schema)?;
    let mut db_cursor = cursors.get_cursor(db)?;
    db_cursor.iter_all(false, true, |cursor, id_bytes, obj| {
        // We need to copy the data here because it will become invalid during the write
        let id = id_bytes.to_id();
        let obj = obj.to_vec();

        let legacy_object = LegacyIsarObject::from_bytes(&obj);
        let mut new_object = ObjectBuilder::new(&props, buffer.take());
        for (prop, legacy_prop) in props.iter().zip(&legacy_props) {
            match prop.data_type {
                DataType::Bool => {
                    if legacy_object.is_null(*legacy_prop) {
                        new_object.write_bool(prop.offset, None);
                    } else {
                        new_object
                            .write_bool(prop.offset, Some(legacy_object.read_bool(*legacy_prop)))
                    }
                }
                DataType::Byte => {
                    new_object.write_byte(prop.offset, legacy_object.read_byte(*legacy_prop))
                }
                DataType::Int => {
                    new_object.write_int(prop.offset, legacy_object.read_int(*legacy_prop))
                }
                DataType::Float => {
                    new_object.write_float(prop.offset, legacy_object.read_float(*legacy_prop))
                }
                DataType::Long => {
                    new_object.write_long(prop.offset, legacy_object.read_long(*legacy_prop))
                }
                DataType::Double => {
                    new_object.write_double(prop.offset, legacy_object.read_double(*legacy_prop))
                }
                DataType::String => {
                    new_object.write_string(prop.offset, legacy_object.read_string(*legacy_prop))
                }
                DataType::BoolList => {
                    let byte_list = legacy_object.read_byte_list(*legacy_prop);
                    let bool_list = byte_list.map(|bytes| {
                        bytes
                            .into_iter()
                            .map(|b| IsarObject::byte_to_bool(*b))
                            .collect_vec()
                    });
                    new_object.write_bool_list(prop.offset, bool_list.as_deref())
                }
                DataType::ByteList => new_object
                    .write_byte_list(prop.offset, legacy_object.read_byte_list(*legacy_prop)),
                DataType::IntList => new_object.write_int_list(
                    prop.offset,
                    legacy_object.read_int_list(*legacy_prop).as_deref(),
                ),
                DataType::FloatList => new_object.write_float_list(
                    prop.offset,
                    legacy_object.read_float_list(*legacy_prop).as_deref(),
                ),
                DataType::LongList => new_object.write_long_list(
                    prop.offset,
                    legacy_object.read_long_list(*legacy_prop).as_deref(),
                ),
                DataType::DoubleList => new_object.write_double_list(
                    prop.offset,
                    legacy_object.read_double_list(*legacy_prop).as_deref(),
                ),
                DataType::StringList => new_object.write_string_list(
                    prop.offset,
                    legacy_object.read_string_list(*legacy_prop).as_deref(),
                ),
                _ => unreachable!(),
            }
        }

        cursor.put(&id, new_object.finish().as_bytes())?;
        buffer.replace(new_object.recycle());
        Ok(true)
    })?;

    Ok(())
}
