use super::sqlite3::SQLite3;
use super::sqlite_query::SQLiteQuery;
use crate::core::error::IsarError;
use crate::core::watcher::CollectionWatchers;
use crate::core::{error::Result, watcher::ChangeSet};
use std::cell::{Cell, RefCell};
use std::rc::Rc;
use std::sync::Arc;

pub struct SQLiteTxn {
    write: bool,
    sqlite: Rc<SQLite3>,
    active: Cell<bool>,
    change_set: Rc<RefCell<ChangeSet>>,
}

impl SQLiteTxn {
    pub(crate) fn new(sqlite: Rc<SQLite3>, write: bool) -> Result<SQLiteTxn> {
        sqlite.prepare("BEGIN")?.step()?;
        let txn = SQLiteTxn {
            write,
            sqlite: sqlite,
            active: Cell::new(true),
            change_set: Rc::new(RefCell::new(ChangeSet::new())),
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

    pub(crate) fn is_write(&self) -> bool {
        self.write
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

    pub(crate) fn monitor_changes(&self, watchers: &Arc<CollectionWatchers<SQLiteQuery>>) {
        if watchers.has_watchers() {
            let change_set = self.change_set.clone();
            let watchers = watchers.clone();
            self.sqlite.set_update_hook(move |id| {
                if let Ok(mut change_set) = change_set.try_borrow_mut() {
                    change_set.register_change(&watchers, id, &());
                }
            });
        }
    }

    pub(crate) fn stop_monitor_changes(&self) {
        self.sqlite.clear_update_hook();
    }

    pub(crate) fn commit(self) -> Result<()> {
        if !self.active.get() {
            return Err(IsarError::TransactionClosed {});
        }
        self.sqlite.prepare("COMMIT")?.step()?;
        self.sqlite.clear_update_hook();
        self.change_set.borrow_mut().notify_watchers();
        Ok(())
    }

    pub(crate) fn abort(&self) {
        if self.active.get() {
            self.sqlite.clear_update_hook();
            let stmt = self.sqlite.prepare("ROLLBACK");
            if let Ok(mut stmt) = stmt {
                let _ = stmt.step();
            }
        }
    }
}
