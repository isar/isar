use std::cell::Cell;

use byteorder::{ByteOrder, LittleEndian};

use super::native_collection::NativeCollection;
use super::native_txn::NativeTxn;
use super::MAX_OBJ_SIZE;
use crate::core::error::{IsarError, Result};
use crate::core::insert::IsarInsert;

pub struct NativeInsert<'a> {
    txn: NativeTxn,
    pub(crate) collection: &'a NativeCollection,
    pub(crate) all_collections: &'a Vec<NativeCollection>,

    inserted_count: u32,
    count: u32,

    pub(crate) buffer: Cell<Vec<u8>>,
    pub(crate) property: usize,
    id: i64,
}

impl<'a> NativeInsert<'a> {
    pub fn new(
        txn: NativeTxn,
        collection: &'a NativeCollection,
        all_collections: &'a Vec<NativeCollection>,
        count: u32,
    ) -> Self {
        let mut buffer = Vec::with_capacity(collection.static_size as usize * 2);
        buffer.resize(collection.static_size as usize, 0);
        LittleEndian::write_u16(&mut buffer, collection.static_size as u16);

        Self {
            buffer: Cell::new(buffer),
            property: 0,
            id: 0,
            txn,
            collection,
            all_collections,
            inserted_count: 0,
            count: count,
        }
    }
}

impl<'a> IsarInsert<'a> for NativeInsert<'a> {
    type Txn = NativeTxn;

    fn save(mut self, id: Option<i64>) -> Result<Self> {
        if self.property != self.collection.properties.len() {
            return Result::Err(IsarError::InsertIncomplete {});
        }

        let buffer = self.buffer.get_mut();
        if buffer.len() > MAX_OBJ_SIZE as usize {
            return Result::Err(IsarError::ObjectLimitReached {});
        }

        {
            self.txn.guard(|| {
                // TODO: avoid opening a new cursor for every insert
                let mut cursor = self.txn.get_cursor(self.collection.get_db()?)?;
                cursor.put(&self.id, &buffer)
            })?;
        }

        self.inserted_count += 1;

        if self.inserted_count < self.count {
            self.id = if let Some(id) = id {
                id
            } else {
                self.collection.auto_increment()?
            };

            self.property = 0;
            buffer.truncate(2); // leave only the static size
            buffer.resize(self.collection.static_size as usize, 0);
        }

        Ok(self)
    }

    fn finish(self) -> Result<Self::Txn> {
        if self.inserted_count < self.count {
            return Result::Err(IsarError::InsertIncomplete {});
        }
        Ok(self.txn)
    }
}
