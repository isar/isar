use itertools::Itertools;

use super::sqlite3::SQLite3;
use crate::core::{
    error::Result,
    schema::{CollectionSchema, IndexSchema, IsarSchema},
};

pub struct SQLiteSchemaManager<'a> {
    sqlite: &'a SQLite3,
}

impl<'a> SQLiteSchemaManager<'a> {
    pub fn new(sqlite: &SQLite3) -> SQLiteSchemaManager {
        SQLiteSchemaManager { sqlite }
    }

    pub fn perform_migration(&self, schema: &IsarSchema) -> Result<()> {
        let table_names = self.sqlite.get_table_names()?;
        for collection in &schema.collections {
            if table_names.contains(&collection.name) {
                self.update_table(collection)?;
            } else {
                self.create_table(collection)?;
                for index in &collection.indexes {
                    self.create_index(&collection.name, index)?;
                }
            }
        }
        for table in table_names {
            if !schema.collections.iter().any(|c| c.name == table) {
                let sql = format!("DROP TABLE {}", table);
                self.sqlite.execute(&sql)?;
            }
        }

        Ok(())
    }

    fn create_table(&self, collection: &CollectionSchema) -> Result<()> {
        let sql = format!(
            "CREATE TABLE {} ({}) STRICT",
            collection.name,
            collection
                .properties
                .iter()
                .filter_map(|p| p.name.as_ref())
                .map(|p| format!("{} ANY", p))
                .join(", ")
        );
        self.sqlite.execute(&sql)
    }

    fn create_index(&self, collection_name: &str, index: &IndexSchema) -> Result<()> {
        let index_name = format!("{}_{}", collection_name, index.name);
        let sql = format!(
            "CREATE {} INDEX {} ON {} ({})",
            if index.unique { "UNIQUE" } else { "" },
            index_name,
            collection_name,
            index.properties.join(", ")
        );
        self.sqlite.execute(&sql)
    }

    fn update_table(&self, collection: &CollectionSchema) -> Result<()> {
        let col_names = self.sqlite.get_table_columns(&collection.name)?;
        let indexes = self.sqlite.get_table_indexes(&collection.name)?;
        for prop in &collection.properties {
            if let Some(prop_name) = &prop.name {
                if !col_names.contains(prop_name) {
                    let sql = format!("ALTER TABLE {} ADD COLUMN {}", collection.name, prop_name);
                    self.sqlite.execute(&sql)?;
                }
            }
        }

        for index in &collection.indexes {
            let index_name = format!("{}_{}", collection.name, index.name);
            let existing_index = indexes.iter().find(|(name, _, _)| name == &index_name);
            let index_equals = if let Some((_, unique, cols)) = existing_index {
                *unique == index.unique && cols == &index.properties
            } else {
                false
            };
            if existing_index.is_some() && !index_equals {
                let sql = format!("DROP INDEX {}", index_name);
                self.sqlite.execute(&sql)?;
            }
            if existing_index.is_none() || !index_equals {
                self.create_index(&collection.name, index)?;
            }
        }

        for (index_name, _, _) in indexes {
            let index_defined = collection
                .indexes
                .iter()
                .any(|i| format!("{}_{}", collection.name, i.name) == index_name);
            if !index_defined {
                let sql = format!("DROP INDEX {}", index_name);
                self.sqlite.execute(&sql)?;
            }
        }

        for col in col_names {
            let col_defined = collection
                .properties
                .iter()
                .any(|p| p.name.as_deref() == Some(&col));
            if !col_defined {
                let sql = format!("ALTER TABLE {} DROP COLUMN {}", collection.name, col);
                self.sqlite.execute(&sql)?;
            }
        }

        Ok(())
    }
}
