use super::sqlite_collection::SQLiteCollection;
use super::sqlite_insert::SQLiteInsert;
use crate::core::writer::IsarWriter;
use base64::{encoded_len, engine::general_purpose, Engine};
use serde_json::ser::{CompactFormatter, Formatter};
use std::cell::Cell;

impl<'a> IsarWriter<'a> for SQLiteInsert<'a> {
    type ObjectWriter = SQLiteObjectWriter<'a>;

    type ListWriter = SQLiteListWriter<'a>;

    fn write_null(&mut self) {
        let batch_property = self.batch_property;
        let _ = self.with_stmt(|stmt| stmt.bind_null(batch_property));
        self.batch_property += 1;
    }

    fn write_bool(&mut self, value: Option<bool>) {
        let batch_property = self.batch_property;
        let _ = self.with_stmt(|stmt| {
            if let Some(value) = value {
                stmt.bind_int(batch_property, value as i32)
            } else {
                stmt.bind_null(batch_property)
            }
        });
        self.batch_property += 1;
    }

    fn write_byte(&mut self, value: u8) {
        let batch_property = self.batch_property;
        let _ = self.with_stmt(|stmt| stmt.bind_int(batch_property, value as i32));
        self.batch_property += 1;
    }

    fn write_int(&mut self, value: i32) {
        let batch_property = self.batch_property;
        let _ = self.with_stmt(|stmt| {
            if value != i32::MIN {
                stmt.bind_int(batch_property, value)
            } else {
                stmt.bind_null(batch_property)
            }
        });
        self.batch_property += 1;
    }

    fn write_float(&mut self, value: f32) {
        let batch_property = self.batch_property;
        let _ = self.with_stmt(|stmt| {
            if !value.is_nan() {
                stmt.bind_double(batch_property, value as f64)
            } else {
                stmt.bind_null(batch_property)
            }
        });
        self.batch_property += 1;
    }

    fn write_long(&mut self, value: i64) {
        let batch_property = self.batch_property;
        let _ = self.with_stmt(|stmt| {
            if value != i64::MIN {
                stmt.bind_long(batch_property, value)
            } else {
                stmt.bind_null(batch_property)
            }
        });
        self.batch_property += 1;
    }

    fn write_double(&mut self, value: f64) {
        let batch_property = self.batch_property;
        let _ = self.with_stmt(|stmt| {
            if !value.is_nan() {
                stmt.bind_double(batch_property, value)
            } else {
                stmt.bind_null(batch_property)
            }
        });
        self.batch_property += 1;
    }

    fn write_string(&mut self, value: &str) {
        let batch_property = self.batch_property;
        let _ = self.with_stmt(|stmt| stmt.bind_text(batch_property, value));
        self.batch_property += 1;
    }

    fn write_byte_list(&mut self, value: &[u8]) {
        let batch_property = self.batch_property;
        let _ = self.with_stmt(|stmt| stmt.bind_blob(batch_property, value));
        self.batch_property += 1;
    }

    fn begin_object<'b>(&mut self) -> Option<Self::ObjectWriter> {
        let property_index = self.batch_property as usize % (self.collection.properties.len() + 1);
        let property = self.collection.get_property(property_index as u16)?;

        if let Some(collection_index) = property.collection_index {
            let target_collection = &self.all_collections[collection_index as usize];
            if let Some(mut buffer) = self.buffer.take() {
                buffer.clear();
                return Some(SQLiteObjectWriter::new(
                    target_collection,
                    self.all_collections,
                    buffer,
                ));
            }
        }
        None
    }

    fn end_object<'b>(&'b mut self, writer: Self::ObjectWriter) {
        let buffer = writer.finalize();
        let json = unsafe { std::str::from_utf8_unchecked(buffer.as_slice()) };
        self.write_string(json);
        self.buffer = Some(buffer);
    }

    fn begin_list(&mut self, _: u32) -> Option<Self::ListWriter> {
        let property_index = self.batch_property as usize % (self.collection.properties.len() + 1);
        let property = self.collection.get_property(property_index as u16)?;

        if let Some(mut buffer) = self.buffer.take() {
            buffer.clear();
            Some(SQLiteListWriter::new(
                property.collection_index,
                self.all_collections,
                buffer,
            ))
        } else {
            None
        }
    }

    fn end_list<'b>(&'b mut self, writer: Self::ListWriter) {
        let buffer = writer.finalize();
        let json: &str = unsafe { std::str::from_utf8_unchecked(buffer.as_slice()) };
        self.write_string(json);
        self.buffer = Some(buffer);
    }
}

