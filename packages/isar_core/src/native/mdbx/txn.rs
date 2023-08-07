use super::{env::Env, mdbx_result};
use crate::core::error::Result;
use core::ptr;
use std::sync::Arc;

pub(crate) struct Txn {
    pub(crate) txn: *mut mdbx_sys::MDBX_txn,
    _env: Arc<Env>,
}

impl Txn {
    pub(crate) fn new(env: Arc<Env>, txn: *mut mdbx_sys::MDBX_txn) -> Self {
        Txn { txn, _env: env }
    }

    pub fn commit(mut self) -> Result<()> {
        let result =
            unsafe { mdbx_result(mdbx_sys::mdbx_txn_commit_ex(self.txn, ptr::null_mut())) };
        self.txn = ptr::null_mut();
        result?;
        Ok(())
    }

    pub fn abort(self) {}

    pub fn mark_broken(&self) {
        unsafe {
            mdbx_sys::mdbx_txn_break(self.txn);
        }
    }
}

impl Drop for Txn {
    fn drop(&mut self) {
        if !self.txn.is_null() {
            unsafe {
                mdbx_sys::mdbx_txn_abort(self.txn);
            }
            self.txn = ptr::null_mut();
        }
    }
}
