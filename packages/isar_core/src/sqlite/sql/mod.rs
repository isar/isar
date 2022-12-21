use crate::core::data_type::DataType;

pub mod create_table;
pub mod insert;

trait SqlExt {
    fn to_sql(&self) -> &str;
}

impl SqlExt for DataType {
    fn to_sql(&self) -> &str {
        match self {
            DataType::Bool | DataType::Byte | DataType::Int | DataType::Long => "INTEGER NOT NULL",
            DataType::Float | DataType::Double => "REAL NOT NULL",
            DataType::String => "TEXT",
            _ => "BLOB",
        }
    }
}
