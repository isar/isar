use crate::core::collection::IsarCollection;
use crate::sqlite::sqlite_collection::SQLiteCollection;

const MAX_SQLITE_VARIABLES: usize = 999;

pub fn sql_insert_bulk(collection: &SQLiteCollection, count: usize) -> (String, usize) {
    let mut sql = String::new();
    sql.push_str("INSERT INTO ");
    sql.push_str(collection.name());
    sql.push_str(" (");
    sql.push_str("_id");

    for property in collection.properties().iter() {
        sql.push_str(", c");
        sql.push_str(&property.offset.to_string());
    }

    sql.push_str(") VALUES ");

    let batch_count =
        (MAX_SQLITE_VARIABLES / (collection.properties().len() + 1)).min(count.min(50));
    let mut batch = String::new();
    batch.push_str("(?");
    for _ in 0..collection.properties().len() {
        batch.push_str(",?");
    }
    batch.push_str(")");

    sql.push_str(&batch);
    for _ in 1..batch_count {
        sql.push_str(",");
        sql.push_str(&batch);
    }

    (sql, batch_count)
}
