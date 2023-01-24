use super::sqlite3::SQLite3;
use crate::core::{
    error::{IsarError, Result},
    txn::IsarTxn,
};
use std::cell::RefCell;

pub struct SQLiteTxn<'conn> {
    write: bool,
    sqlite: RefCell<Option<&'conn SQLite3>>,
}

impl<'conn> SQLiteTxn<'conn> {
    pub(crate) fn new(sqlite: &'conn SQLite3, write: bool) -> Result<SQLiteTxn<'conn>> {
        sqlite.prepare("BEGIN")?.step()?;
        let txn = SQLiteTxn {
            write,
            sqlite: RefCell::new(Some(sqlite)),
        };
        Ok(txn)
    }

    pub(crate) fn get_sqlite(&self, write: bool) -> Result<&SQLite3> {
        if let Some(sqlite) = self.sqlite.borrow().as_ref() {
            if write && !self.write {
                return Err(IsarError::WriteTxnRequired {});
            }
            Ok(sqlite)
        } else {
            Err(IsarError::TransactionClosed {})
        }
    }

    pub(crate) fn guard<T, F>(&self, job: F) -> Result<T>
    where
        F: FnOnce() -> Result<T>,
    {
        if let Some(sqlite) = self.sqlite.borrow().as_ref() {
            let result = job();
            if !result.is_ok() {
                sqlite.prepare("ROLLBACK")?.step()?;
                self.sqlite.replace(None);
            }
            result
        } else {
            Err(IsarError::TransactionClosed {})
        }
    }
}

impl<'conn> IsarTxn for SQLiteTxn<'conn> {
    fn commit(self) -> Result<()> {
        if let Some(sqlite) = self.sqlite.take() {
            sqlite.prepare("COMMIT")?.step()?;
            Ok(())
        } else {
            Err(IsarError::TransactionClosed {})
        }
    }

    fn abort(self) {
        if let Some(sqlite) = self.sqlite.take() {
            let stmt = sqlite.prepare("ROLLBACK");
            if let Ok(mut stmt) = stmt {
                let _ = stmt.step();
            }
        }
    }
}
