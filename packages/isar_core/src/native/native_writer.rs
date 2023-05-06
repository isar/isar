use super::native_collection::{NativeCollection, NativeProperty};
use super::native_insert::NativeInsert;
use super::{bool_to_byte, NULL_BOOL, NULL_BYTE, NULL_DOUBLE, NULL_FLOAT, NULL_INT, NULL_LONG};
use crate::core::data_type::DataType;
use crate::core::writer::IsarWriter;
use byteorder::{ByteOrder, LittleEndian};
use serde_json::Value;
use std::cell::Cell;

trait WriterImpl<'a> {
    fn next_property(&mut self) -> NativeProperty;

    fn get_collections(&self) -> &'a [NativeCollection];

    fn get_buffer(&mut self) -> &mut Vec<u8>;

    fn take_buffer(&mut self) -> Vec<u8>;

    fn replace_buffer(&mut self, buffer: Vec<u8>);

    fn write(&mut self, offset: u32, bytes: &[u8]) {
        self.get_buffer()[offset as usize..offset as usize + bytes.len()].copy_from_slice(bytes);
    }

    fn write_u24(&mut self, offset: u32, value: u32) {
        LittleEndian::write_u24(&mut self.get_buffer()[offset as usize..], value);
    }

    fn append(&mut self, bytes: &[u8]) {
        self.get_buffer().extend_from_slice(bytes);
    }

    fn append_u24(&mut self, value: u32) {
        let mut bytes = [0u8; 3];
        LittleEndian::write_u24(&mut bytes, value);
        self.append(&bytes);
    }
}

impl<'a, T: WriterImpl<'a>> IsarWriter<'a> for T {
    type ObjectWriter = NativeObjectWriter<'a>;

    type ListWriter = NativeListWriter<'a>;

    fn write_null(&mut self) {
        let property = self.next_property();
        match property.data_type {
            DataType::Bool => self.write_byte(NULL_BOOL),
            DataType::Byte => self.write_byte(NULL_BYTE),
            DataType::Int => self.write_int(NULL_INT),
            DataType::Float => self.write_float(NULL_FLOAT),
            DataType::Long => self.write_long(NULL_LONG),
            DataType::Double => self.write_double(NULL_DOUBLE),
            _ => self.write_u24(property.offset, 0),
        }
    }

    fn write_bool(&mut self, value: Option<bool>) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Bool);
        self.write(property.offset, &[bool_to_byte(value)]);
    }

    fn write_byte(&mut self, value: u8) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Byte);
        self.write(property.offset, &[value]);
    }

    fn write_int(&mut self, value: i32) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Int);
        self.write(property.offset, &value.to_le_bytes());
    }

    fn write_float(&mut self, value: f32) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Float);
        self.write(property.offset, &value.to_le_bytes());
    }

    fn write_long(&mut self, value: i64) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Long);
        self.write(property.offset, &value.to_le_bytes());
    }

    fn write_double(&mut self, value: f64) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Double);
        self.write(property.offset, &value.to_le_bytes());
    }

    fn write_string(&mut self, value: &str) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::String);

        let offset = self.get_buffer().len() as u32;
        self.write_u24(property.offset, offset);
        self.append_u24(value.len() as u32);
        self.append(value.as_bytes());
    }

    fn write_json(&mut self, value: &Value) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Json);

        if let Ok(bytes) = serde_json::to_vec(value) {
            let offset = self.get_buffer().len() as u32;
            self.write_u24(property.offset, offset);
            self.append_u24(bytes.len() as u32);
            self.append(&bytes);
        } else {
            self.write_u24(property.offset, 0);
        }
    }

    fn write_byte_list(&mut self, value: &[u8]) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::ByteList);

        let offset = self.get_buffer().len() as u32;
        self.write_u24(property.offset, offset);
        self.append_u24(value.len() as u32);
        self.append(value);
    }

    fn begin_object(&mut self) -> Self::ObjectWriter {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Object);

        let offset = self.get_buffer().len();
        self.write_u24(property.offset, offset as u32);

        self.append_u24(0); // length unknown

        let collection_index = property.embedded_collection_index.unwrap();
        let collections = self.get_collections();
        NativeObjectWriter::new(
            &collections[collection_index as usize],
            collections,
            self.take_buffer(),
        )
    }

    fn end_object(&mut self, writer: Self::ObjectWriter) {
        if writer.property != writer.collection.properties.len() {
            panic!("Not all properties have been written ");
        }

        let buffer = writer.buffer.take();
        let length = buffer.len() as u32 - writer.intial_offset;

        self.replace_buffer(buffer);
        self.write_u24(writer.intial_offset, length);
    }

    fn begin_list(&mut self, length: u32) -> Self::ListWriter {
        let property = self.next_property();
        assert!(property.data_type.is_list());

        let offset = self.get_buffer().len() as u32;
        self.write_u24(property.offset, offset);
        self.append_u24(length as u32);

        NativeListWriter::new(property, self.get_collections(), self.take_buffer(), length)
    }

    fn end_list(&mut self, writer: Self::ListWriter) {
        if writer.offset != writer.max_offset {
            panic!("Not all items have been written ");
        }
        self.replace_buffer(writer.buffer.take());
    }
}

