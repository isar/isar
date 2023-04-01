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
    pub(crate) version: u8,
}

impl CollectionSchema {
    pub fn new(
        name: &str,
        properties: Vec<PropertySchema>,
        indexes: Vec<IndexSchema>,
        embedded: bool,
    ) -> CollectionSchema {
        CollectionSchema {
            name: name.to_uppercase(),
            embedded,
            properties,
            indexes,
            version: 0,
        }
    }

    pub fn find_changes(
        &self,
        old_collection: &CollectionSchema,
    ) -> (
        Vec<&'_ PropertySchema>,
        Vec<String>,
        Vec<&'_ IndexSchema>,
        Vec<(String, bool)>,
    ) {
        let mut add_properties = Vec::new();
        let mut drop_properties = Vec::new();
        let mut add_indexes = Vec::new();
        let mut drop_indexes = Vec::new();

        for old_prop in &old_collection.properties {
            let prop = self.properties.iter().find(|p| p.name == old_prop.name);
            if let Some(prop) = prop {
                if prop.data_type != old_prop.data_type || prop.collection != old_prop.collection {
                    add_properties.push(prop);
                    drop_properties.push(prop.name.as_ref().unwrap().clone());
                }
            } else if let Some(old_prop_name) = &old_prop.name {
                drop_properties.push(old_prop_name.clone());
            }
        }

        for prop in &self.properties {
            if let Some(prop_name) = &prop.name {
                let does_not_exist = !old_collection
                    .properties
                    .iter()
                    .any(|p| p.name.as_deref() == Some(prop_name));
                if does_not_exist {
                    add_properties.push(prop);
                }
            }
        }

        for old_index in &old_collection.indexes {
            let index = self.indexes.iter().find(|i| i.name == old_index.name);
            if let Some(index) = index {
                let property_dropped = index.properties.iter().any(|p| drop_properties.contains(p));
                if index.unique != old_index.unique
                    || &index.properties != &old_index.properties
                    || property_dropped
                {
                    add_indexes.push(index);
                    drop_indexes.push((old_index.name.clone(), old_index.unique));
                }
            } else {
                drop_indexes.push((old_index.name.clone(), old_index.unique));
            }
        }

        for index in &self.indexes {
            let does_not_exist = !old_collection
                .indexes
                .iter()
                .any(|old_index| index.name == old_index.name);
            if does_not_exist {
                add_indexes.push(index);
            }
        }

        (add_properties, drop_properties, add_indexes, drop_indexes)
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
            name: Some(name.to_uppercase()),
            data_type,
            collection: collection.map(|col| col.to_uppercase()),
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
            name: name.to_uppercase(),
            properties: properties.iter().map(|p| p.to_uppercase()).collect(),
            unique,
        }
    }
}
