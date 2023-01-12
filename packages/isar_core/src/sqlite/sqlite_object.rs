use crate::core::{data_type::DataType, error::Result, object::IsarObject};

use super::sqlite3::SQLiteStatement;

pub struct SQLiteObject<'a> {
    stmt: &'a SQLiteStatement<'a>,
}

impl<'a> SQLiteObject<'a> {
    pub fn new(stmt: &'a SQLiteStatement<'a>) -> Self {
        Self { stmt }
    }
}

impl<'a> IsarObject<'a> for SQLiteObject<'a> {
    fn is_null(&self, col: usize, _: DataType) -> bool {
        self.stmt.is_null(col)
    }

    fn read_byte(&self, col: usize) -> u8 {
        self.stmt.get_int(col) as u8
    }

    fn read_bool(&self, col: usize) -> Option<bool> {
        if self.is_null(col, DataType::Bool) {
            None
        } else {
            Some(self.stmt.get_int(col) != 0)
        }
    }

    fn read_int(&self, col: usize) -> i32 {
        let val = self.stmt.get_int(col);
        if val == 0 && self.is_null(col, DataType::Int) {
            i32::MIN
        } else {
            val
        }
    }

    fn read_float(&self, col: usize) -> f32 {
        self.read_double(col) as f32
    }

    fn read_long(&self, col: usize) -> i64 {
        let val = self.stmt.get_long(col);
        if val == 0 && self.is_null(col, DataType::Long) {
            i64::MIN
        } else {
            val
        }
    }

    fn read_double(&self, col: usize) -> f64 {
        let val = self.stmt.get_double(col);
        if val == 0.0 && self.is_null(col, DataType::Double) {
            f64::NAN
        } else {
            val
        }
    }
}
