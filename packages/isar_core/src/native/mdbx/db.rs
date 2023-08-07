use super::mdbx_result;
use super::txn::Txn;
use crate::core::error::Result;
use std::ffi::CString;
use std::mem::size_of;
use std::ptr;

#[derive(Copy, Clone, Eq, PartialEq)]
pub(crate) struct Db {
    pub(crate) dbi: mdbx_sys::MDBX_dbi,
    pub dup: bool,
}

impl Db {
    pub fn open(txn: &Txn, name: Option<&str>, int_key: bool, dup: bool) -> Result<Self> {
        let mut flags = mdbx_sys::MDBX_CREATE;
        if int_key {
            flags |= mdbx_sys::MDBX_INTEGERKEY;
        }
        if dup {
            flags |= mdbx_sys::MDBX_DUPSORT;
        }

        let mut dbi: mdbx_sys::MDBX_dbi = 0;
        if let Some(name) = name {
            let name = CString::new(name.as_bytes()).unwrap();
            unsafe {
                mdbx_result(mdbx_sys::mdbx_dbi_open(
                    txn.txn,
                    name.as_ptr(),
                    flags,
                    &mut dbi,
                ))?;
            }
        } else {
            unsafe {
                mdbx_result(mdbx_sys::mdbx_dbi_open(txn.txn, ptr::null(), 0, &mut dbi))?;
            }
        }

        Ok(Self { dbi, dup })
    }

    pub fn stat(&self, txn: &Txn) -> Result<(u64, u64)> {
        let mut stat = mdbx_sys::MDBX_stat {
            ms_psize: 0,
            ms_depth: 0,
            ms_branch_pages: 0,
            ms_leaf_pages: 0,
            ms_overflow_pages: 0,
            ms_entries: 0,
            ms_mod_txnid: 0,
        };
        let stat_ptr = &mut stat as *mut mdbx_sys::MDBX_stat;
        unsafe {
            mdbx_sys::mdbx_dbi_stat(
                txn.txn,
                self.dbi,
                stat_ptr,
                size_of::<mdbx_sys::MDBX_stat>() as mdbx_sys::size_t,
            );
        }
        let size = (stat.ms_branch_pages + stat.ms_leaf_pages + stat.ms_overflow_pages)
            * stat.ms_psize as u64;
        Ok((stat.ms_entries, size))
    }

    pub fn clear(&self, txn: &Txn) -> Result<()> {
        unsafe { mdbx_result(mdbx_sys::mdbx_drop(txn.txn, self.dbi, false)) }?;
        Ok(())
    }

    pub fn drop(self, txn: &Txn) -> Result<()> {
        unsafe { mdbx_result(mdbx_sys::mdbx_drop(txn.txn, self.dbi, true)) }?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {

    /*#[test]
    fn test_open() {
        let env = get_env();

        let read_txn = env.txn(false).unwrap();
        assert!(Db::open(&read_txn, "test", false, false).is_err());
        read_txn.abort();

        let flags = vec![
            (false, false, 0),
            (false, true, 0),
            (true, false, mdbx_sys::MDB_DUPSORT),
            (true, true, mdbx_sys::MDB_DUPSORT | mdbx_sys::MDB_DUPFIXED),
        ];

        for (i, (dup, fixed_vals, flags)) in flags.iter().enumerate() {
            let txn = env.txn(true).unwrap();
            let db = Db::open(&txn, format!("test{}", i).as_str(), *dup, *fixed_vals).unwrap();
            txn.commit().unwrap();

            let mut actual_flags: u32 = 0;
            let txn = env.txn(false).unwrap();
            unsafe {
                mdbx_sys::mdb_dbi_flags(txn.txn, db.dbi, &mut actual_flags);
            }
            txn.abort();
            assert_eq!(*flags, actual_flags);
        }
    }*/
}
