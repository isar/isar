use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, PartialEq, Eq, Clone, Copy, Hash, Debug)]
pub enum DataType {
    #[serde(alias = "Bool")]
    Byte,
    Int,
    Float,
    #[serde(alias = "DateTime")]
    Long,
    Double,
    String,
    Object,
    Json,
    #[serde(alias = "BoolList")]
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
    pub fn is_list(&self) -> bool {
        match self {
            DataType::ByteList
            | DataType::IntList
            | DataType::FloatList
            | DataType::LongList
            | DataType::DoubleList
            | DataType::StringList
            | DataType::ObjectList => true,
            _ => false,
        }
    }
}
