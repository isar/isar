use crate::cursor::IsarCursors;
use crate::error::{IsarError, Result};
use crate::mdbx::cursor::UnboundCursor;
use crate::mdbx::db::Db;
use crate::mdbx::txn::Txn;
use crate::watch::change_set::ChangeSet;
use std::cell::RefCell;

pub struct IsarTxn<'env> {
    instance_id: u64,
    txn: Txn<'env>,
    write: bool,
    change_set: RefCell<Option<ChangeSet<'env>>>,
    unbound_cursors: RefCell<Option<Vec<UnboundCursor>>>,
}

impl<'env> IsarTxn<'env> {
    pub(crate) fn new(
        instance_id: u64,
        txn: Txn<'env>,
        write: bool,
        change_set: Option<ChangeSet<'env>>,
    ) -> Result<Self> {
        Ok(IsarTxn {
            instance_id,
            txn,
            write,
            change_set: RefCell::new(change_set),
            unbound_cursors: RefCell::new(Some(vec![])),
        })
    }

    pub fn is_active(&self) -> bool {
        self.unbound_cursors.borrow().is_some()
    }

    fn verify_instance_id(&self, instance_id: u64) -> Result<()> {
        if self.instance_id != instance_id {
            Err(IsarError::InstanceMismatch {})
        } else {
            Ok(())
        }
    }

    pub(crate) fn read<'txn, T, F>(&'txn mut self, instance_id: u64, job: F) -> Result<T>
    where
        F: FnOnce(&IsarCursors<'txn, 'env>) -> Result<T>,
    {
        self.verify_instance_id(instance_id)?;
        if let Some(unbound_cursors) = self.unbound_cursors.take() {
            let cursors = IsarCursors::new(&self.txn, unbound_cursors);
            let result = job(&cursors);
            self.unbound_cursors.borrow_mut().replace(cursors.close());
            result
        } else {
            Err(IsarError::TransactionClosed {})
        }
    }

    pub(crate) fn write<'txn, T, F>(&'txn mut self, instance_id: u64, job: F) -> Result<T>
    where
        F: FnOnce(&IsarCursors<'txn, 'env>, Option<&mut ChangeSet<'_>>) -> Result<T>,
    {
        self.verify_instance_id(instance_id)?;
        if !self.write {
            return Err(IsarError::WriteTxnRequired {});
        }
        if let Some(unbound_cursors) = self.unbound_cursors.take() {
            let mut change_set = self.change_set.take();
            let cursors = IsarCursors::new(&self.txn, unbound_cursors);
            let result = job(&cursors, change_set.as_mut());
            let unbounded_cursors = cursors.close();
            if result.is_ok() {
                self.unbound_cursors.borrow_mut().replace(unbounded_cursors);
                if let Some(change_set) = change_set {
                    self.change_set.borrow_mut().replace(change_set);
                }
            }
            result
        } else {
            Err(IsarError::TransactionClosed {})
        }
    }

    pub fn commit(self) -> Result<()> {
        if !self.is_active() {
            return Err(IsarError::TransactionClosed {});
        }

        if self.write {
            self.txn.commit()?;
            if let Some(change_set) = self.change_set.take() {
                change_set.notify_watchers();
            }
        }
        Ok(())
    }

    pub fn abort(self) {
        self.txn.abort()
    }

    pub(crate) fn db_names(&mut self) -> Result<Vec<String>> {
        let unnamed_db = Db::open(&self.txn, None, false, false, false)?;
        let cursor = UnboundCursor::new();
        let mut cursor = cursor.bind(&self.txn, unnamed_db)?;

        let mut names = vec![];
        cursor.iter_all(false, true, |_, name, _| {
            names.push(String::from_utf8(name.to_vec()).unwrap());
            Ok(true)
        })?;
        Ok(names)
    }
}
