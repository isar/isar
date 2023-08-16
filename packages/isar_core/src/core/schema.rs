use super::error::Result;
use super::{data_type::DataType, error::IsarError};
use itertools::Itertools;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Hash, Debug, PartialEq, Eq)]
pub struct IsarSchema {
    pub name: String,
    #[serde(rename = "idName", skip_serializing, default)]
    pub id_name: Option<String>,
    #[serde(default)]
    pub embedded: bool,
    pub properties: Vec<PropertySchema>,
    #[serde(default)]
    pub indexes: Vec<IndexSchema>,
    #[serde(default)]
    pub(crate) version: u8,
}

impl IsarSchema {
    pub fn new(
        name: &str,
        id_name: Option<&str>,
        properties: Vec<PropertySchema>,
        indexes: Vec<IndexSchema>,
        embedded: bool,
    ) -> IsarSchema {
        IsarSchema {
            name: name.to_string(),
            id_name: id_name.map(|s| s.to_string()),
            embedded,
            properties,
            indexes,
            version: 0,
        }
    }

    pub fn from_json(json: &[u8]) -> Result<Vec<Self>> {
        if let Ok(collections) = serde_json::from_slice::<Vec<IsarSchema>>(json) {
            Ok(collections)
        } else {
            schema_error("Could not deserialize schema JSON")
        }
    }

    pub fn verify_schemas(schemas: &[Self]) -> Result<()> {
        for schema in schemas {
            schema.verify(schemas)?;
        }
        Ok(())
    }

