use super::{FALSE_BOOL, NULL_DOUBLE, NULL_FLOAT, NULL_INT, NULL_LONG, TRUE_BOOL};
use crate::core::data_type::DataType;
use byteorder::{ByteOrder, LittleEndian};
use std::str::from_utf8_unchecked;
use xxhash_rust::xxh3::xxh3_64_with_seed;

#[derive(Copy, Clone, Eq, PartialEq)]
pub(crate) struct IsarDeserializer<'a> {
    pub bytes: &'a [u8],
    static_size: u32,
}

impl<'a> IsarDeserializer<'a> {
    #[inline]
    pub fn from_bytes(bytes: &'a [u8]) -> Self {
        let static_size = LittleEndian::read_u24(bytes);
        Self {
            bytes: &bytes[3..], // account for static size
            static_size,
        }
    }

    #[inline]
    fn contains_offset(&self, offset: u32) -> bool {
        self.static_size > offset
    }

    #[inline]
    pub fn is_null(&self, offset: u32, data_type: DataType) -> bool {
        match data_type {
            DataType::Bool => self.read_bool(offset).is_none(),
            DataType::Byte => !self.contains_offset(offset),
            DataType::Int => self.read_int(offset) == NULL_INT,
            DataType::Float => self.read_float(offset).is_nan(),
            DataType::Long => self.read_long(offset) == NULL_LONG,
            DataType::Double => self.read_double(offset).is_nan(),
            _ => self.get_offset_length(offset).is_none(),
        }
    }

    #[inline]
    pub fn read_bool(&self, offset: u32) -> Option<bool> {
        if self.contains_offset(offset) {
            match self.bytes[offset as usize] {
                FALSE_BOOL => Some(false),
                TRUE_BOOL => Some(true),
                _ => None,
            }
        } else {
            None
        }
    }

    #[inline]
    pub fn read_byte(&self, offset: u32) -> u8 {
        if self.contains_offset(offset) {
            self.bytes[offset as usize]
        } else {
            0
        }
    }

    #[inline]
    pub fn read_int(&self, offset: u32) -> i32 {
        if self.contains_offset(offset) {
            LittleEndian::read_i32(&self.bytes[offset as usize..])
        } else {
            NULL_INT
        }
    }

    #[inline]
    pub fn read_float(&self, offset: u32) -> f32 {
        if self.contains_offset(offset) {
            LittleEndian::read_f32(&self.bytes[offset as usize..])
        } else {
            NULL_FLOAT
        }
    }

    #[inline]
    pub fn read_long(&self, offset: u32) -> i64 {
        if self.contains_offset(offset) {
            LittleEndian::read_i64(&self.bytes[offset as usize..])
        } else {
            NULL_LONG
        }
    }

    #[inline]
    pub fn read_double(&self, offset: u32) -> f64 {
        if self.contains_offset(offset) {
            LittleEndian::read_f64(&self.bytes[offset as usize..])
        } else {
            NULL_DOUBLE
        }
    }

    #[inline]
    fn get_offset(&self, offset: u32) -> Option<usize> {
        if self.contains_offset(offset) {
            let offset = LittleEndian::read_u24(&self.bytes[offset as usize..]);
            if offset > 0 {
                return Some(offset as usize);
            }
        }
        None
    }

    #[inline]
    fn get_offset_length(&self, offset: u32) -> Option<(usize, usize)> {
        let offset = self.get_offset(offset)?;
        let length = LittleEndian::read_u24(&self.bytes[offset as usize..]);
        Some((offset as usize + 3, length as usize))
    }

