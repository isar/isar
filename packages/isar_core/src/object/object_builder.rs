use byteorder::{ByteOrder, LittleEndian};
use itertools::Itertools;

use crate::object::data_type::DataType;
use crate::object::isar_object::IsarObject;
use std::slice::from_raw_parts;

use super::property::Property;

/*
u16 static properties size

--- Static properties ---
i64 field1
u24 field2_offset or 0
f32 field3
u24 field4_offset or 0

--- Dynamic data ---
field2_offset:
u24 field2_length
... field2_data ...

field4_offset:
u24 field4_length
u24 field4_item1_length + 1 or 0
u24 field4_item2_length + 1 or 0
... field4_item1 ...
... field4_item2 ...

*/

pub struct ObjectBuilder {
    buffer: Vec<u8>,
    dynamic_offset: usize,
}

impl ObjectBuilder {
    pub fn new(properties: &[Property], buffer: Option<Vec<u8>>) -> ObjectBuilder {
        let static_size = properties
            .iter()
            .max_by_key(|p| p.offset)
            .map_or(0, |p| p.offset + p.data_type.get_static_size());

        let mut buffer = buffer.unwrap_or_else(|| Vec::with_capacity(2 + static_size * 2));
        buffer.clear();

        let mut ob = ObjectBuilder {
            buffer,
            dynamic_offset: static_size,
        };
        ob.write_at(0, &(static_size as u16).to_le_bytes());
        ob
    }

    #[inline]
    fn write_at(&mut self, offset: usize, bytes: &[u8]) {
        if offset + bytes.len() > self.buffer.len() {
            self.buffer.resize(offset + bytes.len(), 0);
        }
        self.buffer[offset..offset + bytes.len()].copy_from_slice(bytes);
    }

    #[inline]
    fn write_u24(&mut self, offset: usize, value: usize) {
        if offset + 3 > self.buffer.len() {
            self.buffer.resize(offset + 3, 0);
        }
        LittleEndian::write_u24(&mut self.buffer[offset..], value as u32);
    }

    pub fn write_null(&mut self, offset: usize, data_type: DataType) {
        match data_type {
            DataType::Bool => self.write_bool(offset, None),
            DataType::Byte => self.write_byte(offset, IsarObject::NULL_BYTE),
            DataType::Int => self.write_int(offset, IsarObject::NULL_INT),
            DataType::Float => self.write_float(offset, IsarObject::NULL_FLOAT),
            DataType::Long => self.write_long(offset, IsarObject::NULL_LONG),
            DataType::Double => self.write_double(offset, IsarObject::NULL_DOUBLE),
            DataType::String => self.write_string(offset, None),
            DataType::Object => self.write_object(offset, None),
            DataType::BoolList => self.write_bool_list(offset, None),
            DataType::ByteList => self.write_byte_list(offset, None),
            DataType::IntList => self.write_int_list(offset, None),
            DataType::FloatList => self.write_float_list(offset, None),
            DataType::LongList => self.write_long_list(offset, None),
            DataType::DoubleList => self.write_double_list(offset, None),
            DataType::StringList => self.write_string_list(offset, None),
            DataType::ObjectList => self.write_object_list(offset, None),
        }
    }

    pub fn bool_to_byte(value: Option<bool>) -> u8 {
        if let Some(value) = value {
            if value {
                IsarObject::TRUE_BOOL
            } else {
                IsarObject::FALSE_BOOL
            }
        } else {
            IsarObject::NULL_BOOL
        }
    }

    pub fn write_byte(&mut self, offset: usize, value: u8) {
        self.write_at(offset, &[value]);
    }

    pub fn write_bool(&mut self, offset: usize, value: Option<bool>) {
        let value = Self::bool_to_byte(value);
        self.write_at(offset, &[value]);
    }

    pub fn write_int(&mut self, offset: usize, value: i32) {
        self.write_at(offset, &value.to_le_bytes());
    }

    pub fn write_float(&mut self, offset: usize, value: f32) {
        self.write_at(offset, &value.to_le_bytes());
    }

    pub fn write_long(&mut self, offset: usize, value: i64) {
        self.write_at(offset, &value.to_le_bytes());
    }

