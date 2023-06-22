use isar_core::core::value::IsarValue;

use crate::CIsarUpdate;

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
