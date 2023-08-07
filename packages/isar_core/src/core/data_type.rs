use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, PartialEq, Eq, Clone, Copy, Hash, Debug)]
pub enum DataType {
    Bool,
    Byte,
    Int,
    Float,
    #[serde(alias = "DateTime")]
    Long,
    Double,
    String,
    Object,
    Json,
    BoolList,
    ByteList,
    IntList,
    FloatList,
    #[serde(alias = "DateTimeList")]
    LongList,
    DoubleList,
    StringList,
    ObjectList,
}

impl DataType {
    pub const fn is_list(&self) -> bool {
        self.element_type().is_some()
    }

    pub const fn element_type(&self) -> Option<DataType> {
        match self {
            DataType::BoolList => Some(DataType::Bool),
            DataType::ByteList => Some(DataType::Byte),
            DataType::IntList => Some(DataType::Int),
            DataType::FloatList => Some(DataType::Float),
            DataType::LongList => Some(DataType::Long),
            DataType::DoubleList => Some(DataType::Double),
            DataType::StringList => Some(DataType::String),
            DataType::ObjectList => Some(DataType::Object),
            _ => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_list() {
        assert!(!DataType::Bool.is_list());
        assert!(!DataType::Byte.is_list());
        assert!(!DataType::Int.is_list());
        assert!(!DataType::Float.is_list());
        assert!(!DataType::Long.is_list());
        assert!(!DataType::Double.is_list());
        assert!(!DataType::String.is_list());
        assert!(!DataType::Object.is_list());
        assert!(!DataType::Json.is_list());
        assert!(DataType::BoolList.is_list());
        assert!(DataType::ByteList.is_list());
        assert!(DataType::IntList.is_list());
        assert!(DataType::FloatList.is_list());
        assert!(DataType::LongList.is_list());
        assert!(DataType::DoubleList.is_list());
        assert!(DataType::StringList.is_list());
        assert!(DataType::ObjectList.is_list());
    }

    #[test]
    fn test_element_type() {
        assert_eq!(DataType::Bool.element_type(), None);
        assert_eq!(DataType::Byte.element_type(), None);
        assert_eq!(DataType::Int.element_type(), None);
        assert_eq!(DataType::Float.element_type(), None);
        assert_eq!(DataType::Long.element_type(), None);
        assert_eq!(DataType::Double.element_type(), None);
        assert_eq!(DataType::String.element_type(), None);
        assert_eq!(DataType::Object.element_type(), None);
        assert_eq!(DataType::Json.element_type(), None);
        assert_eq!(DataType::BoolList.element_type(), Some(DataType::Bool));
        assert_eq!(DataType::ByteList.element_type(), Some(DataType::Byte));
        assert_eq!(DataType::IntList.element_type(), Some(DataType::Int));
        assert_eq!(DataType::FloatList.element_type(), Some(DataType::Float));
        assert_eq!(DataType::LongList.element_type(), Some(DataType::Long));
        assert_eq!(DataType::DoubleList.element_type(), Some(DataType::Double));
        assert_eq!(DataType::StringList.element_type(), Some(DataType::String));
        assert_eq!(DataType::ObjectList.element_type(), Some(DataType::Object));
    }
}
