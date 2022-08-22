use intmap::IntMap;
use serde_json::{json, Value};
use std::cmp::Ordering;

use crate::collection::IsarCollection;
use crate::cursor::IsarCursors;
use crate::error::Result;
use crate::object::isar_object::IsarObject;
use crate::object::json_encode_decode::JsonEncodeDecode;
use crate::object::property::Property;
use crate::query::filter::Filter;
use crate::query::where_clause::WhereClause;
use crate::txn::IsarTxn;

mod fast_wild_match;
pub mod filter;
mod id_where_clause;
mod index_where_clause;
mod link_where_clause;
pub mod query_builder;
mod where_clause;

#[derive(Copy, Clone, Eq, PartialEq)]
pub enum Sort {
    Ascending,
    Descending,
}

pub enum Case {
    Sensitive,
    Insensitive,
}

#[derive(Clone)]
pub struct Query {
    instance_id: u64,
    where_clauses: Vec<WhereClause>,
    where_clauses_dup: bool,
    filter: Option<Filter>,
    sort: Vec<(Property, Sort)>,
    distinct: Vec<(Property, bool)>,
    offset: usize,
    limit: usize,
}

impl<'txn> Query {
    #[allow(clippy::too_many_arguments)]
    pub(crate) fn new(
        instance_id: u64,
        where_clauses: Vec<WhereClause>,
        filter: Option<Filter>,
        sort: Vec<(Property, Sort)>,
        distinct: Vec<(Property, bool)>,
        offset: usize,
        limit: usize,
    ) -> Self {
        let where_clauses_dup = Self::check_where_clauses_duplicates(&where_clauses);
        Query {
            instance_id,
            where_clauses,
            where_clauses_dup,
            filter,
            sort,
            distinct,
            offset,
            limit,
        }
    }

    fn check_where_clauses_duplicates(where_clauses: &[WhereClause]) -> bool {
        for (i, wc1) in where_clauses.iter().enumerate() {
            if wc1.has_duplicates() {
                return true;
            }
            for wc2 in where_clauses.iter().skip(i + 1) {
                if wc1.is_overlapping(wc2) {
                    return true;
                }
            }
        }
        false
    }

    pub(crate) fn execute_raw<'env, F>(
        &self,
        cursors: &IsarCursors<'txn, 'env>,
        mut callback: F,
    ) -> Result<()>
    where
        F: FnMut(i64, IsarObject<'txn>) -> Result<bool>,
    {
        let mut result_ids = if self.where_clauses_dup {
            Some(IntMap::new())
        } else {
            None
        };

        let static_filter = Filter::stat(true);
        let filter = self.filter.as_ref().unwrap_or(&static_filter);

        for where_clause in &self.where_clauses {
            let result = where_clause.iter(cursors, result_ids.as_mut(), |id, object| {
                if filter.evaluate(id, object, Some(cursors))? {
                    callback(id, object)
                } else {
                    Ok(true)
                }
            })?;
            if !result {
                return Ok(());
            }
        }

        Ok(())
    }

    fn execute_unsorted<'env, F>(
        &self,
        cursors: &IsarCursors<'txn, 'env>,
        callback: F,
    ) -> Result<()>
    where
        F: FnMut(i64, IsarObject<'txn>) -> Result<bool>,
    {
        if !self.distinct.is_empty() {
            let callback = self.add_distinct_unsorted(callback);
            let callback = self.add_offset_limit_unsorted(callback);
            self.execute_raw(cursors, callback)
        } else {
            let callback = self.add_offset_limit_unsorted(callback);
            self.execute_raw(cursors, callback)
        }
    }

    fn hash_properties(object: IsarObject, properties: &[(Property, bool)]) -> u64 {
        let mut hash = 0;
        for (p, case_sensitive) in properties {
            hash = object.hash_property(p.offset, p.data_type, *case_sensitive, hash);
        }
        hash
    }

    fn add_distinct_unsorted<F>(
        &self,
        mut callback: F,
    ) -> impl FnMut(i64, IsarObject<'txn>) -> Result<bool>
    where
        F: FnMut(i64, IsarObject<'txn>) -> Result<bool>,
    {
        let properties = self.distinct.clone();
        let mut hashes = IntMap::new();
        move |id, object| {
            let hash = Self::hash_properties(object, &properties);
            if hashes.insert_checked(hash, ()) {
                callback(id, object)
            } else {
                Ok(true)
            }
        }
    }

    fn add_offset_limit_unsorted<F>(
        &self,
        mut callback: F,
    ) -> impl FnMut(i64, IsarObject<'txn>) -> Result<bool>
    where
        F: FnMut(i64, IsarObject<'txn>) -> Result<bool>,
    {
        let offset = self.offset;
        let max_count = self.limit.saturating_add(offset);
        let mut count = 0;
        move |id, value| {
            count += 1;
            if count > max_count || (count > offset && !callback(id, value)?) {
                Ok(false)
            } else {
                Ok(true)
            }
        }
    }

    fn execute_sorted<'env>(
        &self,
        cursors: &IsarCursors<'txn, 'env>,
    ) -> Result<Vec<(i64, IsarObject<'txn>)>> {
        let mut results = vec![];
        self.execute_raw(cursors, |id, object| {
            results.push((id, object));
            Ok(true)
        })?;

        results.sort_unstable_by(|(_, o1), (_, o2)| {
            for (p, sort) in &self.sort {
                let ord = o1.compare_property(o2, p.offset, p.data_type);
                if ord != Ordering::Equal {
                    return if *sort == Sort::Ascending {
                        ord
                    } else {
                        ord.reverse()
                    };
                }
            }
            Ordering::Equal
        });

        if !self.distinct.is_empty() {
            Ok(self.add_distinct_sorted(results))
        } else {
            Ok(results)
        }
    }

    fn add_distinct_sorted(
        &self,
        results: Vec<(i64, IsarObject<'txn>)>,
    ) -> Vec<(i64, IsarObject<'txn>)> {
        let properties = self.distinct.clone();
        let mut hashes = IntMap::new();
        results
            .into_iter()
            .filter(|(_, object)| {
                let hash = Self::hash_properties(*object, &properties);
                hashes.insert_checked(hash, ())
            })
            .collect()
    }

    fn add_offset_limit_sorted(
        &self,
        results: Vec<(i64, IsarObject<'txn>)>,
    ) -> impl IntoIterator<Item = (i64, IsarObject<'txn>)> {
        results.into_iter().skip(self.offset).take(self.limit)
    }

    pub(crate) fn maybe_matches_wc_filter(&self, id: i64, object: IsarObject) -> bool {
        let maybe_matches = self
            .where_clauses
            .iter()
            .any(|wc| wc.maybe_matches(id, object));
        if !maybe_matches {
            return false;
        }

        if let Some(filter) = &self.filter {
            filter.evaluate(id, object, None).unwrap_or(true)
        } else {
            true
        }
    }

    pub fn find_while<F>(&self, txn: &'txn mut IsarTxn, mut callback: F) -> Result<()>
    where
        F: FnMut(i64, IsarObject<'txn>) -> bool,
    {
        txn.read(self.instance_id, |cursors| {
            if self.sort.is_empty() {
                self.execute_unsorted(cursors, |id, object| {
                    let cont = callback(id, object);
                    Ok(cont)
                })?;
            } else {
                let results = self.execute_sorted(cursors)?;
                let results_iter = self.add_offset_limit_sorted(results);
                for (id, object) in results_iter {
                    if !callback(id, object) {
                        break;
                    }
                }
            }
            Ok(())
        })
    }

    pub fn find_all_vec(&self, txn: &'txn mut IsarTxn) -> Result<Vec<(i64, IsarObject<'txn>)>> {
        let mut results = vec![];
        self.find_while(txn, |id, object| {
            results.push((id, object));
            true
        })?;
        Ok(results)
    }

    pub fn count(&self, txn: &mut IsarTxn) -> Result<u32> {
        let mut counter = 0;
        self.find_while(txn, |_, _| {
            counter += 1;
            true
        })?;
        Ok(counter)
    }

    pub fn export_json(
        &self,
        txn: &mut IsarTxn,
        collection: &IsarCollection,
        id_name: Option<&str>,
        primitive_null: bool,
    ) -> Result<Value> {
        let mut items = vec![];
        self.find_while(txn, |id, object| {
            let mut json = JsonEncodeDecode::encode(
                &collection.properties,
                &collection.embedded_properties,
                object,
                primitive_null,
            );
            if let Some(id_name) = id_name {
                json.insert(id_name.to_string(), Value::from(id));
            }
            items.push(json);
            true
        })?;
        Ok(json!(items))
    }
}