    #[inline]
    pub fn read_dynamic(&self, offset: u32) -> Option<&'a [u8]> {
        let (offset, length) = self.get_offset_length(offset)?;
        let bytes = &self.bytes[offset..offset + length];
        Some(bytes)
    }

    #[inline]
    pub fn read_string(&self, offset: u32) -> Option<&'a str> {
        let bytes = self.read_dynamic(offset)?;
        unsafe { Some(from_utf8_unchecked(bytes)) }
    }

    #[inline]
    pub fn read_nested(&self, offset: u32) -> Option<IsarDeserializer<'a>> {
        let offset = self.get_offset(offset)?;
        let object = Self::from_bytes(&self.bytes[offset..]);
        Some(object)
    }

    #[inline]
    pub fn read_list(
        &self,
        offset: u32,
        element_type: DataType,
    ) -> Option<(IsarDeserializer<'a>, u32)> {
        let nested = self.read_nested(offset)?;
        let length = nested.static_size / element_type.static_size() as u32;
        Some((nested, length))
    }

    pub fn hash_property(
        &self,
        offset: u32,
        data_type: DataType,
        case_sensitive: bool,
        mut seed: u64,
    ) -> u64 {
        match data_type {
            DataType::Bool => {
                if let Some(value) = self.read_bool(offset) {
                    if value {
                        xxh3_64_with_seed(&[1], seed)
                    } else {
                        xxh3_64_with_seed(&[0], seed)
                    }
                } else {
                    xxh3_64_with_seed(&[255], seed)
                }
            }
            DataType::Byte => xxh3_64_with_seed(&[self.read_byte(offset)], seed),
            DataType::Int => xxh3_64_with_seed(&self.read_int(offset).to_le_bytes(), seed),
            DataType::Float => {
                let value = self.read_float(offset);
                if value.is_nan() {
                    xxh3_64_with_seed(&[1, 0, 128, 127], seed)
                } else {
                    xxh3_64_with_seed(&value.to_le_bytes(), seed)
                }
            }
            DataType::Long => xxh3_64_with_seed(&self.read_long(offset).to_le_bytes(), seed),
            DataType::Double => {
                let value = self.read_double(offset);
                if value.is_nan() {
                    xxh3_64_with_seed(&[0, 0, 0, 0, 0, 0, 248, 127], seed)
                } else {
                    xxh3_64_with_seed(&value.to_le_bytes(), seed)
                }
            }
            DataType::String => {
                if let Some(str) = self.read_string(offset) {
                    seed = xxh3_64_with_seed(&[1], seed);
                    if case_sensitive {
                        xxh3_64_with_seed(str.as_bytes(), seed)
                    } else {
                        xxh3_64_with_seed(str.to_lowercase().as_bytes(), seed)
                    }
                } else {
                    xxh3_64_with_seed(&[0], seed)
                }
            }
            _ => seed,
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    macro_rules! concat {
        ($($iter:expr),*) => {
            {
                let mut v = Vec::new();
                $(
                    for item in $iter {
                        v.push(item);
                    }
                )*
                v
            }
        }
    }

    #[test]
    fn test_read_bool_contains_offset() {
        let bytes = [3, 0, 0, TRUE_BOOL, FALSE_BOOL, 255];
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_bool(0), Some(true));
        assert_eq!(deserializer.read_bool(1), Some(false));
        assert_eq!(deserializer.read_bool(2), None);

        assert_eq!(deserializer.is_null(0, DataType::Bool), false);
        assert_eq!(deserializer.is_null(1, DataType::Bool), false);
        assert_eq!(deserializer.is_null(2, DataType::Bool), true);
    }

    #[test]
    fn test_read_bool_not_contains_offset() {
        let bytes = [3, 0, 0, TRUE_BOOL, FALSE_BOOL, 255];
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_bool(3), None);
        assert_eq!(deserializer.read_bool(4), None);

        assert_eq!(deserializer.is_null(3, DataType::Bool), true);
        assert_eq!(deserializer.is_null(4, DataType::Bool), true);
    }

    #[test]
    fn test_read_byte_contains_offset() {
        let bytes = [3, 0, 0, 0, 1, 255];
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_byte(0), 0);
        assert_eq!(deserializer.read_byte(1), 1);
        assert_eq!(deserializer.read_byte(2), 255);

        assert_eq!(deserializer.is_null(0, DataType::Byte), false);
        assert_eq!(deserializer.is_null(1, DataType::Byte), false);
        assert_eq!(deserializer.is_null(2, DataType::Byte), false);
    }

    #[test]
    fn test_read_byte_not_contains_offset() {
        let bytes = [3, 0, 0, 0, 1, 255];
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_byte(3), 0);
        assert_eq!(deserializer.read_byte(4), 0);

        assert_eq!(deserializer.is_null(3, DataType::Byte), true);
        assert_eq!(deserializer.is_null(4, DataType::Byte), true);
    }

    #[test]
    fn test_read_int_contains_offset() {
        let bytes = concat!(
            [12, 0, 0],
            i32::MIN.to_le_bytes(),
            i32::MAX.to_le_bytes(),
            (-5i32).to_le_bytes()
        );
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_int(0), i32::MIN);
        assert_eq!(deserializer.read_int(4), i32::MAX);
        assert_eq!(deserializer.read_int(8), -5);

        assert_eq!(deserializer.is_null(0, DataType::Int), true);
        assert_eq!(deserializer.is_null(4, DataType::Int), false);
        assert_eq!(deserializer.is_null(8, DataType::Int), false);
    }

    #[test]
    fn test_read_int_not_contains_offset() {
        let bytes = [3, 0, 0, 0, 1, 2];
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_int(3), i32::MIN);
        assert_eq!(deserializer.read_int(4), i32::MIN);

        assert_eq!(deserializer.is_null(3, DataType::Int), true);
        assert_eq!(deserializer.is_null(4, DataType::Int), true);
    }

    #[test]
    fn test_read_float_contains_offset() {
        let bytes = concat!(
            [12, 0, 0],
            f32::MIN.to_le_bytes(),
            f32::INFINITY.to_le_bytes(),
            f32::NAN.to_le_bytes()
        );
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_float(0), f32::MIN);
        assert_eq!(deserializer.read_float(4), f32::INFINITY);
        assert_eq!(deserializer.read_float(8).is_nan(), true);

        assert_eq!(deserializer.is_null(0, DataType::Float), false);
        assert_eq!(deserializer.is_null(4, DataType::Float), false);
        assert_eq!(deserializer.is_null(8, DataType::Float), true);
    }

    #[test]
    fn test_read_float_not_contains_offset() {
        let bytes = [3, 0, 0, 0, 1, 2];
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_float(3).is_nan(), true);
        assert_eq!(deserializer.read_float(4).is_nan(), true);

        assert_eq!(deserializer.is_null(3, DataType::Float), true);
        assert_eq!(deserializer.is_null(4, DataType::Float), true);
    }

    #[test]
    fn test_read_long_contains_offset() {
        let bytes = concat!(
            [24, 0, 0],
            i64::MIN.to_le_bytes(),
            i64::MAX.to_le_bytes(),
            (-5i64).to_le_bytes()
        );
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_long(0), i64::MIN);
        assert_eq!(deserializer.read_long(8), i64::MAX);
        assert_eq!(deserializer.read_long(16), -5);

        assert_eq!(deserializer.is_null(0, DataType::Long), true);
        assert_eq!(deserializer.is_null(8, DataType::Long), false);
        assert_eq!(deserializer.is_null(16, DataType::Long), false);
    }

    #[test]
    fn test_read_long_not_contains_offset() {
        let bytes = [3, 0, 0, 0, 1, 2];
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_long(3), i64::MIN);
        assert_eq!(deserializer.read_long(4), i64::MIN);

        assert_eq!(deserializer.is_null(3, DataType::Long), true);
        assert_eq!(deserializer.is_null(4, DataType::Long), true);
    }

    #[test]
    fn test_read_double_contains_offset() {
        let bytes = concat!(
            [24, 0, 0],
            f64::MIN.to_le_bytes(),
            f64::INFINITY.to_le_bytes(),
            f64::NAN.to_le_bytes()
        );
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_double(0), f64::MIN);
        assert_eq!(deserializer.read_double(8), f64::INFINITY);
        assert_eq!(deserializer.read_double(16).is_nan(), true);

        assert_eq!(deserializer.is_null(0, DataType::Double), false);
        assert_eq!(deserializer.is_null(8, DataType::Double), false);
        assert_eq!(deserializer.is_null(16, DataType::Double), true);
    }

    #[test]
    fn test_read_double_not_contains_offset() {
        let bytes = [3, 0, 0, 0, 1, 2];
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_double(3).is_nan(), true);
        assert_eq!(deserializer.read_double(4).is_nan(), true);

        assert_eq!(deserializer.is_null(3, DataType::Double), true);
        assert_eq!(deserializer.is_null(4, DataType::Double), true);
    }

    #[test]
    fn test_read_dynamic_contains_offset() {
        let bytes = concat!([6, 0, 0], [6, 0, 0, 0, 0, 0], [3, 0, 0, 4, 5, 6]);
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_dynamic(0), Some(&[4, 5, 6][..]));
        assert_eq!(deserializer.read_dynamic(3), None);

        assert_eq!(deserializer.is_null(0, DataType::ByteList), false);
        assert_eq!(deserializer.is_null(3, DataType::ByteList), true);
    }

    #[test]
    fn test_read_dynamic_not_contains_offset() {
        let bytes = [3, 0, 0, 0, 1, 2];
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_dynamic(3), None);
        assert_eq!(deserializer.is_null(3, DataType::ByteList), true);
    }

    #[test]
    fn test_read_string_contains_offset() {
        let bytes = concat!([6, 0, 0], [6, 0, 0, 0, 0, 0], [3, 0, 0, 97, 98, 99]);
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_string(0), Some("abc"));
        assert_eq!(deserializer.read_string(3), None);

        assert_eq!(deserializer.is_null(0, DataType::String), false);
        assert_eq!(deserializer.is_null(3, DataType::String), true);
    }

    #[test]
    fn test_read_string_not_contains_offset() {
        let bytes = [3, 0, 0, 0, 1, 2];
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_string(3), None);
        assert_eq!(deserializer.is_null(3, DataType::String), true);
    }

    #[test]
    fn test_read_nested_contains_offset() {
        let bytes = concat!([6, 0, 0], [6, 0, 0, 0, 0, 0], [4, 0, 0, 69, 0, 0, 0]);
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        let nested = deserializer.read_nested(0).unwrap();
        assert_eq!(nested.read_int(0), 69);
        assert_eq!(deserializer.read_nested(3).is_some(), false);

        assert_eq!(deserializer.is_null(0, DataType::Object), false);
        assert_eq!(deserializer.is_null(3, DataType::Object), true);
    }

    #[test]
    fn test_read_nested_not_contains_offset() {
        let bytes = [3, 0, 0, 0, 1, 2];
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_nested(3).is_some(), false);
        assert_eq!(deserializer.is_null(3, DataType::Object), true);
    }

    #[test]
    fn test_read_list_contains_offset() {
        let bytes = concat!(
            [9, 0, 0],
            [9, 0, 0, 15, 0, 0, 0, 0, 0],
            [3, 0, 0, 1, 0, 255],
            [4, 0, 0, 111, 0, 0, 0]
        );
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        let (nested, length) = deserializer.read_list(0, DataType::Bool).unwrap();
        assert_eq!(length, 3);
        assert_eq!(nested.read_bool(0), Some(true));
        assert_eq!(nested.read_bool(1), Some(false));
        assert_eq!(nested.read_bool(2), None);
        assert_eq!(nested.read_bool(3), None);

        let (nested, length) = deserializer.read_list(3, DataType::Int).unwrap();
        assert_eq!(length, 1);
        assert_eq!(nested.read_int(0), 111);
        assert_eq!(nested.read_int(4), NULL_INT);

        assert_eq!(deserializer.read_list(6, DataType::Int).is_some(), false);
        assert_eq!(deserializer.is_null(0, DataType::BoolList), false);
        assert_eq!(deserializer.is_null(3, DataType::IntList), false);
        assert_eq!(deserializer.is_null(6, DataType::IntList), true);
    }

    #[test]
    fn test_read_list_not_contains_offset() {
        let bytes = [3, 0, 0, 0, 1, 2];
        let deserializer = IsarDeserializer::from_bytes(&bytes);

        assert_eq!(deserializer.read_list(3, DataType::Bool).is_some(), false);
        assert_eq!(deserializer.is_null(3, DataType::BoolList), true);
    }

    #[test]
    fn test_hash_bool_property() {
        let bytes = [3, 0, 0, 0, 1, 7];
        let deserializer = IsarDeserializer::from_bytes(&bytes);
        assert_eq!(
            deserializer.hash_property(0, DataType::Bool, false, 0),
            xxh3_64_with_seed(&[0], 0)
        );
        assert_eq!(
            deserializer.hash_property(1, DataType::Bool, false, 2),
            xxh3_64_with_seed(&[1], 2)
        );
        assert_eq!(
            deserializer.hash_property(2, DataType::Bool, true, 9),
            xxh3_64_with_seed(&[255], 9)
        );
        assert_eq!(
            deserializer.hash_property(3, DataType::Bool, true, 9),
            xxh3_64_with_seed(&[255], 9)
        );
    }

    #[test]
    fn test_hash_byte_property() {
        let bytes = [3, 0, 0, 0, 1, 5];
        let deserializer = IsarDeserializer::from_bytes(&bytes);
        assert_eq!(
            deserializer.hash_property(2, DataType::Byte, false, 0),
            xxh3_64_with_seed(&[5], 0)
        );
        assert_eq!(
            deserializer.hash_property(1, DataType::Byte, false, 2),
            xxh3_64_with_seed(&[1], 2)
        );
        assert_eq!(
            deserializer.hash_property(3, DataType::Byte, true, 9),
            xxh3_64_with_seed(&[0], 9)
        );
    }

    #[test]
    fn test_hash_int_property() {
        let bytes = concat!([8, 0, 0], i32::MIN.to_le_bytes(), i32::MAX.to_le_bytes());
        let deserializer = IsarDeserializer::from_bytes(&bytes);
        assert_eq!(
            deserializer.hash_property(0, DataType::Int, false, 0),
            xxh3_64_with_seed(&i32::MIN.to_le_bytes(), 0)
        );
        assert_eq!(
            deserializer.hash_property(4, DataType::Int, false, 2),
            xxh3_64_with_seed(&i32::MAX.to_le_bytes(), 2)
        );
        assert_eq!(
            deserializer.hash_property(8, DataType::Int, true, 9),
            xxh3_64_with_seed(&i32::MIN.to_le_bytes(), 9)
        );
    }

    #[test]
    fn test_hash_float_property() {
        let bytes = concat!(
            [8, 0, 0],
            f32::NAN.to_le_bytes(),
            f32::INFINITY.to_le_bytes()
        );
        let deserializer = IsarDeserializer::from_bytes(&bytes);
        assert_eq!(
            deserializer.hash_property(0, DataType::Float, false, 0),
            xxh3_64_with_seed(&[1, 0, 128, 127], 0)
        );
        assert_eq!(
            deserializer.hash_property(4, DataType::Float, false, 2),
            xxh3_64_with_seed(&f32::INFINITY.to_le_bytes(), 2)
        );
        assert_eq!(
            deserializer.hash_property(8, DataType::Float, true, 9),
            xxh3_64_with_seed(&[1, 0, 128, 127], 9)
        );
    }

    #[test]
    fn test_hash_long_property() {
        let bytes = concat!([16, 0, 0], i64::MIN.to_le_bytes(), i64::MAX.to_le_bytes());
        let deserializer = IsarDeserializer::from_bytes(&bytes);
        assert_eq!(
            deserializer.hash_property(0, DataType::Long, false, 0),
            xxh3_64_with_seed(&i64::MIN.to_le_bytes(), 0)
        );
        assert_eq!(
            deserializer.hash_property(8, DataType::Long, false, 2),
            xxh3_64_with_seed(&i64::MAX.to_le_bytes(), 2)
        );
        assert_eq!(
            deserializer.hash_property(16, DataType::Long, true, 9),
            xxh3_64_with_seed(&i64::MIN.to_le_bytes(), 9)
        );
    }

    #[test]
    fn test_hash_double_property() {
        let bytes = concat!(
            [16, 0, 0],
            f64::NAN.to_le_bytes(),
            f64::INFINITY.to_le_bytes()
        );
        let deserializer = IsarDeserializer::from_bytes(&bytes);
        assert_eq!(
            deserializer.hash_property(0, DataType::Double, false, 0),
            xxh3_64_with_seed(&[0, 0, 0, 0, 0, 0, 248, 127], 0)
        );
        assert_eq!(
            deserializer.hash_property(8, DataType::Double, false, 2),
            xxh3_64_with_seed(&f64::INFINITY.to_le_bytes(), 2)
        );
        assert_eq!(
            deserializer.hash_property(16, DataType::Double, true, 9),
            xxh3_64_with_seed(&[0, 0, 0, 0, 0, 0, 248, 127], 9)
        );
    }

    #[test]
    fn test_hash_string_property() {
        let bytes = concat!([6, 0, 0], [6, 0, 0, 0, 0, 0], [3, 0, 0, 97, 66, 99]);
        let deserializer = IsarDeserializer::from_bytes(&bytes);
        assert_eq!(
            deserializer.hash_property(0, DataType::String, true, 0),
            xxh3_64_with_seed(b"aBc", xxh3_64_with_seed(&[1], 0))
        );
        assert_eq!(
            deserializer.hash_property(0, DataType::String, false, 66),
            xxh3_64_with_seed(b"abc", xxh3_64_with_seed(&[1], 66))
        );
        assert_eq!(
            deserializer.hash_property(3, DataType::String, false, 2),
            xxh3_64_with_seed(&[0], 2)
        );
    }

    #[test]
    fn test_hash_byte_list_property() {
        let bytes = concat!([3, 0, 0], [3, 0, 0], [2, 0, 0, 1, 0]);
        let deserializer = IsarDeserializer::from_bytes(&bytes);
        assert_eq!(
            deserializer.hash_property(0, DataType::ByteList, false, 212),
            212
        );
        assert_eq!(
            deserializer.hash_property(3, DataType::ByteList, false, 121),
            121
        );
    }
}
