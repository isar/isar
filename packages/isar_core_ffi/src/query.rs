use crate::{CIsarCursor, CIsarInstance, CIsarQuery, CIsarQueryBuilder, CIsarTxn};
use isar_core::core::instance::IsarInstance;
use isar_core::core::query_builder::{IsarQueryBuilder, Sort};
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
    let optimized = filter.optimize();
    match builder {
        CIsarQueryBuilder::Native(builder) => builder.set_filter(optimized),
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
                isar.query_delete(txn,query)?
            }
        };
        *count = new_count;
    }
}
