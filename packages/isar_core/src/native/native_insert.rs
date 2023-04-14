use std::cell::Cell;

use byteorder::{ByteOrder, LittleEndian};

use super::native_collection::NativeCollection;
use super::native_txn::NativeTxn;
use super::MAX_OBJ_SIZE;
use crate::core::error::{illegal_arg, Result};
use crate::core::insert::IsarInsert;

pub struct NativeInsert<'a> {
    txn: NativeTxn<'a>,
    pub(crate) collection: &'a NativeCollection,
    pub(crate) all_collections: &'a Vec<NativeCollection>,

    inserted_count: usize,
    count: usize,

    pub(crate) buffer: Cell<Vec<u8>>,
    pub(crate) property: usize,
    id: i64,
}

impl<'a> NativeInsert<'a> {
    pub fn new(
        txn: NativeTxn<'a>,
        collection: &'a NativeCollection,
        all_collections: &'a Vec<NativeCollection>,
        count: usize,
    ) -> Self {
        let mut buffer = Vec::with_capacity(collection.static_size * 2);
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
    type Txn<'txn> = NativeTxn<'txn>;

    fn insert(mut self, id: Option<i64>) -> Result<Self> {
        if self.property != self.collection.properties.len() {
            illegal_arg("Not all properties have been written ")?;
        }

        let buffer = self.buffer.get_mut();
        if buffer.len() < 2 {
            illegal_arg("No properties have been written")?;
        } else if buffer.len() > MAX_OBJ_SIZE as usize {
            illegal_arg("Object is bigger than 16MB")?;
        }

        {
            let mut cursor = self.txn.get_cursor(self.collection.db)?;
            cursor.put(&self.id, &buffer)?;
        }

        self.inserted_count += 1;

        if self.inserted_count < self.count {
            self.id = id.unwrap_or(0);
            self.property = 0;
            buffer.truncate(2);
        }

        Ok(self)
    }

    fn finish(self) -> Result<Self::Txn<'a>> {
        if self.inserted_count < self.count {
            illegal_arg("Not all objects have been inserted")?;
        }
        Ok(self.txn)
    }
}
