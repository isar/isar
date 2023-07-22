use super::{index_iterator::IndexIterator, native_filter::NativeFilter};
use crate::native::isar_deserializer::IsarDeserializer;
use intmap::IntMap;

pub(crate) struct UnsortedQueryIterator<'a> {
    iterator: IndexIterator<'a>,
    returned_ids: Option<IntMap<()>>,
    filter: &'a NativeFilter,
    skip: u32,
    take: u32,
}

impl<'a> UnsortedQueryIterator<'a> {
    pub fn new(
        iterator: IndexIterator<'a>,
        has_duplicates: bool,
        filter: &'a NativeFilter,
        offset: u32,
        limit: u32,
    ) -> UnsortedQueryIterator<'a> {
        let returned_ids = if has_duplicates {
            Some(IntMap::new())
        } else {
            None
        };
        UnsortedQueryIterator {
            iterator,
            returned_ids,
            filter,
            skip: offset,
            take: limit,
        }
    }
}

impl<'a> Iterator for UnsortedQueryIterator<'a> {
    type Item = (i64, IsarDeserializer<'a>);

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        while let Some((id, object)) = self.iterator.next() {
            if let Some(returned_ids) = &mut self.returned_ids {
                if returned_ids.insert(id as u64, ()).is_some() {
                    continue;
                }
            }
            if self.filter.evaluate(id, object) {
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
        None
    }
}
