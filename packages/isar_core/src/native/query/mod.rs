use self::aggregate::{aggregate_min_max, aggregate_sum_average};
use self::native_filter::NativeFilter;
use self::query_iterator::QueryIterator;
use super::index_key::IndexKey;
use super::isar_deserializer::IsarDeserializer;
use super::native_collection::{NativeCollection, NativeProperty};
use super::native_reader::NativeReader;
use super::native_txn::NativeTxn;
use crate::core::cursor::IsarQueryCursor;
use crate::core::error::Result;
use crate::core::instance::Aggregation;
use crate::core::query_builder::Sort;
use crate::core::value::IsarValue;
use crate::core::watcher::QueryMatches;

mod aggregate;
mod index_iterator;
pub(crate) mod native_filter;
mod query_iterator;
mod sorted_query_iterator;
mod unsorted_distinct_query_iterator;
mod unsorted_query_iterator;

#[derive(Clone)]
pub(crate) enum QueryIndex {
    Primary(i64, i64),
    Secondary(IndexKey, IndexKey),
}

#[derive(Clone)]
pub struct NativeQuery {
    pub(crate) instance_id: u32,
    pub(crate) collection_index: u16,
    pub(self) indexes: Vec<QueryIndex>,
    pub(self) filter: NativeFilter,
    pub(self) sort: Vec<(Option<NativeProperty>, Sort, bool)>,
    pub(self) distinct: Vec<(NativeProperty, bool)>,
}

impl NativeQuery {
    pub(crate) fn new(
        instance_id: u32,
        collection_index: u16,
        indexes: Vec<QueryIndex>,
        filter: NativeFilter,
        sort: Vec<(Option<NativeProperty>, Sort, bool)>,
        distinct: Vec<(NativeProperty, bool)>,
    ) -> Self {
        Self {
            instance_id,
            collection_index,
            indexes,
            filter,
            sort,
            distinct,
        }
    }

    pub(crate) fn cursor<'a>(
        &'a self,
        txn: &'a NativeTxn,
        all_collections: &'a [NativeCollection],
        offset: Option<u32>,
        limit: Option<u32>,
    ) -> NativeQueryCursor<'_> {
        let collection = &all_collections[self.collection_index as usize];
        let iterator = QueryIterator::new(
            txn,
            collection,
            self,
            false,
            offset.unwrap_or(0),
            limit.unwrap_or(u32::MAX),
        );
        NativeQueryCursor::new(iterator, collection, all_collections)
    }

    pub(crate) fn aggregate(
        &self,
        txn: &NativeTxn,
        all_collections: &[NativeCollection],
        aggregation: Aggregation,
        property_index: Option<u16>,
    ) -> Option<IsarValue> {
        let collection = &all_collections[self.collection_index as usize];
        let property = if let Some(property_index) = property_index {
            collection.get_property(property_index)
        } else {
            None
        };

        let mut iterator = QueryIterator::new(txn, collection, self, true, 0, u32::MAX);
        match aggregation {
            Aggregation::Min | Aggregation::Max => {
                aggregate_min_max(iterator, property, aggregation == Aggregation::Min)
            }
            Aggregation::Sum | Aggregation::Average => {
                aggregate_sum_average(iterator, property, aggregation == Aggregation::Sum)
            }
            Aggregation::Count => Some(IsarValue::Integer(iterator.count() as i64)),
            Aggregation::IsEmpty => Some(IsarValue::Bool(iterator.next().is_none())),
        }
    }

    pub(crate) fn update(
        &self,
        txn: &NativeTxn,
        collection: &NativeCollection,
        offset: Option<u32>,
        limit: Option<u32>,
        updates: &[(u16, Option<IsarValue>)],
    ) -> Result<u32> {
        let iterator = QueryIterator::new(
            txn,
            collection,
            self,
            false,
            offset.unwrap_or(0),
            limit.unwrap_or(u32::MAX),
        );
        let change_set = &mut txn.get_change_set();
        let mut cursor = collection.get_cursor(txn)?;
        let mut count = 0;
        for (id, _) in iterator {
            collection.update(txn, change_set, &mut cursor, id, updates)?;
            count += 1;
        }
        Ok(count)
    }

    pub(crate) fn delete(
        &self,
        txn: &NativeTxn,
        collection: &NativeCollection,
        offset: Option<u32>,
        limit: Option<u32>,
    ) -> Result<u32> {
        let iterator = QueryIterator::new(
            txn,
            collection,
            self,
            false,
            offset.unwrap_or(0),
            limit.unwrap_or(u32::MAX),
        );
        let change_set = &mut txn.get_change_set();
        let mut cursor = collection.get_cursor(txn)?;
        let mut count = 0;
        for (id, _) in iterator {
            collection.delete(txn, change_set, &mut cursor, id)?;
            count += 1;
        }
        Ok(count)
    }
}

impl QueryMatches for NativeQuery {
    type Object<'a> = IsarDeserializer<'a>;

    fn matches<'a>(&self, id: i64, object: &IsarDeserializer<'a>) -> bool {
        self.filter.evaluate(id, *object)
    }
}

pub struct NativeQueryCursor<'a> {
    iterator: QueryIterator<'a>,
    collection: &'a NativeCollection,
    all_collections: &'a [NativeCollection],
}

impl<'a> NativeQueryCursor<'a> {
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

impl<'a> IsarQueryCursor for NativeQueryCursor<'a> {
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
