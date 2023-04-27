use super::sqlite3::SQLite3;
use super::sqlite_txn::SQLiteTxn;
use crate::core::data_type::DataType;
use crate::core::error::Result;
use crate::core::schema::{CollectionSchema, IndexSchema, IsarSchema, PropertySchema};
use itertools::Itertools;
use std::borrow::Cow;

pub fn perform_migration(txn: &SQLiteTxn, schema: &IsarSchema) -> Result<()> {
    /*txn.guard(|| {
        let sqlite = txn.get_sqlite(true)?;
        let table_names = sqlite.get_table_names()?;
        for collection in &schema.collections {
            if !collection.embedded {
                if table_names.contains(&collection.name) {
                    update_table(sqlite, collection)?;
                } else {
                    let sql = create_table_sql(collection);
                    sqlite.execute(&sql)?;
                    for index in &collection.indexes {
                        let sql = create_index_sql(&collection.name, index);
                        sqlite.execute(&sql)?;
                    }
                }
            }
        }

        for table in table_names {
            if !schema
                .collections
                .iter()
                .any(|c| c.name == table && !c.embedded)
            {
                let sql = format!("DROP TABLE {}", table);
                sqlite.execute(&sql)?;
            }
        }

        Ok(())
    })*/
    todo!()
}

fn create_table_sql(collection: &CollectionSchema) -> String {
    format!(
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
    )
}

fn create_index_sql(table_name: &str, index: &IndexSchema) -> String {
    let index_name = format!("{}_{}", table_name, index.name);
    format!(
        "CREATE {} INDEX {}_{} ON {} ({})",
        if index.unique { "UNIQUE" } else { "" },
        index_name,
        table_name,
        table_name,
        index.properties.join(", ")
    )
}

fn read_col_schema(sqlite: &SQLite3, name: &str) -> Result<CollectionSchema> {
    let columns = sqlite.get_table_columns(name)?;
    let indexes = sqlite.get_table_indexes(name)?;

    let properties = columns
        .iter()
        .map(|(name, sql_type)| {
            let (data_type, collection) = get_data_type(sql_type);
            PropertySchema::new(name, data_type, collection)
        })
        .collect();

    let indexes = indexes
        .iter()
        .map(|(name, unique, cols)| {
            let name = name.split('_').last().unwrap();
            let cols = cols.iter().map(|c| c.as_str()).collect();
            IndexSchema::new(name, cols, *unique)
        })
        .collect();

    Ok(CollectionSchema::new(name, properties, indexes, false))
}

fn update_table(sqlite: &SQLite3, collection: &CollectionSchema) -> Result<()> {
    let existing_schema = read_col_schema(sqlite, &collection.name)?;
    let (add_properties, drop_properties, add_indexes, drop_indexes) =
        collection.find_changes(&existing_schema);

    for (index, _) in drop_indexes {
        let sql = format!("DROP INDEX {}_{}", collection.name, index);
        sqlite.execute(&sql)?;
    }

    for property in &drop_properties {
        let sql = format!("ALTER TABLE {} DROP COLUMN {}", collection.name, property);
        sqlite.execute(&sql)?;
    }

    for property in &add_properties {
        let sql = format!(
            "ALTER TABLE {} ADD COLUMN {} {}",
            collection.name,
            property.name.as_ref().unwrap(),
            get_sqlite_type(property)
        );
        sqlite.execute(&sql)?;
    }

    for index in &add_indexes {
        let sql = create_index_sql(&collection.name, index);
        sqlite.execute(&sql)?;
    }

    Ok(())
}

fn get_sqlite_type(property: &PropertySchema) -> Cow<str> {
    match property.data_type {
        DataType::Byte => Cow::Borrowed("_BYTE"),
        DataType::Int => Cow::Borrowed("_I32"),
        DataType::Float => Cow::Borrowed("_F32"),
        DataType::Long => Cow::Borrowed("_I64"),
        DataType::Double => Cow::Borrowed("_F64"),
        DataType::String => Cow::Borrowed("_STR"),
        DataType::Json => Cow::Borrowed("_JSON"),
        DataType::Object => Cow::Borrowed(property.collection.as_ref().unwrap()),
        DataType::ByteList => Cow::Borrowed("_BYTE[]"),
        DataType::IntList => Cow::Borrowed("_I32[]"),
        DataType::FloatList => Cow::Borrowed("_F32[]"),
        DataType::LongList => Cow::Borrowed("_I64[]"),
        DataType::DoubleList => Cow::Borrowed("_F64[]"),
        DataType::StringList => Cow::Borrowed("_STR[]"),
        DataType::ObjectList => {
            let target_collection = property.collection.as_ref().unwrap();
            Cow::Owned(format!("{target_collection}[]"))
        }
    }
}

fn get_data_type(sqlite_type: &str) -> (DataType, Option<&str>) {
    match sqlite_type {
        "_BYTE" => (DataType::Byte, None),
        "_I32" => (DataType::Int, None),
        "_F32" => (DataType::Float, None),
        "_I64" => (DataType::Long, None),
        "_F64" => (DataType::Double, None),
        "_STR" => (DataType::String, None),
        "_JSON" => (DataType::Json, None),
        "_U8[]" => (DataType::ByteList, None),
        "_I32[]" => (DataType::IntList, None),
        "_F32[]" => (DataType::FloatList, None),
        "_I64[]" => (DataType::LongList, None),
        "_F64[]" => (DataType::DoubleList, None),
        "_STR[]" => (DataType::StringList, None),
        _ => {
            if let Some(target_collection) = sqlite_type.strip_suffix("[]") {
                (DataType::ObjectList, Some(target_collection))
            } else {
                (DataType::Object, Some(sqlite_type))
            }
        }
    }
}
