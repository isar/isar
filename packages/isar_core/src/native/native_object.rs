use super::{NULL_BYTE, NULL_DOUBLE, NULL_FLOAT, NULL_INT, NULL_LONG};
use crate::core::data_type::DataType;
use byteorder::{ByteOrder, LittleEndian};
use serde_json::Value;
use std::str::from_utf8_unchecked;
use xxhash_rust::xxh3::xxh3_64_with_seed;

#[derive(Copy, Clone, Eq, PartialEq)]
pub struct NativeObject<'a> {
    bytes: &'a [u8],
    static_size: usize,
    dynamic_offset: usize,
}

impl<'a> NativeObject<'a> {
    pub fn from_bytes(bytes: &'a [u8]) -> Self {
        let static_size = LittleEndian::read_u16(bytes) as usize;
        NativeObject {
            bytes,
            static_size,
            dynamic_offset: 0,
        }
    }

    #[inline]
    fn contains_offset(&self, offset: usize) -> bool {
        self.static_size > offset
    }

    #[inline]
    pub fn read_byte(&self, offset: usize) -> u8 {
        if self.contains_offset(offset) {
            self.bytes[offset]
        } else {
            NULL_BYTE
        }
    }

    #[inline]
    pub fn read_int(&self, offset: usize) -> i32 {
        if self.contains_offset(offset) {
            LittleEndian::read_i32(&self.bytes[offset..])
        } else {
            NULL_INT
        }
    }

    #[inline]
    pub fn read_float(&self, offset: usize) -> f32 {
        if self.contains_offset(offset) {
            LittleEndian::read_f32(&self.bytes[offset..])
        } else {
            NULL_FLOAT
        }
    }

    #[inline]
    pub fn read_long(&self, offset: usize) -> i64 {
        if self.contains_offset(offset) {
            LittleEndian::read_i64(&self.bytes[offset..])
        } else {
            NULL_LONG
        }
    }

    #[inline]
    pub fn read_double(&self, offset: usize) -> f64 {
        if self.contains_offset(offset) {
            LittleEndian::read_f64(&self.bytes[offset..])
        } else {
            NULL_DOUBLE
        }
    }

    fn get_offset_length(&self, offset: usize) -> Option<(usize, usize)> {
        if self.contains_offset(offset) {
            let mut length_offset = LittleEndian::read_u24(&self.bytes[offset..]) as usize;
            if length_offset > self.dynamic_offset {
                length_offset -= self.dynamic_offset;
                let length = LittleEndian::read_u24(&self.bytes[length_offset..]) as usize;
                return Some((length_offset + 3, length));
            }
        }
        None
    }

    #[inline]
    pub fn read_string(&self, offset: usize) -> Option<&'a str> {
        let (offset, length) = self.get_offset_length(offset)?;
        let bytes = &self.bytes[offset..offset + length];
        let str = unsafe { from_utf8_unchecked(bytes) };
        Some(str)
    }

    #[inline]
    pub fn read_bytes(&self, offset: usize) -> Option<&'a [u8]> {
        let (offset, length) = self.get_offset_length(offset)?;
        let bytes = &self.bytes[offset..offset + length];
        Some(bytes)
    }

    #[inline]
    pub fn read_json(&self, offset: usize) -> Option<Value> {
        let (offset, length) = self.get_offset_length(offset)?;
        let bytes = &self.bytes[offset..offset + length];
        serde_json::from_slice(bytes).ok()
    }

    #[inline]
    pub fn read_object(&self, offset: usize) -> Option<NativeObject<'a>> {
        let (offset, length) = self.get_offset_length(offset)?;
        let bytes = &self.bytes[offset..offset + length];
        Some(NativeObject::from_bytes(bytes))
    }

    #[inline]
    pub fn read_list(
        &self,
        offset: usize,
        element_type: DataType,
    ) -> Option<(NativeObject<'a>, usize)> {
        assert!(!element_type.is_list());
        let (offset, length) = self.get_offset_length(offset)?;
        let object = NativeObject {
            bytes: &self.bytes[offset..],
            static_size: length * element_type.static_size(),
            dynamic_offset: offset,
        };
        Some((object, length))
    }

    #[inline]
    pub fn read_list_length(&self, offset: usize) -> Option<usize> {
        let (offset, length) = self.get_offset_length(offset)?;
        if offset != 0 {
            Some(length)
        } else {
            None
        }
    }

    pub fn hash_property(
        &self,
        offset: usize,
        data_type: DataType,
        case_insensitive: bool,
        mut seed: u64,
    ) -> u64 {
        match data_type {
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
                let value = self.read_float(offset);
                if value.is_nan() {
                    xxh3_64_with_seed(&[0, 0, 0, 0, 0, 0, 248, 127], seed)
                } else {
                    xxh3_64_with_seed(&value.to_le_bytes(), seed)
                }
            }
            DataType::String => {
                if let Some(str) = self.read_string(offset) {
                    seed = xxh3_64_with_seed(&[1], seed);
                    if case_insensitive {
                        xxh3_64_with_seed(str.to_lowercase().as_bytes(), seed)
                    } else {
                        xxh3_64_with_seed(str.as_bytes(), seed)
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
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_read_byte() {
        let data = [0x01, 0x02, 0x03];
        let object = NativeObject::from_bytes(&data);

        assert_eq!(1, object.read_byte(0));
        assert_eq!(2, object.read_byte(1));
        assert_eq!(3, object.read_byte(2));
        assert_eq!(0, object.read_byte(3));
    }

    #[test]
    fn test_read_int() {
        let data = [0x0A, 0x00, 0x2A, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF];
        let object = NativeObject::from_bytes(&data);

        assert_eq!(42, object.read_int(2));
        assert_eq!(-1, object.read_int(6));
        assert_eq!(NULL_INT, object.read_int(10));
    }

    #[test]
    fn test_read_string() {
        let data = [
            0x08, 0x00, 0x00, 0x00, 0x00, 0x0B, 0x00, 0x00, 0x05, 0x00, 0x00, 0x68, 0x65, 0x6C,
            0x6C, 0x6F,
        ];
        let object = NativeObject::from_bytes(&data);

        assert_eq!(None, object.read_string(2));
        assert_eq!(Some("hello"), object.read_string(5));
    }

    #[test]
    fn test_read_json() {
        let data = [
            0x08, 0x00, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x0B, 0x00, 0x00, 0x7B, 0x22, 0x61,
            0x22, 0x3A, 0x31, 0x7D,
        ];
        let object = NativeObject::from_bytes(&data);

        assert_eq!(None, object.read_json(2));
        assert_eq!(Some(json!({"a": 1})), object.read_json(5));
    }

    // Add more tests to cover other read methods and edge cases.
}
