use super::sqlite3::SQLiteStatement;
use super::sqlite_collection::SQLiteCollection;
use crate::core::reader::IsarReader;
use intmap::IntMap;
use serde_json::{Map, Value};
use std::borrow::Cow;

pub struct SQLiteReader<'a> {
    stmt: &'a SQLiteStatement<'a>,
    collection: &'a SQLiteCollection,
    all_collections: &'a IntMap<SQLiteCollection>,
}

impl<'a> SQLiteReader<'a> {
    pub fn new(
        stmt: &'a SQLiteStatement<'a>,
        collection: &'a SQLiteCollection,
        all_collections: &'a IntMap<SQLiteCollection>,
    ) -> Self {
        Self {
            stmt,
            collection,
            all_collections,
        }
    }
}

impl<'a> IsarReader for SQLiteReader<'a> {
    type ObjectReader<'b> = SQLiteObjectReader<'b> where 'a: 'b;

    type ListReader<'b> = SQLiteListReader<'b> where 'a: 'b;

    fn is_null(&self, index: usize) -> bool {
        self.stmt.is_null(index)
    }

    fn read_id(&self) -> i64 {
        self.stmt.get_long(0)
    }

    fn read_byte(&self, index: usize) -> u8 {
        self.stmt.get_int(index) as u8
    }

    fn read_bool(&self, index: usize) -> Option<bool> {
        if self.is_null(index) {
            None
        } else {
            Some(self.stmt.get_int(index) != 0)
        }
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

    fn read_object(&self, index: usize) -> Option<Self::ObjectReader<'a>> {
        let text = self.stmt.get_text(index);
        if let Ok(Value::Object(object)) = serde_json::from_str(text) {
            let target_id = self.collection.properties[index].target_id.unwrap();
            let collection = self.all_collections.get(target_id).unwrap();
            return Some(SQLiteObjectReader {
                object: Cow::Owned(object),
                collection,
                all_collections: self.all_collections,
            });
        }
        None
    }

    fn read_list(&self, index: usize) -> Option<Self::ListReader<'a>> {
        let text = self.stmt.get_text(index);
        if let Ok(Value::Array(list)) = serde_json::from_str(text) {
            let target_id = self.collection.properties[index].target_id;
            return Some(SQLiteListReader {
                list: Cow::Owned(list),
                target_id: target_id,
                all_collections: self.all_collections,
            });
        }
        None
    }
}

pub struct SQLiteObjectReader<'a> {
    object: Cow<'a, Map<String, Value>>,
    collection: &'a SQLiteCollection,
    all_collections: &'a IntMap<SQLiteCollection>,
}

impl<'a> IsarReader for SQLiteObjectReader<'a> {
    type ObjectReader<'b> = SQLiteObjectReader<'b> where 'a: 'b;

    type ListReader<'b> = SQLiteListReader<'b> where 'a: 'b;

    fn is_null(&self, index: usize) -> bool {
        let property = &self.collection.properties[index];
        let value = self.object.get(&property.name);
        if let Some(Value::Null) = value {
            true
        } else {
            false
        }
    }

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

    fn read_bool(&self, index: usize) -> Option<bool> {
        let property = &self.collection.properties[index];
        let value = self.object.get(&property.name);
        match value {
            Some(Value::Bool(val)) => Some(*val),
            Some(Value::Number(num)) => {
                if let Some(val) = num.as_u64() {
                    Some(val != 0)
                } else {
                    None
                }
            }
            _ => None,
        }
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

    fn read_object(&self, index: usize) -> Option<Self::ObjectReader<'_>> {
        let property = &self.collection.properties[index];
        let value = self.object.get(&property.name);
        if let Some(Value::Object(object)) = value {
            let target_id = property.target_id.unwrap();
            let collection = self.all_collections.get(target_id).unwrap();
            Some(SQLiteObjectReader {
                object: Cow::Borrowed(object),
                collection,
                all_collections: self.all_collections,
            })
        } else {
            None
        }
    }

    fn read_list(&self, index: usize) -> Option<Self::ListReader<'_>> {
        let property = &self.collection.properties[index];
        let value = self.object.get(&property.name);
        if let Some(Value::Array(list)) = value {
            Some(SQLiteListReader {
                list: Cow::Borrowed(list),
                target_id: property.target_id,
                all_collections: self.all_collections,
            })
        } else {
            None
        }
    }
}

pub struct SQLiteListReader<'a> {
    list: Cow<'a, Vec<Value>>,
    target_id: Option<u64>,
    all_collections: &'a IntMap<SQLiteCollection>,
}

impl<'a> IsarReader for SQLiteListReader<'a> {
    type ObjectReader<'b> = SQLiteObjectReader<'b> where 'a: 'b;

    type ListReader<'b> = SQLiteListReader<'b> where 'a: 'b;

    fn is_null(&self, index: usize) -> bool {
        if let Some(Value::Null) = self.list.get(index) {
            true
        } else {
            false
        }
    }

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

    fn read_bool(&self, index: usize) -> Option<bool> {
        match self.list.get(index) {
            Some(Value::Bool(val)) => Some(*val),
            Some(Value::Number(num)) => {
                if let Some(val) = num.as_u64() {
                    Some(val != 0)
                } else {
                    None
                }
            }
            _ => None,
        }
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

    fn read_object(&self, index: usize) -> Option<Self::ObjectReader<'_>> {
        if let Some(Value::Object(object)) = self.list.get(index) {
            let target_id = self.target_id.unwrap();
            let collection = self.all_collections.get(target_id).unwrap();
            Some(SQLiteObjectReader {
                object: Cow::Borrowed(object),
                collection,
                all_collections: self.all_collections,
            })
        } else {
            None
        }
    }

    fn read_list(&self, _: usize) -> Option<Self::ListReader<'_>> {
        panic!("Nested lists are not supported")
    }
}
