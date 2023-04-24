use std::cell::Cell;

use super::sqlite_collection::SQLiteCollection;
use super::sqlite_insert::SQLiteInsert;
use crate::core::writer::IsarWriter;
use base64::{encoded_len, engine::general_purpose, Engine};
use serde_json::{
    ser::{CompactFormatter, Formatter},
    Value,
};

impl<'a> IsarWriter<'a> for SQLiteInsert<'a> {
    type ObjectWriter = SQLiteObjectWriter<'a>;

    type ListWriter = SQLiteListWriter<'a>;

    fn write_null(&mut self) {
        let _ = self.stmt.bind_null(self.property);
        self.property += 1;
    }

    fn write_byte(&mut self, value: u8) {
        let _ = self.stmt.bind_int(self.property, value as i32);
        self.property += 1;
    }

    fn write_bool(&mut self, value: bool) {
        let value = if value { 1 } else { 0 };
        let _ = self.stmt.bind_int(self.property, value);
        self.property += 1;
    }

    fn write_int(&mut self, value: i32) {
        if value != i32::MIN {
            let _ = self.stmt.bind_int(self.property, value);
        } else {
            let _ = self.stmt.bind_null(self.property);
        }
        self.property += 1;
    }

    fn write_float(&mut self, value: f32) {
        if !value.is_nan() {
            let _ = self.stmt.bind_double(self.property, value as f64);
        } else {
            let _ = self.stmt.bind_null(self.property);
        }
        self.property += 1;
    }

    fn write_long(&mut self, value: i64) {
        if value != i64::MIN {
            let _ = self.stmt.bind_long(self.property, value);
        } else {
            let _ = self.stmt.bind_null(self.property);
        }
        self.property += 1;
    }

    fn write_double(&mut self, value: f64) {
        if !value.is_nan() {
            let _ = self.stmt.bind_double(self.property, value);
        } else {
            let _ = self.stmt.bind_null(self.property);
        }
        self.property += 1;
    }

    fn write_string(&mut self, value: &str) {
        let _ = self.stmt.bind_text(self.property, value);
        self.property += 1;
    }

    fn write_blob(&mut self, value: &[u8]) {
        let _ = self.stmt.bind_blob(self.property, value);
        self.property += 1;
    }

    fn write_json(&mut self, value: &Value) {
        match value {
            Value::Null => self.write_null(),
            Value::Bool(value) => self.write_bool(*value),
            Value::Number(value) => {
                if let Some(value) = value.as_i64() {
                    self.write_long(value);
                } else if let Some(value) = value.as_f64() {
                    self.write_double(value);
                } else {
                    self.write_null();
                }
            }
            Value::String(value) => self.write_string(value),
            _ => {
                let bytes = serde_json::to_vec(value);
                if let Ok(bytes) = bytes {
                    self.write_blob(bytes.as_slice());
                } else {
                    self.write_null();
                }
            }
        }
    }

    fn begin_object<'b>(&mut self) -> Self::ObjectWriter {
        let property_index = self.property % (self.collection.properties.len() + 1);
        let property = &self.collection.properties[property_index - 1];
        let collection_index = property.collection_index.unwrap();
        let target_collection = &self.all_collections[collection_index as usize];

        if let Some(mut buffer) = self.buffer.take() {
            buffer.clear();
            SQLiteObjectWriter::new(target_collection, self.all_collections, buffer)
        } else {
            panic!("Buffer is already borrowed");
        }
    }

    fn end_object<'b>(&'b mut self, writer: Self::ObjectWriter) {
        let buffer = writer.finalize();
        self.write_blob(buffer.as_slice());
        self.buffer = Some(buffer);
    }

    fn begin_list(&mut self, _: usize) -> Self::ListWriter {
        let property_index = self.property % (self.collection.properties.len() + 1);
        let property = &self.collection.properties[property_index - 1];

        if let Some(mut buffer) = self.buffer.take() {
            buffer.clear();
            SQLiteListWriter::new(property.collection_index, self.all_collections, buffer)
        } else {
            panic!("Buffer is already borrowed");
        }
    }

    fn end_list<'b>(&'b mut self, writer: Self::ListWriter) {
        let buffer = writer.finalize();
        self.write_blob(buffer.as_slice());
        self.buffer = Some(buffer);
    }
}

pub struct SQLiteObjectWriter<'a> {
    collection: &'a SQLiteCollection,
    all_collections: &'a Vec<SQLiteCollection>,
    property: usize,
    first: bool,
    buffer: Cell<Vec<u8>>,
}

