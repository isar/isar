use crate::{CIsarInstance, CIsarQuery, CIsarQueryBuilder, CIsarQueryCursor, CIsarTxn};
use isar_core::core::error::IsarError;
use isar_core::core::filter::Filter;
use isar_core::core::instance::{Aggregation, IsarInstance};
use isar_core::core::query_builder::{IsarQueryBuilder, Sort};
use isar_core::core::value::IsarValue;
use std::ptr;

#[no_mangle]
pub unsafe extern "C" fn isar_query_new(
    isar: &'static CIsarInstance,
    collection_index: u16,
    query_builder: *mut *const CIsarQueryBuilder,
) -> u8 {
    isar_try! {
        let new_builder = match isar {
            #[cfg(feature = "native")]
            CIsarInstance::Native(isar) => CIsarQueryBuilder::Native(isar.query(collection_index)?),
            #[cfg(feature = "sqlite")]
            CIsarInstance::SQLite(isar) => CIsarQueryBuilder::SQLite(isar.query(collection_index)?),
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
    match builder {
        #[cfg(feature = "native")]
        CIsarQueryBuilder::Native(builder) => builder.set_filter(filter),
        #[cfg(feature = "sqlite")]
        CIsarQueryBuilder::SQLite(builder) => builder.set_filter(filter),
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
        #[cfg(feature = "native")]
        CIsarQueryBuilder::Native(builder) => {
            builder.add_sort(property_index, sort, case_sensitive)
        }
        #[cfg(feature = "sqlite")]
        CIsarQueryBuilder::SQLite(builder) => {
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
        #[cfg(feature = "native")]
        CIsarQueryBuilder::Native(builder) => builder.add_distinct(property_index, case_sensitive),
        #[cfg(feature = "sqlite")]
        CIsarQueryBuilder::SQLite(builder) => builder.add_distinct(property_index, case_sensitive),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_build(builder: *mut CIsarQueryBuilder) -> *mut CIsarQuery {
    let builder = *Box::from_raw(builder);
    match builder {
        #[cfg(feature = "native")]
        CIsarQueryBuilder::Native(builder) => {
            let query = builder.build();
            Box::into_raw(Box::new(CIsarQuery::Native(query)))
        }
        #[cfg(feature = "sqlite")]
        CIsarQueryBuilder::SQLite(builder) => {
            let query = builder.build();
            Box::into_raw(Box::new(CIsarQuery::SQLite(query)))
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_cursor(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    query: &'static CIsarQuery,
    cursor: *mut *const CIsarQueryCursor,
    offset: u32,
    limit: u32,
) -> u8 {
    let offset = if offset == 0 { None } else { Some(offset) };
    let limit = if limit == 0 { None } else { Some(limit) };

    isar_try! {
        let new_cursor = match (isar, txn, query) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn), CIsarQuery::Native(query)) => {
                let cursor = isar.query_cursor(txn, query, offset, limit)?;
                CIsarQueryCursor::Native(cursor)
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn), CIsarQuery::SQLite(query)) => {
                let cursor = isar.query_cursor(txn, query, offset, limit)?;
                CIsarQueryCursor::SQLite(cursor)
            }
            _ => return Err(IsarError::IllegalArgument {}),
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
        let new_value = match (isar, txn, query) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn), CIsarQuery::Native(query)) => {
                isar.query_aggregate(txn, query, aggregation, Some(property_index))?
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn), CIsarQuery::SQLite(query)) => {
                isar.query_aggregate(txn, query, aggregation, Some(property_index))?
            }
            _ => return Err(IsarError::IllegalArgument {}),
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
    offset: u32,
    limit: u32,
    count: *mut u32,
) -> u8 {
    let offset = if offset == 0 { None } else { Some(offset) };
    let limit = if limit == 0 { None } else { Some(limit) };
    isar_try! {
        let new_count = match (isar, txn, query) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn), CIsarQuery::Native(query)) => {
                isar.query_delete(txn, query, offset, limit)?
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn), CIsarQuery::SQLite(query)) => {
                isar.query_delete(txn, query, offset, limit)?
            }
            _ => return Err(IsarError::IllegalArgument {}),
        };
        *count = new_count;
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_free(query: *mut CIsarQuery) {
    if !query.is_null() {
        drop(Box::from_raw(query));
    }
}
