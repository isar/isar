use super::sqlite3::SQLiteStatement;
use super::sqlite_collection::SQLiteCollection;
use crate::core::reader::IsarReader;
use base64::{engine::general_purpose, Engine as _};
use serde_json::{Map, Value};
use std::borrow::Cow;

pub struct SQLiteReader<'a> {
    stmt: &'a SQLiteStatement<'a>,
    collection: &'a SQLiteCollection,
    all_collections: &'a Vec<SQLiteCollection>,
}

impl<'a> SQLiteReader<'a> {
    pub fn new(
        stmt: &'a SQLiteStatement,
        collection: &'a SQLiteCollection,
        all_collections: &'a Vec<SQLiteCollection>,
    ) -> Self {
        Self {
            stmt,
            collection,
            all_collections,
        }
    }

    fn is_null(&self, index: usize) -> bool {
        self.stmt.is_null(index)
    }
}

impl<'a> IsarReader for SQLiteReader<'a> {
    type ObjectReader<'b> = SQLiteObjectReader<'b> where 'a: 'b;

    type ListReader<'b> = SQLiteListReader<'b> where 'a: 'b;

    fn read_id(&self) -> i64 {
        self.stmt.get_long(0)
    }

    fn read_byte(&self, index: usize) -> u8 {
        self.stmt.get_int(index) as u8
    }

    fn read_int(&self, index: usize) -> i32 {
        let val = self.stmt.get_int(index);
        if val == 0 && self.is_null(index) {
            i32::MIN
        } else {
            val
        }
    }

    fn read_float(&self, index: usize) -> f32 {
        self.read_double(index) as f32
    }

    fn read_long(&self, index: usize) -> i64 {
        let val = self.stmt.get_long(index);
        if val == 0 && self.is_null(index) {
            i64::MIN
        } else {
            val
        }
    }

    fn read_double(&self, index: usize) -> f64 {
        let val = self.stmt.get_double(index);
        if val == 0.0 && self.is_null(index) {
            f64::NAN
        } else {
            val
        }
    }

    fn read_string(&self, index: usize) -> Option<&'a str> {
        if self.is_null(index) {
            None
        } else {
            Some(self.stmt.get_text(index))
        }
    }

    fn read_blob(&self, index: usize) -> Option<Cow<'a, [u8]>> {
        if self.is_null(index) {
            None
        } else {
            let bytes = self.stmt.get_blob(index);
            Some(Cow::Borrowed(bytes))
        }
    }

    fn read_object(&self, index: usize) -> Option<Self::ObjectReader<'a>> {
        let text = self.stmt.get_text(index);
        if let Ok(Value::Object(object)) = serde_json::from_str(text) {
            let collection_index = self.collection.properties[index].collection_index.unwrap();
            let collection = &self.all_collections[collection_index as usize];
            return Some(SQLiteObjectReader {
                object: Cow::Owned(object),
                collection,
                all_collections: self.all_collections,
            });
        }
        None
    }

    fn read_json(&self, index: usize) -> Option<Cow<'a, Value>> {
        let text = self.stmt.get_text(index);
        if let Ok(value) = serde_json::from_str(text) {
            return Some(Cow::Owned(value));
        }
        None
    }

    fn read_list(&self, index: usize) -> Option<(Self::ListReader<'a>, usize)> {
        let text = self.stmt.get_text(index);
        if let Ok(Value::Array(list)) = serde_json::from_str(text) {
            let list_length = list.len();
            let collection_index = self.collection.properties[index].collection_index;
            let list_reader = SQLiteListReader {
                list: Cow::Owned(list),
                collection_index,
                all_collections: self.all_collections,
            };
            return Some((list_reader, list_length));
        }
        None
    }
}

pub struct SQLiteObjectReader<'a> {
    object: Cow<'a, Map<String, Value>>,
    collection: &'a SQLiteCollection,
    all_collections: &'a Vec<SQLiteCollection>,
}

impl<'a> IsarReader for SQLiteObjectReader<'a> {
    type ObjectReader<'b> = SQLiteObjectReader<'b> where 'a: 'b;

    type ListReader<'b> = SQLiteListReader<'b> where 'a: 'b;

    fn read_id(&self) -> i64 {
        panic!("Embedded objects don't have an id");
    }

    fn read_byte(&self, index: usize) -> u8 {
        let property = &self.collection.properties[index];
        let value = self.object.get(&property.name);
        if let Some(Value::Number(num)) = value {
            if let Some(val) = num.as_u64() {
                return val as u8;
            }
        }
        0
    }

    fn read_int(&self, index: usize) -> i32 {
        self.read_long(index) as i32
    }

    fn read_float(&self, index: usize) -> f32 {
        self.read_double(index) as f32
    }

