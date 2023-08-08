use super::sqlite3::{SQLite3, SQLiteFnContext};
use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use super::sqlite_query::QueryParam;
use crate::core::data_type::DataType;
use crate::core::error::Result;
use crate::core::filter::{ConditionType, Filter, FilterCondition, JsonCondition};
use crate::core::schema::{IndexSchema, IsarSchema, PropertySchema};
use crate::core::value::IsarValue;
use itertools::Itertools;
use serde_json::Value;
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

pub(crate) fn filter_sql(
    collection_index: u16,
    all_collections: &[SQLiteCollection],
    filter: Filter,
) -> (String, Vec<QueryParam>) {
    filter_sql_path(collection_index, all_collections, filter, vec![])
}

fn filter_sql_path(
    collection_index: u16,
    all_collections: &[SQLiteCollection],
    filter: Filter,
    mut path: Vec<String>,
) -> (String, Vec<QueryParam>) {
    let collection = &all_collections[collection_index as usize];
    match filter {
        Filter::Condition(condition) => {
            let is_list = collection
                .get_property(condition.property_index)
                .map_or(false, |p| p.data_type.is_list());
            let property_name = collection.get_property_name(condition.property_index);
            if !path.is_empty() {
                let first_path_part = path.remove(0);
                path.push(property_name.to_string());
                let sql = format!("{}({}, ?)", FN_FILTER_JSON_NAME, first_path_part);
                let condition = JsonCondition::new(
                    path,
                    condition.condition_type,
                    is_list,
                    condition.values,
                    condition.case_sensitive,
                );
                (sql, vec![QueryParam::JsonCondition(condition)])
            } else if is_list {
                let sql = format!("{}({}, ?)", FN_FILTER_JSON_NAME, property_name);
                let condition = JsonCondition::new(
                    vec![],
                    condition.condition_type,
                    true,
                    condition.values,
                    condition.case_sensitive,
                );
                (sql, vec![QueryParam::JsonCondition(condition)])
            } else {
                condition_sql(collection, &condition).unwrap_or(("FALSE".to_string(), vec![]))
            }
        }
        Filter::Json(_) => todo!(),
        Filter::Nested(nested) => {
            if let Some(property) = collection.get_property(nested.property_index) {
                if property.data_type == DataType::Object {
                    path.push(property.name.clone());
                    return filter_sql_path(
                        property.collection_index.unwrap(),
                        all_collections,
                        *nested.filter,
                        path,
                    );
                }
            }
            ("FALSE".to_string(), vec![])
        }
        Filter::And(filters) => {
            let mut sql = String::new();
            let mut params = vec![];
            for filter in filters {
                if !sql.is_empty() {
                    sql.push_str(" AND ");
                }
                let (filter_sql, filter_params) =
                    filter_sql_path(collection_index, all_collections, filter, path.clone());
                sql.push_str(&filter_sql);
                params.extend(filter_params.into_iter());
            }
            (format!("({})", sql), params)
        }
        Filter::Or(filters) => {
            let mut sql = String::new();
            let mut params = vec![];
            for filter in filters {
                if !sql.is_empty() {
                    sql.push_str(" OR ");
                }
                let (filter_sql, filter_params) =
                    filter_sql_path(collection_index, all_collections, filter, path.clone());
                sql.push_str(&filter_sql);
                params.extend(filter_params.into_iter());
            }
            (format!("({})", sql), params)
        }
        Filter::Not(filter) => {
            let (sql, params) = filter_sql_path(collection_index, all_collections, *filter, path);
            (format!("NOT ({})", sql), params)
        }
    }
}

