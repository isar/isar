use super::NativeQuery;
use super::iterator_index::IndexIterator;
use super::iterator_sorted_query::SortedQueryIterator;
use super::iterator_unsorted_distinct_query::UnsortedDistinctQueryIterator;
use super::iterator_unsorted_query::UnsortedQueryIterator;
use crate::native::isar_deserializer::IsarDeserializer;
use crate::native::native_collection::NativeCollection;
use crate::native::native_txn::NativeTxn;

pub(crate) enum QueryIterator<'a> {
    Unsorted(UnsortedQueryIterator<'a>),
    UnsortedDistinct(UnsortedDistinctQueryIterator<'a>),
    Sorted(SortedQueryIterator<'a>),
}

impl<'a> QueryIterator<'a> {
    pub fn new(
        txn: &'a NativeTxn,
        collection: &'a NativeCollection,
        query: &'a NativeQuery,
        ignore_sort: bool,
        offset: u32,
        limit: u32,
    ) -> Self {
        let index_iterator = IndexIterator::new(txn, collection, &query.indexes);
        if !query.sort.is_empty() && !ignore_sort {
            QueryIterator::Sorted(SortedQueryIterator::new(
                index_iterator,
                false,
                &query.filter,
                &query.sort,
                &query.distinct,
                offset,
                limit,
            ))
        } else if !query.distinct.is_empty() {
            QueryIterator::UnsortedDistinct(UnsortedDistinctQueryIterator::new(
                index_iterator,
                &query.filter,
                &query.distinct,
                offset,
                limit,
            ))
        } else {
            QueryIterator::Unsorted(UnsortedQueryIterator::new(
                index_iterator,
                false,
                &query.filter,
                offset,
                limit,
            ))
        }
    }
}

impl<'txn> Iterator for QueryIterator<'txn> {
    type Item = (i64, IsarDeserializer<'txn>);

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        match self {
            QueryIterator::Sorted(iterator) => iterator.next(),
            QueryIterator::Unsorted(iterator) => iterator.next(),
            QueryIterator::UnsortedDistinct(iterator) => iterator.next(),
        }
    }
}
