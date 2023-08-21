use super::sqlite_collection::SQLiteCollection;
use super::sqlite_insert::SQLiteInsert;
use crate::core::{data_type::DataType, writer::IsarWriter};
use base64::{engine::general_purpose, Engine};
use serde_json::{Map, Number, Value};
use std::iter::empty;

impl<'a> SQLiteInsert<'a> {
    fn property_index(&self, index: u32) -> u32 {
        (self.batch_size - self.batch_remaining) * (self.collection.properties.len() as u32 + 1)
            + index
    }
}

impl<'a> IsarWriter<'a> for SQLiteInsert<'a> {
    type ObjectWriter = SQLiteObjectWriter<'a>;

    type ListWriter = SQLiteListWriter<'a>;

    fn id_name(&self) -> Option<&str> {
        self.collection.id_name.as_deref()
    }

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> {
        self.collection
            .properties
            .iter()
            .map(|p| (p.name.as_str(), p.data_type))
    }

    fn write_null(&mut self, index: u32) {
        let col = self.property_index(index);
        let _ = self.with_stmt(|stmt| stmt.bind_null(col));
    }

    fn write_bool(&mut self, index: u32, value: bool) {
        let col = self.property_index(index);
        let _ = self.with_stmt(|stmt| stmt.bind_int(col, value as i32));
    }

    fn write_byte(&mut self, index: u32, value: u8) {
        let col = self.property_index(index);
        let _ = self.with_stmt(|stmt| stmt.bind_int(col, value as i32));
    }

    fn write_int(&mut self, index: u32, value: i32) {
        let col = self.property_index(index);
        let _ = self.with_stmt(|stmt| {
            if value != i32::MIN {
                stmt.bind_int(col, value)
            } else {
                stmt.bind_null(col)
            }
        });
    }

    fn write_float(&mut self, index: u32, value: f32) {
        let col = self.property_index(index);
        let _ = self.with_stmt(|stmt| {
            if !value.is_nan() {
                stmt.bind_double(col, value as f64)
            } else {
                stmt.bind_null(col)
            }
        });
    }

    fn write_long(&mut self, index: u32, value: i64) {
        let col = self.property_index(index);
        let _ = self.with_stmt(|stmt| {
            if value != i64::MIN {
                stmt.bind_long(col, value)
            } else {
                stmt.bind_null(col)
            }
        });
    }

    fn write_double(&mut self, index: u32, value: f64) {
        let col = self.property_index(index);
        let _ = self.with_stmt(|stmt| {
            if !value.is_nan() {
                stmt.bind_double(col, value)
            } else {
                stmt.bind_null(col)
            }
        });
    }

    fn write_string(&mut self, index: u32, value: &str) {
        let col = self.property_index(index);
        let _ = self.with_stmt(|stmt| stmt.bind_text(col, value));
    }

    fn write_byte_list(&mut self, index: u32, value: &[u8]) {
        let col = self.property_index(index);
        let _ = self.with_stmt(|stmt| stmt.bind_blob(col, value));
    }

    fn begin_object<'b>(&mut self, index: u32) -> Option<Self::ObjectWriter> {
        let property = self.collection.get_property(index as u16)?;
        if let Some(collection_index) = property.collection_index {
            let target_collection = &self.all_collections[collection_index as usize];
            return Some(SQLiteObjectWriter::new(
                target_collection,
                self.all_collections,
                index as u16,
            ));
        }
        None
    }

    fn end_object<'b>(&'b mut self, writer: Self::ObjectWriter) {
        if let Ok(json) = serde_json::to_string(&writer.map) {
            self.write_string(writer.property_index as u32, &json);
        } else {
            self.write_null(writer.property_index as u32);
        }
    }

    fn begin_list(&mut self, index: u32, length: u32) -> Option<Self::ListWriter> {
        let property = self.collection.get_property(index as u16)?;
        Some(SQLiteListWriter::new(
            property.collection_index,
            self.all_collections,
            index as u16,
            length,
        ))
    }

    fn end_list<'b>(&'b mut self, writer: Self::ListWriter) {
        if let Ok(json) = serde_json::to_string(&writer.list) {
            self.write_string(writer.property_index as u32, &json);
        } else {
            self.write_null(writer.property_index as u32);
        }
    }
}

