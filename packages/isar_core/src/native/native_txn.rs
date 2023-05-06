use super::mdbx::cursor::{Cursor, UnboundCursor};
use super::mdbx::cursor_iterator::{CursorBetweenIterator, CursorIterator};
use super::mdbx::db::Db;
use super::mdbx::env::Env;
use super::mdbx::txn::Txn;
use super::mdbx::Key;
use crate::core::error::{IsarError, Result};
use std::cell::{Cell, RefCell};
use std::ops::{Deref, DerefMut};
use std::sync::Arc;

pub struct NativeTxn {
    pub(crate) instance_id: u32,
    txn: Txn,
    active: Cell<bool>,
    unbound_cursors: RefCell<Vec<UnboundCursor>>,
}

impl NativeTxn {
    pub(crate) fn new(instance_id: u32, env: &Arc<Env>, write: bool) -> Result<Self> {
        let txn = env.txn(write)?;
        let txn = Self {
            instance_id,
            txn,
            active: Cell::new(true),
            unbound_cursors: RefCell::new(Vec::new()),
        };
        Ok(txn)
    }

    pub(crate) fn get_cursor<'txn>(&'txn self, db: Db) -> Result<TxnCursor<'txn>> {
        let unbound = self
            .unbound_cursors
            .borrow_mut()
            .pop()
            .unwrap_or_else(UnboundCursor::new);
        let cursor = unbound.bind(&self.txn, db)?;

        Ok(TxnCursor {
            txn: self,
            cursor: Some(cursor),
        })
    }

    #[inline]
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

    pub(crate) fn open_db(&self, name: &str, int_key: bool, dup: bool) -> Result<Db> {
        if !self.active.get() {
            return Err(IsarError::TransactionClosed {});
        }
        Db::open(&self.txn, name, int_key, dup)
    }

    pub(crate) fn drop_db(&self, db: Db) -> Result<()> {
        if !self.active.get() {
            return Err(IsarError::TransactionClosed {});
        }
        db.drop(&self.txn)
    }

    pub(crate) fn stat(&self, db: Db) -> Result<(u64, u64)> {
        db.stat(&self.txn)
    }

    pub(crate) fn commit(self) -> Result<()> {
        if !self.active.get() {
            return Err(IsarError::TransactionClosed {});
        }
        self.txn.commit()
    }

    pub(crate) fn abort(self) {
        if self.active.get() {
            self.txn.abort()
        }
    }
}

pub(crate) struct TxnCursor<'txn> {
    txn: &'txn NativeTxn,
    cursor: Option<Cursor<'txn>>,
}

impl<'txn> TxnCursor<'txn> {
    pub fn iter(self, ascending: bool) -> Result<CursorIterator<'txn, Self>> {
        CursorIterator::new(self, ascending)
    }

    pub fn iter_between<K: Key>(
        self,
        lower_key: K,
        upper_key: K,
        duplicates: bool,
        skip_duplicates: bool,
    ) -> Result<CursorBetweenIterator<'txn, Self, K>> {
        CursorBetweenIterator::new(self, lower_key, upper_key, duplicates, skip_duplicates)
    }
}

impl<'txn> Deref for TxnCursor<'txn> {
    type Target = Cursor<'txn>;

    fn deref(&self) -> &Self::Target {
        self.cursor.as_ref().unwrap()
    }
}

impl<'txn> DerefMut for TxnCursor<'txn> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        self.cursor.as_mut().unwrap()
    }
}

impl<'txn> AsMut<Cursor<'txn>> for TxnCursor<'txn> {
    fn as_mut(&mut self) -> &mut Cursor<'txn> {
        self.cursor.as_mut().unwrap()
    }
}

impl<'txn> Drop for TxnCursor<'txn> {
    fn drop(&mut self) {
        let cursor = self.cursor.take().unwrap();
        if self.txn.unbound_cursors.borrow().len() < 3 {
            self.txn.unbound_cursors.borrow_mut().push(cursor.unbind());
        }
    }
}
