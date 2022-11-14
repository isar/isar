use super::osal::*;
use crate::error::{IsarError, Result};
use crate::mdbx::mdbx_result;
use crate::mdbx::txn::Txn;
use core::ptr;

pub struct Env {
    env: *mut ffi::MDBX_env,
}

unsafe impl Sync for Env {}
unsafe impl Send for Env {}

const MIB: isize = 1 << 20;

impl Env {
    pub fn create(
        path: &str,
        max_dbs: u64,
        max_size_mib: usize,
        relaxed_durability: bool,
    ) -> Result<Env> {
        let path = str_to_os(path)?;
        let mut env: *mut ffi::MDBX_env = ptr::null_mut();
        unsafe {
            mdbx_result(ffi::mdbx_env_create(&mut env))?;
            mdbx_result(ffi::mdbx_env_set_option(
                env,
                ffi::MDBX_option_t::MDBX_opt_max_db,
                max_dbs,
            ))?;

            let mut flags = ffi::MDBX_NOTLS | ffi::MDBX_COALESCE | ffi::MDBX_NOSUBDIR;
            if relaxed_durability {
                flags |= ffi::MDBX_NOMETASYNC;
            }

            let max_size = (max_size_mib as isize).saturating_mul(MIB);

            let mut err_code = 0;
            for i in 0..9 {
                let max_size_i = (max_size - i * (max_size / 10)).clamp(10 * MIB, isize::MAX);
                mdbx_result(ffi::mdbx_env_set_geometry(
                    env,
                    MIB,
                    0,
                    max_size_i,
                    5 * MIB,
                    20 * MIB,
                    -1,
                ))?;

                err_code = ENV_OPEN(env, path.as_ptr(), flags, 0o600);
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
        let path = str_to_os(path)?;
        unsafe { mdbx_result(ENV_COPY(self.env, path.as_ptr(), ffi::MDBX_CP_COMPACT)) }
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
