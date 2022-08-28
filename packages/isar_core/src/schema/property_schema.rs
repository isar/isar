use crate::object::data_type::DataType;
use crate::object::property::Property;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Eq)]
pub struct PropertySchema {
    pub(crate) name: Option<String>,
    #[serde(rename = "type")]
    pub(crate) data_type: DataType,
    #[serde(default)]
    #[serde(rename = "target")]
    pub(crate) target_col: Option<String>,
}

impl PropertySchema {
    pub fn new(
        name: Option<String>,
        data_type: DataType,
        target_col: Option<String>,
    ) -> PropertySchema {
        PropertySchema {
            name,
            data_type,
            target_col,
        }
    }

    pub(crate) fn as_property(&self, offset: usize) -> Option<Property> {
        if let Some(name) = &self.name {
            let p = Property::new(name, self.data_type, offset, self.target_col.as_deref());
            Some(p)
        } else {
            None
        }
    }
}

impl PartialEq for PropertySchema {
    fn eq(&self, other: &Self) -> bool {
        let type_bool_byte = (self.data_type == DataType::Bool || self.data_type == DataType::Byte)
            && (other.data_type == DataType::Bool || other.data_type == DataType::Byte);

        let type_bool_byte_list = (self.data_type == DataType::BoolList
            || self.data_type == DataType::ByteList)
            && (other.data_type == DataType::BoolList || other.data_type == DataType::ByteList);

        let type_eq = self.data_type == other.data_type || type_bool_byte || type_bool_byte_list;

        self.name == other.name && type_eq && self.target_col == other.target_col
    }
}
