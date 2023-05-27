use std::ptr;

use isar_core::core::value::IsarValue;

#[no_mangle]
pub unsafe extern "C" fn isar_value_bool(value: bool, null: bool) -> *const IsarValue {
    let value = if null { None } else { Some(value) };
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
    let string = if value.is_null() {
        None
    } else {
        Some(*Box::from_raw(value))
    };
    let filter_value = IsarValue::String(string);
    Box::into_raw(Box::new(filter_value))
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_get_bool(value: &IsarValue) -> bool {
    value.bool().flatten().unwrap_or(false)
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_get_integer(value: &IsarValue) -> i64 {
    value.integer().unwrap_or(i64::MIN)
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_get_real(value: &IsarValue) -> f64 {
    value.real().unwrap_or(f64::NAN)
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_get_string(value: &IsarValue, str: *mut *const u8) -> u32 {
    *str = ptr::null();
    if let IsarValue::String(Some(value)) = value {
        *str = value.as_bytes().as_ptr();
        return value.len() as u32;
    }
    0
}
