use crate::object::{data_type::DataType, isar_object::IsarObject};
use byteorder::{ByteOrder, LittleEndian};

#[derive(Copy, Clone, Eq, PartialEq)]
pub struct LegacyProperty {
    pub data_type: DataType,
    pub offset: usize,
}

impl LegacyProperty {
    pub const fn new(data_type: DataType, offset: usize) -> Self {
        LegacyProperty { data_type, offset }
    }
}

#[derive(Copy, Clone, Eq, PartialEq)]
pub struct LegacyIsarObject<'a> {
    bytes: &'a [u8],
    static_size: usize,
}

impl<'a> LegacyIsarObject<'a> {
    pub fn from_bytes(bytes: &'a [u8]) -> Self {
        let static_size = LittleEndian::read_u16(bytes) as usize;
        LegacyIsarObject { bytes, static_size }
    }

    #[inline]
    pub(crate) fn contains_offset(&self, offset: usize) -> bool {
        self.static_size > offset
    }

    #[inline]
    pub fn contains_property(&self, property: LegacyProperty) -> bool {
        self.contains_offset(property.offset)
    }

    pub fn is_null(&self, property: LegacyProperty) -> bool {
        match property.data_type {
            DataType::Byte => self.read_byte(property) == IsarObject::NULL_BYTE,
            DataType::Int => self.read_int(property) == IsarObject::NULL_INT,
            DataType::Long => self.read_long(property) == IsarObject::NULL_LONG,
            DataType::Float => self.read_float(property).is_nan(),
            DataType::Double => self.read_double(property).is_nan(),
            _ => self.get_offset_length(property.offset, false).is_none(),
        }
    }

    pub fn read_byte(&self, property: LegacyProperty) -> u8 {
        if self.contains_property(property) {
            self.bytes[property.offset]
        } else {
            IsarObject::NULL_BYTE
        }
    }

    pub fn read_bool(&self, property: LegacyProperty) -> bool {
        self.read_byte(property) == IsarObject::TRUE_BOOL
    }

    pub fn read_int(&self, property: LegacyProperty) -> i32 {
        if self.contains_property(property) {
            LittleEndian::read_i32(&self.bytes[property.offset..])
        } else {
            IsarObject::NULL_INT
        }
    }

    pub fn read_float(&self, property: LegacyProperty) -> f32 {
        if self.contains_property(property) {
            LittleEndian::read_f32(&self.bytes[property.offset..])
        } else {
            IsarObject::NULL_FLOAT
        }
    }

    pub fn read_long(&self, property: LegacyProperty) -> i64 {
        if self.contains_property(property) {
            LittleEndian::read_i64(&self.bytes[property.offset..])
        } else {
            IsarObject::NULL_LONG
        }
    }

    pub fn read_double(&self, property: LegacyProperty) -> f64 {
        if self.contains_property(property) {
            LittleEndian::read_f64(&self.bytes[property.offset..])
        } else {
            IsarObject::NULL_DOUBLE
        }
    }

    fn get_offset_length(&self, offset: usize, dynamic_offset: bool) -> Option<(usize, usize)> {
        if dynamic_offset || self.contains_offset(offset) {
            let list_offset = LittleEndian::read_u32(&self.bytes[offset..]) as usize;
            let length = LittleEndian::read_u32(&self.bytes[offset + 4..]);
            if list_offset != 0 {
                return Some((list_offset as usize, length as usize));
            }
        }
        None
    }

    fn read_string_at(&self, offset: usize, dynamic_offset: bool) -> Option<&'a str> {
        let (offset, length) = self.get_offset_length(offset, dynamic_offset)?;
        let str = unsafe { std::str::from_utf8_unchecked(&self.bytes[offset..offset + length]) };
        Some(str)
    }

    pub fn read_string(&'a self, property: LegacyProperty) -> Option<&'a str> {
        self.read_string_at(property.offset, false)
    }

    pub fn read_byte_list(&self, property: LegacyProperty) -> Option<&'a [u8]> {
        let (offset, length) = self.get_offset_length(property.offset, false)?;
        Some(&self.bytes[offset..offset + length])
    }

    pub fn read_int_list(&self, property: LegacyProperty) -> Option<Vec<i32>> {
        let (offset, length) = self.get_offset_length(property.offset, false)?;
        let list = (offset..offset + length * 4)
            .step_by(4)
            .into_iter()
            .map(|offset| LittleEndian::read_i32(&self.bytes[offset..]))
            .collect();
        Some(list)
    }

    pub fn read_float_list(&self, property: LegacyProperty) -> Option<Vec<f32>> {
        let (offset, length) = self.get_offset_length(property.offset, false)?;
        let list = (offset..offset + length * 4)
            .step_by(4)
            .into_iter()
            .map(|offset| LittleEndian::read_f32(&self.bytes[offset..]))
            .collect();
        Some(list)
    }

    pub fn read_long_list(&self, property: LegacyProperty) -> Option<Vec<i64>> {
        let (offset, length) = self.get_offset_length(property.offset, false)?;
        let list = (offset..offset + length * 8)
            .step_by(8)
            .into_iter()
            .map(|offset| LittleEndian::read_i64(&self.bytes[offset..]))
            .collect();
        Some(list)
    }

    pub fn read_double_list(&self, property: LegacyProperty) -> Option<Vec<f64>> {
        let (offset, length) = self.get_offset_length(property.offset, false)?;
        let list = (offset..offset + length * 8)
            .step_by(8)
            .into_iter()
            .map(|offset| LittleEndian::read_f64(&self.bytes[offset..]))
            .collect();
        Some(list)
    }

    pub fn read_string_list(&self, property: LegacyProperty) -> Option<Vec<Option<&'a str>>> {
        let (offset, length) = self.get_offset_length(property.offset, false)?;
        let list = (offset..offset + length * 8)
            .step_by(8)
            .into_iter()
            .map(|offset| self.read_string_at(offset, true))
            .collect();
        Some(list)
    }
}
