use super::fast_wild_match::fast_wild_match;
use super::filter::ConditionType;
use super::value::IsarValue;
use serde_json::Value;

pub fn matches_json(
    json: &Value,
    condition_type: ConditionType,
    path: &[String],
    values: &[Option<IsarValue>],
    case_sensitive: bool,
) -> bool {
    let value = extract_value(&json, &path);
    if let Some(value) = value {
        match condition_type {
            ConditionType::IsNull => value == &Value::Null,
            ConditionType::Equal => equal(value, values.get(0).unwrap_or(&None), case_sensitive),
            ConditionType::Greater => {
                greater(value, values.get(0).unwrap_or(&None), case_sensitive)
            }
            ConditionType::GreaterOrEqual => {
                greater_or_equal(value, values.get(0).unwrap_or(&None), case_sensitive)
            }
            ConditionType::Less => less(value, values.get(0).unwrap_or(&None), case_sensitive),
            ConditionType::LessOrEqual => {
                less_or_equal(value, values.get(0).unwrap_or(&None), case_sensitive)
            }
            ConditionType::Between => between(
                value,
                values.get(0).unwrap_or(&None),
                values.get(1).unwrap_or(&None),
                case_sensitive,
            ),
            ConditionType::StringStartsWith => {
                string_starts_with(value, values.get(0).unwrap_or(&None), case_sensitive)
            }
            ConditionType::StringEndsWith => {
                string_ends_with(value, values.get(0).unwrap_or(&None), case_sensitive)
            }
            ConditionType::StringContains => {
                string_contains(value, values.get(0).unwrap_or(&None), case_sensitive)
            }
            ConditionType::StringMatches => {
                string_matches(value, values.get(0).unwrap_or(&None), case_sensitive)
            }
        }
    } else {
        false
    }
}

fn extract_value<'a>(json: &'a Value, path: &[String]) -> Option<&'a Value> {
    let mut value = json;
    for key in path.iter() {
        match value {
            Value::Object(map) => value = map.get(key).unwrap_or(&Value::Null),
            Value::Array(vec) => {
                let index = key.parse::<usize>().ok()?;
                value = vec.get(index).unwrap_or(&Value::Null);
            }
            _ => return None,
        }
    }
    Some(value)
}

fn equal(value: &Value, cond_value: &Option<IsarValue>, case_sensitive: bool) -> bool {
    match (value, cond_value) {
        (Value::Null, None) => true,
        (Value::Bool(value), Some(IsarValue::Bool(cond_value))) => value == cond_value,
        (Value::Number(value), Some(IsarValue::Integer(cond_value))) => {
            value.as_i64() == Some(*cond_value)
        }
        (Value::Number(value), Some(IsarValue::Real(cond_value))) => {
            value.as_f64() == Some(*cond_value)
        }
        (Value::String(value), Some(IsarValue::String(cond_value))) => {
            if case_sensitive {
                value == cond_value
            } else {
                &value.to_lowercase() == cond_value
            }
        }
        (Value::Array(array), cond_value) => array
            .iter()
            .any(|value| equal(value, cond_value, case_sensitive)),
        _ => false,
    }
}

fn greater(value: &Value, cond_value: &Option<IsarValue>, case_sensitive: bool) -> bool {
    match (value, cond_value) {
        (Value::Bool(value), Some(IsarValue::Bool(cond_value))) => value > cond_value,
        (Value::Number(value), Some(IsarValue::Integer(cond_value))) => {
            value.as_i64() > Some(*cond_value)
        }
        (Value::Number(value), Some(IsarValue::Real(cond_value))) => {
            value.as_f64() > Some(*cond_value)
        }
        (Value::String(value), Some(IsarValue::String(cond_value))) => {
            if case_sensitive {
                value > cond_value
            } else {
                &value.to_lowercase() > cond_value
            }
        }
        (Value::Array(value), cond_value) => value
            .iter()
            .any(|value| greater(value, cond_value, case_sensitive)),
        (value, None) => !value.is_null(),
        _ => false,
    }
}

