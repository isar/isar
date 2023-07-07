use std::sync::Arc;

use super::sqlite_query::SQLiteQuery;
use crate::core::data_type::DataType;
use crate::core::watcher::CollectionWatchers;

#[derive(Debug)]
pub struct SQLiteProperty {
    pub name: String,
    pub data_type: DataType,
    // for embedded objects
    pub collection_index: Option<u16>,
}

impl SQLiteProperty {
    pub const ID_NAME: &str = "_rowid_";

    pub fn new(name: &str, data_type: DataType, collection_index: Option<u16>) -> Self {
        SQLiteProperty {
            name: name.to_string(),
            data_type,
            collection_index,
        }
    }
}

pub struct SQLiteCollection {
    pub name: String,
    pub id_name: Option<String>,
    pub properties: Vec<SQLiteProperty>,
    pub watchers: Arc<CollectionWatchers<SQLiteQuery>>,
}

impl SQLiteCollection {
    pub fn new(name: String, id_name: Option<String>, properties: Vec<SQLiteProperty>) -> Self {
        Self {
            name,
            id_name,
            properties,
            watchers: CollectionWatchers::new(),
        }
    }

    pub fn get_property(&self, property_index: u16) -> Option<&SQLiteProperty> {
        if property_index != 0 {
            self.properties.get(property_index as usize - 1)
        } else {
            None
        }
    }

    pub fn get_property_name(&self, property_index: u16) -> &str {
        if let Some(property) = self.get_property(property_index) {
            &property.name
        } else {
            SQLiteProperty::ID_NAME
        }
    }
}
