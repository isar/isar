use super::index_iterator::IndexIterator;
use super::native_filter::NativeFilter;
use crate::native::isar_deserializer::IsarDeserializer;
use crate::native::native_collection::NativeProperty;
use intmap::IntMap;

pub(crate) struct UnsortedDistinctQueryIterator<'a> {
    iterator: IndexIterator<'a>,
    filter: &'a NativeFilter,
    properties: &'a [(NativeProperty, bool)],
    hashes: IntMap<()>,
    skip: u32,
    take: u32,
}

impl<'a> UnsortedDistinctQueryIterator<'a> {
    pub fn new(
        iterator: IndexIterator<'a>,
        filter: &'a NativeFilter,
        properties: &'a [(NativeProperty, bool)],
        offset: u32,
        limit: u32,
    ) -> UnsortedDistinctQueryIterator<'a> {
        UnsortedDistinctQueryIterator {
            iterator,
            filter,
            properties,
            hashes: IntMap::new(),
            skip: offset,
            take: limit,
        }
    }
}

impl<'a> Iterator for UnsortedDistinctQueryIterator<'a> {
    type Item = (i64, IsarDeserializer<'a>);

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        while let Some((id, object)) = self.iterator.next() {
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
