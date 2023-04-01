use super::sqlite3::SQLiteStatement;
use super::sqlite_collection::SQLiteCollection;
use crate::core::writer::IsarWriter;
use serde_json::ser::{CompactFormatter, Formatter};

pub struct SQLiteWriter<'a> {
    stmt: SQLiteStatement<'a>,
    collection: &'a SQLiteCollection,
    all_collections: &'a Vec<SQLiteCollection>,
    property: usize,
    count: usize,
    buffer: Option<Vec<u8>>,
}

impl<'a> SQLiteWriter<'a> {
    pub fn new(
        stmt: SQLiteStatement<'a>,
        count: usize,
        collection: &'a SQLiteCollection,
        all_collections: &'a Vec<SQLiteCollection>,
        buffer: Option<Vec<u8>>,
    ) -> SQLiteWriter<'a> {
        SQLiteWriter {
            stmt,
            collection,
            all_collections,
            property: 0,
            count,
            buffer: Some(buffer.unwrap_or(Vec::new())),
        }
    }

    pub fn next(&self) -> bool {
        let properties_and_id = self.collection.properties.len() + 1;
        assert!(self.property % properties_and_id == 0);
        if self.property < self.count * properties_and_id {
            true
        } else {
            false
        }
    }

    pub fn finalize(self) -> (SQLiteStatement<'a>, usize, Vec<u8>) {
        let buffer = self.buffer.unwrap();
        (self.stmt, self.count, buffer)
    }
}

impl<'a> IsarWriter<'a> for SQLiteWriter<'a> {
    type ObjectWriter = SQLiteObjectWriter<'a>;

    type ListWriter = SQLiteListWriter<'a>;

    fn write_id(&mut self, id: i64) {
        let _ = self.stmt.bind_long(self.property, id);
        self.property += 1;
    }

    fn write_null(&mut self) {
        let _ = self.stmt.bind_null(self.property);
        self.property += 1;
    }

    fn write_byte(&mut self, value: u8) {
        let _ = self.stmt.bind_int(self.property, value as i32);
        self.property += 1;
    }

    fn write_bool(&mut self, value: Option<bool>) {
        if let Some(value) = value {
            let _ = self.stmt.bind_int(self.property, value as i32);
        } else {
            let _ = self.stmt.bind_null(self.property);
        }
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

    fn write_string(&mut self, value: Option<&str>) {
        if let Some(value) = value {
            let _ = self.stmt.bind_text(self.property, value);
        } else {
            let _ = self.stmt.bind_null(self.property);
        }
        self.property += 1;
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
        let _ = self.stmt.bind_blob(self.property, &buffer);
        self.buffer = Some(buffer);
        self.property += 1;
    }

    fn begin_list(&mut self, _size: usize) -> Self::ListWriter {
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
        let _ = self.stmt.bind_blob(self.property, &buffer);
        self.buffer = Some(buffer);
        self.property += 1;
    }
}

pub struct SQLiteObjectWriter<'a> {
    collection: &'a SQLiteCollection,
    all_collections: &'a Vec<SQLiteCollection>,
    property: usize,
    first: bool,
    buffer: Option<Vec<u8>>,
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
            buffer: Some(buffer),
        }
    }

    fn write_property_name(&mut self, name: &str) -> &mut Vec<u8> {
        if let Some(buffer) = self.buffer.as_mut() {
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
            buffer
        } else {
            panic!("Buffer is already borrowed");
        }
    }

    fn finalize(mut self) -> Vec<u8> {
        assert!(self.property == self.collection.properties.len());
        if let Some(mut buffer) = self.buffer.take() {
            CompactFormatter.end_object(&mut buffer).unwrap();
            buffer
        } else {
            panic!("A nested object or list is unfinished");
        }
    }
}

impl<'a> IsarWriter<'a> for SQLiteObjectWriter<'a> {
    type ObjectWriter = SQLiteObjectWriter<'a>;

    type ListWriter = SQLiteListWriter<'a>;

    fn write_id(&mut self, _: i64) {
        panic!("Embedded objects cannot have an id")
    }

    fn write_null(&mut self) {
        self.property += 1;
    }

    fn write_byte(&mut self, value: u8) {
        let property = &self.collection.properties[self.property];
        let buffer = self.write_property_name(&property.name);

        CompactFormatter.write_u8(buffer, value).unwrap();

        self.property += 1;
    }

    fn write_bool(&mut self, value: Option<bool>) {
        if let Some(value) = value {
            let property = &self.collection.properties[self.property];
            let buffer = self.write_property_name(&property.name);
            CompactFormatter.write_bool(buffer, value).unwrap();
        }

        self.property += 1;
    }

    fn write_int(&mut self, value: i32) {
        if value != i32::MIN {
            let property = &self.collection.properties[self.property];
            let buffer = self.write_property_name(&property.name);
            CompactFormatter.write_i32(buffer, value).unwrap();
        }

        self.property += 1;
    }

    fn write_float(&mut self, value: f32) {
        if !value.is_nan() {
            let property = &self.collection.properties[self.property];
            let buffer = self.write_property_name(&property.name);
            CompactFormatter.write_f32(buffer, value).unwrap();
        }

        self.property += 1;
    }

    fn write_long(&mut self, value: i64) {
        if value != i64::MIN {
            let property = &self.collection.properties[self.property];
            let buffer = self.write_property_name(&property.name);
            CompactFormatter.write_i64(buffer, value).unwrap();
        }

        self.property += 1;
    }

    fn write_double(&mut self, value: f64) {
        if !value.is_nan() {
            let property = &self.collection.properties[self.property];
            let buffer = self.write_property_name(&property.name);
            CompactFormatter.write_f64(buffer, value).unwrap();
        }

        self.property += 1;
    }

    fn write_string(&mut self, value: Option<&str>) {
        if let Some(value) = value {
            let property = &self.collection.properties[self.property];
            let buffer = self.write_property_name(&property.name);
            CompactFormatter.begin_string(buffer).unwrap();
            CompactFormatter
                .write_string_fragment(buffer, value)
                .unwrap();
            CompactFormatter.end_string(buffer).unwrap();
        }

        self.property += 1;
    }

    fn begin_object(&mut self) -> Self::ObjectWriter {
        let property = &self.collection.properties[self.property];
        self.write_property_name(&property.name);

        let collection_index = property.collection_index.unwrap();
        let target_collection = &self.all_collections[collection_index as usize];

        let buffer = self.buffer.take().unwrap();
        SQLiteObjectWriter::new(target_collection, self.all_collections, buffer)
    }

    fn end_object<'b>(&'b mut self, writer: Self::ObjectWriter) {
        let buffer = writer.finalize();
        self.buffer = Some(buffer);
        self.property += 1;
    }

    fn begin_list(&mut self, _size: usize) -> Self::ListWriter {
        let property = &self.collection.properties[self.property];
        self.write_property_name(&property.name);

        let buffer = self.buffer.take().unwrap();
        SQLiteListWriter::new(property.collection_index, self.all_collections, buffer)
    }

    fn end_list<'b>(&'b mut self, writer: Self::ListWriter) {
        let buffer = writer.finalize();
        self.buffer = Some(buffer);
        self.property += 1;
    }
}

