use super::sqlite3::SQLite3;
use crate::core::error::{IsarError, Result};

pub struct SQLiteTxn {
    instance_id: u64,
    write: bool,
    sqlite: SQLite3,
}

impl SQLiteTxn {
    pub(crate) fn new(instance_id: u64, write: bool, sqlite: SQLite3) -> Result<SQLiteTxn> {
        sqlite.prepare("BEGIN")?.step()?;
        let txn = SQLiteTxn {
            instance_id,
            write,
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

    pub(crate) fn get_sqlite(&self, instance_id: u64, write: bool) -> Result<&SQLite3> {
        self.verify_instance_id(instance_id)?;
        if write && !self.write {
            return Err(IsarError::WriteTxnRequired {});
        }

        Ok(&self.sqlite)
    }

    pub(crate) fn guard<T, F>(&self, job: F) -> Result<T>
    where
        F: FnOnce() -> Result<T>,
    {
        let result = job();
        if !result.is_ok() {
            //self.txn.borrow_mut().take();
        }
        result
    }
}