impl<'a> SQLiteObjectWriter<'a> {
    fn new(
        collection: &'a SQLiteCollection,
        all_collections: &'a Vec<SQLiteCollection>,
        mut buffer: Vec<u8>,
    ) -> Self {
        CompactFormatter.begin_object(&mut buffer).unwrap();
        Self {
            collection,
            all_collections,
            property: 0,
            first: true,
            buffer: Cell::new(buffer),
        }
    }

    fn write_property_name(&mut self, name: &str) {
        let buffer = self.buffer.get_mut();
        CompactFormatter
            .begin_object_key(buffer, self.first)
            .unwrap();
        CompactFormatter.begin_string(buffer).unwrap();
        CompactFormatter
            .write_string_fragment(buffer, name)
            .unwrap();
        CompactFormatter.end_string(buffer).unwrap();
        CompactFormatter.end_object_key(buffer).unwrap();
        CompactFormatter.begin_object_value(buffer).unwrap();
        self.first = false;
    }

    fn finalize(self) -> Vec<u8> {
        assert!(self.property == self.collection.properties.len());
        let mut buffer = self.buffer.take();
        CompactFormatter.end_object(&mut buffer).unwrap();
        buffer
    }
}

impl<'a> IsarWriter<'a> for SQLiteObjectWriter<'a> {
    type ObjectWriter = SQLiteObjectWriter<'a>;

    type ListWriter = SQLiteListWriter<'a>;

    fn write_null(&mut self) {
        self.property += 1;
    }

    fn write_byte(&mut self, value: u8) {
        let property = &self.collection.properties[self.property];
        self.write_property_name(&property.name);

        CompactFormatter
            .write_u8(self.buffer.get_mut(), value)
            .unwrap();

        self.property += 1;
    }

    fn write_bool(&mut self, value: bool) {
        let property = &self.collection.properties[self.property];
        self.write_property_name(&property.name);
        CompactFormatter
            .write_bool(self.buffer.get_mut(), value)
            .unwrap();

        self.property += 1;
    }

    fn write_int(&mut self, value: i32) {
        if value != i32::MIN {
            let property = &self.collection.properties[self.property];
            self.write_property_name(&property.name);
            CompactFormatter
                .write_i32(self.buffer.get_mut(), value)
                .unwrap();
        }

        self.property += 1;
    }

    fn write_float(&mut self, value: f32) {
        if !value.is_nan() {
            let property = &self.collection.properties[self.property];
            self.write_property_name(&property.name);
            CompactFormatter
                .write_f32(self.buffer.get_mut(), value)
                .unwrap();
        }

        self.property += 1;
    }

    fn write_long(&mut self, value: i64) {
        if value != i64::MIN {
            let property = &self.collection.properties[self.property];
            self.write_property_name(&property.name);
            CompactFormatter
                .write_i64(self.buffer.get_mut(), value)
                .unwrap();
        }

        self.property += 1;
    }

    fn write_double(&mut self, value: f64) {
        if !value.is_nan() {
            let property = &self.collection.properties[self.property];
            self.write_property_name(&property.name);
            CompactFormatter
                .write_f64(self.buffer.get_mut(), value)
                .unwrap();
        }

        self.property += 1;
    }

    fn write_string(&mut self, value: &str) {
        let property = &self.collection.properties[self.property];
        self.write_property_name(&property.name);

        let buffer = self.buffer.get_mut();
        CompactFormatter.begin_string(buffer).unwrap();
        CompactFormatter
            .write_string_fragment(buffer, value)
            .unwrap();
        CompactFormatter.end_string(buffer).unwrap();

        self.property += 1;
    }

    fn write_blob(&mut self, value: &[u8]) {
        let property = &self.collection.properties[self.property];
        self.write_property_name(&property.name);

        let buffer = self.buffer.get_mut();
        CompactFormatter.begin_string(buffer);

        let offset = buffer.len();
        let base64_len = encoded_len(value.len(), false).unwrap();
        buffer.resize(offset + base64_len, 0);
        general_purpose::STANDARD_NO_PAD.encode_slice(value, &mut buffer[offset..]);
        CompactFormatter.end_string(buffer).unwrap();

        self.property += 1;
    }

    fn write_json(&mut self, value: &Value) {
        let property = &self.collection.properties[self.property];
        self.write_property_name(&property.name);

        let buffer = self.buffer.get_mut();
        serde_json::to_writer(buffer, value);
        self.property += 1;
    }

    fn begin_object(&mut self) -> Self::ObjectWriter {
        let property = &self.collection.properties[self.property];
        self.write_property_name(&property.name);

        let collection_index = property.collection_index.unwrap();
        let target_collection = &self.all_collections[collection_index as usize];

        SQLiteObjectWriter::new(target_collection, self.all_collections, self.buffer.take())
    }

    fn end_object<'b>(&'b mut self, writer: Self::ObjectWriter) {
        self.buffer.replace(writer.finalize());
        self.property += 1;
    }

    fn begin_list(&mut self, _length: usize) -> Self::ListWriter {
        let property = &self.collection.properties[self.property];
        self.write_property_name(&property.name);

        SQLiteListWriter::new(
            property.collection_index,
            self.all_collections,
            self.buffer.take(),
        )
    }

    fn end_list<'b>(&'b mut self, writer: Self::ListWriter) {
        self.buffer.replace(writer.finalize());
        self.property += 1;
    }
}

