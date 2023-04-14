use crate::core::data_type::DataType;
use byteorder::{ByteOrder, LittleEndian};
use serde_json::Value;
use std::str::from_utf8_unchecked;

#[derive(Copy, Clone, Eq, PartialEq)]
pub struct NativeObject<'a> {
    bytes: &'a [u8],
    static_size: usize,
    dynamic_offset: usize,
}

impl<'a> NativeObject<'a> {
    pub const NULL_BYTE: u8 = 0;
    pub const NULL_BOOL: u8 = 0;
    pub const FALSE_BOOL: u8 = 1;
    pub const TRUE_BOOL: u8 = 2;
    pub const NULL_INT: i32 = i32::MIN;
    pub const NULL_LONG: i64 = i64::MIN;
    pub const NULL_FLOAT: f32 = f32::NAN;
    pub const NULL_DOUBLE: f64 = f64::NAN;
    pub const MAX_SIZE: u32 = 2 << 24;

    pub fn from_bytes(bytes: &'a [u8]) -> Self {
        let static_size = LittleEndian::read_u16(bytes) as usize;
        NativeObject {
            bytes,
            static_size,
            dynamic_offset: 0,
        }
    }

    #[inline]
    pub(crate) fn contains_offset(&self, offset: usize) -> bool {
        self.static_size > offset
    }

    pub fn is_null(&self, offset: usize, data_type: DataType) -> bool {
        match data_type {
            DataType::Byte => false,
            DataType::Bool => self.read_bool(offset).is_none(),
            DataType::Int => self.read_int(offset) == Self::NULL_INT,
            DataType::Long => self.read_long(offset) == Self::NULL_LONG,
            DataType::Float => self.read_float(offset).is_nan(),
            DataType::Double => self.read_double(offset).is_nan(),
            _ => self.get_offset_length(offset).is_none(),
        }
    }

    pub fn read_byte(&self, offset: usize) -> u8 {
        if self.contains_offset(offset) {
            self.bytes[offset]
        } else {
            Self::NULL_BYTE
        }
    }

    pub fn read_bool(&self, offset: usize) -> Option<bool> {
        if self.contains_offset(offset) {
            match self.bytes[offset] {
                Self::NULL_BOOL => None,
                Self::FALSE_BOOL => Some(false),
                _ => Some(true),
            }
        } else {
            None
        }
    }

    pub fn read_int(&self, offset: usize) -> i32 {
        if self.contains_offset(offset) {
            LittleEndian::read_i32(&self.bytes[offset..])
        } else {
            Self::NULL_INT
        }
    }

    pub fn read_float(&self, offset: usize) -> f32 {
        if self.contains_offset(offset) {
            LittleEndian::read_f32(&self.bytes[offset..])
        } else {
            Self::NULL_FLOAT
        }
    }

    pub fn read_long(&self, offset: usize) -> i64 {
        if self.contains_offset(offset) {
            LittleEndian::read_i64(&self.bytes[offset..])
        } else {
            Self::NULL_LONG
        }
    }

    pub fn read_double(&self, offset: usize) -> f64 {
        if self.contains_offset(offset) {
            LittleEndian::read_f64(&self.bytes[offset..])
        } else {
            Self::NULL_DOUBLE
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

    pub fn read_string(&'a self, offset: usize) -> Option<&'a str> {
        let (offset, length) = self.get_offset_length(offset)?;
        let bytes = &self.bytes[offset..offset + length];
        let str = unsafe { from_utf8_unchecked(bytes) };
        Some(str)
    }

    pub fn read_any(&'a self, offset: usize) -> Option<Value> {
        let (offset, length) = self.get_offset_length(offset)?;
        let bytes = &self.bytes[offset..offset + length];
        serde_json::from_slice(bytes).ok()
    }

    pub fn read_object(&self, offset: usize) -> Option<NativeObject<'a>> {
        let (offset, length) = self.get_offset_length(offset)?;
        let bytes = &self.bytes[offset..offset + length];
        Some(NativeObject::from_bytes(bytes))
    }

    pub fn read_list(&self, offset: usize, element_size: u8) -> Option<(NativeObject<'a>, usize)> {
        let (offset, length) = self.get_offset_length(offset)?;
        let object = NativeObject {
            bytes: &self.bytes[offset..],
            static_size: length * element_size as usize,
            dynamic_offset: offset,
        };
        Some((object, length))
    }
}