impl<'a> WriterImpl<'a> for NativeInsert<'a> {
    fn next_property(&mut self) -> NativeProperty {
        if let Some(property) = self.collection.properties.get(self.property) {
            self.property += 1;
            return *property;
        } else {
            panic!("Invalid property index");
        }
    }

    fn get_collections(&self) -> &'a [NativeCollection] {
        self.all_collections
    }

    fn get_buffer(&mut self) -> &mut Vec<u8> {
        self.buffer.get_mut()
    }

    fn take_buffer(&mut self) -> Vec<u8> {
        self.buffer.take()
    }

    fn replace_buffer(&mut self, buffer: Vec<u8>) {
        self.buffer.replace(buffer);
    }
}

pub struct NativeObjectWriter<'a> {
    collection: &'a NativeCollection,
    all_collections: &'a [NativeCollection],
    buffer: Cell<Vec<u8>>,
    intial_offset: u32,
    property: usize,
}

impl<'a> NativeObjectWriter<'a> {
    pub fn new(
        collection: &'a NativeCollection,
        all_collections: &'a [NativeCollection],
        mut buffer: Vec<u8>,
    ) -> Self {
        let initial_len = buffer.len() as u32;
        let new_len = initial_len + collection.static_size as u32;
        buffer.resize(new_len as usize, 0);
        LittleEndian::write_u16(
            &mut buffer[initial_len as usize..],
            collection.static_size as u16,
        );
        Self {
            collection,
            all_collections,
            buffer: Cell::new(buffer),
            intial_offset: initial_len,
            property: 0,
        }
    }
}

impl<'a> WriterImpl<'a> for NativeObjectWriter<'a> {
    fn next_property(&mut self) -> NativeProperty {
        if let Some(property) = self.collection.properties.get(self.property) {
            self.property += 1;
            return *property;
        } else {
            panic!("Invalid property index");
        }
    }

    fn get_collections(&self) -> &'a [NativeCollection] {
        self.all_collections
    }

    fn get_buffer(&mut self) -> &mut Vec<u8> {
        self.buffer.get_mut()
    }

    fn take_buffer(&mut self) -> Vec<u8> {
        self.buffer.take()
    }

    fn replace_buffer(&mut self, buffer: Vec<u8>) {
        self.buffer.replace(buffer);
    }
}

impl<'a> Drop for NativeObjectWriter<'a> {
    fn drop(&mut self) {
        assert!(self.buffer.get_mut().is_empty());
    }
}

pub struct NativeListWriter<'a> {
    data_type: DataType,
    element_size: u8,
    embedded_collection_index: Option<u16>,
    all_collections: &'a [NativeCollection],
    buffer: Cell<Vec<u8>>,
    offset: u32,
    max_offset: u32,
}

impl<'a> NativeListWriter<'a> {
    pub fn new(
        property: NativeProperty,
        all_collections: &'a [NativeCollection],
        buffer: Vec<u8>,
        length: u32,
    ) -> Self {
        let initial_len = buffer.len() as u32;
        let element_size = match property.data_type {
            DataType::BoolList | DataType::ByteList => 1,
            DataType::IntList | DataType::FloatList => 4,
            DataType::LongList | DataType::DoubleList => 8,
            DataType::StringList | DataType::Object => 3,
            _ => panic!("Invalid list type"),
        };
        Self {
            data_type: property.data_type,
            element_size: element_size,
            embedded_collection_index: property.embedded_collection_index,
            all_collections,
            buffer: Cell::new(buffer),
            offset: initial_len,
            max_offset: initial_len + (length - 1) * element_size as u32,
        }
    }
}

impl<'a> WriterImpl<'a> for NativeListWriter<'a> {
    fn next_property(&mut self) -> NativeProperty {
        if self.offset > self.max_offset {
            panic!("Too many items in list");
        }

        let property = NativeProperty {
            data_type: self.data_type,
            embedded_collection_index: self.embedded_collection_index,
            offset: self.offset,
        };
        self.offset += self.element_size as u32;
        property
    }

    fn get_collections(&self) -> &'a [NativeCollection] {
        self.all_collections
    }

    fn get_buffer(&mut self) -> &mut Vec<u8> {
        self.buffer.get_mut()
    }

    fn take_buffer(&mut self) -> Vec<u8> {
        self.buffer.take()
    }

    fn replace_buffer(&mut self, buffer: Vec<u8>) {
        self.buffer.replace(buffer);
    }
}

impl<'a> Drop for NativeListWriter<'a> {
    fn drop(&mut self) {
        assert!(self.buffer.get_mut().is_empty());
    }
}

/*#[cfg(test)]
mod tests {
    use super::*;

    macro_rules! builder {
        ($var:ident, $prop:ident, $type:ident) => {
            let $prop = NativeProperty::debug($type, 3);
            let props = vec![NativeProperty::debug(Byte, 2), $prop.clone()];
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
*/
