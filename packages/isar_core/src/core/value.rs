#[derive(PartialEq, Clone, Debug)]
pub enum IsarValue {
    Bool(Option<bool>),
    Integer(i64),
    Real(f64),
    String(Option<String>),
}

impl IsarValue {
    pub const MAX_STRING: &str = "\u{10ffff}";

    pub fn get_null(&self) -> Self {
        match self {
            IsarValue::Bool(_) => IsarValue::Bool(None),
            IsarValue::Integer(_) => IsarValue::Integer(i64::MIN),
            IsarValue::Real(_) => IsarValue::Real(f64::NAN),
            IsarValue::String(_) => IsarValue::String(None),
        }
    }

    pub fn is_null(&self) -> bool {
        match self {
            IsarValue::Bool(value) => value.is_none(),
            IsarValue::Integer(value) => *value == i64::MIN,
            IsarValue::Real(value) => value.is_nan(),
            IsarValue::String(value) => value.is_none(),
        }
    }

    pub fn get_max(&self) -> Self {
        match self {
            IsarValue::Bool(_) => IsarValue::Bool(Some(true)),
            IsarValue::Integer(_) => IsarValue::Integer(i64::MAX),
            IsarValue::Real(_) => IsarValue::Real(f64::INFINITY),
            IsarValue::String(_) => IsarValue::String(Some(Self::MAX_STRING.to_string())),
        }
    }

    pub fn try_increment(&self) -> Option<Self> {
        match self {
            IsarValue::Bool(value) => match value {
                Some(true) => None,
                Some(false) => Some(IsarValue::Bool(Some(true))),
                None => Some(IsarValue::Bool(Some(false))),
            },
            IsarValue::Integer(value) => Some(IsarValue::Integer(value.checked_add(1)?)),
            IsarValue::Real(value) => {
                if value.is_nan() {
                    Some(IsarValue::Real(f64::NEG_INFINITY))
                } else if value.is_infinite() && value.is_sign_positive() {
                    None
                } else {
                    let next = (*value as f32).next_up() as f64;
                    Some(IsarValue::Real(next))
                }
            }
            IsarValue::String(value) => {
                if let Some(value) = value {
                    if value.is_empty() {
                        return Some(IsarValue::String(Some('\u{0}'.to_string())));
                    }
                    let mut value = value.clone();
                    let last_char = value.pop()?;
                    let new_last_char = char::from_u32((last_char as u32).checked_add(1)?)?;
                    value.push(new_last_char);
                    Some(IsarValue::String(Some(value)))
                } else {
                    Some(IsarValue::String(Some(String::new())))
                }
            }
        }
    }

    pub fn try_decrement(&self) -> Option<Self> {
        match self {
            IsarValue::Bool(value) => match value {
                Some(true) => Some(IsarValue::Bool(Some(false))),
                Some(false) => Some(IsarValue::Bool(None)),
                None => None,
            },
            IsarValue::Integer(value) => Some(IsarValue::Integer(value.checked_sub(1)?)),
            IsarValue::Real(value) => {
                if value.is_nan() {
                    None
                } else if value.is_infinite() && value.is_sign_negative() {
                    Some(IsarValue::Real(f64::NAN))
                } else {
                    let next = (*value as f32).next_down() as f64;
                    Some(IsarValue::Real(next))
                }
            }
            IsarValue::String(value) => {
                let value = value.as_ref()?;
                if value.is_empty() {
                    return Some(IsarValue::String(None));
                }
                let mut value = value.clone();
                let last_char_code = value.pop()? as u32;

                // If the last char is '\0', remove it. Otherwise, decrement it.
                if last_char_code > 0 {
                    let new_last_char = char::from_u32(last_char_code - 1)?;
                    value.push(new_last_char);
                }

                Some(IsarValue::String(Some(value)))
            }
        }
    }

    pub fn bool(&self) -> Option<Option<bool>> {
        if let IsarValue::Bool(value) = self {
            Some(*value)
        } else {
            None
        }
    }

    pub fn integer(&self) -> Option<i64> {
        if let IsarValue::Integer(value) = self {
            Some(*value)
        } else {
            None
        }
    }

    pub fn real(&self) -> Option<f64> {
        if let IsarValue::Real(value) = self {
            Some(*value)
        } else {
            None
        }
    }

    pub fn string(&self) -> Option<Option<&str>> {
        if let IsarValue::String(value) = self {
            Some(value.as_deref())
        } else {
            None
        }
    }
}
