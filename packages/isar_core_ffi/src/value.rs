use isar_core::core::value::IsarValue;

#[no_mangle]
pub unsafe extern "C" fn isar_value_bool(value: bool, null: bool) -> *const IsarValue {
    let filter = if null {
        IsarValue::Bool(None)
    } else {
        IsarValue::Bool(Some(value))
    };
    Box::into_raw(Box::new(filter))
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
    let value = if value.is_null() {
        None
    } else {
        Some(*Box::from_raw(value))
    };
    let filter_value = IsarValue::String(value);
    Box::into_raw(Box::new(filter_value))
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_is_null(value: &IsarValue) -> bool {
    value.is_null()
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_get_bool(value: &IsarValue) -> bool {
    if let IsarValue::Bool(Some(value)) = value {
        *value
    } else {
        false
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_get_integer(value: &IsarValue) -> i64 {
    if let IsarValue::Integer(value) = value {
        *value
    } else {
        i64::MIN
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_get_real(value: &IsarValue) -> f64 {
    if let IsarValue::Real(value) = value {
        *value
    } else {
        f64::NAN
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_value_get_string(value: &IsarValue, str: *mut *const u8) -> u32 {
    if let IsarValue::String(value) = value {
        if let Some(value) = value {
            *str = value.as_bytes().as_ptr();
            return value.len() as u32;
        }
    }
    0
}
