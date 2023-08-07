use super::db::Db;
use super::txn::Txn;
use super::{from_mdb_val, to_mdb_val, KeyVal, EMPTY_KEY, EMPTY_VAL};
use crate::core::error::Result;
use crate::native::mdbx::mdbx_result;
use core::ptr;
use std::marker::PhantomData;

pub(crate) struct UnboundCursor {
    cursor: *mut mdbx_sys::MDBX_cursor,
}

impl UnboundCursor {
    pub(crate) fn new() -> Self {
        let cursor = unsafe { mdbx_sys::mdbx_cursor_create(ptr::null_mut()) };

        UnboundCursor { cursor }
    }

    pub fn bind<'txn>(self, txn: &'txn Txn, db: Db) -> Result<Cursor<'txn>> {
        unsafe {
            mdbx_result(mdbx_sys::mdbx_cursor_bind(txn.txn, self.cursor, db.dbi))?;
        }

        Ok(Cursor {
            cursor: self,
            _marker: PhantomData::default(),
        })
    }
}

impl Drop for UnboundCursor {
    fn drop(&mut self) {
        unsafe { mdbx_sys::mdbx_cursor_close(self.cursor) }
    }
}

pub(crate) struct Cursor<'txn> {
    cursor: UnboundCursor,
    _marker: PhantomData<&'txn ()>,
}

impl<'txn> AsMut<Cursor<'txn>> for Cursor<'txn> {
    fn as_mut(&mut self) -> &mut Cursor<'txn> {
        self
    }
}

impl<'txn> Cursor<'txn> {
    pub fn unbind(self) -> UnboundCursor {
        self.cursor
    }

    #[inline]
    pub(super) fn op_get(
        &mut self,
        op: mdbx_sys::MDBX_cursor_op,
        key: Option<&[u8]>,
        val: Option<&[u8]>,
    ) -> Result<Option<KeyVal<'txn>>> {
        let mut key = key.map_or(EMPTY_KEY, |key| unsafe { to_mdb_val(key) });
        let mut data = val.map_or(EMPTY_VAL, |val| unsafe { to_mdb_val(val) });

        let result =
            unsafe { mdbx_sys::mdbx_cursor_get(self.cursor.cursor, &mut key, &mut data, op) };

        match result {
            mdbx_sys::MDBX_SUCCESS | mdbx_sys::MDBX_RESULT_TRUE => {
                let key = unsafe { from_mdb_val(&key) };
                let data = unsafe { from_mdb_val(&data) };
                Ok(Some((key, data)))
            }
            mdbx_sys::MDBX_NOTFOUND | mdbx_sys::MDBX_ENODATA => Ok(None),
            e => {
                mdbx_result(e)?;
                unreachable!();
            }
        }
    }

    pub fn move_to(&mut self, key: &[u8]) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(mdbx_sys::MDBX_cursor_op::MDBX_SET_KEY, Some(key), None)
    }

    pub fn move_to_key_val(&mut self, key: &[u8], val: &[u8]) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(
            mdbx_sys::MDBX_cursor_op::MDBX_GET_BOTH,
            Some(key),
            Some(val),
        )
    }

    pub fn move_to_gte(&mut self, key: &[u8]) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(mdbx_sys::MDBX_cursor_op::MDBX_SET_RANGE, Some(key), None)
    }

    #[allow(dead_code)]
    fn move_to_next_dup(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(mdbx_sys::MDBX_cursor_op::MDBX_NEXT_DUP, None, None)
    }

    pub fn move_to_last_dup(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(mdbx_sys::MDBX_cursor_op::MDBX_LAST_DUP, None, None)
    }

    pub fn move_to_prev_no_dup(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(mdbx_sys::MDBX_cursor_op::MDBX_PREV_NODUP, None, None)
    }

    #[allow(dead_code)]
    pub fn move_to_next(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(mdbx_sys::MDBX_cursor_op::MDBX_NEXT, None, None)
    }

    #[allow(dead_code)]
    pub fn move_to_first(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(mdbx_sys::MDBX_cursor_op::MDBX_FIRST, None, None)
    }

    pub fn move_to_last(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(mdbx_sys::MDBX_cursor_op::MDBX_LAST, None, None)
    }

    pub fn put(&mut self, key: &[u8], data: &[u8]) -> Result<()> {
        unsafe {
            let key = to_mdb_val(key);
            let mut data = to_mdb_val(data);
            mdbx_result(mdbx_sys::mdbx_cursor_put(
                self.cursor.cursor,
                &key,
                &mut data,
                0,
            ))?;
        }
        Ok(())
    }

    /// Requires the cursor to have a valid position
    pub fn delete_current(&mut self) -> Result<()> {
        unsafe { mdbx_result(mdbx_sys::mdbx_cursor_del(self.cursor.cursor, 0))? };

        Ok(())
    }
}
