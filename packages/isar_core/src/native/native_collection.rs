use crate::core::data_type::DataType;

use super::mdbx::db::Db;

#[derive(Copy, Clone)]
pub struct NativeProperty {
    pub data_type: DataType,
    pub offset: usize,
    pub collection_index: Option<usize>,
}

pub struct NativeCollection {
    pub properties: Vec<NativeProperty>,
    pub db: Db,
}
