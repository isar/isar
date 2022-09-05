use crate::error::{schema_error, IsarError, Result};
use crate::object::data_type::DataType;
use crate::object::property::Property;
use crate::schema::index_schema::{IndexSchema, IndexType};
use crate::schema::link_schema::LinkSchema;
use crate::schema::property_schema::PropertySchema;
use itertools::Itertools;
use serde::{Deserialize, Serialize};

use super::schema_manager::SchemaManager;

#[derive(Serialize, Deserialize, Clone, Eq)]
pub struct CollectionSchema {
    pub(crate) name: String,
    #[serde(default)]
    pub(crate) embedded: bool,
    pub(crate) properties: Vec<PropertySchema>,
    #[serde(default)]
    pub(crate) indexes: Vec<IndexSchema>,
    #[serde(default)]
    pub(crate) links: Vec<LinkSchema>,
    #[serde(default)]
    pub(crate) version: u8,
}

impl PartialEq for CollectionSchema {
    fn eq(&self, other: &Self) -> bool {
        self.name == other.name && self.embedded == other.embedded
    }
}

impl CollectionSchema {
    pub fn new(
        name: &str,
        embedded: bool,
        properties: Vec<PropertySchema>,
        indexes: Vec<IndexSchema>,
        links: Vec<LinkSchema>,
    ) -> CollectionSchema {
        CollectionSchema {
            name: name.to_string(),
            embedded,
            properties,
            indexes,
            links,
            version: SchemaManager::ISAR_FILE_VERSION,
        }
    }

    fn verify_name(name: &str) -> Result<()> {
        if name.is_empty() {
            schema_error("Empty names are not allowed.")
        } else if name.starts_with('_') {
            schema_error("Names must not begin with an underscore.")
        } else {
            Ok(())
        }
    }

    pub(crate) fn verify(&self, collections: &[CollectionSchema]) -> Result<()> {
        Self::verify_name(&self.name)?;

        if self.embedded && (!self.links.is_empty() || !self.indexes.is_empty()) {
            schema_error("Embedded objects must not have Links or Indexes.")?;
        }

        let verify_target_col_exists = |col: &str, embedded: bool| -> Result<()> {
            if !collections
                .iter()
                .any(|c| c.name == col && c.embedded == embedded)
            {
                schema_error("Target collection does not exist.")?;
            }
            Ok(())
        };

        for property in &self.properties {
            if let Some(name) = &property.name {
                Self::verify_name(name)?;
            }

            if property.data_type == DataType::Object || property.data_type == DataType::ObjectList
            {
                if let Some(target_col) = &property.target_col {
                    verify_target_col_exists(target_col, true)?;
                } else {
                    schema_error("Object property must have a target collection.")?;
                }
            } else {
                if property.target_col.is_some() {
                    schema_error("Target collection can only be set for object properties.")?;
                }
            }
        }

        for link in &self.links {
            Self::verify_name(&link.name)?;
            verify_target_col_exists(&link.target_col, false)?;
        }

        let property_names = self
            .properties
            .iter()
            .unique_by(|p| p.name.as_ref().unwrap());
        if property_names.count() != self.properties.len() {
            schema_error("Duplicate property name")?;
        }

        let index_names = self.indexes.iter().unique_by(|i| i.name.as_str());
        if index_names.count() != self.indexes.len() {
            schema_error("Duplicate index name")?;
        }

        let link_names = self.links.iter().unique_by(|l| l.name.as_str());
        if link_names.count() != self.links.len() {
            schema_error("Duplicate link name")?;
        }

        for index in &self.indexes {
            if index.properties.is_empty() {
                schema_error("At least one property needs to be added to a valid index")?;
            } else if index.properties.len() > 3 {
                schema_error("No more than three properties may be used as a composite index")?;
            }

            if !index.unique && index.replace {
                schema_error("Only unique indexes can replace")?;
            }

            for (i, index_property) in index.properties.iter().enumerate() {
                let property = self
                    .properties
                    .iter()
                    .find(|p| p.name.as_ref() == Some(&index_property.name));
                if property.is_none() {
                    schema_error("IsarIndex property does not exist")?;
                }
                let property = property.unwrap();

                if property.data_type == DataType::Object
                    || property.data_type == DataType::ObjectList
                {
                    schema_error("Object and ObjectList cannot be indexed.")?;
                }

                if property.data_type == DataType::Float
                    || property.data_type == DataType::Double
                    || property.data_type == DataType::FloatList
                    || property.data_type == DataType::DoubleList
                {
                    if index_property.index_type == IndexType::Hash {
                        schema_error("Float values cannot be hashed.")?;
                    } else if i != index.properties.len() - 1 {
                        schema_error(
                            "Float indexes must only be at the end of a composite index.",
                        )?;
                    }
                }

                if property.data_type.get_element_type().is_some() {
                    if index.properties.len() > 1 && index_property.index_type != IndexType::Hash {
                        schema_error("Composite list indexes are not supported.")?;
                    }
                } else if property.data_type == DataType::String
                    && i != index.properties.len() - 1
                    && index_property.index_type != IndexType::Hash
                {
                    schema_error(
                        "Non-hashed string indexes must only be at the end of a composite index.",
                    )?;
                }

                if property.data_type != DataType::String
                    && property.data_type.get_element_type().is_none()
                    && index_property.index_type == IndexType::Hash
                {
                    schema_error("Only string and list indexes may be hashed")?;
                }
                if property.data_type != DataType::StringList
                    && index_property.index_type == IndexType::HashElements
                {
                    schema_error("Only string list indexes may be use hash elements")?;
                }
                if property.data_type != DataType::String
                    && property.data_type != DataType::StringList
                    && index_property.case_sensitive
                {
                    schema_error("Only String and StringList indexes may be case sensitive.")?;
                }
            }
        }

        Ok(())
    }

