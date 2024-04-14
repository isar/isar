use super::sql::{
    add_column_sql, create_index_sql, create_table_sql, drop_column_sql, drop_index_sql,
    sql_data_type,
};
use super::sqlite3::SQLite3;
use super::sqlite_txn::SQLiteTxn;
use crate::core::error::{IsarError, Result};
use crate::core::schema::{IndexSchema, IsarSchema, PropertySchema};
use crate::sqlite::sqlite_collection::SQLiteProperty;
use itertools::Itertools;

pub(crate) fn perform_migration(txn: &SQLiteTxn, schemas: &[IsarSchema]) -> Result<()> {
    txn.guard(|| {
        let sqlite = txn.get_sqlite(true)?;
        let table_names = sqlite.get_table_names()?;

        for collection in schemas {
            if !collection.embedded {
                if table_names.contains(&collection.name) {
                    update_table(sqlite, collection)?;
                } else {
                    let sql = create_table_sql(collection);
                    sqlite.prepare(&sql)?.step()?;
                    for index in &collection.indexes {
                        let sql = create_index_sql(&collection.name, index);
                        sqlite.prepare(&sql)?.step()?;
                    }
                }
            }
        }

        for table in table_names {
            if !schemas.iter().any(|c| c.name == table && !c.embedded) {
                let sql = format!("DROP TABLE {}", table);
                sqlite.prepare(&sql)?.step()?;
            }
        }

        Ok(())
    })
}

fn read_col_schema(sqlite: &SQLite3, name: &str) -> Result<IsarSchema> {
    let columns = sqlite.get_table_columns(name)?;
    let indexes = sqlite.get_table_indexes(name)?;

    let mut properties = columns
        .iter()
        .map(|(name, sql_type)| {
            let (data_type, collection) = sql_data_type(sql_type);
            PropertySchema::new(name, data_type, collection)
        })
        .collect_vec();

    let id_prop_index = properties
        .iter()
        .position(|p| p.name == Some(SQLiteProperty::ID_NAME.to_string()));
    if let Some(id_prop_index) = id_prop_index {
        properties.remove(id_prop_index);
    } else {
        return Err(IsarError::SchemaError {
            message: format!("Table {} has no id column", name),
        });
    }

    let indexes = indexes
        .iter()
        .map(|(name, unique, cols)| {
            let name = name.split('_').last().unwrap();
            let cols = cols.iter().map(|c| c.as_str()).collect();
            IndexSchema::new(name, cols, *unique, false)
        })
        .collect();

    Ok(IsarSchema::new(name, None, properties, indexes, false))
}

fn update_table(sqlite: &SQLite3, collection: &IsarSchema) -> Result<()> {
    let existing_schema = read_col_schema(sqlite, &collection.name)?;
    let changes = collection.find_changes(&existing_schema);

    for index in changes.dropped_index_names {
        let sql = drop_index_sql(&collection.name, &index);
        sqlite.prepare(&sql)?.step()?;
    }

    for property in &changes.dropped_property_names {
        let sql = drop_column_sql(collection, property);
        sqlite.prepare(&sql)?.step()?;
    }

    for property in changes.added_properties {
        let sql = add_column_sql(collection, property);
        sqlite.prepare(&sql)?.step()?;
    }

    for index in changes.added_indexes {
        let sql = create_index_sql(&collection.name, index);
        sqlite.prepare(&sql)?.step()?;
    }

    Ok(())
}
