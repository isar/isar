use intmap::IntMap;

use super::collection_iterator::CollectionIterator;
use crate::native::isar_deserializer::IsarDeserializer;
use crate::native::native_collection::NativeProperty;
use crate::native::native_filter::NativeFilter;
use std::iter::Flatten;
use std::vec::IntoIter;

pub(crate) struct UnsortedDistinctQueryIterator<'txn> {
    collection_iterators: Flatten<IntoIter<CollectionIterator<'txn>>>,
    filter: NativeFilter,
    properties: Vec<(NativeProperty, bool)>,
    hashes: IntMap<()>,
    skip: u32,
    take: u32,
}

impl<'txn> UnsortedDistinctQueryIterator<'txn> {
    pub fn new(
        collection_iterators: Vec<CollectionIterator<'txn>>,
        filter: NativeFilter,
        properties: Vec<(NativeProperty, bool)>,
        offset: u32,
        limit: u32,
    ) -> UnsortedDistinctQueryIterator<'txn> {
        UnsortedDistinctQueryIterator {
            collection_iterators: collection_iterators.into_iter().flatten(),
            filter,
            properties,
            hashes: IntMap::new(),
            skip: offset,
            take: limit,
        }
    }
}

impl<'txn> Iterator for UnsortedDistinctQueryIterator<'txn> {
    type Item = (i64, IsarDeserializer<'txn>);

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        while let Some((id, object)) = self.collection_iterators.next() {
            if self.filter.evaluate(id, object) {
                let hash = self
                    .properties
                    .iter()
                    .fold(0, |hash, (property, case_sensitive)| {
                        object.hash_property(
                            property.offset,
                            property.data_type,
                            *case_sensitive,
                            hash,
                        )
                    });
                if self.hashes.insert(hash, ()).is_none() {
                    if self.skip > 0 {
                        self.skip -= 1;
                    } else if self.take > 0 {
                        self.take -= 1;
                        return Some((id, object));
                    } else {
                        return None;
                    }
                }
            }
        }
        None
    }
}
