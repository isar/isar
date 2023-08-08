#[derive(PartialEq, Clone, Debug)]
pub enum IsarValue {
    Bool(bool),
    Integer(i64),
    Real(f64),
    String(String),
}

impl IsarValue {
    pub const MAX_STRING: &str = "\u{10ffff}";

    pub fn bool(&self) -> Option<bool> {
        if let IsarValue::Bool(value) = self {
            Some(*value)
        } else {
            None
        }
    }

    pub fn u8(&self) -> Option<u8> {
        self.i64()?.try_into().ok()
    }

    pub fn i32(&self) -> Option<i32> {
        self.i64()?.try_into().ok()
    }

    pub fn i64(&self) -> Option<i64> {
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

    pub fn string(&self) -> Option<&str> {
        if let IsarValue::String(value) = self {
            Some(value.as_str())
        } else {
            None
        }
    }
}

#[cfg(test)]
impl Eq for IsarValue {}
