use super::native_collection::NativeCollection;
use super::native_txn::NativeTxn;
use super::native_writer::NativeWriter;
use crate::core::error::Result;
use crate::core::insert::IsarInsert;

pub struct NativeInsert<'a> {
    txn: NativeTxn<'a>,
    collection: &'a NativeCollection,
    all_collections: &'a Vec<NativeCollection>,
    inserted_count: usize,
    count: usize,
}

impl<'a> NativeInsert<'a> {
    pub fn new(
        txn: NativeTxn<'a>,
        collection: &'a NativeCollection,
        all_collections: &'a Vec<NativeCollection>,
        count: usize,
    ) -> Self {
        Self {
            txn,
            collection,
            all_collections,
            inserted_count: 0,
            count: count,
        }
    }
}

impl<'a> IsarInsert<'a> for NativeInsert<'a> {
    type Writer = NativeWriter<'a>;

    type Txn<'txn> = NativeTxn<'txn>;

    fn get_writer(&self) -> Result<Self::Writer> {
        let writer = NativeWriter::new(self.collection, self.all_collections);
        Ok(writer)
    }

    fn insert(&mut self, writer: Self::Writer) -> Result<Option<Self::Writer>> {
        let (id, bytes) = writer.finish()?;

        let mut cursor = self.txn.get_cursor(self.collection.db)?;
        cursor.put(&id, bytes)?;

        self.inserted_count += 1;
        if self.inserted_count < self.count {
            Ok(Some(writer))
        } else {
            Ok(None)
        }
    }

    fn finish(self) -> Result<Self::Txn<'a>> {
        Ok(self.txn)
    }
}
