use super::isar_deserializer::IsarDeserializer;
use super::isar_serializer::IsarSerializer;
use super::mdbx::db::Db;
use super::native_index::NativeIndex;
use super::native_txn::{NativeTxn, TxnCursor};
use super::query::NativeQuery;
use super::{BytesToId, IdToBytes};
use crate::core::data_type::DataType;
use crate::core::error::{IsarError, Result};
use crate::core::value::IsarValue;
use crate::core::watcher::{ChangeSet, CollectionWatchers};
use std::sync::atomic::{self, AtomicI64};
use std::sync::Arc;

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

pub(crate) struct NativeCollection {
    pub collection_index: u16,
    pub name: String,
    pub id_name: Option<String>,
    pub properties: Vec<(String, NativeProperty)>,
    pub indexes: Vec<NativeIndex>,
    pub static_size: u32,
    pub watchers: Arc<CollectionWatchers<NativeQuery>>,
    auto_increment: AtomicI64,
    db: Option<Db>,
}

impl NativeCollection {
    pub fn new(
        collection_index: u16,
        name: &str,
        id_name: Option<&str>,
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
            name: name.to_string(),
            id_name: id_name.map(|s| s.to_string()),
            properties,
            indexes,
            static_size,
            watchers: CollectionWatchers::new(),
            auto_increment: AtomicI64::new(1),
            db,
        }
    }

    pub fn get_cursor<'a>(&self, txn: &'a NativeTxn) -> Result<TxnCursor<'a>> {
        let db = self.db.ok_or(IsarError::UnsupportedOperation {})?;
        txn.get_cursor(db)
    }

    pub fn is_embedded(&self) -> bool {
        self.id_name.is_none()
    }

    pub fn init_auto_increment(&self, txn: &NativeTxn) -> Result<()> {
        let mut cursor = self.get_cursor(txn)?;
        if let Some((key, _)) = cursor.move_to_last()? {
            let next_id = key.to_id() + 1;
            self.auto_increment
                .store(next_id, atomic::Ordering::Release);
        }
        Ok(())
    }

    pub fn auto_increment(&self) -> i64 {
        self.auto_increment.fetch_add(1, atomic::Ordering::AcqRel)
    }

    fn update_auto_increment(&self, id: i64) {
        self.auto_increment
            .fetch_max(id + 1, atomic::Ordering::AcqRel);
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
        if let Some(db) = self.db {
            let mut size = txn.stat(db)?.1;
            if include_indexes {
                for index in &self.indexes {
                    size += index.get_size(txn)?;
                }
            }
            Ok(size)
        } else {
            Ok(0)
        }
    }

    pub fn count(&self, txn: &NativeTxn) -> Result<u32> {
        if let Some(db) = self.db {
            Ok(txn.stat(db)?.0 as u32)
        } else {
            Ok(0)
        }
    }

    pub fn put<'a>(
        &self,
        txn: &'a NativeTxn,
        change_set: &mut ChangeSet,
        cursor: &mut TxnCursor<'a>,
        id: i64,
        bytes: &[u8],
    ) -> Result<()> {
        let id_bytes = id.to_id_bytes();

        // we only fetch the previous object if there are query watchers or indexes
        if !self.indexes.is_empty() || self.watchers.has_query_watchers() {
            if let Some((_, bytes)) = cursor.move_to(&id_bytes)? {
                let object = IsarDeserializer::from_bytes(&bytes);
                // register old object change
                change_set.register_change(&self.watchers, id, &object);

                if !self.indexes.is_empty() {
                    let mut buffer = txn.take_buffer();
                    // delete old object indexes
                    for index in &self.indexes {
                        buffer = index.delete_for_object(txn, id, object, buffer)?;
                    }
                    txn.put_buffer(buffer);
                }
            }
        }

        let object = IsarDeserializer::from_bytes(&bytes);
        // register new object change
        change_set.register_change(&self.watchers, id, &object);

        if !self.indexes.is_empty() {
            let mut buffer = txn.take_buffer();

            // create new object indexes
            for index in &self.indexes {
                buffer = index.create_for_object(txn, id, object, buffer, |id| {
                    self.delete(txn, change_set, cursor, id)?;
                    Ok(())
                })?;
            }

            txn.put_buffer(buffer);
        }

        self.update_auto_increment(id);
        cursor.put(&id_bytes, bytes)
    }

    pub fn delete<'a>(
        &self,
        txn: &'a NativeTxn,
        change_set: &mut ChangeSet,
        cursor: &mut TxnCursor<'a>,
        id: i64,
    ) -> Result<bool> {
        if let Some((_, bytes)) = cursor.move_to(&id.to_id_bytes())? {
            let object = IsarDeserializer::from_bytes(&bytes);
            change_set.register_change(&self.watchers, id, &object);

            if !self.indexes.is_empty() {
                let mut buffer = txn.take_buffer();
                for index in &self.indexes {
                    buffer = index.delete_for_object(txn, id, object, buffer)?;
                }
                txn.put_buffer(buffer);
            }

            cursor.delete_current()?;
            Ok(true)
        } else {
            Ok(false)
        }
    }

    pub fn update<'a>(
        &self,
        txn: &'a NativeTxn,
        change_set: &mut ChangeSet,
        cursor: &mut TxnCursor<'a>,
        id: i64,
        updates: &[(u16, Option<IsarValue>)],
    ) -> Result<bool> {
        if let Some((_, old_object)) = cursor.move_to(&id.to_id_bytes())? {
            let mut buffer = txn.take_buffer();
            buffer.extend_from_slice(&old_object);
            let mut new_object = IsarSerializer::new(buffer, 0, self.static_size);

            for (property_index, value) in updates {
                self.write_value(&mut new_object, *property_index as u16, value.as_ref())?;
            }

            let buffer = new_object.finish();
            self.put(txn, change_set, cursor, id, &buffer)?;
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
                    object.write_bool(p.offset, *value)
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

    pub fn clear(&self, txn: &NativeTxn) -> Result<()> {
        let db = self.db.ok_or(IsarError::UnsupportedOperation {})?;
        let mut change_set = txn.get_change_set();
        change_set.register_all(&self.watchers);
        txn.clear_db(db)?;
        for index in &self.indexes {
            index.clear(txn)?;
        }
        Ok(())
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
