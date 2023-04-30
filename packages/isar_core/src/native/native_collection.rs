use super::index::id_key::BytesToId;
use super::index::NativeIndex;
use super::mdbx::db::Db;
use super::native_txn::NativeTxn;
use crate::core::data_type::DataType;
use crate::core::error::{IsarError, Result};
use std::cell::Cell;

#[derive(Copy, Clone, Eq, PartialEq, Hash)]
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
    pub(crate) collection_index: usize,
    pub(crate) properties: Vec<NativeProperty>,
    pub(crate) indexes: Vec<NativeIndex>,
    pub(crate) embedded: bool,
    pub(crate) static_size: u16,
    db: Option<Db>,
    auto_increment: Cell<i64>,
}

impl NativeCollection {
    pub fn new(
        collection_index: usize,
        properties: Vec<NativeProperty>,
        indexes: Vec<NativeIndex>,
        embedded: bool,
        db: Option<Db>,
    ) -> Self {
        let static_size = properties
            .iter()
            .max_by_key(|p| p.offset)
            .map_or(0, |p| p.offset + p.data_type.static_size() as u32);
        Self {
            collection_index,
            properties,
            indexes,
            embedded,
            static_size: static_size as u16,
            db,
            auto_increment: Cell::new(i64::MIN),
        }
    }

    pub fn init_auto_increment(&self, txn: &NativeTxn) -> Result<()> {
        if let Some(db) = self.db {
            let mut cursor = txn.get_cursor(db)?;
            if let Some((key, _)) = cursor.move_to_last()? {
                let id = key.to_id();
                self.auto_increment.set(id);
            }
        }
        Ok(())
    }

    pub fn auto_increment(&self) -> Result<i64> {
        let last = self.auto_increment.get();
        if last < i64::MAX {
            self.auto_increment.set(last + 1);
            Ok(last + 1)
        } else {
            Err(IsarError::AutoIncrementOverflow {})
        }
    }

    pub fn get_db(&self) -> Result<Db> {
        self.db.ok_or(IsarError::UnsupportedOperation {
            message: "Operation not supported for embedded collections".to_string(),
        })
    }
}

unsafe impl Send for NativeCollection {}
unsafe impl Sync for NativeCollection {}

impl DataType {
    pub const fn static_size(&self) -> u8 {
        match self {
            DataType::Byte => 1,
            DataType::Int | DataType::Float => 4,
            DataType::Long | DataType::Double => 8,
            _ => 3,
        }
    }
}
