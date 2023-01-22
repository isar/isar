use std::cell::RefCell;

use super::sqlite3::SQLite3;
use crate::core::error::{IsarError, Result};

pub struct SQLiteTxn {
    write: bool,
    active: RefCell<bool>,
    sqlite: SQLite3,
}

impl SQLiteTxn {
    pub(crate) fn new(sqlite: SQLite3, write: bool) -> Result<SQLiteTxn> {
        sqlite.prepare("BEGIN")?.step()?;
        let txn = SQLiteTxn {
            write,
            active: RefCell::new(true),
            sqlite,
        };
        Ok(txn)
    }
}

impl SQLiteTxn {
    pub(crate) fn get_sqlite(&self, write: bool) -> Result<&SQLite3> {
        if write && !self.write {
            return Err(IsarError::WriteTxnRequired {});
        }
        if !*self.active.borrow() {
            return Err(IsarError::TransactionClosed {});
        }

        Ok(&self.sqlite)
    }

    pub(crate) fn guard<T, F>(&self, job: F) -> Result<T>
    where
        F: FnOnce() -> Result<T>,
    {
        let result = job();
        if !result.is_ok() {
            self.active.replace(false);
        }
        result
    }

    pub(crate) fn commit(self) -> Result<SQLite3> {
        self.sqlite.prepare("COMMIT")?.step()?;
        Ok(self.sqlite)
    }

    pub(crate) fn abort(self) -> Result<SQLite3> {
        self.sqlite.prepare("ROLLBACK")?.step()?;
        Ok(self.sqlite)
    }
}
