use std::slice;

use crate::{CIsarCursor, CIsarInstance, CIsarQuery, CIsarQueryBuilder, CIsarTxn};
use isar_core::core::instance::IsarInstance;
use isar_core::core::query_builder::{IsarQueryBuilder, Sort};
use isar_core::filter::filter_condition::FilterCondition;
use isar_core::filter::filter_group::{FilterGroup, GroupType};
use isar_core::filter::filter_value::FilterValue;
use isar_core::filter::Filter;
use itertools::Itertools;

#[no_mangle]
pub unsafe extern "C" fn isar_query_new(
    isar: &'static CIsarInstance,
    collection_index: u16,
    query_builder: *mut *const CIsarQueryBuilder,
) -> u8 {
    isar_try! {
        let new_builder = match isar {
            CIsarInstance::Native(isar) => {
                let builder = isar.query(collection_index)?;
                CIsarQueryBuilder::Native(builder)
            }
        };
        *query_builder = Box::into_raw(Box::new(new_builder));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_new_id(
    isar: &'static CIsarInstance,
    collection_index: u16,
    id: i64,
    query: *mut *const CIsarQuery,
) -> u8 {
    isar_try! {
        let condition = FilterCondition::new_equal_to(0, FilterValue::Integer(id), false);
        let filter = Filter::Condition(condition);
        let new_query = match isar {
            CIsarInstance::Native(isar) => {
                let mut builder = isar.query(collection_index)?;
                builder.set_filter(filter);
                CIsarQuery::Native(builder.build())
            }
        };
        *query = Box::into_raw(Box::new(new_query));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_new_ids(
    isar: &'static CIsarInstance,
    collection_index: u16,
    ids: *const i64,
    length: u32,
    query: *mut *const CIsarQuery,
) -> u8 {
    isar_try! {
        let ids = slice::from_raw_parts(ids, length as usize);
        let filters = ids
            .iter()
            .map(|id| {
                let condition = FilterCondition::new_equal_to(0, FilterValue::Integer(*id), false);
                Filter::Condition(condition)
            })
            .collect_vec();
        let filter = Filter::Group(FilterGroup::new(GroupType::Or, filters));
        let new_query = match isar {
            CIsarInstance::Native(isar) => {
                let mut builder = isar.query(collection_index)?;
                builder.set_filter(filter);
                CIsarQuery::Native(builder.build())
            }
        };
        *query = Box::into_raw(Box::new(new_query));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_set_filter(
    builder: &'static mut CIsarQueryBuilder,
    filter: *mut Filter,
) {
    let filter = *Box::from_raw(filter);
    match builder {
        CIsarQueryBuilder::Native(builder) => builder.set_filter(filter),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_add_sort(
    builder: &'static mut CIsarQueryBuilder,
    property_index: u16,
    ascending: bool,
) {
    let sort = if ascending { Sort::Asc } else { Sort::Desc };
    match builder {
        CIsarQueryBuilder::Native(builder) => builder.add_sort(property_index, sort),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_build(builder: *mut CIsarQueryBuilder) -> *mut CIsarQuery {
    let builder = *Box::from_raw(builder);
    match builder {
        CIsarQueryBuilder::Native(builder) => {
            let query = builder.build();
            Box::into_raw(Box::new(CIsarQuery::Native(query)))
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_cursor(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    query: &'static CIsarQuery,
    cursor: *mut *const CIsarCursor,
    offset: i64,
    limit: i64,
) -> u8 {
    isar_try! {
        let offset = if offset < 0 { None } else { Some(offset.clamp(0, u32::MAX as i64) as u32) };
        let limit = if limit < 0 { None } else { Some(limit.clamp(0, u32::MAX as i64) as u32) };
        let new_cursor = match (isar,txn,query) {
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn), CIsarQuery::Native(query)) => {
                let cursor = isar.cursor(txn, query, offset, limit)?;
                CIsarCursor::Native(cursor)
            }
        };
        *cursor = Box::into_raw(Box::new(new_cursor));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_delete(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    query: &'static CIsarQuery,
    count: *mut u32,
) -> u8 {
    isar_try! {
        let new_count = match (isar, txn, query) {
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn),CIsarQuery::Native(query)) => {
                isar.delete(txn,query)?
            }
        };
        *count = new_count;
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_free(query: *mut CIsarQuery) {
    drop(Box::from_raw(query));
}
