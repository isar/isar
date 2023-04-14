use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, PartialEq, Eq, Clone, Copy, Hash, Debug)]
pub enum DataType {
    Any,
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
    pub fn is_scalar(&self) -> bool {
        self.get_element_type().is_none()
    }

    pub fn is_list(&self) -> bool {
        self.get_element_type().is_some()
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
