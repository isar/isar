use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, PartialEq, Eq, Clone, Copy, Hash)]
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
    pub fn is_static(&self) -> bool {
        matches!(
            &self,
            DataType::Bool
                | DataType::Byte
                | DataType::Int
                | DataType::Long
                | DataType::Float
                | DataType::Double
        )
    }

    pub fn is_dynamic(&self) -> bool {
        !self.is_static()
    }

    pub fn get_static_size(&self) -> usize {
        match *self {
            DataType::Bool | DataType::Byte => 1,
            DataType::Int | DataType::Float => 4,
            DataType::Long | DataType::Double => 8,
            _ => 3,
        }
    }

    pub fn is_scalar(&self) -> bool {
        self.get_element_type().is_none()
    }

    pub fn get_element_type(&self) -> Option<DataType> {
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
