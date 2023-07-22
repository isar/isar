use super::fast_wild_match::fast_wild_match;
use super::filter::{ConditionType, JsonCondition};
use super::value::IsarValue;
use serde_json::Value;

impl JsonCondition {
    pub fn matches(&self, json: Value) -> bool {
        let value = extract_value(&json, &self.path);
        if let Some(value) = value {
            self.matches_value(value).unwrap_or(false)
        } else {
            false
        }
    }

    fn matches_value(&self, value: &Value) -> Option<bool> {
        let result = if self.is_list {
            match self.condition_type {
                ConditionType::IsNull => value == &Value::Null,
                ConditionType::Equal => {
                    let cond_value = self.values.get(0)?;
                    if let Value::Array(arr) = value {
                        arr.iter()
                            .any(|value| equal(value, cond_value, self.case_sensitive))
                    } else {
                        false
                    }
                }
                ConditionType::Greater => {
                    let cond_value = self.values.get(0)?;
                    if let Value::Array(arr) = value {
                        arr.iter()
                            .any(|value| greater(value, cond_value, self.case_sensitive))
                    } else {
                        false
                    }
                }
                ConditionType::GreaterOrEqual => {
                    let cond_value = self.values.get(0)?;
                    if let Value::Array(arr) = value {
                        arr.iter()
                            .any(|value| greater_or_equal(value, cond_value, self.case_sensitive))
                    } else {
                        false
                    }
                }
                ConditionType::Less => {
                    let cond_value = self.values.get(0)?;
                    if let Value::Array(arr) = value {
                        arr.iter()
                            .any(|value| less(value, cond_value, self.case_sensitive))
                    } else {
                        false
                    }
                }
                ConditionType::LessOrEqual => {
                    let cond_value = self.values.get(0)?;
                    if let Value::Array(arr) = value {
                        arr.iter()
                            .any(|value| less_or_equal(value, cond_value, self.case_sensitive))
                    } else {
                        false
                    }
                }
                ConditionType::Between => {
                    let lower = self.values.get(0)?;
                    let upper = self.values.get(1)?;
                    if let Value::Array(arr) = value {
                        arr.iter()
                            .any(|value| between(value, lower, upper, self.case_sensitive))
                    } else {
                        false
                    }
                }
                ConditionType::StringStartsWith => {
                    let cond_value = self.values.get(0)?;
                    if let Value::Array(arr) = value {
                        arr.iter()
                            .any(|value| string_starts_with(value, cond_value, self.case_sensitive))
                    } else {
                        false
                    }
                }
                ConditionType::StringEndsWith => {
                    let cond_value = self.values.get(0)?;
                    if let Value::Array(arr) = value {
                        arr.iter()
                            .any(|value| string_ends_with(value, cond_value, self.case_sensitive))
                    } else {
                        false
                    }
                }
                ConditionType::StringContains => {
                    let cond_value = self.values.get(0)?;
                    if let Value::Array(arr) = value {
                        arr.iter()
                            .any(|value| string_contains(value, cond_value, self.case_sensitive))
                    } else {
                        false
                    }
                }
                ConditionType::StringMatches => {
                    let cond_value = self.values.get(0)?;
                    if let Value::Array(arr) = value {
                        arr.iter()
                            .any(|value| string_matches(value, cond_value, self.case_sensitive))
                    } else {
                        false
                    }
                }
            }
        } else {
            match self.condition_type {
                ConditionType::IsNull => value == &Value::Null,
                ConditionType::Equal => equal(value, self.values.get(0)?, self.case_sensitive),
                ConditionType::Greater => greater(value, self.values.get(0)?, self.case_sensitive),
                ConditionType::GreaterOrEqual => {
                    greater_or_equal(value, self.values.get(0)?, self.case_sensitive)
                }
                ConditionType::Less => less(value, self.values.get(0)?, self.case_sensitive),
                ConditionType::LessOrEqual => {
                    less_or_equal(value, self.values.get(0)?, self.case_sensitive)
                }
                ConditionType::Between => between(
                    value,
                    self.values.get(0)?,
                    self.values.get(1)?,
                    self.case_sensitive,
                ),
                ConditionType::StringStartsWith => {
                    string_starts_with(value, self.values.get(0)?, self.case_sensitive)
                }
                ConditionType::StringEndsWith => {
                    string_ends_with(value, self.values.get(0)?, self.case_sensitive)
                }
                ConditionType::StringContains => {
                    string_contains(value, self.values.get(0)?, self.case_sensitive)
                }
                ConditionType::StringMatches => {
                    string_matches(value, self.values.get(0)?, self.case_sensitive)
                }
            }
        };
        Some(result)
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
        _ => false,
    }
}

fn greater(value: &Value, cond_value: &Option<IsarValue>, case_sensitive: bool) -> bool {
    match (value, cond_value) {
        (value, None) => !value.is_null(),
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
        _ => false,
    }
}

fn greater_or_equal(value: &Value, cond_value: &Option<IsarValue>, case_sensitive: bool) -> bool {
    match (value, cond_value) {
        (_, None) => true,
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
        _ => false,
    }
}

fn less_or_equal(value: &Value, cond_value: &Option<IsarValue>, case_sensitive: bool) -> bool {
    match (value, cond_value) {
        (Value::Null, _) => true,
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
        _ => false,
    }
}
