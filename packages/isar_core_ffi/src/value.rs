use std::ptr;

use isar_core::core::value::IsarValue;

#[no_mangle]
pub unsafe extern "C" fn isar_value_bool(value: bool) -> *const IsarValue {
    Box::into_raw(Box::new(IsarValue::Bool(value)))
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_integer(value: i64) -> *const IsarValue {
    Box::into_raw(Box::new(IsarValue::Integer(value)))
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_real(value: f64) -> *const IsarValue {
    Box::into_raw(Box::new(IsarValue::Real(value)))
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_string(value: *mut String) -> *const IsarValue {
    Box::into_raw(Box::new(IsarValue::String(*Box::from_raw(value))))
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_get_bool(value: *const IsarValue) -> bool {
    value.as_ref().map(|v| v.bool()).flatten().unwrap_or(false)
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_get_integer(value: *const IsarValue) -> i64 {
    value
        .as_ref()
        .map(|v| v.i64())
        .flatten()
        .unwrap_or(i64::MIN)
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_get_real(value: *const IsarValue) -> f64 {
    value
        .as_ref()
        .map(|v| v.real())
        .flatten()
        .unwrap_or(f64::NAN)
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_get_string(
    value: *const IsarValue,
    str: *mut *const u8,
) -> u32 {
    *str = ptr::null();
    if let Some(value) = value.as_ref().map(|v| v.string()).flatten() {
        *str = value.as_bytes().as_ptr();
        return value.len() as u32;
    }
    0
}
