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
        // Group non-list types
        let non_list_types = [
            DataType::Bool,
            DataType::Byte,
            DataType::Int,
            DataType::Float,
            DataType::Long,
            DataType::Double,
            DataType::String,
            DataType::Object,
            DataType::Json,
        ];
        for dtype in non_list_types {
            assert!(!dtype.is_list(), "{:?} should not be a list type", dtype);
        }

        // Group list types
        let list_types = [
            DataType::BoolList,
            DataType::ByteList,
            DataType::IntList,
            DataType::FloatList,
            DataType::LongList,
            DataType::DoubleList,
            DataType::StringList,
            DataType::ObjectList,
        ];
        for dtype in list_types {
            assert!(dtype.is_list(), "{:?} should be a list type", dtype);
        }
    }

    #[test]
    fn test_element_type() {
        // Test non-list types return None
        let non_list_types = [
            DataType::Bool,
            DataType::Byte,
            DataType::Int,
            DataType::Float,
            DataType::Long,
            DataType::Double,
            DataType::String,
            DataType::Object,
            DataType::Json,
        ];
        for dtype in non_list_types {
            assert_eq!(
                dtype.element_type(),
                None,
                "{:?} should not have an element type",
                dtype
            );
        }

        // Test list types return correct element type
        let list_type_pairs = [
            (DataType::BoolList, DataType::Bool),
            (DataType::ByteList, DataType::Byte),
            (DataType::IntList, DataType::Int),
            (DataType::FloatList, DataType::Float),
            (DataType::LongList, DataType::Long),
            (DataType::DoubleList, DataType::Double),
            (DataType::StringList, DataType::String),
            (DataType::ObjectList, DataType::Object),
        ];
        for (list_type, expected_element_type) in list_type_pairs {
            assert_eq!(
                list_type.element_type(),
                Some(expected_element_type),
                "{:?} should have element type {:?}",
                list_type,
                expected_element_type
            );
        }
    }

    #[test]
    fn test_datetime_alias() {
        // Test that DateTime alias works in serialization
        let long_type = DataType::Long;
        let serialized = serde_json::to_string(&long_type).unwrap();
        assert_eq!(serialized, "\"Long\"");

        // Test that DateTime can be deserialized to Long
        let deserialized: DataType = serde_json::from_str("\"DateTime\"").unwrap();
        assert_eq!(deserialized, DataType::Long);
    }

    #[test]
    fn test_datetime_list_alias() {
        // Test that DateTimeList alias works in serialization
        let long_list_type = DataType::LongList;
        let serialized = serde_json::to_string(&long_list_type).unwrap();
        assert_eq!(serialized, "\"LongList\"");

        // Test that DateTimeList can be deserialized to LongList
        let deserialized: DataType = serde_json::from_str("\"DateTimeList\"").unwrap();
        assert_eq!(deserialized, DataType::LongList);
    }
}
