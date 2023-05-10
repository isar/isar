use super::ids_iterator::IdsIterator;
use super::QueryIndex;
use crate::core::error::Result;
use crate::core::query_builder::Sort;
use crate::native::index::id_key::BytesToId;
use crate::native::isar_deserializer::IsarDeserializer;
use crate::native::mdbx::cursor_iterator::{CursorBetweenIterator, CursorIterator};
use crate::native::native_collection::NativeCollection;
use crate::native::native_txn::{NativeTxn, TxnCursor};

pub(crate) enum CollectionIterator<'txn> {
    Full(CursorIterator<'txn, TxnCursor<'txn>>),
    Ids(IdsIterator<'txn>),
    IdsBetween(CursorBetweenIterator<'txn, TxnCursor<'txn>, i64>),
    IndexBetween((usize, usize)),
}

impl<'txn> CollectionIterator<'txn> {
    pub fn new(
        txn: &'txn NativeTxn,
        collection: &NativeCollection,
        index: &QueryIndex,
    ) -> Result<Self> {
        match index {
            QueryIndex::Full(sort) => {
                let ascending = *sort == Sort::Asc;
                let cursor = txn.get_cursor(collection.get_db()?)?;
                let iterator = cursor.iter(ascending)?;
                Ok(CollectionIterator::Full(iterator))
            }
            QueryIndex::Ids(ids) => {
                let cursor = txn.get_cursor(collection.get_db()?)?;
                let iterator = IdsIterator::new(cursor, ids.clone());
                Ok(CollectionIterator::Ids(iterator))
            }
            QueryIndex::IdsBetween(lower, upper) => {
                let cursor = txn.get_cursor(collection.get_db()?)?;
                let iterator = cursor.iter_between(*lower, *upper, false, false)?;
                Ok(CollectionIterator::IdsBetween(iterator))
            }
        }
    }
}

impl<'txn> Iterator for CollectionIterator<'txn> {
    type Item = (i64, IsarDeserializer<'txn>);

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        match self {
            CollectionIterator::Full(iterator) => {
                let (key, value) = iterator.next()?;
                Some((key.to_id(), IsarDeserializer::from_bytes(value)))
            }
            CollectionIterator::Ids(iterator) => iterator.next(),
            CollectionIterator::IdsBetween(iterator) => {
                let (key, value) = iterator.next()?;
                Some((key.to_id(), IsarDeserializer::from_bytes(value)))
            }
            CollectionIterator::IndexBetween(_) => todo!(),
        }
    }
}