    pub fn write_double(&mut self, offset: usize, value: f64) {
        self.write_at(offset, &value.to_le_bytes());
    }

    pub fn write_string(&mut self, offset: usize, value: Option<&str>) {
        let bytes = value.map(|s| s.as_ref());
        self.write_list(offset, bytes);
    }

    pub fn write_object(&mut self, offset: usize, value: Option<IsarObject>) {
        self.write_list(offset, value.as_ref().map(|o| o.as_bytes()));
    }

    pub fn write_bool_list(&mut self, offset: usize, value: Option<&[Option<bool>]>) {
        let list = value.map(|list| list.iter().map(|b| Self::bool_to_byte(*b)).collect_vec());
        self.write_list(offset, list.as_deref());
    }

    pub fn write_byte_list(&mut self, offset: usize, value: Option<&[u8]>) {
        self.write_list(offset, value);
    }

    pub fn write_int_list(&mut self, offset: usize, value: Option<&[i32]>) {
        self.write_list(offset, value);
    }

    pub fn write_float_list(&mut self, offset: usize, value: Option<&[f32]>) {
        self.write_list(offset, value);
    }

    pub fn write_long_list(&mut self, offset: usize, value: Option<&[i64]>) {
        self.write_list(offset, value);
    }

    pub fn write_double_list(&mut self, offset: usize, value: Option<&[f64]>) {
        self.write_list(offset, value);
    }

    pub fn write_string_list(&mut self, offset: usize, value: Option<&[Option<&str>]>) {
        self.write_list_list(offset, value, |v| v.as_bytes())
    }

    pub fn write_object_list(&mut self, offset: usize, value: Option<&[Option<IsarObject>]>) {
        self.write_list_list(offset, value, |v| v.as_bytes())
    }

    fn write_list<T>(&mut self, offset: usize, list: Option<&[T]>) {
        if let Some(list) = list {
            let bytes = Self::get_list_bytes(list);
            self.write_u24(offset, self.dynamic_offset);
            self.write_u24(self.dynamic_offset, list.len());
            self.write_at(self.dynamic_offset + 3, bytes);
            self.dynamic_offset += bytes.len() + 3;
        } else {
            self.write_u24(offset, 0);
        }
    }

    fn write_list_list<T>(
        &mut self,
        offset: usize,
        value: Option<&[Option<T>]>,
        to_bytes: impl Fn(&T) -> &[u8],
    ) {
        if let Some(value) = value {
            self.write_u24(offset, self.dynamic_offset);
            self.write_u24(self.dynamic_offset, value.len());

            let mut offset_list_offset = self.dynamic_offset + 3;
            self.dynamic_offset += 3 + value.len() * 3;
            for v in value {
                if let Some(bytes) = v.as_ref().map(|v| to_bytes(v)) {
                    self.write_u24(offset_list_offset, bytes.len() + 1);
                    self.write_at(self.dynamic_offset, bytes);
                    self.dynamic_offset += bytes.len();
                } else {
                    self.write_u24(offset_list_offset, 0);
                }
                offset_list_offset += 3;
            }
        } else {
            self.write_u24(offset, 0);
        }
    }

    #[inline]
    pub(crate) fn get_list_bytes<T>(list: &[T]) -> &[u8] {
        let type_size = std::mem::size_of::<T>();
        let ptr = list.as_ptr() as *const T;
        unsafe { from_raw_parts::<u8>(ptr as *const u8, list.len() * type_size) }
    }

    pub fn finish(&self) -> IsarObject {
        IsarObject::from_bytes(&self.buffer)
    }

    pub fn recycle(self) -> Vec<u8> {
        let mut buffer = self.buffer;
        buffer.clear();
        buffer
    }
}

#[cfg(test)]
mod tests {
    use super::ObjectBuilder;
    use crate::object::data_type::DataType::{self, *};
    use crate::object::isar_object::IsarObject;
    use crate::object::property::Property;

    macro_rules! builder {
        ($var:ident, $prop:ident, $type:ident) => {
            let $prop = Property::debug($type, 3);
            let props = vec![Property::debug(Byte, 2), $prop.clone()];
            let mut $var = ObjectBuilder::new(&props, None);
            $var.write_byte(2, 255);
        };
    }