pub struct SQLiteObjectWriter<'a> {
    collection: &'a SQLiteCollection,
    all_collections: &'a Vec<SQLiteCollection>,
    property_index: u16,
    map: Map<String, Value>,
}

impl<'a> SQLiteObjectWriter<'a> {
    fn new(
        collection: &'a SQLiteCollection,
        all_collections: &'a Vec<SQLiteCollection>,
        property_index: u16,
    ) -> Self {
        Self {
            collection,
            all_collections,
            property_index,
            map: Map::new(),
        }
    }
}

impl<'a> IsarWriter<'a> for SQLiteObjectWriter<'a> {
    type ObjectWriter = SQLiteObjectWriter<'a>;

    type ListWriter = SQLiteListWriter<'a>;

    fn id_name(&self) -> Option<&str> {
        None
    }

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> {
        self.collection
            .properties
            .iter()
            .map(|p| (p.name.as_str(), p.data_type))
    }

    fn write_null(&mut self, index: u32) {
        if let Some(property) = self.collection.get_property(index as u16) {
            self.map.remove(&property.name);
        }
    }

    fn write_bool(&mut self, index: u32, value: bool) {
        if let Some(property) = self.collection.get_property(index as u16) {
            self.map.insert(property.name.clone(), Value::Bool(value));
        }
    }

    fn write_byte(&mut self, index: u32, value: u8) {
        if let Some(property) = self.collection.get_property(index as u16) {
            self.map
                .insert(property.name.clone(), Value::Number(value.into()));
        }
    }

    fn write_int(&mut self, index: u32, value: i32) {
        if let Some(property) = self.collection.get_property(index as u16) {
            if value != i32::MIN {
                self.map
                    .insert(property.name.clone(), Value::Number(value.into()));
            }
        }
    }

    fn write_float(&mut self, index: u32, value: f32) {
        if let Some(property) = self.collection.get_property(index as u16) {
            if !value.is_nan() {
                if let Some(value) = Number::from_f64(value as f64) {
                    self.map.insert(property.name.clone(), Value::Number(value));
                }
            }
        }
    }

    fn write_long(&mut self, index: u32, value: i64) {
        if let Some(property) = self.collection.get_property(index as u16) {
            if value != i64::MIN {
                self.map
                    .insert(property.name.clone(), Value::Number(value.into()));
            }
        }
    }

    fn write_double(&mut self, index: u32, value: f64) {
        if let Some(property) = self.collection.get_property(index as u16) {
            if !value.is_nan() {
                if let Some(value) = Number::from_f64(value) {
                    self.map.insert(property.name.clone(), Value::Number(value));
                }
            }
        }
    }

    fn write_string(&mut self, index: u32, value: &str) {
        if let Some(property) = self.collection.get_property(index as u16) {
            self.map
                .insert(property.name.clone(), Value::String(value.to_string()));
        }
    }

    fn write_byte_list(&mut self, index: u32, value: &[u8]) {
        let mut string = String::new();
        let _ = general_purpose::STANDARD_NO_PAD.encode_string(value, &mut string);
        self.write_string(index, &string);
    }

    fn begin_object(&mut self, index: u32) -> Option<Self::ObjectWriter> {
        if let Some(property) = self.collection.get_property(index as u16) {
            if let Some(collection_index) = property.collection_index {
                let target_collection = &self.all_collections[collection_index as usize];
                let writer =
                    SQLiteObjectWriter::new(target_collection, self.all_collections, index as u16);
                return Some(writer);
            }
        }
        None
    }

    fn end_object<'b>(&'b mut self, writer: Self::ObjectWriter) {
        if let Some(property) = self.collection.get_property(writer.property_index) {
            self.map
                .insert(property.name.clone(), Value::Object(writer.map));
        }
    }

    fn begin_list(&mut self, index: u32, length: u32) -> Option<Self::ListWriter> {
        if let Some(property) = self.collection.get_property(index as u16) {
            let writer = SQLiteListWriter::new(
                property.collection_index,
                self.all_collections,
                index as u16,
                length,
            );
            Some(writer)
        } else {
            None
        }
    }

    fn end_list<'b>(&'b mut self, writer: Self::ListWriter) {
        if let Some(property) = self.collection.get_property(writer.property_index) {
            self.map
                .insert(property.name.clone(), Value::Array(writer.list));
        }
    }
}

