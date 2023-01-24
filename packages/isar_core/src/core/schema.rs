use super::data_type::DataType;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Hash)]
pub struct IsarSchema {
    pub collections: Vec<CollectionSchema>,
}

impl IsarSchema {
    pub fn new(collections: Vec<CollectionSchema>) -> IsarSchema {
        IsarSchema { collections }
    }
}

#[derive(Serialize, Deserialize, Clone, Hash)]
pub struct CollectionSchema {
    pub name: String,
    #[serde(default)]
    pub embedded: bool,
    pub properties: Vec<PropertySchema>,
    #[serde(default)]
    pub indexes: Vec<IndexSchema>,
    #[serde(default)]
    pub(crate) version: usize,
}

impl CollectionSchema {
    pub fn new(
        name: &str,
        properties: Vec<PropertySchema>,
        indexes: Vec<IndexSchema>,
        embedded: bool,
    ) -> CollectionSchema {
        CollectionSchema {
            name: name.to_string(),
            embedded,
            properties,
            indexes,
            version: 0,
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Eq, PartialEq, Hash)]
pub struct PropertySchema {
    pub name: Option<String>,
    #[serde(rename = "type")]
    pub data_type: DataType,
    #[serde(default)]
    #[serde(rename = "target")]
    pub collection: Option<String>,
}

impl PropertySchema {
    pub fn new(name: &str, data_type: DataType, collection: Option<&str>) -> PropertySchema {
        PropertySchema {
            name: Some(name.to_string()),
            data_type,
            collection: collection.map(|col| col.to_string()),
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Eq, PartialEq, Hash)]
pub struct IndexSchema {
    pub name: String,
    pub properties: Vec<String>,
    pub unique: bool,
}

impl IndexSchema {
    pub fn new(name: &str, properties: Vec<&str>, unique: bool) -> IndexSchema {
        IndexSchema {
            name: name.to_string(),
            properties: properties.iter().map(|p| p.to_string()).collect(),
            unique,
        }
    }
}
