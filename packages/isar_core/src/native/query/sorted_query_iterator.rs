use intmap::IntMap;

use super::collection_iterator::CollectionIterator;
use crate::core::data_type::DataType;
use crate::core::query_builder::Sort;
use crate::native::isar_deserializer::IsarDeserializer;
use crate::native::native_collection::NativeProperty;
use crate::native::native_filter::NativeFilter;
use std::cmp::Ordering;
use std::iter::{Skip, Take};
use std::vec::IntoIter;

pub(crate) struct SortedQueryIterator<'txn> {
    iterator: Take<Skip<IntoIter<(i64, IsarDeserializer<'txn>)>>>,
}

impl<'txn> SortedQueryIterator<'txn> {
    pub fn new(
        collection_iterators: Vec<CollectionIterator<'txn>>,
        has_duplicates: bool,
        filter: &NativeFilter,
        sort: &[(NativeProperty, Sort)],
        distinct: &[(NativeProperty, bool)],
        offset: u32,
        limit: u32,
    ) -> SortedQueryIterator<'txn> {
        let mut returned_ids = if has_duplicates {
            Some(IntMap::new())
        } else {
            None
        };

        let mut iter = collection_iterators.into_iter().flatten();
        let mut results = vec![];
        while let Some((id, object)) = iter.next() {
            if let Some(returned_ids) = &mut returned_ids {
                if returned_ids.insert(id as u64, ()).is_some() {
                    continue;
                }
            }
            if filter.evaluate(id, object) {
                results.push((id, object));
            }
        }

        results.sort_unstable_by(|(_, o1), (_, o2)| {
            for (p, sort) in sort {
                let ord = Self::compare_property(o1, o2, p.offset, p.data_type);
                if ord != Ordering::Equal {
                    return if *sort == Sort::Asc {
                        ord
                    } else {
                        ord.reverse()
                    };
                }
            }
            Ordering::Equal
        });

        if !distinct.is_empty() {
            let mut hashes = IntMap::new();
            results = results
                .into_iter()
                .filter(|(_, object)| {
                    let hash = distinct.iter().fold(0, |hash, (property, case_sensitive)| {
                        object.hash_property(
                            property.offset,
                            property.data_type,
                            *case_sensitive,
                            hash,
                        )
                    });
                    hashes.insert_checked(hash, ())
                })
                .collect()
        }

        let results = results
            .into_iter()
            .skip(offset as usize)
            .take(limit as usize);

        SortedQueryIterator { iterator: results }
    }

    fn compare_property(
        o1: &IsarDeserializer,
        o2: &IsarDeserializer,
        offset: u32,
        data_type: DataType,
    ) -> Ordering {
        match data_type {
            DataType::Bool => o1.read_bool(offset).cmp(&o2.read_bool(offset)),
            DataType::Byte => o1.read_byte(offset).cmp(&o2.read_byte(offset)),
            DataType::Int => o1.read_int(offset).cmp(&o2.read_int(offset)),
            DataType::Float => o1.read_float(offset).total_cmp(&o2.read_float(offset)),
            DataType::Long => o1.read_long(offset).cmp(&o2.read_long(offset)),
            DataType::Double => o1.read_double(offset).total_cmp(&o2.read_double(offset)),
            DataType::String => o1.read_string(offset).cmp(&o2.read_string(offset)),
            _ => Ordering::Equal,
        }
    }
}

impl<'txn> Iterator for SortedQueryIterator<'txn> {
    type Item = (i64, IsarDeserializer<'txn>);

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        self.iterator.next()
    }
}