pub struct SQLiteListWriter<'a> {
    collection_index: Option<u16>,
    all_collections: &'a Vec<SQLiteCollection>,
    first: bool,
    buffer: Cell<Vec<u8>>,
}

impl<'a> SQLiteListWriter<'a> {
    fn new(
        collection_index: Option<u16>,
        all_collections: &'a Vec<SQLiteCollection>,
        mut buffer: Vec<u8>,
    ) -> Self {
        CompactFormatter.begin_array(&mut buffer).unwrap();
        Self {
            collection_index,
            all_collections,
            first: true,
            buffer: Cell::new(buffer),
        }
    }

    fn prepare_value(&mut self) {
        CompactFormatter
            .begin_array_value(self.buffer.get_mut(), self.first)
            .unwrap();
        self.first = false;
    }

    fn finalize(mut self) -> Vec<u8> {
        CompactFormatter.end_array(self.buffer.get_mut()).unwrap();
        self.buffer.take()
    }
}

impl<'a> IsarWriter<'a> for SQLiteListWriter<'a> {
    type ObjectWriter = SQLiteObjectWriter<'a>;

    type ListWriter = SQLiteListWriter<'a>;

    fn write_null(&mut self) {
        self.prepare_value();
        CompactFormatter.write_null(self.buffer.get_mut()).unwrap();
    }

    fn write_byte(&mut self, value: u8) {
        self.prepare_value();
        CompactFormatter
            .write_u8(self.buffer.get_mut(), value)
            .unwrap();
    }

    fn write_bool(&mut self, value: bool) {
        self.prepare_value();
        CompactFormatter
            .write_bool(self.buffer.get_mut(), value)
            .unwrap();
    }

    fn write_int(&mut self, value: i32) {
        self.prepare_value();
        if value != i32::MIN {
            CompactFormatter
                .write_i32(self.buffer.get_mut(), value)
                .unwrap();
        } else {
            CompactFormatter.write_null(self.buffer.get_mut()).unwrap();
        }
    }

    fn write_float(&mut self, value: f32) {
        self.prepare_value();
        if !value.is_nan() {
            CompactFormatter
                .write_f32(self.buffer.get_mut(), value)
                .unwrap();
        } else {
            CompactFormatter.write_null(self.buffer.get_mut()).unwrap();
        }
    }

    fn write_long(&mut self, value: i64) {
        self.prepare_value();
        if value != i64::MIN {
            CompactFormatter
                .write_i64(self.buffer.get_mut(), value)
                .unwrap();
        } else {
            CompactFormatter.write_null(self.buffer.get_mut()).unwrap();
        }
    }

    fn write_double(&mut self, value: f64) {
        self.prepare_value();
        if !value.is_nan() {
            CompactFormatter
                .write_f64(self.buffer.get_mut(), value)
                .unwrap();
        } else {
            CompactFormatter.write_null(self.buffer.get_mut()).unwrap();
        }
    }

    fn write_string(&mut self, value: &str) {
        self.prepare_value();
        let buffer = self.buffer.get_mut();
        CompactFormatter.begin_string(buffer).unwrap();
        CompactFormatter
            .write_string_fragment(buffer, value)
            .unwrap();
        CompactFormatter.end_string(buffer).unwrap();
    }

    fn write_blob(&mut self, _value: &[u8]) {
        panic!("Nested lists are not supported");
    }

    fn write_json(&mut self, value: &Value) {
        todo!()
    }

    fn begin_object(&mut self) -> Self::ObjectWriter {
        let collection_index = self.collection_index.unwrap();
        let target_collection = &self.all_collections[collection_index as usize];

        SQLiteObjectWriter::new(target_collection, self.all_collections, self.buffer.take())
    }

    fn end_object<'b>(&'b mut self, writer: Self::ObjectWriter) {
        self.buffer.replace(writer.finalize());
    }

    fn begin_list(&mut self, _length: usize) -> Self::ListWriter {
        panic!("Nested lists are not supported");
    }

    fn end_list<'b>(&'b mut self, _: Self::ListWriter) {
        panic!("Nested lists are not supported");
    }
}
