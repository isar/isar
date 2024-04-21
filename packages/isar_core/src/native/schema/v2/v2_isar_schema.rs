use serde::{Deserialize, Serialize};

use crate::core::schema::{IndexSchema, IsarSchema, PropertySchema};

#[derive(Serialize, Deserialize)]
pub struct V2IsarSchema {
    pub name: String,
    #[serde(default)]
    pub embedded: bool,
    // V2 and V3 both have the same property schema.
    pub properties: Vec<PropertySchema>,
    #[serde(default)]
    pub indexes: Vec<V2IndexSchema>,
    #[serde(default)]
    pub links: Vec<V2LinkSchema>,
    #[serde(default)]
    pub version: u8,
}

impl V2IsarSchema {
    pub fn to_v3_schema(&self) -> IsarSchema {
        let indexes = self
            .indexes
            .iter()
            .map(V2IndexSchema::to_v3_index_schema)
            .collect();

        IsarSchema {
            name: self.name.clone(),
            id_name: None,
            embedded: self.embedded,
            properties: self.properties.clone(),
            indexes,
            version: self.version,
        }
    }
}

#[derive(Serialize, Deserialize, Eq, PartialEq)]
pub enum V2IndexType {
    Value,
    Hash,
    HashElements,
}

#[derive(Serialize, Deserialize)]
pub struct V2IndexPropertySchema {
    pub name: String,
    #[serde(rename = "type")]
    pub index_type: V2IndexType,
    #[serde(rename = "caseSensitive")]
    pub case_sensitive: bool,
}

#[derive(Serialize, Deserialize)]
pub struct V2IndexSchema {
    pub name: String,
    pub properties: Vec<V2IndexPropertySchema>,
    pub unique: bool,
    #[serde(default)]
    pub replace: bool,
}

impl V2IndexSchema {
    pub fn to_v3_index_schema(&self) -> IndexSchema {
        let properties = self
            .properties
            .iter()
            .map(|v2_property| v2_property.name.clone())
            .collect();

        let hash = self
            .properties
            .iter()
            .any(|property| property.index_type == V2IndexType::Hash);

        IndexSchema {
            name: self.name.clone(),
            properties,
            unique: self.unique,
            hash,
        }
    }
}

#[derive(Serialize, Deserialize)]
pub struct V2LinkSchema {
    pub name: String,
    #[serde(rename = "target")]
    pub target_col: String,
}
