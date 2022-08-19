use crate::error::{IsarError, Result};
use crate::mdbx::mdbx_result;
use crate::mdbx::txn::Txn;
use core::ptr;
use std::ffi::CString;

pub struct Env {
    env: *mut ffi::MDBX_env,
}

unsafe impl Sync for Env {}
unsafe impl Send for Env {}

const MB: isize = 1 << 20;

impl Env {
    pub fn create(path: &str, max_dbs: u64, relaxed_durability: bool) -> Result<Env> {
        let path = CString::new(path.as_bytes()).unwrap();
        let mut env: *mut ffi::MDBX_env = ptr::null_mut();
        unsafe {
            mdbx_result(ffi::mdbx_env_create(&mut env))?;
            mdbx_result(ffi::mdbx_env_set_option(
                env,
                ffi::MDBX_option_t::MDBX_opt_max_db,
                max_dbs,
            ))?;

            let mut flags = ffi::MDBX_NOTLS
                | ffi::MDBX_EXCLUSIVE
                | ffi::MDBX_NOMEMINIT
                | ffi::MDBX_COALESCE
                | ffi::MDBX_NOSUBDIR;
            if relaxed_durability {
                flags |= ffi::MDBX_NOMETASYNC;
            }

            let mut err_code = 0;
            for i in 0..9 {
                mdbx_result(ffi::mdbx_env_set_geometry(
                    env,
                    MB,
                    0,
                    (2000 - i * 200) * MB,
                    5 * MB,
                    20 * MB,
                    -1,
                ))?;

                err_code = ffi::mdbx_env_open(env, path.as_ptr(), flags, 0o600);
                if err_code == ffi::MDBX_SUCCESS {
                    break;
                }
            }

            match err_code {
                ffi::MDBX_SUCCESS => Ok(Env { env }),
                ffi::MDBX_EPERM | ffi::MDBX_ENOFILE => Err(IsarError::PathError {}),
                e => {
                    mdbx_result(e)?;
                    unreachable!()
                }
            }
        }
    }

    pub fn txn(&self, write: bool) -> Result<Txn> {
        let flags = if write { 0 } else { ffi::MDBX_TXN_RDONLY };
        let mut txn: *mut ffi::MDBX_txn = ptr::null_mut();
        unsafe {
            mdbx_result(ffi::mdbx_txn_begin_ex(
                self.env,
                ptr::null_mut(),
                flags,
                &mut txn,
                ptr::null_mut(),
            ))?;
        }
        Ok(Txn::new(txn, write))
    }

    pub fn copy(&self, path: &str) -> Result<()> {
        let path = CString::new(path.as_bytes()).unwrap();
        unsafe {
            mdbx_result(ffi::mdbx_env_copy(
                self.env,
                path.as_ptr(),
                ffi::MDBX_CP_COMPACT,
            ))
        }
    }
}

impl Drop for Env {
    fn drop(&mut self) {
        if !self.env.is_null() {
            unsafe {
                ffi::mdbx_env_close_ex(self.env, false);
            }
            self.env = ptr::null_mut();
        }
    }
}

#[cfg(test)]
pub mod tests {

    use super::*;

    #[test]
    fn test_create() {
        get_env();
    }

    pub fn get_env() -> Env {
        let mut dir = std::env::temp_dir();
        let r: u64 = rand::random();
        dir.push(&r.to_string());
        Env::create(dir.to_str().unwrap(), 50, false).unwrap()
    }
}
