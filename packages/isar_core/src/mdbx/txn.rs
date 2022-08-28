use crate::error::Result;
use crate::mdbx::mdbx_result;
use core::ptr;
use std::marker::PhantomData;

pub struct Txn<'env> {
    pub(crate) txn: *mut ffi::MDBX_txn,
    pub write: bool,
    _marker: PhantomData<&'env ()>,
}

impl<'env> Txn<'env> {
    pub(crate) fn new(txn: *mut ffi::MDBX_txn, write: bool) -> Self {
        Txn {
            txn,
            write,
            _marker: PhantomData::default(),
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

impl<'a> Drop for Txn<'a> {
    fn drop(&mut self) {
        if !self.txn.is_null() {
            unsafe {
                ffi::mdbx_txn_abort(self.txn);
            }
            self.txn = ptr::null_mut();
        }
    }
}
