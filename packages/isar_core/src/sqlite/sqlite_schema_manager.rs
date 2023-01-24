use super::sqlite3::SQLite3;
use crate::core::data_type::DataType;
use crate::core::error::Result;
use crate::core::schema::{CollectionSchema, IndexSchema, IsarSchema, PropertySchema};
use itertools::Itertools;
use std::borrow::Cow;
use xxhash_rust::xxh3::xxh3_64;

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
            "CREATE TABLE {} ({}) ",
            collection.name,
            collection
                .properties
                .iter()
                .filter_map(|p| {
                    if let Some(name) = &p.name {
                        let sql_type = get_sqlite_type(p);
                        Some(format!("{name} {sql_type}"))
                    } else {
                        None
                    }
                })
                .join(", ")
        );
        self.sqlite.execute(&sql)
    }

    fn create_index(&self, table_name: &str, index: &IndexSchema) -> Result<()> {
        let index_name = format!("{}_{}", table_name, index.name);
        let sql = format!(
            "CREATE {} INDEX {} ON {} ({})",
            if index.unique { "UNIQUE" } else { "" },
            index_name,
            table_name,
            index.properties.join(", ")
        );
        self.sqlite.execute(&sql)?;

        Ok(())
    }

    fn find_changes<'b>(
        &self,
        collection: &'b CollectionSchema,
    ) -> Result<(
        Vec<&'b PropertySchema>,
        Vec<String>,
        Vec<&'b IndexSchema>,
        Vec<String>,
    )> {
        let mut add_properties = Vec::new();
        let mut drop_properties = Vec::new();
        let mut add_indexes = Vec::new();
        let mut drop_indexes = Vec::new();

        let columns = self.sqlite.get_table_columns(&collection.name)?;
        let indexes = self.sqlite.get_table_indexes(&collection.name)?;

        for (col_name, col_type) in &columns {
            let prop = collection
                .properties
                .iter()
                .find(|p| p.name.as_deref() == Some(col_name));
            if let Some(prop) = prop {
                let sql_type = get_sqlite_type(prop);
                if col_type != &sql_type {
                    add_properties.push(prop);
                    drop_properties.push(col_name.clone());
                }
            } else {
                drop_properties.push(col_name.clone());
            }
        }

        for property in &collection.properties {
            if let Some(prop_name) = &property.name {
                let does_not_exist = !columns.iter().any(|(name, _)| name == prop_name);
                if does_not_exist {
                    add_properties.push(property);
                }
            }
        }

        for (index_name, unique, cols) in &indexes {
            let index = collection
                .indexes
                .iter()
                .find(|i| &format!("{}_{}", collection.name, i.name) == index_name);
            if let Some(index) = index {
                let property_dropped = index.properties.iter().any(|p| drop_properties.contains(p));
                if index.unique != *unique || &index.properties != cols || property_dropped {
                    add_indexes.push(index);
                    drop_indexes.push(index_name.clone());
                }
            } else {
                drop_indexes.push(index_name.clone());
            }
        }

        for index in &collection.indexes {
            let index_name = format!("{}_{}", collection.name, index.name);
            let does_not_exist = !indexes.iter().any(|(name, _, _)| name == &index_name);
            if does_not_exist {
                add_indexes.push(index);
            }
        }

        Ok((add_properties, drop_properties, add_indexes, drop_indexes))
    }

    fn update_table(&self, collection: &CollectionSchema) -> Result<()> {
        let (add_properties, drop_properties, add_indexes, drop_indexes) =
            self.find_changes(collection)?;

        for index in drop_indexes {
            let sql = format!("DROP INDEX {}", index);
            self.sqlite.execute(&sql)?;
        }

        for property in &drop_properties {
            let sql = format!("ALTER TABLE {} DROP COLUMN {}", collection.name, property);
            self.sqlite.execute(&sql)?;
        }

        for property in &add_properties {
            let sql = format!(
                "ALTER TABLE {} ADD COLUMN {} {}",
                collection.name,
                property.name.as_ref().unwrap(),
                get_sqlite_type(property)
            );
            self.sqlite.execute(&sql)?;
        }

        for index in &add_indexes {
            self.create_index(&collection.name, index)?;
        }

        Ok(())
    }
}

fn get_sqlite_type(property: &PropertySchema) -> Cow<str> {
    match property.data_type {
        DataType::Bool => Cow::Borrowed("U1"),
        DataType::Byte => Cow::Borrowed("U8"),
        DataType::Int => Cow::Borrowed("I32"),
        DataType::Float => Cow::Borrowed("F32"),
        DataType::Long => Cow::Borrowed("I64"),
        DataType::Double => Cow::Borrowed("F64"),
        DataType::String => Cow::Borrowed("STR"),
        DataType::Object => {
            let target_collection = property.collection.as_ref().unwrap();
            let target_hash = xxh3_64(target_collection.as_bytes());
            Cow::Owned(format!("OBJ({target_hash})"))
        }
        DataType::BoolList => Cow::Borrowed("U1[]"),
        DataType::ByteList => Cow::Borrowed("U8[]"),
        DataType::IntList => Cow::Borrowed("I32[]"),
        DataType::FloatList => Cow::Borrowed("F32[]"),
        DataType::LongList => Cow::Borrowed("I64[]"),
        DataType::DoubleList => Cow::Borrowed("F64[]"),
        DataType::StringList => Cow::Borrowed("STR[]"),
        DataType::ObjectList => {
            let target_collection = property.collection.as_ref().unwrap();
            let target_hash = xxh3_64(target_collection.as_bytes());
            Cow::Owned(format!("OBJ({target_hash})[]"))
        }
    }
}
