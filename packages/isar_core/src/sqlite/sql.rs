use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use crate::core::data_type::DataType;
use crate::core::filter::{ConditionType, Filter, FilterCondition};
use crate::core::schema::{CollectionSchema, IndexSchema, PropertySchema};
use crate::core::value::IsarValue;
use itertools::Itertools;
use std::borrow::Cow;
use std::vec;

pub(crate) fn create_table_sql(collection: &CollectionSchema) -> String {
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

pub(crate) fn create_index_sql(table_name: &str, index: &IndexSchema) -> String {
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

pub(crate) fn select_properties_sql(collection: &SQLiteCollection) -> String {
    let mut sql = String::new();
    sql.push_str(SQLiteProperty::ID_NAME);
    for prop in &collection.properties {
        sql.push(',');
        sql.push_str(&prop.name);
    }
    sql
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

pub fn filter_sql(collection: &SQLiteCollection, filter: Filter) -> (String, Vec<IsarValue>) {
    match filter {
        Filter::Condition(condition) => {
            condition_sql(collection, &condition).unwrap_or(("FALSE".to_string(), vec![]))
        }
        Filter::Nested(_) => todo!(),
        Filter::And(filters) => {
            let mut sql = String::new();
            let mut values = vec![];
            for filter in filters {
                if !sql.is_empty() {
                    sql.push_str(" AND ");
                }
                let (filter_sql, filter_values) = filter_sql(collection, filter);
                sql.push_str(&filter_sql);
                values.extend_from_slice(&filter_values);
            }
            (format!("({})", sql), values)
        }
        Filter::Or(filters) => {
            let mut sql = String::new();
            let mut values = vec![];
            for filter in filters {
                if !sql.is_empty() {
                    sql.push_str(" OR ");
                }
                let (filter_sql, filter_values) = filter_sql(collection, filter);
                sql.push_str(&filter_sql);
                values.extend_from_slice(&filter_values);
            }
            (format!("({})", sql), values)
        }
        Filter::Not(filter) => {
            let (sql, values) = filter_sql(collection, *filter);
            (format!("NOT ({})", sql), values)
        }
    }
}

fn condition_sql(
    collection: &SQLiteCollection,
    condition: &FilterCondition,
) -> Option<(String, Vec<IsarValue>)> {
    let property_name = collection.get_property_name(condition.property_index);
    let collate = if condition.case_sensitive {
        ""
    } else {
        "COLLATE NOCASE"
    };

    let mut values = vec![];
    let sql = match condition.condition_type {
        ConditionType::IsNull => format!("{} IS NULL", property_name),
        ConditionType::ListIsEmpty => todo!(),
        ConditionType::Equal => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                values.push(value.clone());
                format!("{} = ? {}", property_name, collate)
            } else {
                format!("{} IS NULL", property_name)
            }
        }
        ConditionType::Greater => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                values.push(value.clone());
                format!("{} > ?", property_name)
            } else {
                format!("{} IS NOT NULL", property_name)
            }
        }
        ConditionType::GreaterOrEqual => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                values.push(value.clone());
                format!("{} >= ?", property_name)
            } else {
                "TRUE".to_string()
            }
        }
        ConditionType::Less => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                values.push(value.clone());
                format!("{} < ? OR {} IS NULL", property_name, property_name)
            } else {
                "FALSE".to_string()
            }
        }
        ConditionType::LessOrEqual => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                values.push(value.clone());
                format!("{} <= ? OR {} IS NULL", property_name, property_name)
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
                    format!("{} BETWEEN ? AND ?", property_name)
                } else {
                    values.push(lower.clone());
                    format!("{} >= ?", property_name)
                }
            } else if let Some(upper) = upper {
                values.push(upper.clone());
                format!("{} <= ? OR {} IS NULL", property_name, property_name)
            } else {
                format!("{} IS NULL", property_name)
            }
        }
        ConditionType::StringStartsWith => {
            if let Some(IsarValue::String(prefix)) = condition.values.get(0)? {
                values.push(IsarValue::String(format!("{}%", escape_wildcard(prefix))));
                format!("{} LIKE ? {} ESCAPE '\\'", property_name, collate)
            } else {
                "FALSE".to_string()
            }
        }
        ConditionType::StringEndsWith => {
            if let Some(IsarValue::String(postfix)) = condition.values.get(0)? {
                values.push(IsarValue::String(format!("%{}", escape_wildcard(postfix))));
                format!("{} LIKE ? {} ESCAPE '\\'", property_name, collate)
            } else {
                "FALSE".to_string()
            }
        }
        ConditionType::StringContains => {
            if let Some(IsarValue::String(needle)) = condition.values.get(0)? {
                values.push(IsarValue::String(format!("%{}%", escape_wildcard(needle))));
                format!("{} LIKE ? {} ESCAPE '\\'", property_name, collate)
            } else {
                "FALSE".to_string()
            }
        }
        ConditionType::StringMatches => {
            if let Some(IsarValue::String(wildcard)) = condition.values.get(0)? {
                let wildcard = wildcard
                    .replace("\\", "\\\\")
                    .replace("*", "%")
                    .replace("?", "_");
                values.push(IsarValue::String(wildcard));
                format!("{} LIKE ? {} ESCAPE '\\'", property_name, collate)
            } else {
                "FALSE".to_string()
            }
        }
    };
    Some((sql, values))
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
    match sqlite_type.to_lowercase().as_str() {
        "bool" => (DataType::Bool, None),
        "u8" => (DataType::Byte, None),
        "i32" => (DataType::Int, None),
        "f32" => (DataType::Float, None),
        "i64" => (DataType::Long, None),
        "f64" => (DataType::Double, None),
        "str" => (DataType::String, None),
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
