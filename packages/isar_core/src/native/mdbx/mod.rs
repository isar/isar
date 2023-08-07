#![allow(clippy::missing_safety_doc)]

use crate::core::error::{IsarError, Result};
use byteorder::{ByteOrder, LittleEndian};
use core::slice;
use std::cmp::{self, Ordering};
use std::ffi::{c_int, c_void, CStr};

pub mod cursor;
pub mod cursor_iterator;
pub mod db;
pub mod env;
pub mod txn;

pub(crate) type KeyVal<'txn> = (&'txn [u8], &'txn [u8]);

pub(crate) const EMPTY_KEY: mdbx_sys::MDBX_val = mdbx_sys::MDBX_val {
    iov_len: 0,
    iov_base: 0 as *mut c_void,
};

pub(crate) const EMPTY_VAL: mdbx_sys::MDBX_val = mdbx_sys::MDBX_val {
    iov_len: 0,
    iov_base: 0 as *mut c_void,
};

#[inline]
pub(crate) unsafe fn from_mdb_val<'a>(val: &mdbx_sys::MDBX_val) -> &'a [u8] {
    slice::from_raw_parts(val.iov_base as *const u8, val.iov_len as usize)
}

#[inline]
pub(crate) unsafe fn to_mdb_val(value: &[u8]) -> mdbx_sys::MDBX_val {
    mdbx_sys::MDBX_val {
        iov_len: value.len() as mdbx_sys::size_t,
        iov_base: value.as_ptr() as *mut c_void,
    }
}

#[inline]
pub(crate) fn mdbx_result(err_code: c_int) -> Result<()> {
    match err_code {
        mdbx_sys::MDBX_SUCCESS | mdbx_sys::MDBX_RESULT_TRUE => Ok(()),
        mdbx_sys::MDBX_MAP_FULL => Err(IsarError::DbFull {}),
        other => Err(mdbx_error(other)),
    }
}

#[inline]
pub(crate) fn mdbx_error(err_code: c_int) -> IsarError {
    match err_code {
        mdbx_sys::MDBX_MAP_FULL => IsarError::DbFull {},
        other => unsafe {
            let err_raw = mdbx_sys::mdbx_strerror(other);
            let err = CStr::from_ptr(err_raw);
            IsarError::DbError {
                code: other,
                message: err
                    .to_str()
                    .unwrap_or("Cannot decode error message")
                    .to_string(),
            }
        },
    }
}

#[inline]
pub(crate) fn compare_keys(integer_key: bool, key1: &[u8], key2: &[u8]) -> Ordering {
    if integer_key {
        let key1 = LittleEndian::read_u64(key1);
        let key2 = LittleEndian::read_u64(key2);
        key1.cmp(&key2)
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
        *mut mdbx_sys::MDBX_env,
        *const u16,
        mdbx_sys::MDBX_env_flags_t,
        mdbx_sys::mdbx_mode_t,
    ) -> i32 = mdbx_sys::mdbx_env_openW;

    pub const ENV_COPY: unsafe extern "C" fn(
        *mut mdbx_sys::MDBX_env,
        *const u16,
        mdbx_sys::MDBX_copy_flags_t,
    ) -> i32 = mdbx_sys::mdbx_env_copyW;
}

#[cfg(not(target_os = "windows"))]
pub(crate) mod osal {
    use super::*;
    use std::ffi::{c_char, CString};

    pub fn str_to_os(str: &str) -> Result<CString> {
        CString::new(str.as_bytes()).map_err(|_| IsarError::IllegalString {})
    }

    pub const ENV_OPEN: unsafe extern "C" fn(
        *mut mdbx_sys::MDBX_env,
        *const c_char,
        mdbx_sys::MDBX_env_flags_t,
        mdbx_sys::mdbx_mode_t,
    ) -> i32 = mdbx_sys::mdbx_env_open;

    pub const ENV_COPY: unsafe extern "C" fn(
        *mut mdbx_sys::MDBX_env,
        *const c_char,
        mdbx_sys::MDBX_copy_flags_t,
    ) -> i32 = mdbx_sys::mdbx_env_copy;
}