    fn read_long(&self, index: usize) -> i64 {
        let property = &self.collection.properties[index];
        let value = self.object.get(&property.name);
        if let Some(Value::Number(num)) = value {
            if let Some(val) = num.as_i64() {
                return val;
            }
        }
        i64::MIN
    }

    fn read_double(&self, index: usize) -> f64 {
        let property = &self.collection.properties[index];
        let value = self.object.get(&property.name);
        if let Some(Value::Number(num)) = value {
            if let Some(val) = num.as_f64() {
                return val;
            }
        }
        f64::NAN
    }

    fn read_string(&self, index: usize) -> Option<&str> {
        let property = &self.collection.properties[index];
        let value = self.object.get(&property.name);
        if let Some(Value::String(val)) = value {
            Some(val)
        } else {
            None
        }
    }

    fn read_blob(&self, index: usize) -> Option<Cow<'a, [u8]>> {
        let property = &self.collection.properties[index];
        let value = self.object.get(&property.name);
        if let Some(Value::String(val)) = value {
            if let Ok(bytes) = general_purpose::STANDARD_NO_PAD.decode(val) {
                return Some(Cow::Owned(bytes));
            }
        }
        None
    }

    fn read_object(&self, index: usize) -> Option<Self::ObjectReader<'_>> {
        let property = &self.collection.properties[index];
        let value = self.object.get(&property.name);
        if let Some(Value::Object(object)) = value {
            let collection_index = property.collection_index.unwrap();
            let collection = &self.all_collections[collection_index as usize];
            Some(SQLiteObjectReader {
                object: Cow::Borrowed(object),
                collection,
                all_collections: self.all_collections,
            })
        } else {
            None
        }
    }

    fn read_json(&self, index: usize) -> Option<Cow<'_, Value>> {
        let property = &self.collection.properties[index];
        self.object.get(&property.name).map(Cow::Borrowed)
    }

    fn read_list(&self, index: usize) -> Option<(Self::ListReader<'_>, usize)> {
        let property = &self.collection.properties[index];
        let value = self.object.get(&property.name);
        if let Some(Value::Array(list)) = value {
            let list_reader = SQLiteListReader {
                list: Cow::Borrowed(list),
                collection_index: property.collection_index,
                all_collections: self.all_collections,
            };
            Some((list_reader, list.len()))
        } else {
            None
        }
    }
}

pub struct SQLiteListReader<'a> {
    list: Cow<'a, Vec<Value>>,
    collection_index: Option<u16>,
    all_collections: &'a Vec<SQLiteCollection>,
}

impl<'a> IsarReader for SQLiteListReader<'a> {
    type ObjectReader<'b> = SQLiteObjectReader<'b> where 'a: 'b;

    type ListReader<'b> = SQLiteListReader<'b> where 'a: 'b;

    fn read_id(&self) -> i64 {
        panic!("Lists don't have an id");
    }

    fn read_byte(&self, index: usize) -> u8 {
        if let Some(Value::Number(num)) = self.list.get(index) {
            if let Some(val) = num.as_u64() {
                return val as u8;
            }
        }
        0
    }

    fn read_int(&self, index: usize) -> i32 {
        self.read_long(index) as i32
    }

    fn read_float(&self, index: usize) -> f32 {
        self.read_double(index) as f32
    }

    fn read_long(&self, index: usize) -> i64 {
        if let Some(Value::Number(num)) = self.list.get(index) {
            if let Some(val) = num.as_i64() {
                return val;
            }
        }
        i64::MIN
    }

    fn read_double(&self, index: usize) -> f64 {
        if let Some(Value::Number(num)) = self.list.get(index) {
            if let Some(val) = num.as_f64() {
                return val;
            }
        }
        f64::NAN
    }

    fn read_string(&self, index: usize) -> Option<&str> {
        if let Some(Value::String(val)) = self.list.get(index) {
            Some(val)
        } else {
            None
        }
    }

    fn read_blob(&self, index: usize) -> Option<Cow<'a, [u8]>> {
        panic!("Nested lists are not supported")
    }

    fn read_object(&self, index: usize) -> Option<Self::ObjectReader<'_>> {
        if let Some(Value::Object(object)) = self.list.get(index) {
            let collection_index = self.collection_index.unwrap();
            let collection = &self.all_collections[collection_index as usize];
            Some(SQLiteObjectReader {
                object: Cow::Borrowed(object),
                collection,
                all_collections: self.all_collections,
            })
        } else {
            None
        }
    }

    fn read_json(&self, index: usize) -> Option<Cow<'_, Value>> {
        self.list.get(index).map(Cow::Borrowed)
    }

    fn read_list(&self, _: usize) -> Option<(Self::ListReader<'_>, usize)> {
        panic!("Nested lists are not supported")
    }
}