pub struct SQLiteObjectWriter<'a> {
    collection: &'a SQLiteCollection,
    all_collections: &'a Vec<SQLiteCollection>,
    property: u16,
    first: bool,
    buffer: Cell<Vec<u8>>,
}

impl<'a> SQLiteObjectWriter<'a> {
    fn new(
        collection: &'a SQLiteCollection,
        all_collections: &'a Vec<SQLiteCollection>,
        mut buffer: Vec<u8>,
    ) -> Self {
        let _ = CompactFormatter.begin_object(&mut buffer);
        Self {
            collection,
            all_collections,
            property: 1,
            first: true,
            buffer: Cell::new(buffer),
        }
    }

    fn write_property_name(&mut self, name: &str) {
        let buffer = self.buffer.get_mut();
        let _ = CompactFormatter.begin_object_key(buffer, self.first);
        let _ = CompactFormatter.begin_string(buffer);
        let _ = CompactFormatter.write_string_fragment(buffer, name);
        let _ = CompactFormatter.end_string(buffer);
        let _ = CompactFormatter.end_object_key(buffer);
        let _ = CompactFormatter.begin_object_value(buffer);
        self.first = false;
    }

    fn finalize(self) -> Vec<u8> {
        let mut buffer = self.buffer.take();
        let _ = CompactFormatter.end_object(&mut buffer);
        buffer
    }
}

impl<'a> IsarWriter<'a> for SQLiteObjectWriter<'a> {
    type ObjectWriter = SQLiteObjectWriter<'a>;

    type ListWriter = SQLiteListWriter<'a>;

    fn write_null(&mut self) {
        self.property += 1;
    }

    fn write_bool(&mut self, value: Option<bool>) {
        if let Some(property) = self.collection.get_property(self.property) {
            if let Some(value) = value {
                self.write_property_name(&property.name);
                let _ = CompactFormatter.write_bool(self.buffer.get_mut(), value);
            }
        }

        self.property += 1;
    }

    fn write_byte(&mut self, value: u8) {
        if let Some(property) = self.collection.get_property(self.property) {
            self.write_property_name(&property.name);

            let _ = CompactFormatter.write_u8(self.buffer.get_mut(), value);
        }

        self.property += 1;
    }

    fn write_int(&mut self, value: i32) {
        if let Some(property) = self.collection.get_property(self.property) {
            if value != i32::MIN {
                self.write_property_name(&property.name);
                let _ = CompactFormatter.write_i32(self.buffer.get_mut(), value);
            }
        }

        self.property += 1;
    }

    fn write_float(&mut self, value: f32) {
        if let Some(property) = self.collection.get_property(self.property) {
            if !value.is_nan() {
                self.write_property_name(&property.name);
                let _ = CompactFormatter.write_f32(self.buffer.get_mut(), value);
            }
        }

        self.property += 1;
    }

    fn write_long(&mut self, value: i64) {
        if let Some(property) = self.collection.get_property(self.property) {
            if value != i64::MIN {
                self.write_property_name(&property.name);
                let _ = CompactFormatter.write_i64(self.buffer.get_mut(), value);
            }
        }

        self.property += 1;
    }

    fn write_double(&mut self, value: f64) {
        if let Some(property) = self.collection.get_property(self.property) {
            if !value.is_nan() {
                self.write_property_name(&property.name);
                let _ = CompactFormatter.write_f64(self.buffer.get_mut(), value);
            }
        }

        self.property += 1;
    }

    fn write_string(&mut self, value: &str) {
        if let Some(property) = self.collection.get_property(self.property) {
            self.write_property_name(&property.name);

            let buffer = self.buffer.get_mut();
            let _ = CompactFormatter.begin_string(buffer);
            let _ = CompactFormatter.write_string_fragment(buffer, value);
            let _ = CompactFormatter.end_string(buffer);
        }

        self.property += 1;
    }

    fn write_byte_list(&mut self, value: &[u8]) {
        if let Some(property) = self.collection.get_property(self.property) {
            self.write_property_name(&property.name);

            let buffer = self.buffer.get_mut();
            let _ = CompactFormatter.begin_string(buffer);

            let offset = buffer.len();
            let base64_len = encoded_len(value.len(), false).unwrap();
            buffer.resize(offset + base64_len, 0);
            let _ = general_purpose::STANDARD_NO_PAD.encode_slice(value, &mut buffer[offset..]);
            let _ = CompactFormatter.end_string(buffer);
        }

        self.property += 1;
    }

    fn begin_object(&mut self) -> Option<Self::ObjectWriter> {
        if let Some(property) = self.collection.get_property(self.property) {
            self.write_property_name(&property.name);

            if let Some(collection_index) = property.collection_index {
                let target_collection = &self.all_collections[collection_index as usize];

                let writer = SQLiteObjectWriter::new(
                    target_collection,
                    self.all_collections,
                    self.buffer.take(),
                );
                return Some(writer);
            }
        }
        None
    }

    fn end_object<'b>(&'b mut self, writer: Self::ObjectWriter) {
        self.buffer.replace(writer.finalize());
        self.property += 1;
    }

    fn begin_list(&mut self, _length: u32) -> Option<Self::ListWriter> {
        if let Some(property) = self.collection.get_property(self.property) {
            self.write_property_name(&property.name);

            let writer = SQLiteListWriter::new(
                property.collection_index,
                self.all_collections,
                self.buffer.take(),
            );
            Some(writer)
        } else {
            None
        }
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
        let _ = CompactFormatter.begin_array(&mut buffer);
        Self {
            collection_index,
            all_collections,
            first: true,
            buffer: Cell::new(buffer),
        }
    }

    fn prepare_value(&mut self) {
        let _ = CompactFormatter.begin_array_value(self.buffer.get_mut(), self.first);
        self.first = false;
    }

    fn finalize(mut self) -> Vec<u8> {
        let _ = CompactFormatter.end_array(self.buffer.get_mut());
        self.buffer.take()
    }
}

