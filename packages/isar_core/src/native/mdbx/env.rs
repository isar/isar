use super::mdbx_error;
use super::mdbx_result;
use super::osal::*;
use super::txn::Txn;
use crate::core::error::{IsarError, Result};
use core::ptr;
use std::sync::Arc;

pub(crate) struct Env {
    env: *mut mdbx_sys::MDBX_env,
}

unsafe impl Sync for Env {}
unsafe impl Send for Env {}

const MIB: isize = 1 << 20;

impl Env {
    pub fn create(path: &str, max_dbs: u32, max_size_mib: u32) -> Result<Arc<Env>> {
        unsafe {
            let path = str_to_os(path)?;
            let mut env: *mut mdbx_sys::MDBX_env = ptr::null_mut();

            let flags = mdbx_sys::MDBX_NOTLS
                | mdbx_sys::MDBX_COALESCE
                | mdbx_sys::MDBX_NOSUBDIR
                | mdbx_sys::MDBX_NOMETASYNC;
            let max_size = (max_size_mib as isize).saturating_mul(MIB);

            let mut err_code = 0;
            for i in 0..9 {
                let max_size_i = (max_size - i * (max_size / 10)).clamp(10 * MIB, isize::MAX);

                mdbx_result(mdbx_sys::mdbx_env_create(&mut env))?;
                mdbx_result(mdbx_sys::mdbx_env_set_option(
                    env,
                    mdbx_sys::MDBX_option_t::MDBX_opt_max_db,
                    max_dbs as u64,
                ))?;
                mdbx_result(mdbx_sys::mdbx_env_set_geometry(
                    env,
                    MIB,
                    0,
                    max_size_i,
                    5 * MIB,
                    20 * MIB,
                    -1,
                ))?;

                err_code = ENV_OPEN(env, path.as_ptr(), flags, 0o600);
                if err_code == mdbx_sys::MDBX_SUCCESS {
                    break;
                } else {
                    mdbx_sys::mdbx_env_close_ex(env, true);
                    env = ptr::null_mut();
                }
            }

            match err_code {
                mdbx_sys::MDBX_SUCCESS => Ok(Arc::new(Env { env })),
                mdbx_sys::MDBX_EPERM | mdbx_sys::MDBX_ENOFILE => Err(IsarError::PathError {}),
                e => Err(mdbx_error(e)),
            }
        }
    }

    pub fn txn(self: &Arc<Self>, write: bool) -> Result<Txn> {
        let flags = if write { 0 } else { mdbx_sys::MDBX_TXN_RDONLY };
        let mut txn: *mut mdbx_sys::MDBX_txn = ptr::null_mut();
        unsafe {
            mdbx_result(mdbx_sys::mdbx_txn_begin_ex(
                self.env,
                ptr::null_mut(),
                flags,
                &mut txn,
                ptr::null_mut(),
            ))?;
        }
        Ok(Txn::new(self.clone(), txn))
    }

    pub fn copy(&self, path: &str) -> Result<()> {
        let path = str_to_os(path)?;
        unsafe { mdbx_result(ENV_COPY(self.env, path.as_ptr(), mdbx_sys::MDBX_CP_COMPACT)) }
    }
}

impl Drop for Env {
    fn drop(&mut self) {
        if !self.env.is_null() {
            unsafe {
                mdbx_sys::mdbx_env_close_ex(self.env, false);
            }
            self.env = ptr::null_mut();
        }
    }
}
