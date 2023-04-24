use std::borrow::Cow;

use serde_json::Value;

pub const NULL_BOOL: u8 = 0;
pub const FALSE_BOOL: u8 = 1;
pub const TRUE_BOOL: u8 = 2;
pub const NULL_INT: i32 = i32::MIN;
pub const NULL_LONG: i64 = i64::MIN;

pub trait IsarReader {
    type ObjectReader<'b>: IsarReader
    where
        Self: 'b;

    type ListReader<'b>: IsarReader
    where
        Self: 'b;

    fn is_null(&self, index: usize) -> bool;

    fn read_id(&self) -> i64;

    fn read_byte(&self, index: usize) -> u8;

    fn read_bool(&self, index: usize) -> Option<bool>;

    fn read_int(&self, index: usize) -> i32;

    fn read_float(&self, index: usize) -> f32;

    fn read_long(&self, index: usize) -> i64;

    fn read_double(&self, index: usize) -> f64;

    fn read_string(&self, index: usize) -> Option<&str>;

    fn read_blob(&self, index: usize) -> Option<Cow<'_, [u8]>>;

    fn read_json(&self, index: usize) -> Option<Cow<'_, Value>>;

    fn read_object(&self, index: usize) -> Option<Self::ObjectReader<'_>>;

    fn read_list(&self, index: usize) -> Option<(Self::ListReader<'_>, usize)>;
}
