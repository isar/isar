use crate::{CIsarInstance, CIsarTxn, CIsarUpdate};
use isar_core::core::error::IsarError;
use isar_core::core::instance::IsarInstance;
use isar_core::core::value::IsarValue;

#[no_mangle]
pub unsafe extern "C" fn isar_update(
    isar: &'static CIsarInstance,
    txn: &CIsarTxn,
    collection_index: u16,
    id: i64,
    update: &CIsarUpdate,
    updated: *mut bool,
) -> u8 {
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

#[no_mangle]
pub unsafe extern "C" fn isar_update_free(update: *mut CIsarUpdate) {
    if !update.is_null() {
        drop(Box::from_raw(update));
    }
}
