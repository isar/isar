use rusqlite::Row;

use crate::core::object::IsarObject;

pub struct SQLiteObject<'txn> {
    row: Row<'txn>,
}

impl<'txn> IsarObject<'txn> for SQLiteObject<'txn> {
    fn is_null(&self, offset: usize, data_type: crate::core::data_type::DataType) -> bool {
        todo!()
    }

    fn read_byte(&self, offset: usize) -> u8 {
        todo!()
    }

    fn read_bool(&self, offset: usize) -> Option<bool> {
        todo!()
    }
}
