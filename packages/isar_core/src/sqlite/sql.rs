use std::borrow::Cow;

use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use crate::core::data_type::DataType;
use crate::core::filter::{ConditionType, Filter, FilterCondition};
use crate::core::schema::{CollectionSchema, IndexSchema, PropertySchema};
use crate::core::value::IsarValue;
use itertools::Itertools;

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
        sql.push_str(" OFFSET ");
        sql.push_str(&offset.to_string());
    }
    if let Some(limit) = limit {
        sql.push_str(" LIMIT ");
        sql.push_str(&limit.to_string());
    }
    sql
}

fn value_sql(value: &IsarValue) -> String {
    match value {
        IsarValue::Bool(b) => {
            if let Some(b) = b {
                if *b {
                    "TRUE".to_string()
                } else {
                    "FALSE".to_string()
                }
            } else {
                "NULL".to_string()
            }
        }
        IsarValue::Integer(i) => {
            if *i != i64::MIN {
                i.to_string()
            } else {
                "NULL".to_string()
            }
        }
        IsarValue::Real(r) => {
            if r.is_nan() {
                "NULL".to_string()
            } else if r.is_infinite() {
                if r.is_sign_positive() {
                    "9e999".to_string()
                } else {
                    "-9e999".to_string()
                }
            } else {
                r.to_string()
            }
        }
        IsarValue::String(s) => {
            if let Some(s) = s {
                let mut escaped = s.replace("'", "''");
                escaped.insert(0, '\'');
                escaped.push('\'');
                escaped
            } else {
                "NULL".to_string()
            }
        }
    }
}

pub fn filter_sql(collection: &SQLiteCollection, filter: Filter) -> String {
    match filter {
        Filter::Condition(condition) => {
            condition_sql(collection, &condition).unwrap_or("FALSE".to_string())
        }
        Filter::Nested(_) => todo!(),
        Filter::And(filters) => {
            let mut sql = String::new();
            for filter in filters {
                if !sql.is_empty() {
                    sql.push_str(" AND ");
                }
                sql.push_str(&filter_sql(collection, filter));
            }
            format!("({})", sql)
        }
        Filter::Or(filters) => {
            let mut sql = String::new();
            for filter in filters {
                if !sql.is_empty() {
                    sql.push_str(" OR ");
                }
                sql.push_str(&filter_sql(collection, filter));
            }
            format!("({})", sql)
        }
        Filter::Not(filter) => {
            let sql = filter_sql(collection, *filter);
            format!("NOT ({})", sql)
        }
    }
}

fn condition_sql(collection: &SQLiteCollection, condition: &FilterCondition) -> Option<String> {
    let prop_name = collection.get_property_name(condition.property_index);
    let collate = if condition.case_sensitive {
        ""
    } else {
        " COLLATE NOCASE"
    };

    let sql = match condition.condition_type {
        ConditionType::IsNull => format!("{} IS NULL", prop_name),
        ConditionType::ListIsEmpty => todo!(),
        ConditionType::Equal => {
            let value = condition.values.get(0)?;
            if value.is_null() {
                format!("{} IS NULL", prop_name)
            } else {
                format!("{} = {}{}", prop_name, value_sql(value), collate)
            }
        }
        ConditionType::Greater => {
            let value = condition.values.get(0)?;
            if value.is_null() {
                format!("{} IS NOT NULL", prop_name)
            } else {
                format!("{} > {}", prop_name, value_sql(value))
            }
        }
        ConditionType::GreaterOrEqual => {
            let value = condition.values.get(0)?;
            if value.is_null() {
                "TRUE".to_string()
            } else {
                format!("{} >= {}", prop_name, value_sql(value))
            }
        }
        ConditionType::Less => {
            let value = condition.values.get(0)?;
            if value.is_null() {
                "FALSE".to_string()
            } else {
                format!(
                    "{} < {} OR {} IS NULL",
                    prop_name,
                    value_sql(value),
                    prop_name
                )
            }
        }
        ConditionType::LessOrEqual => {
            let value = condition.values.get(0)?;
            if value.is_null() {
                format!("{} IS NULL", prop_name)
            } else {
                format!(
                    "{} <= {} OR {} IS NULL",
                    prop_name,
                    value_sql(value),
                    prop_name
                )
            }
        }
        ConditionType::Between => {
            let lower = condition.values.get(0)?;
            let upper = condition.values.get(1)?;
            if lower.is_null() {
                if upper.is_null() {
                    format!("{} IS NULL", prop_name)
                } else {
                    format!(
                        "{} <= {} OR {} IS NULL",
                        prop_name,
                        value_sql(upper),
                        prop_name
                    )
                }
            } else if upper.is_null() {
                format!("{} >= {}", prop_name, value_sql(lower))
            } else {
                format!(
                    "{} BETWEEN {} AND {}",
                    prop_name,
                    value_sql(lower),
                    value_sql(upper)
                )
            }
        }
        ConditionType::StringStartsWith => format!(
            "{} LIKE '{}%' {}",
            prop_name,
            value_sql(condition.values.get(0)?),
            collate
        ),
        ConditionType::StringEndsWith => format!(
            "{} LIKE '%{}' {}",
            prop_name,
            value_sql(condition.values.get(0)?),
            collate
        ),
        ConditionType::StringContains => format!(
            "{} LIKE '%{}%' {}",
            prop_name,
            value_sql(condition.values.get(0)?),
            collate
        ),
        ConditionType::StringMatches => format!(
            "{} LIKE {} {}",
            prop_name,
            value_sql(condition.values.get(0)?),
            collate
        ),
    };
    Some(sql)
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
