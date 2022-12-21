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
    pub links: Vec<LinkSchema>,
    #[serde(default)]
    pub(crate) version: usize,
}

impl CollectionSchema {
    pub fn new(
        name: &str,
        properties: Vec<PropertySchema>,
        indexes: Vec<IndexSchema>,
        links: Vec<LinkSchema>,
        embedded: bool,
    ) -> CollectionSchema {
        CollectionSchema {
            name: name.to_string(),
            embedded,
            properties,
            indexes,
            links,
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

#[derive(Serialize, Deserialize, Copy, Clone, Eq, PartialEq, Hash)]
pub enum IndexType {
    Value,
    Hash,
    HashElements,
}

#[derive(Serialize, Deserialize, Clone, Eq, PartialEq, Hash)]
pub struct IndexPropertySchema {
    pub name: String,
    #[serde(rename = "type")]
    pub index_type: IndexType,
    #[serde(rename = "caseSensitive")]
    pub case_sensitive: bool,
}

impl IndexPropertySchema {
    pub fn new(name: &str, index_type: IndexType, case_sensitive: bool) -> IndexPropertySchema {
        IndexPropertySchema {
            name: name.to_string(),
            index_type,
            case_sensitive,
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Eq, PartialEq, Hash)]
pub struct IndexSchema {
    pub name: String,
    pub properties: Vec<IndexPropertySchema>,
    pub unique: bool,
    #[serde(default)]
    pub replace: bool,
}

impl IndexSchema {
    pub fn new(
        name: &str,
        properties: Vec<IndexPropertySchema>,
        unique: bool,
        replace: bool,
    ) -> IndexSchema {
        IndexSchema {
            name: name.to_string(),
            properties,
            unique,
            replace,
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Eq, PartialEq, Hash)]
pub struct LinkSchema {
    pub name: String,
    #[serde(rename = "target")]
    pub target_col: String,
}

impl LinkSchema {
    pub fn new(name: &str, target_col: &str) -> LinkSchema {
        LinkSchema {
            name: name.to_string(),
            target_col: target_col.to_string(),
        }
    }
}
