#![allow(clippy::missing_safety_doc)]

use crate::error::{IsarError, Result};
use core::slice;
use libc::c_int;
use std::borrow::Cow;
use std::cmp::Ordering;
use std::ffi::{c_void, CStr};

pub mod cursor;
pub mod db;
pub mod env;
pub mod txn;

pub type KeyVal<'txn> = (&'txn [u8], &'txn [u8]);

pub const EMPTY_KEY: ffi::MDBX_val = ffi::MDBX_val {
    iov_len: 0,
    iov_base: 0 as *mut c_void,
};

pub const EMPTY_VAL: ffi::MDBX_val = ffi::MDBX_val {
    iov_len: 0,
    iov_base: 0 as *mut c_void,
};

#[inline]
pub unsafe fn from_mdb_val<'a>(val: &ffi::MDBX_val) -> &'a [u8] {
    slice::from_raw_parts(val.iov_base as *const u8, val.iov_len as usize)
}

#[inline]
pub unsafe fn to_mdb_val(value: &[u8]) -> ffi::MDBX_val {
    ffi::MDBX_val {
        iov_len: value.len() as ffi::size_t,
        iov_base: value.as_ptr() as *mut libc::c_void,
    }
}

#[inline]
pub fn mdbx_result(err_code: c_int) -> Result<()> {
    match err_code {
        ffi::MDBX_SUCCESS | ffi::MDBX_RESULT_TRUE => Ok(()),
        ffi::MDBX_MAP_FULL => Err(IsarError::DbFull {}),
        other => unsafe {
            let err_raw = ffi::mdbx_strerror(other);
            let err = CStr::from_ptr(err_raw);
            Err(IsarError::MdbxError {
                code: other,
                message: err.to_str().unwrap().to_string(),
            })
        },
    }
}

pub trait Key {
    fn as_bytes(&self) -> Cow<[u8]>;

    fn cmp_bytes(&self, other: &[u8]) -> Ordering;
}