impl<'a> IsarWriter<'a> for SQLiteListWriter<'a> {
    type ObjectWriter = SQLiteObjectWriter<'a>;

    type ListWriter = SQLiteListWriter<'a>;

    fn write_null(&mut self) {
        self.prepare_value();
        let _ = CompactFormatter.write_null(self.buffer.get_mut());
    }

    fn write_bool(&mut self, value: Option<bool>) {
        self.prepare_value();
        if let Some(value) = value {
            let _ = CompactFormatter.write_bool(self.buffer.get_mut(), value);
        } else {
            let _ = CompactFormatter.write_null(self.buffer.get_mut());
        }
    }

    fn write_byte(&mut self, value: u8) {
        self.prepare_value();
        let _ = CompactFormatter.write_u8(self.buffer.get_mut(), value);
    }

    fn write_int(&mut self, value: i32) {
        self.prepare_value();
        if value != i32::MIN {
            let _ = CompactFormatter.write_i32(self.buffer.get_mut(), value);
        } else {
            let _ = CompactFormatter.write_null(self.buffer.get_mut());
        }
    }

    fn write_float(&mut self, value: f32) {
        self.prepare_value();
        if !value.is_nan() {
            let _ = CompactFormatter.write_f32(self.buffer.get_mut(), value);
        } else {
            let _ = CompactFormatter.write_null(self.buffer.get_mut());
        }
    }

    fn write_long(&mut self, value: i64) {
        self.prepare_value();
        if value != i64::MIN {
            let _ = CompactFormatter.write_i64(self.buffer.get_mut(), value);
        } else {
            let _ = CompactFormatter.write_null(self.buffer.get_mut());
        }
    }

    fn write_double(&mut self, value: f64) {
        self.prepare_value();
        if !value.is_nan() {
            let _ = CompactFormatter.write_f64(self.buffer.get_mut(), value);
        } else {
            let _ = CompactFormatter.write_null(self.buffer.get_mut());
        }
    }

    fn write_string(&mut self, value: &str) {
        self.prepare_value();
        let buffer = self.buffer.get_mut();
        let _ = CompactFormatter.begin_string(buffer);
        let _ = CompactFormatter.write_string_fragment(buffer, value);
        let _ = CompactFormatter.end_string(buffer);
    }

    fn write_byte_list(&mut self, _value: &[u8]) {}

    fn begin_object(&mut self) -> Option<Self::ObjectWriter> {
        self.prepare_value();
        if let Some(collection_index) = self.collection_index {
            let target_collection = &self.all_collections[collection_index as usize];

            let writer = SQLiteObjectWriter::new(
                target_collection,
                self.all_collections,
                self.buffer.take(),
            );
            Some(writer)
        } else {
            None
        }
    }

    fn end_object<'b>(&'b mut self, writer: Self::ObjectWriter) {
        self.buffer.replace(writer.finalize());
    }

    fn begin_list(&mut self, _length: u32) -> Option<Self::ListWriter> {
        None
    }

    fn end_list<'b>(&'b mut self, _: Self::ListWriter) {}
}
