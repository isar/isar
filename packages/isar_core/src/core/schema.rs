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
    use std::vec;

    use super::*;

    fn props_schema(props: Vec<PropertySchema>) -> IsarSchema {
        index_schema(props, vec![])
    }

    fn index_schema(props: Vec<PropertySchema>, indexes: Vec<IndexSchema>) -> IsarSchema {
        IsarSchema::new("test", None, props, indexes, false)
    }

    mod name_validation {
        use super::*;

        #[test]
        fn test_valid_collection_name() {
            let schema = props_schema(Vec::new());
            assert!(schema.verify(&[]).is_ok());
        }

        #[test]
        fn test_invalid_collection_names() {
            let invalid_names = vec![
                "sqlite_test_table",
                "_hidden",
                "",
                "sqlite_sequence",
                "_internal",
            ];

            for name in invalid_names {
                let schema = IsarSchema::new(name, None, vec![], vec![], false);
                assert!(
                    schema.verify(&[]).is_err(),
                    "Name '{}' should be invalid",
                    name
                );
            }
        }
    }

    mod embedded_objects {
        use super::*;

        #[test]
        fn test_embedded_objects_cannot_have_indexes() {
            let schema = IsarSchema::new(
                "test",
                None,
                vec![PropertySchema::new("prop1", DataType::Int, None)],
                vec![IndexSchema::new("index", vec!["prop1"], false, false)],
                true, // embedded
            );
            assert!(schema.verify(&[]).is_err());
        }

        #[test]
        fn test_object_list_property_validation() {
            let embedded = IsarSchema::new("embedded", None, vec![], vec![], true);

            // Valid: target is an embedded collection
            let schema = props_schema(vec![PropertySchema::new(
                "prop1",
                DataType::ObjectList,
                Some("embedded"),
            )]);
            assert!(schema.verify(&[embedded.clone()]).is_ok());

            // Invalid: target is not embedded
            let non_embedded = IsarSchema::new("target", None, vec![], vec![], false);
            let schema = props_schema(vec![PropertySchema::new(
                "prop1",
                DataType::ObjectList,
                Some("target"),
            )]);
            assert!(schema.verify(&[non_embedded]).is_err());

            // Invalid: target doesn't exist
            let schema = props_schema(vec![PropertySchema::new(
                "prop1",
                DataType::ObjectList,
                Some("nonexistent"),
            )]);
            assert!(schema.verify(&[embedded]).is_err());
        }
    }

    mod property_validation {
        use super::*;

        #[test]
        fn test_duplicate_property_names() {
            let schema = props_schema(vec![
                PropertySchema::new("test", DataType::Int, None),
                PropertySchema::new("test2", DataType::Int, None),
                PropertySchema::new("test", DataType::String, None),
            ]);
            assert!(schema.verify(&[]).is_err());
        }

        #[test]
        fn test_object_property_target_validation() {
            let schema = props_schema(vec![PropertySchema::new("prop1", DataType::Object, None)]);
            assert!(
                schema.verify(&[]).is_err(),
                "Object property must have target"
            );

            let schema = props_schema(vec![PropertySchema::new(
                "prop1",
                DataType::Int,
                Some("test2"),
            )]);
            assert!(
                schema.verify(&[]).is_err(),
                "Non-object property must not have target"
            );
        }
    }

    mod index_validation {
        use super::*;

        #[test]
        fn test_composite_index_validation() {
            let schema = index_schema(
                vec![
                    PropertySchema::new("int1", DataType::Int, None),
                    PropertySchema::new("bool1", DataType::Bool, None),
                    PropertySchema::new("str1", DataType::String, None),
                ],
                vec![
                    // Valid: string at end of non-hashed index
                    IndexSchema::new("index1", vec!["int1", "bool1", "str1"], false, false),
                    // Valid: hashed index with any property order
                    IndexSchema::new("index2", vec!["int1", "str1", "bool1"], false, true),
                ],
            );
            assert!(schema.verify(&[]).is_ok());
        }

        #[test]
        fn test_string_property_position() {
            let schema = index_schema(
                vec![
                    PropertySchema::new("int1", DataType::Int, None),
                    PropertySchema::new("str1", DataType::String, None),
                ],
                vec![
                    // Invalid: string not at end in non-hashed index
                    IndexSchema::new("index", vec!["str1", "int1"], false, false),
                ],
            );
            assert!(schema.verify(&[]).is_err());
        }

        #[test]
        fn test_hashed_index_with_multiple_strings() {
            let schema = index_schema(
                vec![
                    PropertySchema::new("str1", DataType::String, None),
                    PropertySchema::new("str2", DataType::String, None),
                    PropertySchema::new("str3", DataType::String, None),
                ],
                vec![IndexSchema::new(
                    "index",
                    vec!["str1", "str2", "str3"],
                    false,
                    true, // hashed
                )],
            );
            assert!(schema.verify(&[]).is_ok());
        }

        #[test]
        fn test_unique_index_validation() {
            let schema = index_schema(
                vec![
                    PropertySchema::new("prop1", DataType::Int, None),
                    PropertySchema::new("prop2", DataType::String, None),
                ],
                vec![
                    IndexSchema::new("index1", vec!["prop1"], true, false),
                    IndexSchema::new("index2", vec!["prop1", "prop2"], true, false),
                ],
            );
            assert!(schema.verify(&[]).is_ok());
        }

        #[test]
        fn test_duplicate_index_names() {
            let schema = index_schema(
                vec![PropertySchema::new("prop1", DataType::Int, None)],
                vec![
                    IndexSchema::new("index", vec!["prop1"], false, false),
                    IndexSchema::new("index", vec!["prop1"], true, false),
                ],
            );
            assert!(schema.verify(&[]).is_err());
        }
    }

    mod schema_changes {
        use super::*;

        #[test]
        fn test_no_changes() {
            let old_schema = index_schema(
                vec![
                    PropertySchema::new("prop1", DataType::Int, None),
                    PropertySchema::new("prop2", DataType::String, None),
                ],
                vec![IndexSchema::new("index1", vec!["prop1"], false, false)],
            );

            let new_schema = old_schema.clone();
            let (add_props, drop_props, add_indexes, drop_indexes) =
                new_schema.find_changes(&old_schema);

            assert!(add_props.is_empty());
            assert!(drop_props.is_empty());
            assert!(add_indexes.is_empty());
            assert!(drop_indexes.is_empty());
        }

        #[test]
        fn test_add_property() {
            let prop1 = PropertySchema::new("prop1", DataType::Int, None);
            let prop2 = PropertySchema::new("prop2", DataType::String, None);
            let old_schema = props_schema(vec![prop1.clone()]);
            let new_schema = props_schema(vec![prop1.clone(), prop2.clone()]);

            let (add_props, drop_props, add_indexes, drop_indexes) =
                new_schema.find_changes(&old_schema);

            assert_eq!(add_props, vec![&prop2]);
            assert!(drop_props.is_empty());
            assert!(add_indexes.is_empty());
            assert!(drop_indexes.is_empty());
        }

        #[test]
        fn test_remove_property() {
            let prop1 = PropertySchema::new("prop1", DataType::Int, None);
            let prop2 = PropertySchema::new("prop2", DataType::String, None);
            let old_schema = props_schema(vec![prop1.clone(), prop2.clone()]);
            let new_schema = props_schema(vec![prop1.clone()]);

            let (add_props, drop_props, add_indexes, drop_indexes) =
                new_schema.find_changes(&old_schema);

            assert!(add_props.is_empty());
            assert_eq!(drop_props, vec!["prop2"]);
            assert!(add_indexes.is_empty());
            assert!(drop_indexes.is_empty());
        }

        #[test]
        fn test_change_property_type() {
            let prop1 = PropertySchema::new("prop1", DataType::Int, None);
            let prop2 = PropertySchema::new("prop2", DataType::String, None);
            let old_schema = props_schema(vec![prop1.clone()]);
            let new_schema = props_schema(vec![prop2.clone()]);

            let (add_props, drop_props, add_indexes, drop_indexes) =
                new_schema.find_changes(&old_schema);

            assert_eq!(add_props, vec![&prop2]);
            assert_eq!(drop_props, vec!["prop1"]);
            assert!(add_indexes.is_empty());
            assert!(drop_indexes.is_empty());
            assert!(drop_indexes.is_empty());
        }

        #[test]
        fn test_change_object_property_target() {
            let old_prop = PropertySchema::new("prop1", DataType::Object, Some("embedded"));
            let old_schema = props_schema(vec![old_prop.clone()]);

            let new_prop = PropertySchema::new("prop1", DataType::Object, Some("embedded2"));
            let new_schema = props_schema(vec![new_prop.clone()]);

            let (add_props, drop_props, add_indexes, drop_indexes) =
                new_schema.find_changes(&old_schema);

            assert_eq!(add_props, vec![&new_prop]);
            assert_eq!(drop_props, vec!["prop1"]);
            assert!(add_indexes.is_empty());
            assert!(drop_indexes.is_empty());
        }

        #[test]
        fn test_add_index() {
            let prop = PropertySchema::new("prop1", DataType::Int, None);
            let index = IndexSchema::new("index1", vec!["prop1"], false, false);
            let old_schema = props_schema(vec![prop.clone()]);
            let new_schema = index_schema(vec![prop.clone()], vec![index.clone()]);

            let (add_props, drop_props, add_indexes, drop_indexes) =
                new_schema.find_changes(&old_schema);

            assert!(add_props.is_empty());
            assert!(drop_props.is_empty());
            assert_eq!(add_indexes, vec![&index]);
            assert!(drop_indexes.is_empty());
        }

        #[test]
        fn test_remove_index() {
            let prop = PropertySchema::new("prop1", DataType::Int, None);
            let index = IndexSchema::new("index1", vec!["prop1"], false, false);
            let old_schema = index_schema(vec![prop.clone()], vec![index.clone()]);
            let new_schema = props_schema(vec![prop.clone()]);

            let (add_props, drop_props, add_indexes, drop_indexes) =
                new_schema.find_changes(&old_schema);

            assert!(add_props.is_empty());
            assert!(drop_props.is_empty());
            assert!(add_indexes.is_empty());
            assert_eq!(drop_indexes, vec!["index1"]);
        }

        #[test]
        fn test_change_index_properties() {
            let prop1 = PropertySchema::new("prop1", DataType::Int, None);
            let prop2 = PropertySchema::new("prop2", DataType::Int, None);
            let old_index = IndexSchema::new("index1", vec!["prop1"], false, false);
            let old_schema =
                index_schema(vec![prop1.clone(), prop2.clone()], vec![old_index.clone()]);

            let new_index = IndexSchema::new("index1", vec!["prop1", "prop2"], false, false);
            let new_schema =
                index_schema(vec![prop1.clone(), prop2.clone()], vec![new_index.clone()]);

            let (add_props, drop_props, add_indexes, drop_indexes) =
                new_schema.find_changes(&old_schema);

            assert!(add_props.is_empty());
            assert!(drop_props.is_empty());
            assert_eq!(add_indexes, vec![&new_index]);
            assert_eq!(drop_indexes, vec!["index1"]);
        }

        #[test]
        fn test_change_index_uniqueness() {
            let prop = PropertySchema::new("prop1", DataType::Int, None);
            let old_index = IndexSchema::new("index1", vec!["prop1"], false, false);
            let old_schema = index_schema(vec![prop.clone()], vec![old_index.clone()]);

            let new_index = IndexSchema::new("index1", vec!["prop1"], true, false);
            let new_schema = index_schema(vec![prop.clone()], vec![new_index.clone()]);

            let (add_props, drop_props, add_indexes, drop_indexes) =
                new_schema.find_changes(&old_schema);

            assert!(add_props.is_empty());
            assert!(drop_props.is_empty());
            assert_eq!(add_indexes, vec![&new_index]);
            assert_eq!(drop_indexes, vec!["index1"]);
        }

        #[test]
        fn test_change_index_hash() {
            let prop = PropertySchema::new("prop1", DataType::String, None);
            let old_index = IndexSchema::new("index1", vec!["prop1"], false, false);
            let old_schema = index_schema(vec![prop.clone()], vec![old_index.clone()]);

            let new_index = IndexSchema::new("index1", vec!["prop1"], false, true);
            let new_schema = index_schema(vec![prop.clone()], vec![new_index.clone()]);

            let (add_props, drop_props, add_indexes, drop_indexes) =
                new_schema.find_changes(&old_schema);

            assert!(add_props.is_empty());
            assert!(drop_props.is_empty());
            assert_eq!(add_indexes, vec![&new_index]);
            assert_eq!(drop_indexes, vec!["index1"]);
        }

        #[test]
        fn test_drop_index_when_property_changed() {
            let prop1 = PropertySchema::new("prop1", DataType::Int, None);
            let prop2 = PropertySchema::new("prop2", DataType::Int, None);
            let old_index = IndexSchema::new("index1", vec!["prop1"], false, false);
            let old_schema =
                index_schema(vec![prop1.clone(), prop2.clone()], vec![old_index.clone()]);

            let new_prop1 = PropertySchema::new("prop1", DataType::String, None);
            let new_schema = index_schema(
                vec![new_prop1.clone(), prop2.clone()],
                vec![old_index.clone()],
            );

            let (add_props, drop_props, add_indexes, drop_indexes) =
                new_schema.find_changes(&old_schema);

            assert_eq!(add_props, vec![&new_prop1]);
            assert_eq!(drop_props, vec!["prop1"]);
            assert_eq!(add_indexes, vec![&old_index]);
            assert_eq!(drop_indexes, vec!["index1"]);
        }
    }
}
