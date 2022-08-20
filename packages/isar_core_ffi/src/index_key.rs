use crate::from_c_str;
use isar_core::index::index_key::IndexKey;
use isar_core::object::isar_object::IsarObject;
use paste::paste;
use std::os::raw::c_char;

#[no_mangle]
pub unsafe extern "C" fn isar_key_create(key: *mut *const IndexKey) {
    let index_key = IndexKey::new();
    let ptr = Box::into_raw(Box::new(index_key));
    key.write(ptr);
}

#[no_mangle]
pub unsafe extern "C" fn isar_key_increase(key: &mut IndexKey) -> bool {
    key.increase()
}

#[no_mangle]
pub unsafe extern "C" fn isar_key_decrease(key: &mut IndexKey) -> bool {
    key.decrease()
}

#[no_mangle]
pub extern "C" fn isar_key_add_byte(key: &mut IndexKey, value: u8) {
    key.add_byte(value);
}

#[no_mangle]
pub extern "C" fn isar_key_add_int(key: &mut IndexKey, value: i32) {
    key.add_int(value);
}

#[no_mangle]
pub extern "C" fn isar_key_add_long(key: &mut IndexKey, value: i64) {
    key.add_long(value);
}

#[no_mangle]
pub extern "C" fn isar_key_add_float(key: &mut IndexKey, value: f64) {
    let value = if value.is_finite() {
        value.clamp(f32::MIN as f64, f32::MAX as f64)
    } else {
        value
    };
    key.add_float(value as f32);
}

#[no_mangle]
pub extern "C" fn isar_key_add_double(key: &mut IndexKey, value: f64) {
    key.add_double(value);
}

#[no_mangle]
pub unsafe extern "C" fn isar_key_add_string(
    key: &mut IndexKey,
    value: *const c_char,
    case_sensitive: bool,
) {
    let value = from_c_str(value).unwrap();
    key.add_string(value, case_sensitive)
}

#[no_mangle]
pub unsafe extern "C" fn isar_key_add_string_hash(
    key: &mut IndexKey,
    value: *const c_char,
    case_sensitive: bool,
) {
    let value = from_c_str(value).unwrap();
    let hash = IsarObject::hash_string(value, case_sensitive, 0);
    key.add_hash(hash);
}

#[no_mangle]
pub unsafe extern "C" fn isar_key_add_string_list_hash(
    key: &mut IndexKey,
    value: *const *const c_char,
    length: u32,
    case_sensitive: bool,
) {
    let value = if !value.is_null() {
        let raw_strings = std::slice::from_raw_parts(value, length as usize);
        let mut strings = vec![];
        for raw_str in raw_strings {
            let str = from_c_str(*raw_str).unwrap();
            strings.push(str);
        }
        Some(strings)
    } else {
        None
    };
    let hash = IsarObject::hash_string_list(value, case_sensitive, 0);
    key.add_hash(hash);
}

#[macro_export]
macro_rules! hash_list {
    ($name:ident, $type:ty) => {
        paste! {
            #[no_mangle]
            pub unsafe extern "C" fn [<isar_key_add_ $name _list_hash>](
                key: &mut IndexKey,
                value: *const $type,
                length: u32,
            ) {
                let value = if !value.is_null() {
                    Some(std::slice::from_raw_parts(value, length as usize))
                } else {
                    None
                };
                let hash = IsarObject::hash_list(value, 0);
                key.add_hash(hash);
            }
        }
    };
}

hash_list!(byte, u8);
hash_list!(int, i32);
hash_list!(long, i64);