    pub fn find_changes(
        &self,
        old_collection: &IsarSchema,
    ) -> (
        Vec<&'_ PropertySchema>,
        Vec<String>,
        Vec<&'_ IndexSchema>,
        Vec<String>,
    ) {
        let mut add_properties = Vec::new();
        let mut drop_properties = Vec::new();
        let mut add_indexes = Vec::new();
        let mut drop_indexes = Vec::new();

        for old_prop in &old_collection.properties {
            if let Some(old_prop_name) = old_prop.name.as_deref() {
                let prop = self
                    .properties
                    .iter()
                    .find(|p| p.name.as_deref() == Some(old_prop_name));
                if let Some(prop) = prop {
                    if prop.data_type != old_prop.data_type
                        || prop.collection != old_prop.collection
                    {
                        add_properties.push(prop);
                        drop_properties.push(prop.name.as_ref().unwrap().clone());
                    }
                } else if let Some(old_prop_name) = &old_prop.name {
                    drop_properties.push(old_prop_name.clone());
                }
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
            let index = self.indexes.iter().find(|i| &i.name == &old_index.name);
            if let Some(index) = index {
                let property_dropped = index.properties.iter().any(|p| drop_properties.contains(p));
                if index.unique != old_index.unique
                    || &index.properties != &old_index.properties
                    || index.hash != old_index.hash
                    || property_dropped
                {
                    add_indexes.push(index);
                    drop_indexes.push(old_index.name.clone());
                }
            } else {
                drop_indexes.push(old_index.name.clone());
            }
        }

        for index in &self.indexes {
            let does_not_exist = !old_collection
                .indexes
                .iter()
                .any(|old_index| &index.name == &old_index.name);
            if does_not_exist {
                add_indexes.push(index);
            }
        }

        (add_properties, drop_properties, add_indexes, drop_indexes)
    }

    fn verify(&self, collections: &[IsarSchema]) -> Result<()> {
        verify_name(&self.name)?;

        if self.embedded && !self.indexes.is_empty() {
            return schema_error("Embedded objects must not have indexes.");
        }

        for property in &self.properties {
            if let Some(name) = &property.name {
                verify_name(name)?;
            }

            if property.data_type == DataType::Object || property.data_type == DataType::ObjectList
            {
                if let Some(target_col) = &property.collection {
                    if !collections
                        .iter()
                        .any(|c| &c.name == target_col && c.embedded == true)
                    {
                        return schema_error("Target collection does not exist.");
                    }
                } else {
                    return schema_error("Object property must have a target collection.");
                }
            } else {
                if property.collection.is_some() {
                    return schema_error(
                        "Target collection can only be set for object properties.",
                    );
                }
            }
        }

        let unique_properties = self.properties.iter().unique_by(|p| &p.name);
        if unique_properties.count() != self.properties.len() {
            return schema_error("Duplicate property name")?;
        }

        let unique_indexes = self.indexes.iter().unique_by(|i| &i.name);
        if unique_indexes.count() != self.indexes.len() {
            return schema_error("Duplicate index name");
        }

        for index in &self.indexes {
            if index.properties.is_empty() {
                return schema_error("At least one property needs to be added to a valid index");
            }

            for index_property in &index.properties {
                let property = self
                    .properties
                    .iter()
                    .find(|p| p.name.as_deref() == Some(&index_property));
                if property.is_none() {
                    return schema_error("Index property does not exist");
                }
                let property = property.unwrap();

                if property.data_type == DataType::Float || property.data_type == DataType::Double {
                    return schema_error("Float properties cannot be indexed.");
                } else if property.data_type == DataType::Object {
                    return schema_error("Object properties cannot be indexed.");
                } else if property.data_type == DataType::Json {
                    return schema_error("JSON properties cannot be indexed.");
                } else if property.data_type.is_list() {
                    return schema_error("List properties cannot be indexed.");
                } else if property.data_type == DataType::String
                    && !index.hash
                    && index.properties.last() != Some(&index_property)
                {
                    return schema_error(
                        "Only the last property of a non-hashed index can be a String.",
                    );
                }
            }
        }

        Ok(())
    }
}

fn schema_error<T>(msg: &str) -> Result<T> {
    Err(IsarError::SchemaError {
        message: msg.to_string(),
    })
}

fn verify_name(name: &str) -> Result<()> {
    if name.is_empty() {
        schema_error("Empty names are not allowed.")
    } else if name.starts_with('_') {
        schema_error("Names must not begin with an underscore.")
    } else if name.starts_with("sqlite_") {
        schema_error("Names must not begin with 'sqlite_'.")
    } else {
        Ok(())
    }
}

#[derive(Serialize, Deserialize, Clone, Eq, PartialEq, Hash, Debug)]
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

#[derive(Serialize, Deserialize, Clone, Eq, PartialEq, Hash, Debug)]
pub struct IndexSchema {
    pub name: String,
    pub properties: Vec<String>,
    pub unique: bool,
    pub hash: bool,
}

impl IndexSchema {
    pub fn new(name: &str, properties: Vec<&str>, unique: bool, hash: bool) -> IndexSchema {
        IndexSchema {
            name: name.to_string(),
            properties: properties.iter().map(|p| p.to_string()).collect(),
            unique,
            hash,
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_verify_checks_name() {
        let schema = IsarSchema::new("test", None, Vec::new(), Vec::new(), false);
        assert!(schema.verify(&[]).is_ok());

        let schema = IsarSchema::new("_test", None, Vec::new(), Vec::new(), false);
        assert!(schema.verify(&[]).is_err());

        let schema = IsarSchema::new("sqlite_test", None, Vec::new(), Vec::new(), false);
        assert!(schema.verify(&[]).is_err());

        let schema = IsarSchema::new("", None, Vec::new(), Vec::new(), false);
        assert!(schema.verify(&[]).is_err());
    }

    #[test]
    fn test_verify_checks_index_names() {
        let schema = IsarSchema::new(
            "test",
            None,
            Vec::new(),
            vec![IndexSchema::new("test", vec!["test"], false, false)],
            true,
        );
        assert!(schema.verify(&[]).is_err());
    }

    #[test]
    fn test_verify_checks_property_name_is_unique() {
        let schema = IsarSchema::new(
            "test",
            None,
            vec![
                PropertySchema::new("test", DataType::Int, None),
                PropertySchema::new("test2", DataType::Int, None),
                PropertySchema::new("test", DataType::String, None),
            ],
            Vec::new(),
            false,
        );
        assert!(schema.verify(&[]).is_err());
    }

    #[test]
    fn test_verify_rejects_index_name_is_unique() {
        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new("prop1", DataType::Int, None)],
            vec![
                IndexSchema::new("test", vec!["prop1"], false, false),
                IndexSchema::new("test2", vec!["prop1"], false, false),
                IndexSchema::new("test", vec!["prop1"], false, false),
            ],
            false,
        );
        assert!(schema.verify(&[]).is_err());
    }