pub struct SQLiteListWriter<'a> {
    collection_index: Option<u16>,
    all_collections: &'a Vec<SQLiteCollection>,
    property_index: u16,
    list: Vec<Value>,
}

impl<'a> SQLiteListWriter<'a> {
    fn new(
        collection_index: Option<u16>,
        all_collections: &'a Vec<SQLiteCollection>,
        property_index: u16,
        length: u32,
    ) -> Self {
        Self {
            collection_index,
            all_collections,
            property_index,
            list: vec![Value::Null; length as usize],
        }
    }
}

impl<'a> IsarWriter<'a> for SQLiteListWriter<'a> {
    type ObjectWriter = SQLiteObjectWriter<'a>;

    type ListWriter = SQLiteListWriter<'a>;

    fn id_name(&self) -> Option<&str> {
        None
    }

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> {
        empty()
    }

    fn write_null(&mut self, index: u32) {
        let index = index as usize;
        if index < self.list.len() {
            self.list[index] = Value::Null;
        }
    }

    fn write_bool(&mut self, index: u32, value: bool) {
        let index = index as usize;
        if index < self.list.len() {
            self.list[index] = Value::Bool(value);
        }
    }

    fn write_byte(&mut self, index: u32, value: u8) {
        let index = index as usize;
        if index < self.list.len() {
            self.list[index] = Value::Number(value.into());
        }
    }

    fn write_int(&mut self, index: u32, value: i32) {
        let index = index as usize;
        if index < self.list.len() {
            if value != i32::MIN {
                self.list[index] = Value::Number(value.into());
            } else {
                self.list[index] = Value::Null;
            }
        }
    }

    fn write_float(&mut self, index: u32, value: f32) {
        let index = index as usize;
        if index < self.list.len() {
            if !value.is_nan() {
                if let Some(value) = Number::from_f64(value as f64) {
                    self.list[index] = Value::Number(value);
                    return;
                }
            }
            self.list[index] = Value::Null;
        }
    }

    fn write_long(&mut self, index: u32, value: i64) {
        let index = index as usize;
        if index < self.list.len() {
            if value != i64::MIN {
                self.list[index] = Value::Number(value.into());
            } else {
                self.list[index] = Value::Null;
            }
        }
    }

    fn write_double(&mut self, index: u32, value: f64) {
        let index = index as usize;
        if index < self.list.len() {
            if !value.is_nan() {
                if let Some(value) = Number::from_f64(value) {
                    self.list[index] = Value::Number(value);
                    return;
                }
            }
            self.list[index] = Value::Null;
        }
    }

    fn write_string(&mut self, index: u32, value: &str) {
        let index = index as usize;
        if index < self.list.len() {
            self.list[index] = Value::String(value.to_string());
        }
    }

    fn write_byte_list(&mut self, _index: u32, _value: &[u8]) {}

    fn begin_object(&mut self, index: u32) -> Option<Self::ObjectWriter> {
        if let Some(collection_index) = self.collection_index {
            let target_collection = &self.all_collections[collection_index as usize];
            let writer =
                SQLiteObjectWriter::new(target_collection, self.all_collections, index as u16);
            Some(writer)
        } else {
            None
        }
    }

    fn end_object<'b>(&'b mut self, writer: Self::ObjectWriter) {
        let index = writer.property_index as usize;
        if index < self.list.len() {
            self.list[index] = Value::Object(writer.map);
        }
    }

    fn begin_list(&mut self, _index: u32, _length: u32) -> Option<Self::ListWriter> {
        None
    }

    fn end_list<'b>(&'b mut self, _writer: Self::ListWriter) {}
}
