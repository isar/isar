use super::index_iterator::IndexIterator;
use super::native_filter::NativeFilter;
use crate::core::data_type::DataType;
use crate::core::query_builder::Sort;
use crate::native::isar_deserializer::IsarDeserializer;
use crate::native::native_collection::NativeProperty;
use intmap::IntMap;
use itertools::Itertools;
use std::cmp::Ordering;
use std::iter::{Skip, Take};
use std::vec::IntoIter;

pub(crate) struct SortedQueryIterator<'txn> {
    iterator: Take<Skip<IntoIter<(i64, IsarDeserializer<'txn>)>>>,
}

impl<'a> SortedQueryIterator<'a> {
    pub fn new(
        mut iterator: IndexIterator<'a>,
        has_duplicates: bool,
        filter: &NativeFilter,
        sort: &[(Option<NativeProperty>, Sort, bool)],
        distinct: &[(NativeProperty, bool)],
        offset: u32,
        limit: u32,
    ) -> SortedQueryIterator<'a> {
        let mut returned_ids = if has_duplicates {
            Some(IntMap::new())
        } else {
            None
        };

        let mut results = vec![];
        while let Some((id, object)) = iterator.next() {
            if let Some(returned_ids) = &mut returned_ids {
                if returned_ids.insert(id as u64, ()).is_some() {
                    continue;
                }
            }
            if filter.evaluate(id, object) {
                results.push((id, object));
            }
        }

        results.sort_unstable_by(|(id1, o1), (id2, o2)| {
            for (p, sort, case_sensitive) in sort {
                let ord = if let Some(p) = p {
                    Self::compare_property(o1, o2, p.offset, p.data_type, *case_sensitive)
                } else {
                    id1.cmp(id2)
                };
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
            let results = results
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
                .skip(offset as usize)
                .take(limit as usize)
                .collect_vec();
            SortedQueryIterator {
                iterator: results.into_iter().skip(0).take(usize::MAX),
            }
        } else {
            SortedQueryIterator {
                iterator: results
                    .into_iter()
                    .skip(offset as usize)
                    .take(limit as usize),
            }
        }
    }

    fn compare_property(
        o1: &IsarDeserializer,
        o2: &IsarDeserializer,
        offset: u32,
        data_type: DataType,
        case_sensitive: bool,
    ) -> Ordering {
        match data_type {
            DataType::Bool => o1.read_bool(offset).cmp(&o2.read_bool(offset)),
            DataType::Byte => o1.read_byte(offset).cmp(&o2.read_byte(offset)),
            DataType::Int => o1.read_int(offset).cmp(&o2.read_int(offset)),
            DataType::Float => o1.read_float(offset).total_cmp(&o2.read_float(offset)),
            DataType::Long => o1.read_long(offset).cmp(&o2.read_long(offset)),
            DataType::Double => o1.read_double(offset).total_cmp(&o2.read_double(offset)),
            DataType::String => {
                let s1 = o1.read_string(offset);
                let s2 = o2.read_string(offset);
                if case_sensitive {
                    s1.cmp(&s2)
                } else {
                    s1.map(|s| s.to_lowercase())
                        .cmp(&s2.map(|s| s.to_lowercase()))
                }
            }
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
