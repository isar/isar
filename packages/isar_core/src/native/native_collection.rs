use std::cell::Cell;

use crate::core::data_type::DataType;

use super::{index::NativeIndex, mdbx::db::Db};

#[derive(Copy, Clone, Eq, PartialEq, Hash)]
pub struct NativeProperty {
    pub data_type: DataType,
    pub offset: u32,
    // for embedded objects
    pub collection_index: Option<u16>,
}

impl NativeProperty {
    pub fn new(data_type: DataType, offset: u32, collection_index: Option<u16>) -> Self {
        NativeProperty {
            data_type,
            offset,
            collection_index,
        }
    }
}

#[derive(Clone)]
pub struct NativeCollection {
    pub(crate) properties: Vec<NativeProperty>,
    pub(crate) indexes: Vec<NativeIndex>,
    pub(crate) static_size: usize,
    pub(crate) db: Db,
    auto_increment: Cell<i64>,
}

impl NativeCollection {
    pub(crate) fn new(properties: Vec<NativeProperty>, indexes: Vec<NativeIndex>, db: Db) -> Self {
        let static_size = properties
            .iter()
            .max_by_key(|p| p.offset)
            .map_or(0, |p| p.offset + data_type_static_size(p.data_type));
        Self {
            properties,
            indexes,
            static_size: static_size as usize,
            db,
            auto_increment: Cell::new(0),
        }
    }
}

unsafe impl Send for NativeCollection {}
unsafe impl Sync for NativeCollection {}

pub fn data_type_static_size(data_type: DataType) -> u32 {
    match data_type {
        DataType::Bool | DataType::Byte => 1,
        DataType::Int | DataType::Float => 4,
        DataType::Long | DataType::Double => 8,
        _ => 3,
    }
}
