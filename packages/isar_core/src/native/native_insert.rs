use super::isar_serializer::IsarSerializer;
use super::mdbx::db::Db;
use super::native_collection::NativeCollection;
use super::native_txn::{NativeTxn, TxnCursor};
use super::{IdToBytes, MAX_OBJ_SIZE};
use crate::core::error::{IsarError, Result};
use crate::core::insert::IsarInsert;
use ouroboros::self_referencing;

#[self_referencing]
struct TxnWithCursor {
    txn: NativeTxn,
    #[borrows(txn)]
    #[covariant]
    cursor: TxnCursor<'this>,
}

impl TxnWithCursor {
    fn open(txn: NativeTxn, db: Db) -> Result<Self> {
        Self::try_new(txn, |txn| txn.get_cursor(db))
    }

    fn put(&mut self, collection: &NativeCollection, id: i64, bytes: &[u8]) -> Result<()> {
        self.with_mut(|this| {
            this.txn.guard(|| {
                if let Some((_, old_bytes)) = this.cursor.move_to(&id.to_id_bytes())? {
                    collection.prepare_delete(this.txn, id, old_bytes)?;
                }
                collection.prepare_put(this.txn, id, bytes)?;
                this.cursor.put(&id.to_id_bytes(), bytes)
            })
        })
    }

    fn close(self) -> NativeTxn {
        self.into_heads().txn
    }
}

pub struct NativeInsert<'a> {
    txn_cursor: TxnWithCursor,
    pub(crate) collection: &'a NativeCollection,
    pub(crate) all_collections: &'a Vec<NativeCollection>,

    remaining: u32,
    pub(crate) object: IsarSerializer,
}

impl<'a> NativeInsert<'a> {
    pub fn new(
        txn: NativeTxn,
        collection: &'a NativeCollection,
        all_collections: &'a Vec<NativeCollection>,
        count: u32,
    ) -> Result<Self> {
        let buffer = txn.take_buffer();
        let txn_cursor = TxnWithCursor::open(txn, collection.get_db()?)?;
        let insert = Self {
            txn_cursor,
            collection,
            all_collections,
            remaining: count,
            object: IsarSerializer::new(buffer, 0, collection.static_size),
        };
        Ok(insert)
    }
}

impl<'a> IsarInsert<'a> for NativeInsert<'a> {
    type Txn = NativeTxn;

    fn save(&mut self, id: i64) -> Result<()> {
        if self.remaining > 0 {
            let mut buffer = self.object.finish();
            if buffer.len() > MAX_OBJ_SIZE as usize {
                return Result::Err(IsarError::ObjectLimitReached {});
            }
            self.txn_cursor.put(self.collection, id, &buffer)?;

            self.remaining -= 1;
            buffer.clear();
            self.object = IsarSerializer::new(buffer, 0, self.collection.static_size);
            Ok(())
        } else {
            Err(IsarError::UnsupportedOperation {})
        }
    }

    fn finish(self) -> Result<Self::Txn> {
        if self.remaining > 0 {
            Err(IsarError::InsertIncomplete {})
        } else {
            let txn = self.txn_cursor.close();
            txn.put_buffer(self.object.finish());
            Ok(txn)
        }
    }
}
