use xxhash_rust::xxh3::xxh3_64;

use super::data_type::DataType;

#[derive(Clone, Eq, PartialEq)]
pub struct Property {
    pub name: String,
    pub data_type: DataType,
    pub offset: usize,
    pub target_id: Option<u64>,
}

impl Property {
    pub fn new(name: &str, data_type: DataType, offset: usize, target_id: Option<&str>) -> Self {
        let target_id = target_id.map(|col| xxh3_64(col.as_bytes()));
        Property {
            name: name.to_string(),
            data_type,
            offset,
            target_id,
        }
    }

    pub const fn debug(data_type: DataType, offset: usize) -> Self {
        Property {
            name: String::new(),
            data_type,
            offset,
            target_id: None,
        }
    }
}
