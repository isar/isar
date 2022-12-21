use std::cell::RefCell;

use rusqlite::Transaction;

use crate::core::error::{IsarError, Result};
use crate::core::txn::IsarTxn;
use crate::watch::change_set::ChangeSet;

use super::sqlite_query::SQLiteQuery;

pub struct SQLiteTxn<'conn> {
    instance_id: u64,
    write: bool,
    txn: RefCell<Option<Transaction<'conn>>>,
    change_set: RefCell<Option<ChangeSet<'conn, SQLiteQuery>>>,
}

impl<'conn> SQLiteTxn<'conn> {
    fn verify_instance_id(&self, instance_id: u64) -> Result<()> {
        if self.instance_id != instance_id {
            Err(IsarError::InstanceMismatch {})
        } else {
            Ok(())
        }
    }

    pub(crate) fn read<'txn, T, F>(&'txn mut self, instance_id: u64, job: F) -> Result<T>
    where
        F: FnOnce(&Transaction<'conn>) -> Result<T>,
    {
        self.verify_instance_id(instance_id)?;
        if let Some(txn) = self.txn.take() {
            let result = job(&txn);
            self.txn.borrow_mut().replace(txn);
            result
        } else {
            Err(IsarError::TransactionClosed {})
        }
    }

    pub(crate) fn write<'txn, T, F>(&'txn mut self, instance_id: u64, job: F) -> Result<T>
    where
        F: FnOnce(&Transaction<'conn>, Option<&mut ChangeSet<'_, SQLiteQuery>>) -> Result<T>,
    {
        self.verify_instance_id(instance_id)?;
        if !self.write {
            return Err(IsarError::WriteTxnRequired {});
        }
        if let Some(txn) = self.txn.take() {
            let mut change_set = self.change_set.take();
            let result = job(&txn, change_set.as_mut());
            if result.is_ok() {
                self.txn.borrow_mut().replace(txn);
                if let Some(change_set) = change_set {
                    self.change_set.borrow_mut().replace(change_set);
                }
            }
            result
        } else {
            Err(IsarError::TransactionClosed {})
        }
    }
}

impl<'a> IsarTxn<'a> for SQLiteTxn<'a> {
    fn is_active(&self) -> bool {
        self.txn.borrow().is_some()
    }

    fn commit(mut self) -> Result<()> {
        if let Some(txn) = self.txn.take() {
            //txn.commit()?;
            Ok(())
        } else {
            Err(IsarError::TransactionClosed {})
        }
    }

    fn abort(self) {}
}