fn greater_or_equal(value: &Value, cond_value: &Option<IsarValue>, case_sensitive: bool) -> bool {
    match (value, cond_value) {
        (Value::Bool(value), Some(IsarValue::Bool(cond_value))) => value >= cond_value,
        (Value::Number(value), Some(IsarValue::Integer(cond_value))) => {
            value.as_i64() >= Some(*cond_value)
        }
        (Value::Number(value), Some(IsarValue::Real(cond_value))) => {
            value.as_f64() >= Some(*cond_value)
        }
        (Value::String(value), Some(IsarValue::String(cond_value))) => {
            if case_sensitive {
                value >= cond_value
            } else {
                &value.to_lowercase() >= cond_value
            }
        }
        (Value::Array(value), cond_value) => value
            .iter()
            .any(|value| greater_or_equal(value, cond_value, case_sensitive)),
        (_, None) => true,
        _ => false,
    }
}

fn less(value: &Value, cond_value: &Option<IsarValue>, case_sensitive: bool) -> bool {
    match (value, cond_value) {
        (Value::Null, cond_value) => cond_value.is_some(),
        (Value::Bool(value), Some(IsarValue::Bool(cond_value))) => value < cond_value,
        (Value::Number(value), Some(IsarValue::Integer(cond_value))) => {
            value.as_i64() < Some(*cond_value)
        }
        (Value::Number(value), Some(IsarValue::Real(cond_value))) => {
            value.as_f64() < Some(*cond_value)
        }
        (Value::String(value), Some(IsarValue::String(cond_value))) => {
            if case_sensitive {
                value < cond_value
            } else {
                &value.to_lowercase() < cond_value
            }
        }
        (Value::Array(value), cond_value) => value
            .iter()
            .any(|value| less(value, cond_value, case_sensitive)),
        _ => false,
    }
}

fn less_or_equal(value: &Value, cond_value: &Option<IsarValue>, case_sensitive: bool) -> bool {
    match (value, cond_value) {
        (Value::Bool(value), Some(IsarValue::Bool(cond_value))) => value <= cond_value,
        (Value::Number(value), Some(IsarValue::Integer(cond_value))) => {
            value.as_i64() <= Some(*cond_value)
        }
        (Value::Number(value), Some(IsarValue::Real(cond_value))) => {
            value.as_f64() <= Some(*cond_value)
        }
        (Value::String(value), Some(IsarValue::String(cond_value))) => {
            if case_sensitive {
                value <= cond_value
            } else {
                &value.to_lowercase() <= cond_value
            }
        }
        (Value::Array(value), cond_value) => value
            .iter()
            .any(|value| less_or_equal(value, cond_value, case_sensitive)),
        (Value::Null, _) => true,
        _ => false,
    }
}

fn between(
    value: &Value,
    lower: &Option<IsarValue>,
    upper: &Option<IsarValue>,
    case_sensitive: bool,
) -> bool {
    match (value, lower, upper) {
        (value, None, upper) => less_or_equal(value, upper, case_sensitive),
        (Value::Bool(value), Some(IsarValue::Bool(lower)), Some(IsarValue::Bool(upper))) => {
            value >= lower && value <= upper
        }
        (
            Value::Number(value),
            Some(IsarValue::Integer(lower)),
            Some(IsarValue::Integer(upper)),
        ) => value.as_i64() >= Some(*lower) && value.as_i64() <= Some(*upper),
        (Value::Number(value), Some(IsarValue::Real(lower)), Some(IsarValue::Real(upper))) => {
            value.as_f64() >= Some(*lower) && value.as_f64() <= Some(*upper)
        }
        (Value::String(value), Some(IsarValue::String(lower)), Some(IsarValue::String(upper))) => {
            if case_sensitive {
                value >= lower && value <= upper
            } else {
                let value = value.to_lowercase();
                &value >= lower && &value <= upper
            }
        }
        (Value::Array(value), lower, upper) => value
            .iter()
            .any(|value| between(value, lower, upper, case_sensitive)),
        _ => false,
    }
}

fn string_starts_with(value: &Value, cond_value: &Option<IsarValue>, case_sensitive: bool) -> bool {
    match (value, cond_value) {
        (Value::String(value), Some(IsarValue::String(cond_value))) => {
            if case_sensitive {
                value.starts_with(cond_value)
            } else {
                value.to_lowercase().starts_with(cond_value)
            }
        }
        (Value::Array(value), cond_value) => value
            .iter()
            .any(|value| string_starts_with(value, cond_value, case_sensitive)),
        _ => false,
    }
}

fn string_ends_with(value: &Value, cond_value: &Option<IsarValue>, case_sensitive: bool) -> bool {
    match (value, cond_value) {
        (Value::String(value), Some(IsarValue::String(cond_value))) => {
            if case_sensitive {
                value.ends_with(cond_value)
            } else {
                value.to_lowercase().ends_with(cond_value)
            }
        }
        (Value::Array(value), cond_value) => value
            .iter()
            .any(|value| string_ends_with(value, cond_value, case_sensitive)),
        _ => false,
    }
}

