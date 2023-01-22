use serde::{Deserialize, Serialize};

use super::data_type::DataType;

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
    pub target_col: Option<String>,
}

impl PropertySchema {
    pub fn new(name: &str, data_type: DataType, target_col: Option<&str>) -> PropertySchema {
        PropertySchema {
            name: Some(name.to_string()),
            data_type,
            target_col: target_col.map(|col| col.to_string()),
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