    #[test]
    fn test_verify_object_property_has_target() {
        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new("prop1", DataType::Object, None)],
            Vec::new(),
            false,
        );
        assert!(schema.verify(&[]).is_err());
    }

    #[test]
    fn test_verify_checks_object_property_has_valid_target() {
        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new(
                "prop1",
                DataType::Object,
                Some("test2"),
            )],
            Vec::new(),
            false,
        );
        assert!(schema.verify(&[]).is_err());

        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new("prop1", DataType::Object, Some("test"))],
            Vec::new(),
            false,
        );
        assert!(schema.verify(&[]).is_err());

        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new(
                "prop1",
                DataType::ObjectList,
                Some("test2"),
            )],
            Vec::new(),
            false,
        );
        assert!(schema.verify(&[]).is_err());

        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new(
                "prop1",
                DataType::ObjectList,
                Some("test"),
            )],
            Vec::new(),
            false,
        );
        assert!(schema.verify(&[]).is_err());
    }

    #[test]
    fn test_verify_checks_non_object_property_has_no_target() {
        let schema1 = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new("prop1", DataType::Int, Some("test2"))],
            Vec::new(),
            false,
        );
        let schema2 = IsarSchema::new("test2", None, vec![], Vec::new(), false);
        assert!(schema1.verify(&[schema2]).is_err());
    }

    #[test]
    fn test_verify_checks_index_properties_not_empty() {
        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new("prop1", DataType::Int, None)],
            vec![IndexSchema::new("index", vec![], false, false)],
            false,
        );
        assert!(schema.verify(&[]).is_err());
    }

    #[test]
    fn test_verify_checks_index_properties_exist() {
        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new("prop1", DataType::Int, None)],
            vec![IndexSchema::new(
                "index",
                vec!["prop1", "prop2"],
                false,
                false,
            )],
            false,
        );
        assert!(schema.verify(&[]).is_err());
    }

    #[test]
    fn test_verify_checks_index_properties_are_not_float() {
        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new("prop1", DataType::Float, None)],
            vec![IndexSchema::new("index", vec!["prop1"], false, false)],
            false,
        );
        assert!(schema.verify(&[]).is_err());

        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new("prop1", DataType::Double, None)],
            vec![IndexSchema::new("index", vec!["prop1"], false, false)],
            false,
        );
        assert!(schema.verify(&[]).is_err());

        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new("prop1", DataType::FloatList, None)],
            vec![IndexSchema::new("index", vec!["prop1"], false, false)],
            false,
        );
        assert!(schema.verify(&[]).is_err());

        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new("prop1", DataType::DoubleList, None)],
            vec![IndexSchema::new("index", vec!["prop1"], false, false)],
            false,
        );
        assert!(schema.verify(&[]).is_err());
    }

    #[test]
    fn test_verify_checks_index_properties_are_not_object() {
        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new(
                "prop1",
                DataType::Object,
                Some("test2"),
            )],
            vec![IndexSchema::new("index", vec!["prop1"], false, false)],
            false,
        );
        let schema2 = IsarSchema::new("test2", None, vec![], vec![], true);
        assert!(schema.verify(&[schema2]).is_err());
    }

    #[test]
    fn test_verify_checks_index_properties_are_not_json() {
        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new("prop1", DataType::Json, None)],
            vec![IndexSchema::new("index", vec!["prop1"], false, false)],
            false,
        );
        assert!(schema.verify(&[]).is_err());
    }

    #[test]
    fn test_verify_checks_index_properties_are_not_list() {
        let schema = IsarSchema::new(
            "test",
            None,
            vec![PropertySchema::new("prop1", DataType::IntList, None)],
            vec![IndexSchema::new("index", vec!["prop1"], false, false)],
            false,
        );
        assert!(schema.verify(&[]).is_err());
    }

    #[test]
    fn test_verify_checks_index_properties_are_not_string_if_not_last() {
        let schema = IsarSchema::new(
            "test",
            None,
            vec![
                PropertySchema::new("prop1", DataType::Int, None),
                PropertySchema::new("prop2", DataType::String, None),
            ],
            vec![IndexSchema::new(
                "index",
                vec!["prop2", "prop1"],
                false,
                false,
            )],
            false,
        );
        assert!(schema.verify(&[]).is_err());

        let schema = IsarSchema::new(
            "test",
            None,
            vec![
                PropertySchema::new("prop1", DataType::Int, None),
                PropertySchema::new("prop2", DataType::String, None),
            ],
            vec![IndexSchema::new(
                "index",
                vec!["prop1", "prop2"],
                false,
                false,
            )],
            false,
        );
        assert!(schema.verify(&[]).is_ok());

        let schema = IsarSchema::new(
            "test",
            None,
            vec![
                PropertySchema::new("prop1", DataType::Int, None),
                PropertySchema::new("prop2", DataType::String, None),
            ],
            vec![IndexSchema::new(
                "index",
                vec!["prop2", "prop1"],
                false,
                true,
            )],
            false,
        );
        assert!(schema.verify(&[]).is_ok());
    }
}
