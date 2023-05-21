#![allow(clippy::missing_safety_doc)]

use crate::core::error::{IsarError, Result};
use core::slice;
use libc::c_int;
use std::cmp::{self, Ordering};
use std::ffi::{c_void, CStr};
use std::mem;

pub mod cursor;
pub mod cursor_iterator;
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
            Err(IsarError::DbError {
                code: other,
                message: err
                    .to_str()
                    .unwrap_or("Cannot decode error message")
                    .to_string(),
            })
        },
    }
}

#[inline]
pub fn compare_keys(integer_key: bool, key1: &[u8], key2: &[u8]) -> Ordering {
    if integer_key {
        let key1 = unsafe { mem::transmute::<&[u8], &[u64]>(key1) };
        let key2 = unsafe { mem::transmute::<&[u8], &[u64]>(key2) };
        key1[0].cmp(&key2[0])
    } else {
        let len = cmp::min(key1.len(), key2.len());
        let cmp = key1[0..len].cmp(&key2[0..len]);
        if cmp == Ordering::Equal {
            key1.len().cmp(&key2.len())
        } else {
            cmp
        }
    }
}

#[cfg(target_os = "windows")]
pub(crate) mod osal {
    use super::*;
    use widestring::U16CString;

    pub fn str_to_os(str: &str) -> Result<U16CString> {
        U16CString::from_str(str).map_err(|_| IsarError::IllegalString {})
    }

    pub const ENV_OPEN: unsafe extern "C" fn(
        *mut ffi::MDBX_env,
        *const u16,
        ffi::MDBX_env_flags_t,
        ffi::mdbx_mode_t,
    ) -> i32 = ffi::mdbx_env_openW;

    pub const ENV_COPY: unsafe extern "C" fn(
        *mut ffi::MDBX_env,
        *const u16,
        ffi::MDBX_copy_flags_t,
    ) -> i32 = ffi::mdbx_env_copyW;
}

#[cfg(not(target_os = "windows"))]
pub(crate) mod osal {
    use super::*;
    use std::ffi::CString;

    pub fn str_to_os(str: &str) -> Result<CString> {
        CString::new(str.as_bytes()).map_err(|_| IsarError::IllegalString {})
    }

    pub const ENV_OPEN: unsafe extern "C" fn(
        *mut ffi::MDBX_env,
        *const libc::c_char,
        ffi::MDBX_env_flags_t,
        ffi::mdbx_mode_t,
    ) -> i32 = ffi::mdbx_env_open;

    pub const ENV_COPY: unsafe extern "C" fn(
        *mut ffi::MDBX_env,
        *const libc::c_char,
        ffi::MDBX_copy_flags_t,
    ) -> i32 = ffi::mdbx_env_copy;
}
