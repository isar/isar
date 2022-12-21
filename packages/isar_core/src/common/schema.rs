use crate::core::data_type::DataType;
use crate::core::error::schema_error;
use crate::core::error::Result;
use crate::core::schema::{CollectionSchema, IndexType, IsarSchema};
use itertools::Itertools;
use std::hash::{Hash, Hasher};
use xxhash_rust::xxh3::Xxh3;

pub fn verify_schema(schema: &IsarSchema) -> Result<()> {
    for col in &schema.collections {
        verify_collection(col, &schema.collections)?;
    }
    Ok(())
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

fn verify_collection(col: &CollectionSchema, collections: &[CollectionSchema]) -> Result<()> {
    verify_name(&col.name)?;

    if col.embedded && (!col.links.is_empty() || !col.indexes.is_empty()) {
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

    for property in &col.properties {
        if let Some(name) = &property.name {
            verify_name(name)?;
        }

        if property.data_type == DataType::Object || property.data_type == DataType::ObjectList {
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

    for link in &col.links {
        verify_name(&link.name)?;
        verify_target_col_exists(&link.target_col, false)?;
    }

    let property_names = col
        .properties
        .iter()
        .unique_by(|p| p.name.as_ref().unwrap());
    if property_names.count() != col.properties.len() {
        schema_error("Duplicate property name")?;
    }

    let index_names = col.indexes.iter().unique_by(|i| i.name.as_str());
    if index_names.count() != col.indexes.len() {
        schema_error("Duplicate index name")?;
    }

    let link_names = col.links.iter().unique_by(|l| l.name.as_str());
    if link_names.count() != col.links.len() {
        schema_error("Duplicate link name")?;
    }

    for index in &col.indexes {
        if index.properties.is_empty() {
            schema_error("At least one property needs to be added to a valid index")?;
        } else if index.properties.len() > 3 {
            schema_error("No more than three properties may be used as a composite index")?;
        }

        if !index.unique && index.replace {
            schema_error("Only unique indexes can replace")?;
        }

        for (i, index_property) in index.properties.iter().enumerate() {
            let property = col
                .properties
                .iter()
                .find(|p| p.name.as_ref() == Some(&index_property.name));
            if property.is_none() {
                schema_error("IsarIndex property does not exist")?;
            }
            let property = property.unwrap();

            if property.data_type == DataType::Object || property.data_type == DataType::ObjectList
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
                    schema_error("Float indexes must only be at the end of a composite index.")?;
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

pub fn hash_schema(schema: &mut IsarSchema) -> u64 {
    for col in &mut schema.collections {
        col.properties.sort_by(|a, b| a.name.cmp(&b.name));
        col.indexes.sort_by(|a, b| a.name.cmp(&b.name));
        col.links.sort_by(|a, b| a.name.cmp(&b.name));
    }
    schema.collections.sort_by(|a, b| a.name.cmp(&b.name));
    let mut hasher = Xxh3::new();
    schema.hash(&mut hasher);
    hasher.finish()
}