    fn offset_size(value: usize) -> [u8; 3] {
        let mut bytes = [0; 3];
        bytes[2] = (value >> 16) as u8;
        bytes[1] = (value >> 8) as u8;
        bytes[0] = value as u8;
        bytes
    }

    #[test]
    pub fn test_write_null() {
        builder!(b, p, Bool);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, 0]);

        builder!(b, p, Byte);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, 0]);

        builder!(b, p, Int);
        b.write_null(p.offset, p.data_type);
        let mut bytes = vec![7, 0, 255];
        bytes.extend_from_slice(&IsarObject::NULL_INT.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, Float);
        b.write_null(p.offset, p.data_type);
        let mut bytes = vec![7, 0, 255];
        bytes.extend_from_slice(&IsarObject::NULL_FLOAT.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, Long);
        b.write_null(p.offset, p.data_type);
        let mut bytes = vec![11, 0, 255];
        bytes.extend_from_slice(&IsarObject::NULL_LONG.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, Double);
        b.write_null(p.offset, p.data_type);
        let mut bytes = vec![11, 0, 255];
        bytes.extend_from_slice(&IsarObject::NULL_DOUBLE.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        let list_types = vec![
            String, Object, ByteList, IntList, FloatList, LongList, DoubleList, StringList,
            ObjectList,
        ];

        for list_type in list_types {
            builder!(b, p, list_type);
            b.write_null(p.offset, p.data_type);
            let bytes = vec![6, 0, 255, 0, 0, 0];
            assert_eq!(b.finish().as_bytes(), &bytes);
        }
    }

    #[test]
    pub fn test_write_bool() {
        builder!(b, p, Bool);
        b.write_bool(p.offset, Some(true));
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, IsarObject::TRUE_BOOL]);

        builder!(b, p, Bool);
        b.write_bool(p.offset, Some(false));
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, IsarObject::FALSE_BOOL]);

        builder!(b, p, Bool);
        b.write_bool(p.offset, None);
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, IsarObject::NULL_BOOL]);
    }

    #[test]
    pub fn test_write_byte() {
        builder!(b, p, Byte);
        b.write_byte(p.offset, 0);
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, 0]);

        builder!(b, p, Byte);
        b.write_byte(p.offset, 123);
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, 123]);

        builder!(b, p, Byte);
        b.write_byte(p.offset, 255);
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, 255]);
    }

    #[test]
    pub fn test_write_int() {
        builder!(b, p, Int);
        b.write_int(p.offset, 123);
        assert_eq!(b.finish().as_bytes(), &[7, 0, 255, 123, 0, 0, 0])
    }

    #[test]
    pub fn test_write_float() {
        builder!(b, p, Float);
        b.write_float(p.offset, 123.123);
        let mut bytes = vec![7, 0, 255];
        bytes.extend_from_slice(&123.123f32.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, Float);
        b.write_float(p.offset, f32::NAN);
        let mut bytes = vec![7, 0, 255];
        bytes.extend_from_slice(&f32::NAN.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_long() {
        builder!(b, p, Long);
        b.write_long(p.offset, 123123);
        let mut bytes = vec![11, 0, 255];
        bytes.extend_from_slice(&123123i64.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes)
    }

    #[test]
    pub fn test_write_double() {
        builder!(b, p, Double);
        b.write_double(p.offset, 123.123);
        let mut bytes = vec![11, 0, 255];
        bytes.extend_from_slice(&123.123f64.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, Double);
        b.write_double(p.offset, f64::NAN);
        let mut bytes = vec![11, 0, 255];
        bytes.extend_from_slice(&f64::NAN.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_string() {
        builder!(b, p, String);
        b.write_string(p.offset, Some("hello"));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(5));
        bytes.extend_from_slice(b"hello");
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, String);
        b.write_string(p.offset, Some(""));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, String);
        b.write_string(p.offset, None);
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_object() {
        builder!(b, p, Object);
        let object = IsarObject::from_bytes(&[3, 0, 111]);
        b.write_object(p.offset, Some(object));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(3));
        bytes.extend_from_slice(&[3, 0, 111]);
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_multiple_static_types() {
        let props = vec![
            Property::debug(DataType::Long, 2),
            Property::debug(DataType::Byte, 10),
            Property::debug(DataType::Int, 11),
            Property::debug(DataType::Float, 15),
            Property::debug(DataType::Long, 19),
            Property::debug(DataType::Double, 27),
        ];
        let mut b = ObjectBuilder::new(&props, None);

        b.write_long(props.get(0).unwrap().offset, 1);
        b.write_byte(props.get(1).unwrap().offset, u8::MAX);
        b.write_int(props.get(2).unwrap().offset, i32::MAX);
        b.write_float(props.get(3).unwrap().offset, std::f32::consts::E);
        b.write_long(props.get(4).unwrap().offset, i64::MIN);
        b.write_double(props.get(5).unwrap().offset, std::f64::consts::PI);

        let mut bytes = vec![35, 0, 1, 0, 0, 0, 0, 0, 0, 0];
        bytes.push(u8::MAX);
        bytes.extend_from_slice(&i32::MAX.to_le_bytes());
        bytes.extend_from_slice(&std::f32::consts::E.to_le_bytes());
        bytes.extend_from_slice(&i64::MIN.to_le_bytes());
        bytes.extend_from_slice(&std::f64::consts::PI.to_le_bytes());

        assert_eq!(b.finish().as_bytes(), bytes);
    }

    #[test]
    pub fn test_write_byte_list() {
        builder!(b, p, ByteList);
        b.write_byte_list(p.offset, Some(&[1, 2, 3]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(3));
        bytes.extend_from_slice(&[1, 2, 3]);
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, ByteList);
        b.write_byte_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_int_list() {
        builder!(b, p, IntList);
        b.write_int_list(p.offset, Some(&[1, -10]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(2));
        bytes.extend_from_slice(&1i32.to_le_bytes());
        bytes.extend_from_slice(&(-10i32).to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, IntList);
        b.write_int_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_float_list() {
        builder!(b, p, FloatList);
        b.write_float_list(p.offset, Some(&[1.1, -10.10]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(2));
        bytes.extend_from_slice(&1.1f32.to_le_bytes());
        bytes.extend_from_slice(&(-10.10f32).to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, FloatList);
        b.write_float_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_long_list() {
        builder!(b, p, LongList);
        b.write_long_list(p.offset, Some(&[1, -10]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(2));
        bytes.extend_from_slice(&1i64.to_le_bytes());
        bytes.extend_from_slice(&(-10i64).to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, LongList);
        b.write_long_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_double_list() {
        builder!(b, p, DoubleList);
        b.write_double_list(p.offset, Some(&[1.1, -10.10]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(2));
        bytes.extend_from_slice(&1.1f64.to_le_bytes());
        bytes.extend_from_slice(&(-10.10f64).to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, DoubleList);
        b.write_double_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_string_list() {
        builder!(b, p, StringList);
        b.write_string_list(p.offset, Some(&[Some("abc"), None, Some(""), Some("de")]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(4));
        bytes.extend_from_slice(&offset_size(4));
        bytes.extend_from_slice(&offset_size(0));
        bytes.extend_from_slice(&offset_size(1));
        bytes.extend_from_slice(&offset_size(3));
        bytes.extend_from_slice(b"abcde");
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, StringList);
        b.write_string_list(p.offset, Some(&[None]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(1));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, StringList);
        b.write_string_list(p.offset, Some(&[Some("")]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(1));
        bytes.extend_from_slice(&offset_size(1));
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, StringList);
        b.write_string_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_object_list() {
        builder!(b, p, ObjectList);
        let object1 = IsarObject::from_bytes(&[2, 0]);
        let object2 = IsarObject::from_bytes(&[3, 0, 123]);
        b.write_object_list(p.offset, Some(&[Some(object1), None, Some(object2)]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(3));
        bytes.extend_from_slice(&offset_size(3));
        bytes.extend_from_slice(&offset_size(0));
        bytes.extend_from_slice(&offset_size(4));
        bytes.extend_from_slice(&[2, 0, 3, 0, 123]);
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, ObjectList);
        b.write_object_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }
}