    pub(crate) fn merge_properties(&mut self, existing: &Self) -> Result<Vec<String>> {
        let mut properties = existing.properties.clone();
        let mut removed_properties = vec![];

        for property in &mut properties {
            if property.name.is_some() && !self.properties.contains(property) {
                removed_properties.push(property.name.take().unwrap());
            }
        }
        for property in &self.properties {
            if !properties.contains(property) {
                properties.push(property.clone())
            }
        }

        self.properties = properties;

        Ok(removed_properties)
    }

    pub fn get_properties(&self) -> Vec<Property> {
        let mut properties = vec![];
        let mut offset = 2;
        for property_schema in self.properties.iter() {
            let property = property_schema.as_property(offset);
            if let Some(property) = property {
                properties.push(property);
            }
            offset += property_schema.data_type.get_static_size();
        }

        properties.sort_by(|a, b| a.name.cmp(&b.name));
        properties
    }

    pub fn to_json_bytes(&self) -> Result<Vec<u8>> {
        serde_json::to_vec(self).map_err(|_| IsarError::SchemaError {
            message: "Could not serialize schema.".to_string(),
        })
    }
}

/*#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add_property_empty_name() {
        let mut col = CollectionSchema::new("col");
        assert!(col.add_property("", DataType::Int).is_err())
    }

    #[test]
    fn test_add_property_duplicate_name() {
        let mut col = CollectionSchema::new("col");
        col.add_property("prop", DataType::Int).unwrap();
        assert!(col.add_property("prop", DataType::Int).is_err())
    }

    #[test]
    fn test_add_property_same_type_wrong_order() {
        let mut col = CollectionSchema::new("col");

        col.add_property("b", DataType::Int).unwrap();
        assert!(col.add_property("a", DataType::Int).is_err())
    }

    #[test]
    fn test_add_property_wrong_order() {
        let mut col = CollectionSchema::new("col");

        col.add_property("a", DataType::Long).unwrap();
        assert!(col.add_property("b", DataType::Int).is_err())
    }

    #[test]
    fn test_add_index_without_properties() {
        let mut col = CollectionSchema::new("col");

        assert!(col.add_index(&[], false, false).is_err())
    }

    #[test]
    fn test_add_index_with_non_existing_property() {
        let mut col = CollectionSchema::new("col");
        col.add_property("prop1", DataType::Int).unwrap();

        col.add_index(&["prop1"], false, false).unwrap();
        assert!(col.add_index(&["wrongprop"], false, false).is_err())
    }

    #[test]
    fn test_add_index_with_illegal_data_type() {
        let mut col = CollectionSchema::new("col");
        col.add_property("byte", DataType::Byte).unwrap();
        col.add_property("int", DataType::Int).unwrap();
        col.add_property("float", DataType::Float).unwrap();
        col.add_property("long", DataType::Long).unwrap();
        col.add_property("double", DataType::Double).unwrap();
        col.add_property("str", DataType::String).unwrap();
        col.add_property("byteList", DataType::ByteList).unwrap();
        col.add_property("intList", DataType::IntList).unwrap();

        col.add_index(&["byte"], false, None, false).unwrap();
        col.add_index(&["int"], false, None, false).unwrap();
        col.add_index(&["float"], false, None, false).unwrap();
        col.add_index(&["long"], false, None, false).unwrap();
        col.add_index(&["double"], false, None, false).unwrap();
        col.add_index(&["str"], false, Some(StringIndexType::Value), false)
            .unwrap();
        assert!(col.add_index(&["byteList"], false, false).is_err());
        assert!(col.add_index(&["intList"], false, false).is_err());
    }

    #[test]
    fn test_add_index_too_many_properties() {
        let mut col = CollectionSchema::new("col");
        col.add_property("prop1", DataType::Int).unwrap();
        col.add_property("prop2", DataType::Int).unwrap();
        col.add_property("prop3", DataType::Int).unwrap();
        col.add_property("prop4", DataType::Int).unwrap();

        assert!(col
            .add_index(&["prop1", "prop2", "prop3", "prop4"], false, false)
            .is_err())
    }

    #[test]
    fn test_add_duplicate_index() {
        let mut col = CollectionSchema::new("col");
        col.add_property("prop1", DataType::Int).unwrap();
        col.add_property("prop2", DataType::Int).unwrap();

        col.add_index(&["prop2"], false, false).unwrap();
        col.add_index(&["prop1", "prop2"], false, false).unwrap();
        assert!(col.add_index(&["prop1", "prop2"], false, false).is_err());
        assert!(col.add_index(&["prop1"], false, false).is_err());
    }

    #[test]
    fn test_add_composite_index_with_non_hashed_string_in_the_middle() {
        let mut col = CollectionSchema::new("col");
        col.add_property("int", DataType::Int).unwrap();
        col.add_property("str", DataType::String).unwrap();

        col.add_index(&["int", "str"], false, false).unwrap();
        assert!(col.add_index(&["str", "int"], false, false).is_err());
        col.add_index(&["str", "int"], false, true).unwrap();
    }

    #[test]
    fn test_properties_have_correct_offset() {
        fn get_offsets(mut schema: CollectionSchema) -> Vec<usize> {
            let mut get_id = || 1;
            schema.update_with_existing_collections(&[], &mut get_id);
            let col = schema.get_isar_collection();
            let mut offsets = vec![];
            for i in 0..schema.properties.len() {
                let (_, p) = col.get_properties().get(i).unwrap();
                offsets.push(p.offset);
            }
            offsets
        }

        let mut col = CollectionSchema::new("col");
        col.add_property("byte", DataType::Byte).unwrap();
        col.add_property("int", DataType::Int).unwrap();
        col.add_property("double", DataType::Double).unwrap();
        assert_eq!(get_offsets(col), vec![0, 2, 10]);

        let mut col = CollectionSchema::new("col");
        col.add_property("byte1", DataType::Byte).unwrap();
        col.add_property("byte2", DataType::Byte).unwrap();
        col.add_property("byte3", DataType::Byte).unwrap();
        col.add_property("str", DataType::String).unwrap();
        assert_eq!(get_offsets(col), vec![0, 1, 2, 10]);

        let mut col = CollectionSchema::new("col");
        col.add_property("byteList", DataType::ByteList).unwrap();
        col.add_property("intList", DataType::IntList).unwrap();
        col.add_property("doubleList", DataType::DoubleList)
            .unwrap();
        assert_eq!(get_offsets(col), vec![2, 10, 18]);
    }

    #[test]
    fn update_with_no_existing_collection() {
        let mut col = CollectionSchema::new("col");
        col.add_property("byte", DataType::Byte).unwrap();
        col.add_property("int", DataType::Int).unwrap();
        col.add_index(&["byte"], true, false).unwrap();
        col.add_index(&["int"], true, false).unwrap();

        let mut counter = 0;
        let mut get_id = || {
            counter += 1;
            counter
        };
        col.update_with_existing_collections(&[], &mut get_id);

        assert_eq!(col.id, Some(1));
        assert_eq!(col.indexes[0].id, Some(2));
        assert_eq!(col.indexes[1].id, Some(3));
    }

    #[test]
    fn update_with_existing_collection() {
        let mut counter = 0;
        let mut get_id = || {
            counter += 1;
            counter
        };

        let mut col1 = CollectionSchema::new("col");
        col1.add_property("byte", DataType::Byte).unwrap();
        col1.add_property("int", DataType::Int).unwrap();
        col1.add_index(&["byte"], true, false).unwrap();
        col1.add_index(&["int"], true, false).unwrap();

        col1.update_with_existing_collections(&[], &mut get_id);
        assert_eq!(col1.id, Some(1));
        assert_eq!(col1.indexes[0].id, Some(2));
        assert_eq!(col1.indexes[1].id, Some(3));

        let mut col2 = CollectionSchema::new("col");
        col2.add_property("byte", DataType::Byte).unwrap();
        col2.add_property("int", DataType::Int).unwrap();
        col2.add_index(&["byte"], true, false).unwrap();
        col2.add_index(&["int", "byte"], true, false).unwrap();

        col2.update_with_existing_collections(&[col1], &mut get_id);
        assert_eq!(col2.id, Some(1));
        assert_eq!(col2.indexes[0].id, Some(2));
        assert_eq!(col2.indexes[1].id, Some(4));

        let mut col3 = CollectionSchema::new("col3");
        col3.update_with_existing_collections(&[col2], &mut get_id);
        assert_eq!(col3.id, Some(5));
    }
}
*/
