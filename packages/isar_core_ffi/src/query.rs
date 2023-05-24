use std::ptr;

use crate::{CIsarCursor, CIsarInstance, CIsarQuery, CIsarQueryBuilder, CIsarTxn};
use isar_core::core::instance::{Aggregation, IsarInstance};
use isar_core::core::query_builder::{IsarQueryBuilder, Sort};
use isar_core::core::value::IsarValue;
use isar_core::filter::Filter;

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
pub unsafe extern "C" fn isar_query_set_filter(
    builder: &'static mut CIsarQueryBuilder,
    filter: *mut Filter,
) {
    let filter = *Box::from_raw(filter);
    //let optimized = filter.optimize();
    match builder {
        CIsarQueryBuilder::Native(builder) => builder.set_filter(filter),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_add_sort(
    builder: &'static mut CIsarQueryBuilder,
    property_index: u16,
    ascending: bool,
    case_sensitive: bool,
) {
    let sort = if ascending { Sort::Asc } else { Sort::Desc };
    match builder {
        CIsarQueryBuilder::Native(builder) => {
            builder.add_sort(property_index, sort, case_sensitive)
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_add_distinct(
    builder: &'static mut CIsarQueryBuilder,
    property_index: u16,
    case_sensitive: bool,
) {
    match builder {
        CIsarQueryBuilder::Native(builder) => builder.add_distinct(property_index, case_sensitive),
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
                let cursor = isar.query_cursor(txn, query, offset, limit)?;
                CIsarCursor::Native(cursor)
            }
        };
        *cursor = Box::into_raw(Box::new(new_cursor));
    }
}

pub const AGGREGATION_COUNT: u8 = 0;
pub const AGGREGATION_IS_EMPTY: u8 = 1;
pub const AGGREGATION_MIN: u8 = 2;
pub const AGGREGATION_MAX: u8 = 3;
pub const AGGREGATION_SUM: u8 = 4;
pub const AGGREGATION_AVERAGE: u8 = 5;

#[no_mangle]
pub unsafe extern "C" fn isar_query_aggregate(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    query: &'static CIsarQuery,
    aggregation: u8,
    property_index: u16,
    value: *mut *const IsarValue,
) -> u8 {
    let aggregation = match aggregation {
        AGGREGATION_COUNT => Aggregation::Count,
        AGGREGATION_IS_EMPTY => Aggregation::IsEmpty,
        AGGREGATION_MIN => Aggregation::Min,
        AGGREGATION_MAX => Aggregation::Max,
        AGGREGATION_SUM => Aggregation::Sum,
        AGGREGATION_AVERAGE => Aggregation::Average,
        _ => {
            *value = ptr::null();
            return 0;
        }
    };
    isar_try! {
        let new_value = match (isar,txn,query) {
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn), CIsarQuery::Native(query)) => {
                isar.query_aggregate(txn, query, aggregation, Some(property_index))?
            }
        };
        if let Some(new_value) = new_value {
            *value = Box::into_raw(Box::new(new_value));
        } else {
            *value = ptr::null();
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_delete(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    query: &'static CIsarQuery,
    offset: i64,
    limit: i64,
    count: *mut u32,
) -> u8 {
    let offset = if offset < 0 {
        None
    } else {
        Some(offset.clamp(0, u32::MAX as i64) as u32)
    };
    let limit = if limit < 0 {
        None
    } else {
        Some(limit.clamp(0, u32::MAX as i64) as u32)
    };
    isar_try! {
        let new_count = match (isar, txn, query) {
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn), CIsarQuery::Native(query)) => {
                isar.query_delete(txn, query, offset, limit)?
            }
        };
        *count = new_count;
    }
}
