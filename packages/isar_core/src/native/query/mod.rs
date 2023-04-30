use self::query_iterator::QueryIterator;
use super::native_collection::{NativeCollection, NativeProperty};
use super::native_filter::NativeFilter;
use super::native_reader::NativeReader;
use super::native_txn::NativeTxn;
use crate::core::cursor::IsarCursor;
use crate::core::error::Result;
use crate::core::query_builder::Sort;

mod collection_iterator;
mod ids_iterator;
mod query_iterator;
mod unsorted_distinct_query_iterator;
mod unsorted_query_iterator;

pub(crate) enum QueryIndex {
    Full(Sort),
    Ids(Vec<i64>),
    IdsBetween(i64, i64),
}

pub struct Query {
    pub(crate) instance_id: u32,
    pub(crate) collection_index: usize,
    pub(self) indexes: Vec<QueryIndex>,
    pub(self) filter: NativeFilter,
    pub(self) sort: Vec<(NativeProperty, Sort)>,
    pub(self) distinct: Vec<(NativeProperty, bool)>,
    pub(self) offset: u32,
    pub(self) limit: u32,
}

impl Query {
    pub(crate) fn new(
        instance_id: u32,
        collection_index: usize,
        indexes: Vec<QueryIndex>,
        filter: NativeFilter,
        sort: Vec<(NativeProperty, Sort)>,
        distinct: Vec<(NativeProperty, bool)>,
        offset: u32,
        limit: u32,
    ) -> Self {
        Self {
            instance_id,
            collection_index,
            indexes,
            filter,
            sort,
            distinct,
            offset,
            limit,
        }
    }

    pub(crate) fn cursor<'a>(
        &'a self,
        txn: &'a NativeTxn,
        all_collections: &'a [NativeCollection],
    ) -> Result<QueryCursor<'a>> {
        let collection = &all_collections[self.collection_index];
        let iterator = QueryIterator::new(txn, collection, self, false)?;
        Ok(QueryCursor::new(iterator, collection, all_collections))
    }

    pub(crate) fn count(
        &self,
        txn: &NativeTxn,
        all_collections: &[NativeCollection],
    ) -> Result<u32> {
        let collection = &all_collections[self.collection_index];
        let iterator = QueryIterator::new(txn, collection, self, true)?;
        Ok(iterator.count() as u32)
    }

    pub(crate) fn delete(&self, txn: &NativeTxn, collection: &NativeCollection) -> Result<u32> {
        todo!()
    }
}

pub struct QueryCursor<'a> {
    iterator: QueryIterator<'a>,
    collection: &'a NativeCollection,
    all_collections: &'a [NativeCollection],
}

impl<'a> QueryCursor<'a> {
    pub(crate) fn new(
        iterator: QueryIterator<'a>,
        collection: &'a NativeCollection,
        all_collections: &'a [NativeCollection],
    ) -> Self {
        Self {
            iterator,
            collection,
            all_collections,
        }
    }
}

impl<'a> IsarCursor for QueryCursor<'a> {
    type Reader<'b> = NativeReader<'b> where Self: 'b;

    #[inline]
    fn next(&mut self) -> Option<Self::Reader<'_>> {
        let (id, object) = self.iterator.next()?;
        Some(NativeReader::new(
            id,
            object,
            self.collection,
            self.all_collections,
        ))
    }
}
