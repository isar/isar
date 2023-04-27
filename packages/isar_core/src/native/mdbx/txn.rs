use super::{env::Env, mdbx_result};
use crate::core::error::Result;
use core::ptr;
use std::sync::Arc;

pub struct Txn {
    pub(crate) txn: *mut ffi::MDBX_txn,
    pub write: bool,
    _env: Arc<Env>,
}

impl Txn {
    pub(crate) fn new(env: Arc<Env>, txn: *mut ffi::MDBX_txn, write: bool) -> Self {
        Txn {
            txn,
            write,
            _env: env,
        }
    }

    pub fn commit(mut self) -> Result<()> {
        let result = unsafe { mdbx_result(ffi::mdbx_txn_commit_ex(self.txn, ptr::null_mut())) };
        self.txn = ptr::null_mut();
        result?;
        Ok(())
    }

    pub fn abort(self) {}
}

impl Drop for Txn {
    fn drop(&mut self) {
        if !self.txn.is_null() {
            unsafe {
                ffi::mdbx_txn_abort(self.txn);
            }
            self.txn = ptr::null_mut();
        }
    }
}
