use super::index::id_key::IdToBytes;
use super::isar_serializer::IsarSerializer;
use super::native_collection::NativeCollection;
use super::native_txn::NativeTxn;
use super::native_writer::WriterImpl;
use super::MAX_OBJ_SIZE;
use crate::core::error::{IsarError, Result};
use crate::core::insert::IsarInsert;

pub struct NativeInsert<'a> {
    txn: NativeTxn,
    pub(crate) collection: &'a NativeCollection,
    pub(crate) all_collections: &'a Vec<NativeCollection>,

    inserted_count: u32,
    count: u32,

    pub(crate) object: IsarSerializer,
    pub(crate) property_index: u32,
}

impl<'a> NativeInsert<'a> {
    pub fn new(
        txn: NativeTxn,
        collection: &'a NativeCollection,
        all_collections: &'a Vec<NativeCollection>,
        count: u32,
    ) -> Self {
        Self {
            txn,
            collection,
            all_collections,
            inserted_count: 0,
            count: count,
            object: IsarSerializer::new(Vec::new(), 0, collection.static_size),
            property_index: 1, // Skip id
        }
    }
}

impl<'a> IsarInsert<'a> for NativeInsert<'a> {
    type Txn = NativeTxn;

    fn save(mut self, id: i64) -> Result<Self> {
        self.write_remaining_null();

        let mut buffer = self.object.finish();
        if buffer.len() > MAX_OBJ_SIZE as usize {
            return Result::Err(IsarError::ObjectLimitReached {});
        }

        {
            self.txn.guard(|| {
                // TODO: avoid opening a new cursor for every insert
                let mut cursor = self.txn.get_cursor(self.collection.get_db()?)?;
                cursor.put(&id.to_id_bytes(), &buffer)
            })?;
        }

        self.inserted_count += 1;
        self.collection.update_largest_id(id);

        if self.inserted_count < self.count {
            self.property_index = 1; // Skip id
            buffer.clear();
            self.object = IsarSerializer::new(buffer, 0, self.collection.static_size);
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
