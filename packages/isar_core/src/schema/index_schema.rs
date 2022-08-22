use crate::index::{IndexProperty, IsarIndex};
use crate::mdbx::db::Db;
use crate::object::property::Property;
use itertools::Itertools;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Copy, Clone, Eq, PartialEq)]
pub enum IndexType {
    Value,
    Hash,
    HashElements,
}

#[derive(Serialize, Deserialize, Clone, Eq, PartialEq)]
pub struct IndexPropertySchema {
    pub(crate) name: String,
    #[serde(rename = "type")]
    pub(crate) index_type: IndexType,
    #[serde(rename = "caseSensitive")]
    pub(crate) case_sensitive: bool,
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

#[derive(Serialize, Deserialize, Clone, Eq, PartialEq)]
pub struct IndexSchema {
    pub(crate) name: String,
    pub(crate) properties: Vec<IndexPropertySchema>,
    pub(crate) unique: bool,
    #[serde(default)]
    pub(crate) replace: bool,
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

    pub(crate) fn as_index(&self, db: Db, properties: &[Property]) -> IsarIndex {
        let index_properties = self
            .properties
            .iter()
            .map(|ip| {
                let property = properties.iter().find(|p| ip.name == *p.name).unwrap();
                IndexProperty::new(property.clone(), ip.index_type, ip.case_sensitive)
            })
            .collect_vec();
        IsarIndex::new(&self.name, db, index_properties, self.unique, self.replace)
    }
}
