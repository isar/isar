use crate::error::Result;
use crate::mdbx::mdbx_result;
use crate::mdbx::txn::Txn;
use std::ffi::CString;
use std::mem::size_of;
use std::ptr;

#[derive(Copy, Clone, Eq, PartialEq)]
pub struct Db {
    pub(crate) dbi: ffi::MDBX_dbi,
    pub dup: bool,
}

impl Db {
    pub fn runtime_id(&self) -> u64 {
        self.dbi as u64
    }

    pub fn open(
        txn: &Txn,
        name: Option<&str>,
        int_key: bool,
        dup: bool,
        int_dup: bool,
    ) -> Result<Self> {
        let mut flags = ffi::MDBX_CREATE;
        if int_key {
            flags |= ffi::MDBX_INTEGERKEY;
        }
        if dup {
            flags |= ffi::MDBX_DUPSORT;
            if int_dup {
                flags |= ffi::MDBX_INTEGERDUP | ffi::MDBX_DUPFIXED;
            }
        }

        let mut dbi: ffi::MDBX_dbi = 0;
        if let Some(name) = name {
            let name = CString::new(name.as_bytes()).unwrap();
            unsafe {
                mdbx_result(ffi::mdbx_dbi_open(txn.txn, name.as_ptr(), flags, &mut dbi))?;
            }
        } else {
            unsafe {
                mdbx_result(ffi::mdbx_dbi_open(txn.txn, ptr::null(), 0, &mut dbi))?;
            }
        }

        Ok(Self { dbi, dup })
    }

    pub fn stat(&self, txn: &Txn) -> Result<(u64, u64)> {
        let mut stat = ffi::MDBX_stat {
            ms_psize: 0,
            ms_depth: 0,
            ms_branch_pages: 0,
            ms_leaf_pages: 0,
            ms_overflow_pages: 0,
            ms_entries: 0,
            ms_mod_txnid: 0,
        };
        let stat_ptr = &mut stat as *mut ffi::MDBX_stat;
        unsafe {
            ffi::mdbx_dbi_stat(
                txn.txn,
                self.dbi,
                stat_ptr,
                size_of::<ffi::MDBX_stat>() as ffi::size_t,
            );
        }
        let size = (stat.ms_branch_pages + stat.ms_leaf_pages + stat.ms_overflow_pages)
            * stat.ms_psize as u64;
        Ok((stat.ms_entries, size))
    }

    pub fn clear(&self, txn: &Txn) -> Result<()> {
        unsafe { mdbx_result(ffi::mdbx_drop(txn.txn, self.dbi, false)) }?;
        Ok(())
    }

    pub fn drop(self, txn: &Txn) -> Result<()> {
        unsafe { mdbx_result(ffi::mdbx_drop(txn.txn, self.dbi, true)) }?;
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
            (true, false, ffi::MDB_DUPSORT),
            (true, true, ffi::MDB_DUPSORT | ffi::MDB_DUPFIXED),
        ];

        for (i, (dup, fixed_vals, flags)) in flags.iter().enumerate() {
            let txn = env.txn(true).unwrap();
            let db = Db::open(&txn, format!("test{}", i).as_str(), *dup, *fixed_vals).unwrap();
            txn.commit().unwrap();

            let mut actual_flags: u32 = 0;
            let txn = env.txn(false).unwrap();
            unsafe {
                ffi::mdb_dbi_flags(txn.txn, db.dbi, &mut actual_flags);
            }
            txn.abort();
            assert_eq!(*flags, actual_flags);
        }
    }*/
}
