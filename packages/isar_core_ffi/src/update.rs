use crate::{isar_to_i64, CIsarInstance, CIsarQuery, CIsarTxn, CIsarUpdate, IsarI64};
use isar_core::core::error::IsarError;
use isar_core::core::instance::IsarInstance;
use isar_core::core::value::IsarValue;

#[no_mangle]
pub unsafe extern "C" fn isar_update(
    isar: &'static CIsarInstance,
    txn: &CIsarTxn,
    collection_index: u16,
    id: IsarI64,
    update: *mut CIsarUpdate,
    updated: *mut bool,
) -> u8 {
    let id = isar_to_i64(id);
    let update = Box::from_raw(update);
    isar_try! {
        match (isar, txn) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                *updated = isar.update(txn, collection_index, id, &update.0)?;
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => {
                *updated = isar.update(txn, collection_index, id, &update.0)?;
            }
            _ => return Err(IsarError::IllegalArgument {}),
        };
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_update(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    query: &'static CIsarQuery,
    offset: u32,
    limit: u32,
    update: *mut CIsarUpdate,
    updated: *mut u32,
) -> u8 {
    let offset = if offset == 0 { None } else { Some(offset) };
    let limit = if limit == 0 { None } else { Some(limit) };

    let update = Box::from_raw(update);

    isar_try! {
        match (isar, txn, query) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn), CIsarQuery::Native(query)) => {
                *updated = isar.query_update(txn, query, offset, limit, &update.0)?;
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn), CIsarQuery::SQLite(query)) => {
                *updated = isar.query_update(txn, query, offset, limit, &update.0)?;
            }
            _ => return Err(IsarError::IllegalArgument {}),
        };
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_update_new() -> *mut CIsarUpdate {
    Box::into_raw(Box::new(CIsarUpdate(Vec::new())))
}

#[no_mangle]
pub unsafe extern "C" fn isar_update_add_value(
    update: &'static mut CIsarUpdate,
    property_index: u16,
    value: *mut IsarValue,
) {
    let value = if !value.is_null() {
        Some(*Box::from_raw(value))
    } else {
        None
    };
    update.0.push((property_index, value));
}
