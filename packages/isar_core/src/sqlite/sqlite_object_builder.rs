use super::sqlite3::SQLiteStatement;
use crate::core::object_builder::IsarObjectBuilder;

pub struct SQLiteObjectBuilder<'sqlite> {
    stmt: SQLiteStatement<'sqlite>,
}

impl<'sqlite> SQLiteObjectBuilder<'sqlite> {
    pub fn new(stmt: SQLiteStatement<'sqlite>) -> Self {
        Self { stmt }
    }

    pub fn finalize(self) -> SQLiteStatement<'sqlite> {
        self.stmt
    }
}

impl<'sqlite> IsarObjectBuilder<'sqlite> for SQLiteObjectBuilder<'sqlite> {
    fn write_byte(&mut self, col: usize, value: u8) {
        let _ = self.stmt.bind_int(col, value as i32);
    }

    fn write_bool(&mut self, col: usize, value: Option<bool>) {
        if let Some(value) = value {
            let _ = self.stmt.bind_int(col, value as i32);
        } else {
            let _ = self.stmt.bind_null(col);
        }
    }

    fn write_int(&mut self, col: usize, value: i32) {
        if value != i32::MIN {
            let _ = self.stmt.bind_int(col, value);
        } else {
            let _ = self.stmt.bind_null(col);
        }
    }

    fn write_float(&mut self, col: usize, value: f32) {
        if !value.is_nan() {
            let _ = self.stmt.bind_double(col, value as f64);
        } else {
            let _ = self.stmt.bind_null(col);
        }
    }

    fn write_long(&mut self, col: usize, value: i64) {
        if value != i64::MIN {
            let _ = self.stmt.bind_long(col, value);
        } else {
            let _ = self.stmt.bind_null(col);
        }
    }

    fn write_double(&mut self, col: usize, value: f64) {
        if !value.is_nan() {
            let _ = self.stmt.bind_double(col, value);
        } else {
            let _ = self.stmt.bind_null(col);
        }
    }

    fn write_string(&mut self, col: usize, value: Option<&str>) {
        //self.stmt.raw_bind_parameter(col + 1, value);
    }
}
