use super::index::id_key::{BytesToId, IdToBytes};
use super::index::NativeIndex;
use super::mdbx::db::Db;
use super::native_txn::NativeTxn;
use crate::core::data_type::DataType;
use crate::core::error::{IsarError, Result};
use std::cell::Cell;

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
    properties: Vec<(String, NativeProperty)>,
    pub(crate) indexes: Vec<NativeIndex>,
    pub(crate) static_size: u32,
    db: Option<Db>,
    auto_increment: Cell<i64>,
}

impl NativeCollection {
    pub fn new(
        collection_index: u16,
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
            properties,
            indexes,
            static_size: static_size,
            db,
            auto_increment: Cell::new(i64::MIN),
        }
    }

    pub fn init_largest_id(&self, txn: &NativeTxn) -> Result<()> {
        if let Some(db) = self.db {
            let mut cursor = txn.get_cursor(db)?;
            if let Some((key, _)) = cursor.move_to_last()? {
                let id = key.to_id();
                self.auto_increment.set(id);
            }
        }
        Ok(())
    }

    pub fn get_largest_id(&self) -> i64 {
        self.auto_increment.get()
    }

    pub fn update_largest_id(&self, id: i64) {
        let last = self.auto_increment.get();
        if last < id {
            self.auto_increment.set(id);
        }
    }

    pub fn get_db(&self) -> Result<Db> {
        self.db.ok_or(IsarError::UnsupportedOperation {})
    }

    #[inline]
    pub fn get_property(&self, property_index: u32) -> Option<&NativeProperty> {
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
    pub const fn static_size(&self) -> u8 {
        match self {
            DataType::Bool | DataType::Byte => 1,
            DataType::Int | DataType::Float => 4,
            DataType::Long | DataType::Double => 8,
            _ => 3,
        }
    }
}
