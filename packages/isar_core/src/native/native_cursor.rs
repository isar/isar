use super::isar_deserializer::IsarDeserializer;
use super::native_collection::NativeCollection;
use super::native_reader::NativeReader;
use super::native_txn::{NativeTxn, TxnCursor};
use super::IdToBytes;
use crate::core::cursor::IsarCursor;
use crate::core::error::Result;

pub struct NativeCursor<'a> {
    cursor: TxnCursor<'a>,
    collection: &'a NativeCollection,
    collections: &'a Vec<NativeCollection>,
}

impl<'a> NativeCursor<'a> {
    pub fn new(
        txn: &'a NativeTxn,
        collection: &'a NativeCollection,
        collections: &'a Vec<NativeCollection>,
    ) -> Result<Self> {
        let cursor = txn.get_cursor(collection.get_db()?)?;
        let nc = Self {
            cursor,
            collection,
            collections,
        };
        Ok(nc)
    }
}

impl<'a> IsarCursor for NativeCursor<'a> {
    type Reader<'b> = NativeReader<'b> where Self: 'b;

    #[inline]
    fn next(&mut self, id: i64) -> Option<Self::Reader<'_>> {
        if let Some((_, bytes)) = self.cursor.move_to(&id.to_id_bytes()).ok()? {
            let object = IsarDeserializer::from_bytes(bytes);
            Some(NativeReader::new(
                id,
                object,
                self.collection,
                &self.collections,
            ))
        } else {
            None
        }
    }
}
