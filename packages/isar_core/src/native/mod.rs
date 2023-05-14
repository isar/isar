mod index;
mod isar_deserializer;
mod isar_serializer;
mod mdbx;
mod native_collection;
mod native_filter;
mod native_insert;
pub mod native_instance;
mod native_query_builder;
mod native_reader;
mod native_txn;
mod native_writer;
mod query;
mod schema_manager;

pub(crate) const NULL_BOOL: u8 = 0;
pub(crate) const FALSE_BOOL: u8 = 1;
pub(crate) const TRUE_BOOL: u8 = 2;
pub(crate) const NULL_BYTE: u8 = 0;
pub(crate) const NULL_INT: i32 = i32::MIN;
pub(crate) const NULL_LONG: i64 = i64::MIN;
pub(crate) const NULL_FLOAT: f32 = f32::NAN;
pub(crate) const NULL_DOUBLE: f64 = f64::NAN;
pub(crate) const MAX_OBJ_SIZE: u32 = 2 << 24;

#[inline]
pub(crate) fn bool_to_byte(value: Option<bool>) -> u8 {
    match value {
        Some(true) => TRUE_BOOL,
        Some(false) => FALSE_BOOL,
        None => NULL_BOOL,
    }
}

#[inline]
pub(crate) fn byte_to_bool(value: u8) -> Option<bool> {
    match value {
        TRUE_BOOL => Some(true),
        FALSE_BOOL => Some(false),
        _ => None,
    }
}
