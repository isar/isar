use super::index::id_key::IdToBytes;
use super::index::NativeIndex;
use super::isar_serializer::IsarSerializer;
use super::mdbx::db::Db;
use super::native_txn::NativeTxn;
use crate::core::data_type::DataType;
use crate::core::error::{IsarError, Result};
use crate::core::value::IsarValue;

#[derive(Copy, Clone, Eq, PartialEq, Hash, Debug)]
pub struct NativeProperty {
    pub data_type: DataType,
    pub offset: u32,
    pub embedded_collection_index: Option<u16>,
}

impl NativeProperty {
    pub fn new(data_type: DataType, offset: u32, embedded_collection_index: Option<u16>) -> Self {
        NativeProperty {
            data_type,
            offset,
            embedded_collection_index,
        }
    }
}

#[derive(Clone)]
pub struct NativeCollection {
    pub(crate) collection_index: u16,
    pub(crate) name: String,
    pub(crate) properties: Vec<(String, NativeProperty)>,
    pub(crate) indexes: Vec<NativeIndex>,
    pub(crate) static_size: u32,
    db: Option<Db>,
}

impl NativeCollection {
    pub fn new(
        collection_index: u16,
        name: String,
        properties: Vec<(String, NativeProperty)>,
        indexes: Vec<NativeIndex>,
        db: Option<Db>,
    ) -> Self {
        let static_size = properties
            .iter()
            .max_by_key(|(_, p)| p.offset)
            .map_or(0, |(_, p)| p.offset + p.data_type.static_size() as u32);
        Self {
            collection_index,
            name,
            properties,
            indexes,
            static_size,
            db,
        }
    }

    pub fn get_db(&self) -> Result<Db> {
        self.db.ok_or(IsarError::UnsupportedOperation {})
    }

    #[inline]
    pub fn get_property(&self, property_index: u16) -> Option<&NativeProperty> {
        if property_index != 0 {
            self.properties
                .get(property_index as usize - 1)
                .map(|(_, p)| p)
        } else {
            None
        }
    }

    pub fn get_size(&self, txn: &NativeTxn, include_indexes: bool) -> Result<u64> {
        let size = txn.stat(self.get_db()?)?.1;

        if include_indexes {
            for index in &self.indexes {
                //size += index.get_size(cursors)?;
            }
        }

        Ok(size)
    }

    pub fn update(
        &self,
        txn: &NativeTxn,
        id: i64,
        updates: &[(u16, Option<IsarValue>)],
    ) -> Result<bool> {
        let mut cursor = txn.get_cursor(self.get_db()?)?;
        let key = id.to_id_bytes();
        if let Some((_, object)) = cursor.move_to(&key)? {
            let mut buffer = txn.take_buffer();
            buffer.extend_from_slice(&object);
            let mut object = IsarSerializer::new(buffer, 0, self.static_size);

            for (property_index, value) in updates {
                self.write_value(&mut object, *property_index as u16, value.as_ref())?;
            }

            let buffer = object.finish();
            cursor.put(&key, &buffer)?;

            txn.put_buffer(buffer);
            Ok(true)
        } else {
            Ok(false)
        }
    }

    fn write_value(
        &self,
        object: &mut IsarSerializer,
        property_index: u16,
        value: Option<&IsarValue>,
    ) -> Result<()> {
        if let Some(p) = self.get_property(property_index) {
            match (value, p.data_type) {
                (None, _) => object.write_null(p.offset, p.data_type),
                (Some(IsarValue::Bool(value)), DataType::Bool) => {
                    object.write_bool(p.offset, Some(*value))
                }
                (Some(IsarValue::Integer(value)), DataType::Byte) => {
                    object.write_byte(p.offset, *value as u8)
                }
                (Some(IsarValue::Integer(value)), DataType::Int) => {
                    object.write_int(p.offset, *value as i32)
                }
                (Some(IsarValue::Integer(value)), DataType::Long) => {
                    object.write_long(p.offset, *value)
                }
                (Some(IsarValue::Real(value)), DataType::Float) => {
                    object.write_float(p.offset, *value as f32)
                }
                (Some(IsarValue::Real(value)), DataType::Double) => {
                    object.write_double(p.offset, *value)
                }
                (Some(IsarValue::String(value)), DataType::String)
                | (Some(IsarValue::String(value)), DataType::Json) => {
                    object.update_dynamic(p.offset, value.as_bytes())
                }
                _ => return Err(IsarError::IllegalArgument {}),
            }
            Ok(())
        } else {
            return Err(IsarError::IllegalArgument {});
        }
    }

    pub fn delete(&self, txn: &NativeTxn, id: i64) -> Result<bool> {
        let mut cursor = txn.get_cursor(self.get_db()?)?;
        if cursor.move_to(&id.to_id_bytes())?.is_some() {
            cursor.delete_current()?;
            Ok(true)
        } else {
            Ok(false)
        }
    }

    pub fn clear(&self, txn: &NativeTxn) -> Result<()> {
        txn.clear_db(self.get_db()?)
    }
}

unsafe impl Send for NativeCollection {}
unsafe impl Sync for NativeCollection {}

impl DataType {
    #[inline]
    pub const fn static_size(&self) -> u8 {
        match self {
            DataType::Bool | DataType::Byte => 1,
            DataType::Int | DataType::Float => 4,
            DataType::Long | DataType::Double => 8,
            _ => 3,
        }
    }
}
