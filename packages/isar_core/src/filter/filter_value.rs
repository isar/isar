use std::cmp::Ordering;

#[derive(PartialEq, Clone, Debug)]
pub enum FilterValue {
    Bool(Option<bool>),
    Integer(i64),
    Real(f64),
    String(Option<String>),
}

impl FilterValue {
    pub fn is_max(&self) -> bool {
        match self {
            FilterValue::Bool(value) => *value == Some(true),
            FilterValue::Integer(value) => *value == i64::MAX,
            FilterValue::Real(value) => value.is_infinite() && value.is_sign_positive(),
            FilterValue::String(_) => false,
        }
    }

    pub fn get_max(&self) -> Self {
        match self {
            FilterValue::Bool(_) => FilterValue::Bool(Some(true)),
            FilterValue::Integer(_) => FilterValue::Integer(i64::MAX),
            FilterValue::Real(_) => FilterValue::Real(f64::INFINITY),
            FilterValue::String(_) => FilterValue::String(Some("\u{10ffff}".to_string())),
        }
    }

    pub fn is_null(&self) -> bool {
        match self {
            FilterValue::Bool(value) => value.is_none(),
            FilterValue::Integer(value) => *value == i64::MIN,
            FilterValue::Real(value) => value.is_nan(),
            FilterValue::String(value) => value.is_none(),
        }
    }

    pub fn get_null(&self) -> Self {
        match self {
            FilterValue::Bool(_) => FilterValue::Bool(None),
            FilterValue::Integer(_) => FilterValue::Integer(i64::MIN),
            FilterValue::Real(_) => FilterValue::Real(f64::NAN),
            FilterValue::String(_) => FilterValue::String(None),
        }
    }

    pub fn try_increment(&self) -> Option<Self> {
        match self {
            FilterValue::Bool(value) => match value {
                Some(true) => None,
                Some(false) => Some(FilterValue::Bool(Some(true))),
                None => Some(FilterValue::Bool(Some(false))),
            },
            FilterValue::Integer(value) => Some(FilterValue::Integer(value.checked_add(1)?)),
            FilterValue::Real(value) => {
                if value.is_nan() {
                    Some(FilterValue::Real(f64::NEG_INFINITY))
                } else if value.is_infinite() && value.is_sign_positive() {
                    None
                } else {
                    Some(FilterValue::Real(value.next_up()))
                }
            }
            FilterValue::String(value) => {
                if let Some(value) = value {
                    if value.is_empty() {
                        return Some(FilterValue::String(Some('\u{0}'.to_string())));
                    }
                    let mut value = value.clone();
                    let last_char = value.pop()?;
                    let new_last_char = char::from_u32((last_char as u32).checked_add(1)?)?;
                    value.push(new_last_char);
                    Some(FilterValue::String(Some(value)))
                } else {
                    Some(FilterValue::String(Some(String::new())))
                }
            }
        }
    }

    pub fn try_decrement(&self) -> Option<Self> {
        match self {
            FilterValue::Bool(value) => match value {
                Some(true) => Some(FilterValue::Bool(Some(false))),
                Some(false) => Some(FilterValue::Bool(None)),
                None => None,
            },
            FilterValue::Integer(value) => Some(FilterValue::Integer(value.checked_sub(1)?)),
            FilterValue::Real(value) => {
                if value.is_nan() {
                    None
                } else if value.is_infinite() && value.is_sign_negative() {
                    Some(FilterValue::Real(f64::NAN))
                } else {
                    Some(FilterValue::Real(value.next_down()))
                }
            }
            FilterValue::String(value) => {
                let value = value.as_ref()?;
                if value.is_empty() {
                    return Some(FilterValue::String(None));
                }
                let mut value = value.clone();
                let last_char = value.pop()?;
                let new_last_char = char::from_u32((last_char as u32).checked_sub(1)?)?;
                value.push(new_last_char);
                Some(FilterValue::String(Some(value)))
            }
        }
    }
}

impl PartialOrd for FilterValue {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        match (self, other) {
            (FilterValue::Bool(a), FilterValue::Bool(b)) => a.partial_cmp(b),
            (FilterValue::Integer(a), FilterValue::Integer(b)) => a.partial_cmp(b),
            (FilterValue::Real(a), FilterValue::Real(b)) => a.partial_cmp(b),
            (FilterValue::String(a), FilterValue::String(b)) => a.partial_cmp(b),
            _ => None,
        }
    }
}
