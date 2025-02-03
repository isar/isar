use crate::{IsarI64, i64_to_isar, isar_to_i64};
use isar_core::core::value::IsarValue;
use std::ptr;

#[unsafe(no_mangle)]
pub unsafe extern "C" fn isar_value_bool(value: bool) -> *const IsarValue {
    Box::into_raw(Box::new(IsarValue::Bool(value)))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn isar_value_integer(value: IsarI64) -> *const IsarValue {
    let value = isar_to_i64(value);
    Box::into_raw(Box::new(IsarValue::Integer(value)))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn isar_value_real(value: f64) -> *const IsarValue {
    Box::into_raw(Box::new(IsarValue::Real(value)))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn isar_value_string(value: *mut String) -> *const IsarValue {
    Box::into_raw(Box::new(IsarValue::String(*Box::from_raw(value))))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn isar_value_get_bool(value: *const IsarValue) -> u8 {
    let value = value.as_ref().map(|v| v.bool()).flatten().unwrap_or(false);
    if value { 1 } else { 0 }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn isar_value_get_integer(value: *const IsarValue) -> IsarI64 {
    let value = value
        .as_ref()
        .map(|v| v.i64())
        .flatten()
        .unwrap_or(i64::MIN);
    i64_to_isar(value)
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn isar_value_get_real(value: *const IsarValue) -> f64 {
    value
        .as_ref()
        .map(|v| v.real())
        .flatten()
        .unwrap_or(f64::NAN)
}

#[unsafe(no_mangle)]
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

#[unsafe(no_mangle)]
pub unsafe extern "C" fn isar_value_free(value: *mut IsarValue) {
    if !value.is_null() {
        drop(Box::from_raw(value));
    }
}