pub struct SQLiteListWriter<'a> {
    collection_index: Option<u16>,
    all_collections: &'a Vec<SQLiteCollection>,
    first: bool,
    buffer: Option<Vec<u8>>,
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
            buffer: Some(buffer),
        }
    }

    fn write_value(&mut self) -> &mut Vec<u8> {
        if let Some(buffer) = self.buffer.as_mut() {
            CompactFormatter
                .begin_array_value(buffer, self.first)
                .unwrap();
            buffer
        } else {
            panic!("Buffer is already borrowed");
        }
    }

    fn finalize(mut self) -> Vec<u8> {
        if let Some(mut buffer) = self.buffer.take() {
            CompactFormatter.end_array(&mut buffer).unwrap();
            buffer
        } else {
            panic!("A nested object or list is unfinished");
        }
    }
}

impl<'a> IsarWriter<'a> for SQLiteListWriter<'a> {
    type ObjectWriter = SQLiteObjectWriter<'a>;

    type ListWriter = SQLiteListWriter<'a>;

    fn write_id(&mut self, _: i64) {
        panic!("Id cannot be written to a list");
    }

    fn write_null(&mut self) {
        let buffer = self.write_value();
        CompactFormatter.write_null(buffer).unwrap();
    }

    fn write_byte(&mut self, value: u8) {
        let buffer = self.write_value();
        CompactFormatter.write_u8(buffer, value).unwrap();
    }

    fn write_bool(&mut self, value: Option<bool>) {
        let buffer = self.write_value();
        if let Some(value) = value {
            CompactFormatter.write_bool(buffer, value).unwrap();
        } else {
            CompactFormatter.write_null(buffer).unwrap();
        }
    }

    fn write_int(&mut self, value: i32) {
        let buffer = self.write_value();
        if value != i32::MIN {
            CompactFormatter.write_i32(buffer, value).unwrap();
        } else {
            CompactFormatter.write_i64(buffer, i64::MIN).unwrap();
        }
    }

    fn write_float(&mut self, value: f32) {
        let buffer = self.write_value();
        if !value.is_nan() {
            CompactFormatter.write_f32(buffer, value).unwrap();
        } else {
            CompactFormatter.write_f64(buffer, f64::NAN).unwrap();
        }
    }

    fn write_long(&mut self, value: i64) {
        let buffer = self.write_value();
        if value != i64::MIN {
            CompactFormatter.write_i64(buffer, value).unwrap();
        } else {
            CompactFormatter.write_i64(buffer, i64::MIN).unwrap();
        }
    }

    fn write_double(&mut self, value: f64) {
        let buffer = self.write_value();
        if !value.is_nan() {
            CompactFormatter.write_f64(buffer, value).unwrap();
        } else {
            CompactFormatter.write_f64(buffer, f64::NAN).unwrap();
        }
    }

    fn write_string(&mut self, value: Option<&str>) {
        let buffer = self.write_value();
        if let Some(value) = value {
            CompactFormatter.begin_string(buffer).unwrap();
            CompactFormatter
                .write_string_fragment(buffer, value)
                .unwrap();
            CompactFormatter.end_string(buffer).unwrap();
        } else {
            CompactFormatter.write_null(buffer).unwrap();
        }
    }

    fn begin_object(&mut self) -> Self::ObjectWriter {
        let collection_index = self.collection_index.unwrap();
        let target_collection = &self.all_collections[collection_index as usize];

        let buffer = self.buffer.take().unwrap();
        SQLiteObjectWriter::new(target_collection, self.all_collections, buffer)
    }

    fn end_object<'b>(&'b mut self, writer: Self::ObjectWriter) {
        let buffer = writer.finalize();
        self.buffer = Some(buffer);
    }

    fn begin_list(&mut self, _size: usize) -> Self::ListWriter {
        panic!("Nested lists are not supported");
    }

    fn end_list<'b>(&'b mut self, _: Self::ListWriter) {
        panic!("Nested lists are not supported");
    }
}
