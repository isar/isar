use std::str::from_utf8_unchecked;

use byteorder::{ByteOrder, LittleEndian};

use crate::core::data_type::DataType;

#[derive(Copy, Clone, Eq, PartialEq)]
pub struct V2IsarObject<'a> {
    bytes: &'a [u8],
    static_size: usize,
}

impl<'a> V2IsarObject<'a> {
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
        V2IsarObject { bytes, static_size }
    }

    pub fn as_bytes(&self) -> &'a [u8] {
        self.bytes
    }

    pub fn len(&self) -> usize {
        self.bytes.len()
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

    #[inline]
    pub fn byte_to_bool(value: u8) -> Option<bool> {
        if value == Self::NULL_BOOL {
            None
        } else {
            Some(value == Self::TRUE_BOOL)
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
        let value = if self.contains_offset(offset) {
            self.bytes[offset]
        } else {
            Self::NULL_BOOL
        };
        Self::byte_to_bool(value)
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

    fn read_u24(&self, offset: usize) -> usize {
        LittleEndian::read_u24(&self.bytes[offset..]) as usize
    }

    fn get_offset_length(&self, offset: usize) -> Option<(usize, usize)> {
        if self.contains_offset(offset) {
            let length_offset = self.read_u24(offset);
            if length_offset != 0 {
                let length = self.read_u24(length_offset);
                return Some((length_offset + 3, length));
            }
        }
        None
    }

    pub fn read_length(&self, offset: usize) -> Option<usize> {
        let (_, length) = self.get_offset_length(offset)?;
        Some(length)
    }

    pub fn read_byte_list(&self, offset: usize) -> Option<&'a [u8]> {
        let (offset, length) = self.get_offset_length(offset)?;
        Some(&self.bytes[offset..offset + length])
    }

    pub fn read_string(&'a self, offset: usize) -> Option<&'a str> {
        let bytes = self.read_byte_list(offset)?;
        let str = unsafe { from_utf8_unchecked(bytes) };
        Some(str)
    }

    pub fn read_object(&'a self, offset: usize) -> Option<V2IsarObject> {
        let bytes = self.read_byte_list(offset)?;
        Some(V2IsarObject::from_bytes(bytes))
    }

    pub fn read_bool_list(&self, offset: usize) -> Option<Vec<Option<bool>>> {
        let (offset, length) = self.get_offset_length(offset)?;
        let mut list = vec![None; length];
        for i in 0..length {
            list[i] = Self::byte_to_bool(self.bytes[offset + i]);
        }
        Some(list)
    }

    pub fn read_int_list(&self, offset: usize) -> Option<Vec<i32>> {
        let (offset, length) = self.get_offset_length(offset)?;
        let mut list = vec![0; length];
        for i in 0..length {
            list[i] = LittleEndian::read_i32(&self.bytes[offset + i * 4..]);
        }
        Some(list)
    }

    pub fn read_int_or_null_list(&self, offset: usize) -> Option<Vec<Option<i32>>> {
        self.read_int_list(offset).map(|list| {
            list.into_iter()
                .map(|value| {
                    if value != Self::NULL_INT {
                        Some(value)
                    } else {
                        None
                    }
                })
                .collect()
        })
    }

    pub fn read_float_list(&self, offset: usize) -> Option<Vec<f32>> {
        let (offset, length) = self.get_offset_length(offset)?;
        let mut list = vec![0.0; length];
        for i in 0..length {
            list[i] = LittleEndian::read_f32(&self.bytes[offset + i * 4..]);
        }
        Some(list)
    }

    pub fn read_float_or_null_list(&self, offset: usize) -> Option<Vec<Option<f32>>> {
        self.read_float_list(offset).map(|list| {
            list.into_iter()
                .map(|value| if !value.is_nan() { Some(value) } else { None })
                .collect()
        })
    }

    pub fn read_long_list(&self, offset: usize) -> Option<Vec<i64>> {
        let (offset, length) = self.get_offset_length(offset)?;
        let mut list = vec![0; length];
        for i in 0..length {
            list[i] = LittleEndian::read_i64(&self.bytes[offset + i * 8..]);
        }
        Some(list)
    }

    pub fn read_long_or_null_list(&self, offset: usize) -> Option<Vec<Option<i64>>> {
        self.read_long_list(offset).map(|list| {
            list.into_iter()
                .map(|value| {
                    if value != Self::NULL_LONG {
                        Some(value)
                    } else {
                        None
                    }
                })
                .collect()
        })
    }

    pub fn read_double_list(&self, offset: usize) -> Option<Vec<f64>> {
        let (offset, length) = self.get_offset_length(offset)?;
        let mut list = vec![0.0; length];
        for i in 0..length {
            list[i] = LittleEndian::read_f64(&self.bytes[offset + i * 8..]);
        }
        Some(list)
    }

    pub fn read_double_or_null_list(&self, offset: usize) -> Option<Vec<Option<f64>>> {
        self.read_double_list(offset).map(|list| {
            list.into_iter()
                .map(|value| if !value.is_nan() { Some(value) } else { None })
                .collect()
        })
    }

    pub fn read_string_list(&self, offset: usize) -> Option<Vec<Option<&'a str>>> {
        self.read_dynamic_list(offset, |bytes| unsafe { from_utf8_unchecked(bytes) })
    }

    pub fn read_object_list(&self, offset: usize) -> Option<Vec<Option<V2IsarObject<'a>>>> {
        self.read_dynamic_list(offset, |bytes| V2IsarObject::from_bytes(bytes))
    }

    fn read_dynamic_list<T: Clone>(
        &self,
        offset: usize,
        transform: impl Fn(&'a [u8]) -> T,
    ) -> Option<Vec<Option<T>>> {
        let (offset, length) = self.get_offset_length(offset)?;

        let mut list = vec![None; length];
        let mut content_offset = offset + length * 3;
        for i in 0..length {
            let item_size = self.read_u24(offset + i * 3);
            if item_size != 0 {
                let item_size = item_size - 1;
                let bytes = &self.bytes[content_offset..content_offset + item_size];
                let value = transform(bytes);
                list[i] = Some(value);
                content_offset += item_size;
            }
        }

        Some(list)
    }
}
