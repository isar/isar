pub mod collection_schema;
pub mod index_schema;
pub mod link_schema;
pub(crate) mod migrate_v1;
pub mod property_schema;
pub(crate) mod schema_manager;

use crate::error::{schema_error, Result};
use crate::schema::collection_schema::CollectionSchema;
use itertools::Itertools;
use serde::{Deserialize, Serialize};
use xxhash_rust::xxh3::xxh3_64_with_seed;

#[derive(Serialize, Deserialize, Clone)]
pub struct Schema {
    pub(crate) collections: Vec<CollectionSchema>,
}

impl Schema {
    pub fn new(collections: Vec<CollectionSchema>) -> Result<Schema> {
        let collection_names = collections.iter().unique_by(|c| &c.name);
        if collection_names.count() != collections.len() {
            schema_error("Duplicate collection name")?;
        }
        for col in &collections {
            col.verify(&collections)?;
        }

        let schema = Schema { collections };
        Ok(schema)
    }

    pub fn from_json(json: &[u8]) -> Result<Schema> {
        if let Ok(collections) = serde_json::from_slice::<Vec<CollectionSchema>>(json) {
            Schema::new(collections)
        } else {
            schema_error("Could not deserialize schema JSON")
        }
    }

    pub(crate) fn get_collection(&self, name: &str, embedded: bool) -> Option<&CollectionSchema> {
        self.collections
            .iter()
            .find(|c| c.name == name && c.embedded == embedded)
    }

    pub(crate) fn count_dbs(&self) -> usize {
        let mut count = 0;
        for col in &self.collections {
            count += 1;
            count += col.indexes.len();
            count += col.links.len() * 2;
        }
        count
    }
}

/*#[cfg(test)]
mod tests {
    use super::*;
    use crate::object::data_type::DataType;

    #[test]
    fn test_add_collection() {
        let mut schema = Schema::new();

        let col1 = CollectionSchema::new("col");
        schema.add_collection(col1).unwrap();

        let col2 = CollectionSchema::new("other");
        schema.add_collection(col2).unwrap();

        let duplicate = CollectionSchema::new("col");
        assert!(schema.add_collection(duplicate).is_err());
    }

    #[test]
    fn test_update_with_existing_schema() -> Result<()> {
        let mut schema1 = Schema::new();
        let mut col = CollectionSchema::new("col");
        col.add_property("byteProperty", DataType::Byte)?;
        col.add_property("intProperty", DataType::Int)?;
        col.add_property("longProperty", DataType::Long)?;
        col.add_property("stringProperty", DataType::String)?;
        col.add_index(&["byteProperty"], false, false)?;
        col.add_index(&["intProperty", "byteProperty"], true, false)?;
        col.add_index(&["longProperty"], false, false)?;
        col.add_index(&["intProperty", "longProperty"], false, false)?;
        col.add_index(&["stringProperty"], false, true)?;
        schema1.add_collection(col)?;

        let mut counter = 0;
        let get_id = || {
            counter += 1;
            counter
        };
        schema1.update_with_existing_schema_internal(None, get_id);
        let col = &schema1.collections[0];
        assert_eq!(col.id, Some(1));
        assert_eq!(col.indexes[0].id, Some(2));
        assert_eq!(col.indexes[1].id, Some(3));
        assert_eq!(col.indexes[2].id, Some(4));
        assert_eq!(col.indexes[3].id, Some(5));
        assert_eq!(col.indexes[4].id, Some(6));

        let mut schema2 = Schema::new();
        let mut col = CollectionSchema::new("col");
        col.add_property("byteProperty", DataType::Byte)?;
        col.add_property("intProperty", DataType::Int)?;
        col.add_property("longProperty", DataType::Double)?; // changed type
        col.add_property("stringProperty", DataType::String)?;
        col.add_index(&["byteProperty"], false, false)?;
        col.add_index(&["intProperty", "byteProperty"], false, false)?; // changed unique
        col.add_index(&["longProperty"], false, false)?; // changed property type
        col.add_index(&["intProperty", "longProperty"], false, false)?; // changed property type-
        col.add_index(&["stringProperty"], false, false)?; // changed hash_value
        schema2.add_collection(col)?;

        let mut counter = 0;
        let get_id = || {
            counter += 1;
            counter
        };
        schema2.update_with_existing_schema_internal(Some(&schema1), get_id);
        let col = &schema2.collections[0];
        assert_eq!(col.id, Some(1));
        assert_eq!(col.indexes[0].id, Some(2));
        assert_eq!(col.indexes[1].id, Some(7));
        assert_eq!(col.indexes[2].id, Some(8));
        assert_eq!(col.indexes[3].id, Some(9));
        assert_eq!(col.indexes[4].id, Some(10));

        Ok(())
    }
}
*/
