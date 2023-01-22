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

    pub(crate) fn hash(&mut self) -> u64 {
        self.collections.sort_by(|a, b| a.name.cmp(&b.name));
        self.collections
            .iter()
            .fold(0, |seed, col| xxh3_64_with_seed(col.name.as_bytes(), seed))
    }
}
