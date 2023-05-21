use crate::native::isar_deserializer::IsarDeserializer;
use std::marker::PhantomData;

pub(crate) struct IndexIterator<'txn> {
    _marker: PhantomData<&'txn ()>,
}

impl IndexIterator<'_> {
    pub fn new() -> Self {
        todo!()
    }
}

impl<'txn> Iterator for IndexIterator<'txn> {
    type Item = (i64, IsarDeserializer<'txn>);

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        todo!()
    }
}
