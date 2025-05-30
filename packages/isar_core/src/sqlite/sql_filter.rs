use super::sql_functions::{FN_FILTER_JSON_NAME, FN_MATCHES_REGEX_NAME};
use super::sqlite_collection::SQLiteProperty;
use super::sqlite_query::{JsonCondition, QueryParam};
use crate::core::data_type::DataType;
use crate::core::filter::{ConditionType, Filter, FilterCondition, FilterJson};
use crate::core::value::IsarValue;
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
            let property = get_property(collection_index, json.condition.property_index);
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
                condition_type: json.condition.condition_type,
                values: json.condition.values,
                case_sensitive: json.condition.case_sensitive,
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

    let mut params = vec![];
    let sql = match condition.condition_type {
        ConditionType::IsNull => format!("{} IS NULL", property_name),
        ConditionType::Equal => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                params.push(QueryParam::Value(value.clone()));
                format!("{} = ?{}", property_name, collate)
            } else {
                format!("{} IS NULL", property_name)
            }
        }
        ConditionType::Greater => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                params.push(QueryParam::Value(value.clone()));
                format!("{} > ?{}", property_name, collate)
            } else {
                format!("{} IS NOT NULL", property_name)
            }
        }
        ConditionType::GreaterOrEqual => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                params.push(QueryParam::Value(value.clone()));
                format!("{} >= ?{}", property_name, collate)
            } else {
                "TRUE".to_string()
            }
        }
        ConditionType::Less => {
            let value = condition.values.get(0)?;
            if let Some(value) = value {
                params.push(QueryParam::Value(value.clone()));
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
                params.push(QueryParam::Value(value.clone()));
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
                    params.push(QueryParam::Value(lower.clone()));
                    params.push(QueryParam::Value(upper.clone()));
                    format!("{} BETWEEN ?{} AND ?{}", property_name, collate, collate)
                } else {
                    params.push(QueryParam::Value(lower.clone()));
                    format!("{} >= ?{}", property_name, collate)
                }
            } else if let Some(upper) = upper {
                params.push(QueryParam::Value(upper.clone()));
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
                let value = IsarValue::String(format!("{}%", escape_wildcard(prefix)));
                params.push(QueryParam::Value(value));
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
                let value = IsarValue::String(format!("%{}", escape_wildcard(postfix)));
                params.push(QueryParam::Value(value));
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
                let value = IsarValue::String(format!("%{}%", escape_wildcard(needle)));
                params.push(QueryParam::Value(value));
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
                params.push(QueryParam::Value(IsarValue::String(wildcard)));
                match condition.case_sensitive {
                    true => format!("{} LIKE ? ESCAPE '\\'", property_name),
                    false => format!("LOWER({}) LIKE LOWER(?) ESCAPE '\\'", property_name),
                }
            } else {
                "FALSE".to_string()
            }
        }
        ConditionType::StringRegex => {
            let value = condition.values.get(0)?;
            if let Some(IsarValue::String(regex)) = value {
                params.push(QueryParam::Value(IsarValue::String(regex.clone())));
                let case_sensitive = if condition.case_sensitive {
                    "TRUE"
                } else {
                    "FALSE"
                };
                format!(
                    "{}(?, {}, {})",
                    FN_MATCHES_REGEX_NAME, case_sensitive, property_name
                )
            } else {
                "FALSE".to_string()
            }
        }
        ConditionType::In => {
            if condition.values.is_empty() {
                "FALSE".to_string()
            } else {
                let in_sql = "?,".repeat(condition.values.len() - 1);
                let sql = format!("{}{} IN ({}?)", property_name, collate, in_sql);
                for value in condition.values.iter() {
                    if let Some(value) = value {
                        params.push(QueryParam::Value(value.clone()));
                    } else {
                        params.push(QueryParam::Null);
                    }
                }
                sql
            }
        }
    };

    Some((sql, params))
}

fn escape_wildcard(wildcard: &str) -> String {
    wildcard
        .replace("\\", "\\\\")
        .replace("%", "\\%")
        .replace("_", "\\_")
}
