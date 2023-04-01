use super::sqlite3::SQLite3;
use crate::core::error::{IsarError, Result};
use std::cell::Cell;

pub struct SQLiteTxn {
    write: bool,
    active: Cell<bool>,
    sqlite: SQLite3,
}

impl SQLiteTxn {
    pub(crate) fn new(sqlite: SQLite3, write: bool) -> Result<SQLiteTxn> {
        sqlite.prepare("BEGIN")?.step()?;
        let txn = SQLiteTxn {
            write,
            active: Cell::new(true),
            sqlite,
        };
        Ok(txn)
    }

    pub(crate) fn get_sqlite(&self, write: bool) -> Result<&SQLite3> {
        if !self.active.get() {
            return Err(IsarError::TransactionClosed {});
        }
        if write && !self.write {
            return Err(IsarError::WriteTxnRequired {});
        }
        Ok(&self.sqlite)
    }

    pub(crate) fn guard<T, F>(&self, job: F) -> Result<T>
    where
        F: FnOnce() -> Result<T>,
    {
        if !self.active.get() {
            return Err(IsarError::TransactionClosed {});
        }
        let result = job();
        if !result.is_ok() {
            self.sqlite.prepare("ROLLBACK")?.step()?;
            self.active.replace(false);
        }
        result
    }

    pub fn commit(&self) -> Result<()> {
        if !self.active.get() {
            return Err(IsarError::TransactionClosed {});
        }
        self.sqlite.prepare("COMMIT")?.step()?;
        Ok(())
    }

    pub fn abort(&self) {
        if self.active.get() {
            let stmt = self.sqlite.prepare("ROLLBACK");
            if let Ok(mut stmt) = stmt {
                let _ = stmt.step();
            }
        }
    }

    pub fn finalize(self) -> SQLite3 {
        self.sqlite
    }
}