fn string_contains(value: &Value, cond_value: &Option<IsarValue>, case_sensitive: bool) -> bool {
    match (value, cond_value) {
        (Value::String(value), Some(IsarValue::String(cond_value))) => {
            if case_sensitive {
                value.contains(cond_value)
            } else {
                value.to_lowercase().contains(cond_value)
            }
        }
        (Value::Array(value), cond_value) => value
            .iter()
            .any(|value| string_contains(value, cond_value, case_sensitive)),
        _ => false,
    }
}

fn string_matches(value: &Value, cond_value: &Option<IsarValue>, case_sensitive: bool) -> bool {
    match (value, cond_value) {
        (Value::String(value), Some(IsarValue::String(cond_value))) => {
            if case_sensitive {
                fast_wild_match(value, cond_value)
            } else {
                fast_wild_match(&value.to_lowercase(), cond_value)
            }
        }
        (Value::Array(value), cond_value) => value
            .iter()
            .any(|value| string_matches(value, cond_value, case_sensitive)),
        _ => false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    mod extract_value_tests {
        use super::*;

        #[test]
        fn simple_key_access() {
            let json = json!({
                "key": "value",
                "number": 42,
                "boolean": true
            });

            assert_eq!(
                extract_value(&json, &vec!["key".to_string()]),
                Some(&Value::String("value".to_string()))
            );
            assert_eq!(
                extract_value(&json, &vec!["number".to_string()]),
                Some(&Value::Number(42.into()))
            );
            assert_eq!(
                extract_value(&json, &vec!["boolean".to_string()]),
                Some(&Value::Bool(true))
            );
        }

        #[test]
        fn nested_object_access() {
            let json = json!({
                "nested": {
                    "deep": {
                        "value": "found"
                    }
                }
            });

            assert_eq!(
                extract_value(
                    &json,
                    &vec![
                        "nested".to_string(),
                        "deep".to_string(),
                        "value".to_string()
                    ]
                ),
                Some(&Value::String("found".to_string()))
            );

            // Non-existent nested path
            assert_eq!(
                extract_value(&json, &vec!["nested".to_string(), "missing".to_string()]),
                Some(&Value::Null)
            );
        }

        #[test]
        fn array_index_access() {
            let json = json!({
                "array": [1, 2, 3],
                "objects": [{"id": 1}, {"id": 2}]
            });

            assert_eq!(
                extract_value(&json, &vec!["array".to_string(), "1".to_string()]),
                Some(&Value::Number(2.into()))
            );

            assert_eq!(
                extract_value(
                    &json,
                    &vec!["objects".to_string(), "0".to_string(), "id".to_string()]
                ),
                Some(&Value::Number(1.into()))
            );
        }

        #[test]
        fn invalid_array_index() {
            let json = json!({
                "array": [1, 2, 3]
            });

            // Out of bounds index
            assert_eq!(
                extract_value(&json, &vec!["array".to_string(), "5".to_string()]),
                Some(&Value::Null)
            );

            // Invalid index format
            assert_eq!(
                extract_value(
                    &json,
                    &vec!["array".to_string(), "not_a_number".to_string()]
                ),
                None
            );
        }

        #[test]
        fn missing_keys() {
            let json = json!({
                "existing": "value"
            });

            assert_eq!(
                extract_value(&json, &vec!["missing".to_string()]),
                Some(&Value::Null)
            );
        }

        #[test]
        fn mixed_object_array_paths() {
            let json = json!({
                "users": [
                    {
                        "details": {
                            "name": "Alice",
                            "scores": [85, 92, 78]
                        }
                    }
                ]
            });

            assert_eq!(
                extract_value(
                    &json,
                    &vec![
                        "users".to_string(),
                        "0".to_string(),
                        "details".to_string(),
                        "name".to_string()
                    ]
                ),
                Some(&Value::String("Alice".to_string()))
            );

            assert_eq!(
                extract_value(
                    &json,
                    &vec![
                        "users".to_string(),
                        "0".to_string(),
                        "details".to_string(),
                        "scores".to_string(),
                        "1".to_string()
                    ]
                ),
                Some(&Value::Number(92.into()))
            );
        }
    }
}
