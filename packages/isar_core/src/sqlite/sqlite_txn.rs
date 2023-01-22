use std::cell::RefCell;

use super::sqlite3::SQLite3;
use crate::core::error::{IsarError, Result};

pub struct SQLiteTxn {
    instance_id: u64,
    write: bool,
    active: RefCell<bool>,
    sqlite: SQLite3,
}

impl SQLiteTxn {
    pub(crate) fn new(instance_id: u64, write: bool, sqlite: SQLite3) -> Result<SQLiteTxn> {
        sqlite.prepare("BEGIN")?.step()?;
        let txn = SQLiteTxn {
            instance_id,
            write,
            active: RefCell::new(true),
            sqlite,
        };
        Ok(txn)
    }
}

impl SQLiteTxn {
    fn verify_instance_id(&self, instance_id: u64) -> Result<()> {
        if self.instance_id != instance_id {
            Err(IsarError::InstanceMismatch {})
        } else {
            Ok(())
        }
    }

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
