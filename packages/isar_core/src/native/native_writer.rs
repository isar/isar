use super::native_collection::{NativeCollection, NativeProperty};
use super::native_insert::NativeInsert;
use super::{
    FALSE_BOOL, NULL_BOOL, NULL_BYTE, NULL_DOUBLE, NULL_FLOAT, NULL_INT, NULL_LONG, TRUE_BOOL,
};
use crate::core::data_type::DataType;
use crate::core::writer::IsarWriter;
use byteorder::{ByteOrder, LittleEndian};
use serde_json::Value;

trait WriterImpl {
    fn next_property(&mut self) -> NativeProperty;

    fn write_at(&mut self, offset: u32, bytes: &[u8]);

    fn get_dynamic_offset(&self) -> u32;

    fn write_u24(&mut self, offset: u32, value: u32) {
        let mut bytes = [0u8; 3];
        LittleEndian::write_u24(&mut bytes, value);
        self.write_at(offset, &bytes);
    }
}

impl<'a, T: WriterImpl> IsarWriter<'a> for T {
    type ObjectWriter = NativeInsert<'a>;

    type ListWriter = NativeInsert<'a>;

    fn write_null(&mut self) {
        let property = self.next_property();
        match property.data_type {
            DataType::Bool => self.write_at(property.offset, &[NULL_BOOL]),
            DataType::Byte => self.write_byte(NULL_BYTE),
            DataType::Int => self.write_int(NULL_INT),
            DataType::Float => self.write_float(NULL_FLOAT),
            DataType::Long => self.write_long(NULL_LONG),
            DataType::Double => self.write_double(NULL_DOUBLE),
            _ => self.write_u24(property.offset, 0),
        }
    }

    fn write_byte(&mut self, value: u8) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Byte);
        self.write_at(property.offset, &[value]);
    }

    fn write_bool(&mut self, value: bool) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Bool);
        let value = if value { TRUE_BOOL } else { FALSE_BOOL };
        self.write_at(property.offset, &[value]);
    }

    fn write_int(&mut self, value: i32) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Int);
        self.write_at(property.offset, &value.to_le_bytes());
    }

    fn write_float(&mut self, value: f32) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Float);
        self.write_at(property.offset, &value.to_le_bytes());
    }

    fn write_long(&mut self, value: i64) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Long);
        self.write_at(property.offset, &value.to_le_bytes());
    }

    fn write_double(&mut self, value: f64) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Double);
        self.write_at(property.offset, &value.to_le_bytes());
    }

    fn write_string(&mut self, value: &str) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::String);

        let offset = self.get_dynamic_offset();
        self.write_u24(property.offset, offset);
        self.write_u24(offset, value.len() as u32);
        self.write_at(offset + 3, value.as_bytes());
    }

    fn write_bytes(&mut self, value: &[u8]) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::ByteList);

        let offset = self.get_dynamic_offset();
        self.write_u24(property.offset, offset);
        self.write_u24(offset, value.len() as u32);
        self.write_at(offset + 3, value);
    }

    fn write_any(&mut self, value: &Value) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Any);

        let offset = self.get_dynamic_offset();
        self.write_u24(property.offset, offset);
    }

    fn begin_object(&mut self) -> Self::ObjectWriter {
        todo!()
    }

    fn end_object(&mut self, writer: Self::ObjectWriter) {
        todo!()
    }

    fn begin_list(&mut self) -> Self::ListWriter {
        todo!()
    }

    fn end_list(&mut self, writer: Self::ListWriter) {
        todo!()
    }
}

impl<'a> WriterImpl for NativeInsert<'a> {
    fn next_property(&mut self) -> NativeProperty {
        let property = self.collection.properties.get(self.property);
        if property.is_none() {
            panic!("Invalid property index");
        }
        self.property += 1;
        *property.unwrap()
    }

    fn write_at(&mut self, offset: u32, bytes: &[u8]) {
        let buffer = self.buffer.get_mut();
        assert!(buffer.len() >= 2);

        let offset = offset as usize;
        if offset + bytes.len() > buffer.len() {
            buffer.resize(offset + bytes.len(), 0);
        }
        buffer[offset..offset + bytes.len()].copy_from_slice(bytes);
    }

    fn get_dynamic_offset(&self) -> u32 {
        //self.buffer.get_mut().len() as u32
        todo!()
    }
}

struct NativeObjectWriter<'a> {
    collection: &'a NativeCollection,
    buffer: Vec<u8>,
    property: usize,
}