fn condition_sql(
    collection: &SQLiteCollection,
    condition: &FilterCondition,
) -> Option<(String, Vec<QueryParam>)> {
    let property_name = collection.get_property_name(condition.property_index);
    let collate = if condition.case_sensitive {
        ""
    } else {
        " COLLATE NOCASE"
    };

    let mut values = vec![];
    let sql = match condition.condition_type {
        ConditionType::IsNull => format!("{} IS NULL", property_name),
        ConditionType::Equal => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                values.push(value.clone());
                format!("{} = ?{}", property_name, collate)
            } else {
                format!("{} IS NULL", property_name)
            }
        }
        ConditionType::Greater => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                values.push(value.clone());
                format!("{} > ?{}", property_name, collate)
            } else {
                format!("{} IS NOT NULL", property_name)
            }
        }
        ConditionType::GreaterOrEqual => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                values.push(value.clone());
                format!("{} >= ?{}", property_name, collate)
            } else {
                "TRUE".to_string()
            }
        }
        ConditionType::Less => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                values.push(value.clone());
                format!(
                    "{} < ?{} OR {} IS NULL",
                    property_name, collate, property_name
                )
            } else {
                "FALSE".to_string()
            }
        }
        ConditionType::LessOrEqual => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                values.push(value.clone());
                format!(
                    "{} <= ?{} OR {} IS NULL",
                    property_name, collate, property_name
                )
            } else {
                format!("{} IS NULL", property_name)
            }
        }
        ConditionType::Between => {
            let lower = condition.values.get(0)?;
            let upper = condition.values.get(1)?;
            if let Some(lower) = lower {
                if let Some(upper) = upper {
                    values.push(lower.clone());
                    values.push(upper.clone());
                    format!("{} BETWEEN ?{} AND ?{}", property_name, collate, collate)
                } else {
                    values.push(lower.clone());
                    format!("{} >= ?{}", property_name, collate)
                }
            } else if let Some(upper) = upper {
                values.push(upper.clone());
                format!(
                    "{} <= ?{} OR {} IS NULL",
                    property_name, collate, property_name
                )
            } else {
                format!("{} IS NULL", property_name)
            }
        }
        ConditionType::StringStartsWith => {
            if let Some(IsarValue::String(prefix)) = condition.values.get(0)? {
                values.push(IsarValue::String(format!("{}%", escape_wildcard(prefix))));
                format!("{} LIKE ? ESCAPE '\\'", property_name)
            } else {
                "FALSE".to_string()
            }
        }
        ConditionType::StringEndsWith => {
            if let Some(IsarValue::String(postfix)) = condition.values.get(0)? {
                values.push(IsarValue::String(format!("%{}", escape_wildcard(postfix))));
                format!("{} LIKE ? ESCAPE '\\'", property_name)
            } else {
                "FALSE".to_string()
            }
        }
        ConditionType::StringContains => {
            if let Some(IsarValue::String(needle)) = condition.values.get(0)? {
                values.push(IsarValue::String(format!("%{}%", escape_wildcard(needle))));
                format!("{} LIKE ? ESCAPE '\\'", property_name)
            } else {
                "FALSE".to_string()
            }
        }
        ConditionType::StringMatches => {
            if let Some(IsarValue::String(wildcard)) = condition.values.get(0)? {
                let wildcard = escape_wildcard(wildcard)
                    .replace("*", "%")
                    .replace("?", "_");
                values.push(IsarValue::String(wildcard));
                format!("{} LIKE ? ESCAPE '\\'", property_name)
            } else {
                "FALSE".to_string()
            }
        }
    };

    let params = values.into_iter().map(|v| QueryParam::Value(v)).collect();
    Some((sql, params))
}

fn escape_wildcard(wildcard: &str) -> String {
    wildcard
        .replace("\\", "\\\\")
        .replace("%", "\\%")
        .replace("_", "\\_")
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

pub(crate) const FN_FILTER_JSON_NAME: &str = "isar_filter_json";
pub(crate) const FN_FILTER_JSON_COND_PTR_TYPE: &[u8] = b"json_condition_ptr\0";
pub(crate) fn sql_fn_filter_json(ctx: &mut SQLiteFnContext) -> Result<()> {
    let json = ctx.get_str(0);

    let value = serde_json::from_str::<Value>(json).unwrap_or(Value::Null);
    let condition = ctx.get_object::<JsonCondition>(1, FN_FILTER_JSON_COND_PTR_TYPE);

    if let Some(condition) = condition {
        let result = condition.matches(value);
        ctx.set_int_result(if result { 1 } else { 0 });
    }

    Ok(())
}
