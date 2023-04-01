use super::mdbx::cursor::{Cursor, UnboundCursor};
use super::mdbx::db::Db;
use super::mdbx::txn::Txn;
use crate::core::error::{IsarError, Result};
use std::cell::{Cell, RefCell};
use std::ops::{Deref, DerefMut};

pub struct NativeTxn<'env> {
    instance_id: u64,
    txn: Txn<'env>,
    active: Cell<bool>,
    unbound_cursors: RefCell<Vec<UnboundCursor>>,
}

impl<'env> NativeTxn<'env> {
    pub(crate) fn new(instance_id: u64, txn: Txn<'env>) -> Self {
        Self {
            instance_id,
            txn,
            active: Cell::new(true),
            unbound_cursors: RefCell::new(Vec::new()),
        }
    }

    pub(crate) fn verify_instance_id(&self, instance_id: u64) -> Result<()> {
        if self.instance_id != instance_id {
            Err(IsarError::InstanceMismatch {})
        } else {
            Ok(())
        }
    }

    pub(crate) fn get_cursor<'txn>(&'txn self, db: Db) -> Result<NativeCursor<'txn>>
    where
        'env: 'txn,
    {
        let unbound = self
            .unbound_cursors
            .borrow_mut()
            .pop()
            .unwrap_or_else(UnboundCursor::new);
        let cursor = unbound.bind(&self.txn, db)?;

        Ok(NativeCursor {
            txn: self,
            cursor: Some(cursor),
        })
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
            self.active.replace(false);
        }
        result
    }

    pub fn open_db(&self, name: &str, int_key: bool, dup: bool) -> Result<Db> {
        if !self.active.get() {
            return Err(IsarError::TransactionClosed {});
        }
        Db::open(&self.txn, name, int_key, dup)
    }

    pub fn drop_db(&self, db: Db) -> Result<()> {
        if !self.active.get() {
            return Err(IsarError::TransactionClosed {});
        }
        db.drop(&self.txn)
    }

    pub(crate) fn commit(self, instance_id: u64) -> Result<()> {
        self.verify_instance_id(instance_id)?;
        if !self.active.get() {
            return Err(IsarError::TransactionClosed {});
        }
        self.txn.commit()
    }

    pub(crate) fn abort(self, instance_id: u64) {
        if self.active.get() && self.verify_instance_id(instance_id).is_ok() {
            self.txn.abort()
        }
    }
}

pub(crate) struct NativeCursor<'txn> {
    txn: &'txn NativeTxn<'txn>,
    cursor: Option<Cursor<'txn>>,
}

impl<'txn> Deref for NativeCursor<'txn> {
    type Target = Cursor<'txn>;

    fn deref(&self) -> &Self::Target {
        self.cursor.as_ref().unwrap()
    }
}

impl<'txn> DerefMut for NativeCursor<'txn> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        self.cursor.as_mut().unwrap()
    }
}

impl<'txn> Drop for NativeCursor<'txn> {
    fn drop(&mut self) {
        let cursor = self.cursor.take().unwrap();
        if self.txn.unbound_cursors.borrow().len() < 3 {
            self.txn.unbound_cursors.borrow_mut().push(cursor.unbind());
        }
    }
}
