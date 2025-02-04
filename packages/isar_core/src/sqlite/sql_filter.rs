use super::sqlite_collection::SQLiteProperty;
use super::sqlite_query::{JsonCondition, QueryParam};
use super::sqlite3::SQLiteFnContext;
use crate::core::data_type::DataType;
use crate::core::error::Result;
use crate::core::filter::{ConditionType, Filter, FilterCondition, FilterJson};
use crate::core::filter_json::matches_json;
use crate::core::value::IsarValue;
use serde_json::Value;
use std::borrow::Cow;
use std::vec;

pub(crate) fn filter_sql<'a, G>(
    collection_index: u16,
    get_property: &G,
    filter: Filter,
) -> (String, Vec<QueryParam>)
where
    G: Fn(u16, u16) -> Option<&'a SQLiteProperty>,
{
    filter_sql_path(collection_index, get_property, filter, vec![])
}

fn filter_sql_path<'a, G>(
    collection_index: u16,
    get_property: &G,
    filter: Filter,
    mut path: Vec<String>,
) -> (String, Vec<QueryParam>)
where
    G: Fn(u16, u16) -> Option<&'a SQLiteProperty>,
{
    match filter {
        Filter::Condition(condition) => {
            let property = get_property(collection_index, condition.property_index);
            filter_condition(property, condition, path)
        }
        Filter::Json(json) => {
            let property = get_property(collection_index, json.property_index);
            filter_json(property, json)
        }
        Filter::Embedded(embedded) => {
            let property = get_property(collection_index, embedded.property_index);
            if let Some(property) = property {
                if let Some(collection_index) = property.collection_index {
                    path.push(property.name.clone());
                    return filter_sql_path(collection_index, get_property, *embedded.filter, path);
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
                    filter_sql_path(collection_index, get_property, filter, path.clone());
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
                    filter_sql_path(collection_index, get_property, filter, path.clone());
                sql.push_str(&filter_sql);
                params.extend(filter_params.into_iter());
            }
            (format!("({})", sql), params)
        }
        Filter::Not(filter) => {
            let (sql, params) = filter_sql_path(collection_index, get_property, *filter, path);
            (format!("NOT {}", sql), params)
        }
    }
}

fn filter_condition(
    property: Option<&SQLiteProperty>,
    condition: FilterCondition,
    mut path: Vec<String>,
) -> (String, Vec<QueryParam>) {
    let property_type = property.map(|p| p.data_type).unwrap_or(DataType::Long);
    let property_name = property
        .map(|p| p.name.as_str())
        .unwrap_or(SQLiteProperty::ID_NAME);
    if !path.is_empty() {
        let column_name = path.remove(0);
        path.push(property_name.to_string());
        let sql = format!("{}({}, ?)", FN_FILTER_JSON_NAME, column_name);
        let condition = JsonCondition {
            path,
            condition_type: condition.condition_type,
            values: condition.values,
            case_sensitive: condition.case_sensitive,
        };
        (sql, vec![QueryParam::JsonCondition(condition)])
    } else if property_type.is_list() {
        if condition.condition_type == ConditionType::IsNull {
            (format!("{} IS NULL", property_name), vec![])
        } else {
            let sql = format!(
                "({} IS NOT NULL AND {}({}, ?))",
                property_name, FN_FILTER_JSON_NAME, property_name
            );
            let condition = JsonCondition {
                path: vec![],
                condition_type: condition.condition_type,
                values: condition.values,
                case_sensitive: condition.case_sensitive,
            };
            (sql, vec![QueryParam::JsonCondition(condition)])
        }
    } else {
        filter_condition_type(&property_name, &condition).unwrap_or(("FALSE".to_string(), vec![]))
    }
}

fn filter_json(property: Option<&SQLiteProperty>, json: FilterJson) -> (String, Vec<QueryParam>) {
    if let Some(property) = property {
        if property.data_type == DataType::Json {
            let sql = format!("{}({}, ?)", property.name, FN_FILTER_JSON_NAME);
            let condition = JsonCondition {
                path: json.path,
                condition_type: json.condition_type,
                values: json.values,
                case_sensitive: json.case_sensitive,
            };
            return (sql, vec![QueryParam::JsonCondition(condition)]);
        }
    }
    ("FALSE".to_string(), vec![])
}

fn filter_condition_type(
    property_name: &str,
    condition: &FilterCondition,
) -> Option<(String, Vec<QueryParam>)> {
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
                    "({} < ?{} OR {} IS NULL)",
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
                    "({} <= ?{} OR {} IS NULL)",
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
                    "({} <= ?{} OR {} IS NULL)",
                    property_name, collate, property_name
                )
            } else {
                format!("{} IS NULL", property_name)
            }
        }
        ConditionType::StringStartsWith => {
            if let Some(IsarValue::String(prefix)) = condition.values.get(0)? {
                values.push(IsarValue::String(format!("{}%", escape_wildcard(prefix))));
                match condition.case_sensitive {
                    true => format!("{} LIKE ? ESCAPE '\\'", property_name),
                    false => format!("LOWER({}) LIKE LOWER(?) ESCAPE '\\'", property_name),
                }
            } else {
                "FALSE".to_string()
            }
        }
        ConditionType::StringEndsWith => {
            if let Some(IsarValue::String(postfix)) = condition.values.get(0)? {
                values.push(IsarValue::String(format!("%{}", escape_wildcard(postfix))));
                match condition.case_sensitive {
                    true => format!("{} LIKE ? ESCAPE '\\'", property_name),
                    false => format!("LOWER({}) LIKE LOWER(?) ESCAPE '\\'", property_name),
                }
            } else {
                "FALSE".to_string()
            }
        }
        ConditionType::StringContains => {
            if let Some(IsarValue::String(needle)) = condition.values.get(0)? {
                values.push(IsarValue::String(format!("%{}%", escape_wildcard(needle))));
                match condition.case_sensitive {
                    true => format!("{} LIKE ? ESCAPE '\\'", property_name),
                    false => format!("LOWER({}) LIKE LOWER(?) ESCAPE '\\'", property_name),
                }
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
                match condition.case_sensitive {
                    true => format!("{} LIKE ? ESCAPE '\\'", property_name),
                    false => format!("LOWER({}) LIKE LOWER(?) ESCAPE '\\'", property_name),
                }
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

pub(crate) const FN_FILTER_JSON_NAME: &str = "isar_filter_json";
pub(crate) const FN_FILTER_JSON_COND_PTR_TYPE: &[u8] = b"json_condition_ptr\0";
pub(crate) fn sql_fn_filter_json(ctx: &mut SQLiteFnContext) -> Result<()> {
    let json = if let Some(json) = ctx.get_auxdata::<Value>(0) {
        Cow::Borrowed(json)
    } else {
        let json_str = ctx.get_str(0);
        let json = serde_json::from_str::<Value>(json_str).unwrap_or(Value::Null);
        Cow::Owned(Box::new(json))
    };

    let condition = ctx.get_object::<JsonCondition>(1, FN_FILTER_JSON_COND_PTR_TYPE);

    if let Some(condition) = condition {
        let result = matches_json(
            &json,
            condition.condition_type,
            &condition.path,
            &condition.values,
            condition.case_sensitive,
        );
        ctx.set_int_result(if result { 1 } else { 0 });
    }

    if let Cow::Owned(mut json) = json {
        ctx.set_auxdata(0, json.take());
    }

    Ok(())
}
