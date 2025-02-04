use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use super::sqlite_query::QueryParam;
use super::sqlite3::SQLite3;
use crate::core::data_type::DataType;
use crate::core::schema::{IndexSchema, IsarSchema, PropertySchema};
use crate::core::value::IsarValue;
use itertools::Itertools;
use std::borrow::Cow;
use std::cmp::min;
use std::vec;

pub(crate) fn create_table_sql(collection: &IsarSchema) -> String {
    format!(
        "CREATE TABLE {} ({} INTEGER PRIMARY KEY {}) ",
        collection.name,
        SQLiteProperty::ID_NAME,
        collection
            .properties
            .iter()
            .filter_map(|p| {
                if let Some(name) = &p.name {
                    Some(format!(", {} {}", name, data_type_sql(&p)))
                } else {
                    None
                }
            })
            .join("")
    )
}

pub(crate) fn add_column_sql(collection: &IsarSchema, property: &PropertySchema) -> String {
    format!(
        "ALTER TABLE {} ADD COLUMN {} {}",
        collection.name,
        property.name.as_ref().unwrap(),
        data_type_sql(property)
    )
}

pub(crate) fn drop_column_sql(collection: &IsarSchema, property_name: &str) -> String {
    format!(
        "ALTER TABLE {} DROP COLUMN {}",
        collection.name, property_name
    )
}

pub(crate) fn create_index_sql(table_name: &str, index: &IndexSchema) -> String {
    format!(
        "CREATE {} INDEX {}_{} ON {} ({})",
        if index.unique { "UNIQUE" } else { "" },
        table_name,
        index.name,
        table_name,
        index.properties.join(", ")
    )
}

pub(crate) fn drop_index_sql(table_name: &str, index_name: &str) -> String {
    format!("DROP INDEX {}_{}", table_name, index_name)
}

pub(crate) fn select_properties_sql(collection: &SQLiteCollection) -> String {
    let mut sql = String::new();
    sql.push_str(SQLiteProperty::ID_NAME);
    for prop in &collection.properties {
        sql.push(',');
        sql.push_str(&prop.name);
    }
    sql
}

pub(crate) fn insert_sql(name: &str, properties: &[SQLiteProperty], count: u32) -> (u32, String) {
    let mut sql = String::new();
    sql.push_str("INSERT OR REPLACE INTO ");
    sql.push_str(name);
    sql.push_str(" (");
    sql.push_str(SQLiteProperty::ID_NAME);

    for property in properties {
        sql.push_str(", ");
        sql.push_str(&property.name);
    }

    sql.push_str(") VALUES ");

    let mut batch = String::new();
    batch.push_str("(?");
    for _ in 0..properties.len() {
        batch.push_str(",?");
    }
    batch.push_str(")");

    let batch_size = min(
        count,
        SQLite3::MAX_PARAM_COUNT / (properties.len() as u32 + 1),
    );
    sql.push_str(&batch);
    for _ in 1..batch_size {
        sql.push_str(",");
        sql.push_str(&batch);
    }

    (batch_size, sql)
}

pub(crate) fn update_properties_sql(
    collection: &SQLiteCollection,
    updates: &[(u16, Option<IsarValue>)],
) -> (String, Vec<QueryParam>) {
    let mut sql = String::new();
    let mut params = vec![];
    for (prop, change) in updates.iter() {
        if let Some(property) = collection.get_property(*prop) {
            if !sql.is_empty() {
                sql.push(',');
            }
            sql.push_str(&property.name);
            if let Some(value) = change {
                sql.push_str("=?");
                params.push(QueryParam::Value(value.clone()));
            } else {
                sql.push_str("=NULL");
            }
        }
    }
    (sql, params)
}

pub(crate) fn offset_limit_sql(offset: Option<u32>, limit: Option<u32>) -> String {
    let mut sql = String::new();
    if let Some(offset) = offset {
        sql.push_str(&format!("LIMIT {}, {}", offset, limit.unwrap_or(u32::MAX)));
    } else if let Some(limit) = limit {
        sql.push_str(&format!("LIMIT {}", limit));
    }
    sql
}

pub(crate) fn data_type_sql(property: &PropertySchema) -> Cow<str> {
    match property.data_type {
        DataType::Bool => Cow::Borrowed("bool"),
        DataType::Byte => Cow::Borrowed("u8"),
        DataType::Int => Cow::Borrowed("i32"),
        DataType::Float => Cow::Borrowed("f32"),
        DataType::Long => Cow::Borrowed("i64"),
        DataType::Double => Cow::Borrowed("f64"),
        DataType::String => Cow::Borrowed("str"),
        DataType::Json => Cow::Borrowed("json"),
        DataType::Object => Cow::Borrowed(property.collection.as_ref().unwrap()),
        DataType::BoolList => Cow::Borrowed("bool[]"),
        DataType::ByteList => Cow::Borrowed("u8[]"),
        DataType::IntList => Cow::Borrowed("i32[]"),
        DataType::FloatList => Cow::Borrowed("f32[]"),
        DataType::LongList => Cow::Borrowed("i64[]"),
        DataType::DoubleList => Cow::Borrowed("f64[]"),
        DataType::StringList => Cow::Borrowed("str[]"),
        DataType::ObjectList => {
            let target_collection = property.collection.as_ref().unwrap();
            Cow::Owned(format!("{target_collection}[]"))
        }
    }
}

pub(crate) fn sql_data_type(sqlite_type: &str) -> (DataType, Option<&str>) {
    match sqlite_type.to_ascii_lowercase().as_str() {
        "bool" => (DataType::Bool, None),
        "u8" => (DataType::Byte, None),
        "i32" => (DataType::Int, None),
        "f32" => (DataType::Float, None),
        "i64" => (DataType::Long, None),
        "f64" => (DataType::Double, None),
        "str" => (DataType::String, None),
        "json" => (DataType::Json, None),
        "bool[]" => (DataType::BoolList, None),
        "u8[]" => (DataType::ByteList, None),
        "i32[]" => (DataType::IntList, None),
        "f32[]" => (DataType::FloatList, None),
        "i64[]" => (DataType::LongList, None),
        "f64[]" => (DataType::DoubleList, None),
        "str[]" => (DataType::StringList, None),
        _ => {
            if let Some(target_collection) = sqlite_type.strip_suffix("[]") {
                (DataType::ObjectList, Some(target_collection))
            } else {
                (DataType::Object, Some(sqlite_type))
            }
        }
    }
}
