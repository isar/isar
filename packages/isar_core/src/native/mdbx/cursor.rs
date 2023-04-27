use super::db::Db;
use super::txn::Txn;
use super::{from_mdb_val, to_mdb_val, Key, KeyVal, EMPTY_KEY, EMPTY_VAL};
use crate::core::error::Result;
use crate::native::mdbx::mdbx_result;
use core::ptr;
use std::marker::PhantomData;

pub struct UnboundCursor {
    cursor: *mut ffi::MDBX_cursor,
}

impl UnboundCursor {
    pub(crate) fn new() -> Self {
        let cursor = unsafe { ffi::mdbx_cursor_create(ptr::null_mut()) };

        UnboundCursor { cursor }
    }

    pub fn bind<'txn>(self, txn: &'txn Txn, db: Db) -> Result<Cursor<'txn>> {
        unsafe {
            mdbx_result(ffi::mdbx_cursor_bind(txn.txn, self.cursor, db.dbi))?;
        }

        Ok(Cursor {
            cursor: self,
            _marker: PhantomData::default(),
        })
    }
}

impl Drop for UnboundCursor {
    fn drop(&mut self) {
        unsafe { ffi::mdbx_cursor_close(self.cursor) }
    }
}

pub struct Cursor<'txn> {
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

    #[allow(clippy::try_err)]
    pub(crate) fn op_get(
        &mut self,
        op: ffi::MDBX_cursor_op,
        key: Option<&[u8]>,
        val: Option<&[u8]>,
    ) -> Result<Option<KeyVal<'txn>>> {
        let mut key = key.map_or(EMPTY_KEY, |key| unsafe { to_mdb_val(key) });
        let mut data = val.map_or(EMPTY_VAL, |val| unsafe { to_mdb_val(val) });

        let result = unsafe { ffi::mdbx_cursor_get(self.cursor.cursor, &mut key, &mut data, op) };

        match result {
            ffi::MDBX_SUCCESS | ffi::MDBX_RESULT_TRUE => {
                let key = unsafe { from_mdb_val(&key) };
                let data = unsafe { from_mdb_val(&data) };
                Ok(Some((key, data)))
            }
            ffi::MDBX_NOTFOUND | ffi::MDBX_ENODATA => Ok(None),
            e => {
                mdbx_result(e)?;
                unreachable!();
            }
        }
    }

    pub fn move_to<K: Key>(&mut self, key: &K) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(
            ffi::MDBX_cursor_op::MDBX_SET_KEY,
            Some(&key.as_bytes()),
            None,
        )
    }

    pub fn move_to_key_val<K: Key>(&mut self, key: &K, val: &[u8]) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(
            ffi::MDBX_cursor_op::MDBX_GET_BOTH,
            Some(&key.as_bytes()),
            Some(val),
        )
    }

    pub(crate) fn move_to_gte<K: Key>(&mut self, key: &K) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(
            ffi::MDBX_cursor_op::MDBX_SET_RANGE,
            Some(&key.as_bytes()),
            None,
        )
    }

    fn move_to_next_dup(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(ffi::MDBX_cursor_op::MDBX_NEXT_DUP, None, None)
    }

    pub(crate) fn move_to_last_dup(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(ffi::MDBX_cursor_op::MDBX_LAST_DUP, None, None)
    }

    pub(crate) fn move_to_prev_no_dup(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(ffi::MDBX_cursor_op::MDBX_PREV_NODUP, None, None)
    }

    pub fn move_to_next(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(ffi::MDBX_cursor_op::MDBX_NEXT, None, None)
    }

    pub fn move_to_first(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(ffi::MDBX_cursor_op::MDBX_FIRST, None, None)
    }

    pub fn move_to_last(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(ffi::MDBX_cursor_op::MDBX_LAST, None, None)
    }

    pub fn put<K: Key>(&mut self, key: &K, data: &[u8]) -> Result<()> {
        unsafe {
            // make sure that bytes are not dropped before the call to mdbx_cursor_put
            let bytes = &key.as_bytes();
            let key = to_mdb_val(bytes);
            let mut data = to_mdb_val(data);
            mdbx_result(ffi::mdbx_cursor_put(self.cursor.cursor, &key, &mut data, 0))?;
        }
        Ok(())
    }

    /// Requires the cursor to have a valid position
    pub fn delete_current(&mut self) -> Result<()> {
        unsafe { mdbx_result(ffi::mdbx_cursor_del(self.cursor.cursor, 0))? };

        Ok(())
    }
}
