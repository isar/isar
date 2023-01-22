use crate::core::data_type::DataType;

pub struct SQLiteProperty {
    pub name: String,
    pub data_type: DataType,
    pub target_id: Option<u64>,
}

impl SQLiteProperty {
    pub fn new(name: &str, data_type: DataType, target_id: Option<u64>) -> Self {
        SQLiteProperty {
            name: name.to_string(),
            data_type,
            target_id,
        }
    }
}

pub struct SQLiteCollection {
    pub name: String,
    pub properties: Vec<SQLiteProperty>,
}

impl SQLiteCollection {
    pub fn new(name: String, properties: Vec<SQLiteProperty>) -> Self {
        Self { name, properties }
    }
}
