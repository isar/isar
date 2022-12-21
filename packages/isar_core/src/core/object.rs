use super::data_type::DataType;
use std::cmp::Ordering;

pub trait IsarObject<'a> {
    fn is_null(&self, offset: usize, data_type: DataType) -> bool;

    fn read_byte(&self, offset: usize) -> u8;

    fn read_bool(&self, offset: usize) -> Option<bool>;

    /*fn read_int(&self, offset: usize) -> i32;

    fn read_float(&self, offset: usize) -> f32;

    fn read_long(&self, offset: usize) -> i64;

    fn read_double(&self, offset: usize) -> f64;

    fn read_byte_list(&self, offset: usize) -> Option<&'a [u8]>;

    fn read_string(&self, offset: usize) -> Option<&'a str>;

    fn read_object(&self, offset: usize) -> Option<impl IsarObject<'a>>;

    fn read_bool_list(&self, offset: usize) -> Option<Vec<Option<bool>>>;

    fn read_int_list(&self, offset: usize) -> Option<Vec<i32>>;

    fn read_int_or_null_list(&self, offset: usize) -> Option<Vec<Option<i32>>>;

    fn read_float_list(&self, offset: usize) -> Option<Vec<f32>>;

    fn read_float_or_null_list(&self, offset: usize) -> Option<Vec<Option<f32>>>;

    fn read_long_list(&self, offset: usize) -> Option<Vec<i64>>;

    fn read_long_or_null_list(&self, offset: usize) -> Option<Vec<Option<i64>>>;

    fn read_double_list(&self, offset: usize) -> Option<Vec<f64>>;

    fn read_double_or_null_list(&self, offset: usize) -> Option<Vec<Option<f64>>>;

    fn read_string_list(&self, offset: usize) -> Option<Vec<Option<&'a str>>>;

    fn read_object_list(&self, offset: usize) -> Option<Vec<Option<impl IsarObject<'a>>>>;

    fn hash_property(
        &self,
        offset: usize,
        data_type: DataType,
        case_sensitive: bool,
        seed: u64,
    ) -> u64;

    fn compare_property<'b>(
        &self,
        other: &impl IsarObject<'b>,
        offset: usize,
        data_type: DataType,
    ) -> Ordering;*/
}
