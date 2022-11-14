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
                message: err
                    .to_str()
                    .unwrap_or("Cannot decode error message")
                    .to_string(),
            })
        },
    }
}

pub trait Key {
    fn as_bytes(&self) -> Cow<[u8]>;

    fn cmp_bytes(&self, other: &[u8]) -> Ordering;
}

#[cfg(target_os = "windows")]
pub(crate) mod osal {
    use super::*;
    use widestring::U16CString;

    pub fn str_to_os(str: &str) -> Result<U16CString> {
        U16CString::from_str(str).map_err(|_| IsarError::IllegalArg {
            message: "Invalid String provided".to_string(),
        })
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
        CString::new(str.as_bytes()).map_err(|_| IsarError::IllegalArg {
            message: "Invalid String provided".to_string(),
        })
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
