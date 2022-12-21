use crate::error::Result;
use crate::mdbx::cursor::{Cursor, UnboundCursor};
use crate::mdbx::db::Db;
use crate::mdbx::txn::Txn;
use intmap::IntMap;
use std::cell::RefCell;
use std::ops::{Deref, DerefMut};

pub(crate) struct IsarCursors<'txn, 'env> {
    txn: &'txn Txn<'env>,
    unbound_cursors: RefCell<Vec<UnboundCursor>>,
    cursors: RefCell<IntMap<Cursor<'txn>>>,
}

impl<'txn, 'env> IsarCursors<'txn, 'env> {
    pub fn new(
        txn: &'txn Txn<'env>,
        unbound_cursors: Vec<UnboundCursor>,
    ) -> IsarCursors<'txn, 'env> {
        IsarCursors {
            txn,
            unbound_cursors: RefCell::new(unbound_cursors),
            cursors: RefCell::new(IntMap::new()),
        }
    }

    pub fn get_cursor<'a>(&'a self, db: Db) -> Result<IsarCursor<'a, 'txn, 'env>> {
        let cursor = if let Some(cursor) = self.cursors.borrow_mut().remove(db.runtime_id()) {
            cursor
        } else {
            let unbound = self
                .unbound_cursors
                .borrow_mut()
                .pop()
                .unwrap_or_else(UnboundCursor::new);
            unbound.bind(self.txn, db)?
        };

        Ok(IsarCursor {
            cursors: self,
            cursor: Some(cursor),
            db_id: db.runtime_id(),
        })
    }

    pub fn db_stat(&self, db: Db) -> Result<(u64, u64)> {
        db.stat(&self.txn)
    }

    pub fn clear_db(&self, db: Db) -> Result<()> {
        db.clear(&self.txn)
    }

    pub fn close(self) -> Vec<UnboundCursor> {
        let mut unbound_cursors = self.unbound_cursors.take();
        for (_, cursor) in self.cursors.borrow_mut().drain() {
            unbound_cursors.push(cursor.unbind())
        }
        unbound_cursors
    }
}

pub(crate) struct IsarCursor<'a, 'txn, 'env> {
    cursors: &'a IsarCursors<'txn, 'env>,
    cursor: Option<Cursor<'txn>>,
    db_id: u64,
}

impl<'a, 'txn, 'env> Deref for IsarCursor<'a, 'txn, 'env> {
    type Target = Cursor<'txn>;

    fn deref(&self) -> &Self::Target {
        self.cursor.as_ref().unwrap()
    }
}

impl<'a, 'txn, 'env> DerefMut for IsarCursor<'a, 'txn, 'env> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        self.cursor.as_mut().unwrap()
    }
}

impl<'a, 'txn, 'env> Drop for IsarCursor<'a, 'txn, 'env> {
    fn drop(&mut self) {
        let cursor = self.cursor.take().unwrap();
        let cursors = &self.cursors.cursors;
        if !cursors.borrow().contains_key(self.db_id) {
            cursors.borrow_mut().insert(self.db_id, cursor);
        } else if self.cursors.unbound_cursors.borrow().len() < 3 {
            self.cursors
                .unbound_cursors
                .borrow_mut()
                .push(cursor.unbind());
        }
    }
}
