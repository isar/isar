use crate::core::collection::IsarCollection;
use crate::core::property::IsarProperty;
use crate::sqlite::sqlite_collection::SQLiteCollection;

const MAX_SQLITE_VARIABLES: usize = 999;

pub fn sql_insert_bulk(collection: &str, properties: &[IsarProperty], count: usize) -> String {
    let mut sql = String::new();
    sql.push_str("INSERT INTO ");
    sql.push_str(collection);
    sql.push_str(" (");
    sql.push_str("_id");

    for property in properties.iter() {
        sql.push_str(", c");
        sql.push_str(&property.offset.to_string());
    }

    sql.push_str(") VALUES ");

    let mut batch = String::new();
    batch.push_str("(?");
    for _ in 0..properties.len() {
        batch.push_str(",?");
    }
    batch.push_str(")");

    sql.push_str(&batch);
    for _ in 1..count {
        sql.push_str(",");
        sql.push_str(&batch);
    }

    sql
}
