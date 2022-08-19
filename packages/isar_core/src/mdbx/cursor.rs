use crate::error::Result;
use crate::mdbx::db::Db;
use crate::mdbx::txn::Txn;
use crate::mdbx::{from_mdb_val, mdbx_result, to_mdb_val, Key, KeyVal, EMPTY_KEY, EMPTY_VAL};
use core::ptr;
use std::cmp::Ordering;
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

impl<'txn> Cursor<'txn> {
    pub fn unbind(self) -> UnboundCursor {
        self.cursor
    }

    #[allow(clippy::try_err)]
    fn op_get(
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

    fn move_to_gte<K: Key>(&mut self, key: &K) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(
            ffi::MDBX_cursor_op::MDBX_SET_RANGE,
            Some(&key.as_bytes()),
            None,
        )
    }

    fn move_to_next_dup(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(ffi::MDBX_cursor_op::MDBX_NEXT_DUP, None, None)
    }

    fn move_to_last_dup(&mut self) -> Result<Option<KeyVal<'txn>>> {
        self.op_get(ffi::MDBX_cursor_op::MDBX_LAST_DUP, None, None)
    }

    fn move_to_prev_no_dup(&mut self) -> Result<Option<KeyVal<'txn>>> {
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

    fn iter(
        &mut self,
        skip_duplicates: bool,
        ascending: bool,
        mut callback: impl FnMut(&mut Self, &'txn [u8], &'txn [u8]) -> Result<bool>,
    ) -> Result<bool> {
        let next = match (ascending, skip_duplicates) {
            (true, true) => ffi::MDBX_cursor_op::MDBX_NEXT_NODUP,
            (true, false) => ffi::MDBX_cursor_op::MDBX_NEXT,
            (false, true) => ffi::MDBX_cursor_op::MDBX_PREV_NODUP,
            (false, false) => ffi::MDBX_cursor_op::MDBX_PREV,
        };
        loop {
            if let Some((key, val)) = self.op_get(next, None, None)? {
                if !callback(self, key, val)? {
                    return Ok(false);
                }
            } else {
                return Ok(true);
            }
        }
    }

    pub fn iter_all(
        &mut self,
        skip_duplicates: bool,
        ascending: bool,
        mut callback: impl FnMut(&mut Self, &'txn [u8], &'txn [u8]) -> Result<bool>,
    ) -> Result<bool> {
        let first = if ascending {
            self.move_to_first()?
        } else {
            self.move_to_last()?
        };

        if let Some((key, val)) = first {
            if !callback(self, key, val)? {
                return Ok(false);
            }
        } else {
            return Ok(true);
        }

        self.iter(skip_duplicates, ascending, callback)
    }

    fn iter_between_first<K: Key>(
        &mut self,
        lower_key: &K,
        upper_key: &K,
        ascending: bool,
        duplicates: bool,
    ) -> Result<Option<KeyVal<'txn>>> {
        let first_entry = if !ascending {
            if let Some(first_entry) = self.move_to_gte(upper_key)? {
                if duplicates {
                    self.move_to_last_dup()?.or(Some(first_entry))
                } else {
                    Some(first_entry)
                }
            } else if let Some(last) = self.move_to_last()? {
                // If some key between upper_key and lower_key happens to be the last key in the db
                if lower_key.cmp_bytes(&last.0) != Ordering::Greater {
                    Some(last)
                } else {
                    None
                }
            } else {
                None
            }
        } else {
            self.move_to_gte(lower_key)?
        };

        if let Some(first_entry) = first_entry {
            if upper_key.cmp_bytes(&first_entry.0) == Ordering::Less {
                if !ascending {
                    if let Some(prev) = self.move_to_prev_no_dup()? {
                        if lower_key.cmp_bytes(&prev.0) != Ordering::Greater {
                            return Ok(Some(prev));
                        }
                    }
                }
                Ok(None)
            } else {
                Ok(Some(first_entry))
            }
        } else {
            Ok(None)
        }
    }

    pub fn iter_between<K: Key>(
        &mut self,
        lower_key: &K,
        upper_key: &K,
        duplicates: bool,
        skip_duplicates: bool,
        ascending: bool,
        mut callback: impl FnMut(&mut Self, &'txn [u8], &'txn [u8]) -> Result<bool>,
    ) -> Result<bool> {
        if upper_key.cmp_bytes(&lower_key.as_bytes()) == Ordering::Less {
            return Ok(true);
        }

        if let Some((key, val)) =
            self.iter_between_first(lower_key, upper_key, ascending, duplicates)?
        {
            if !callback(self, key, val)? {
                return Ok(false);
            }
        } else {
            return Ok(true);
        }

        self.iter(skip_duplicates, ascending, |cursor, key, val| {
            let abort = if ascending {
                upper_key.cmp_bytes(&key) == Ordering::Less
            } else {
                lower_key.cmp_bytes(&key) == Ordering::Greater
            };
            if abort {
                Ok(true)
            } else {
                callback(cursor, key, val)
            }
        })
    }

    pub fn iter_dups<K: Key>(
        &mut self,
        key: &K,
        mut callback: impl FnMut(&mut Self, &'txn [u8]) -> Result<bool>,
    ) -> Result<bool> {
        if let Some((_, val)) = self.move_to(key)? {
            if !callback(self, &val)? {
                return Ok(false);
            }
        } else {
            return Ok(true);
        }
        loop {
            if let Some((_, val)) = self.move_to_next_dup()? {
                if !callback(self, &val)? {
                    return Ok(false);
                }
            } else {
                return Ok(true);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    /*use crate::mdbx::db::Db;
    use crate::mdbx::env::tests::get_env;
    use crate::mdbx::env::Env;
    use itertools::Itertools;
    use std::sync::{Arc, Mutex};

    fn get_filled_db() -> (Env, Db) {
        let env = get_env();
        let txn = env.txn(true).unwrap();
        let db = Db::open(&txn, "test", false, false).unwrap();
        db.put(&txn, b"key1", b"val1").unwrap();
        db.put(&txn, b"key2", b"val2").unwrap();
        db.put(&txn, b"key3", b"val3").unwrap();
        db.put(&txn, b"key4", b"val4").unwrap();
        txn.commit().unwrap();
        (env, db)
    }

    fn get_filled_db_dup() -> (Env, Db) {
        let env = get_env();
        let txn = env.txn(true).unwrap();
        let db = Db::open(&txn, "test", true, false).unwrap();
        db.put(&txn, b"key1", b"val1").unwrap();
        db.put(&txn, b"key1", b"val1b").unwrap();
        db.put(&txn, b"key1", b"val1c").unwrap();
        db.put(&txn, b"key2", b"val2").unwrap();
        db.put(&txn, b"key2", b"val2b").unwrap();
        db.put(&txn, b"key2", b"val2c").unwrap();
        txn.commit().unwrap();
        (env, db)
    }

    fn get_empty_db() -> (Env, Db) {
        let env = get_env();
        let txn = env.txn(true).unwrap();
        let db = Db::open(&txn, "test", true, false).unwrap();
        txn.commit().unwrap();
        (env, db)
    }

    #[test]
    fn test_get() {
        let (env, db) = get_filled_db();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        cur.move_to_first().unwrap();
        let entry = cur.get().unwrap();
        assert_eq!(entry, Some((&b"key1"[..], &b"val1"[..])));

        cur.move_to_next().unwrap();
        let entry = cur.get().unwrap();
        assert_eq!(entry, Some((&b"key2"[..], &b"val2"[..])));
    }

    #[test]
    fn test_get_dup() {
        let (env, db) = get_filled_db_dup();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        cur.move_to_first().unwrap();
        let entry = cur.get().unwrap();
        assert_eq!(entry, Some((&b"key1"[..], &b"val1"[..])));

        cur.move_to_next().unwrap();
        let entry = cur.get().unwrap();
        assert_eq!(entry, Some((&b"key1"[..], &b"val1b"[..])));
    }

    #[test]
    fn test_move_to_first() {
        let (env, db) = get_filled_db();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        let first = cur.move_to_first().unwrap();
        assert_eq!(first, Some((&b"key1"[..], &b"val1"[..])));

        let next = cur.move_to_next().unwrap();
        assert_eq!(next, Some((&b"key2"[..], &b"val2"[..])));
    }

    #[test]
    fn test_move_to_first_empty() {
        let (env, db) = get_empty_db();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        let first = cur.move_to_first().unwrap();
        assert_eq!(first, None);

        let next = cur.move_to_next().unwrap();
        assert_eq!(next, None);
    }

    #[test]
    fn test_move_to_last() {
        let (env, db) = get_filled_db();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        let last = cur.move_to_last().unwrap();
        assert_eq!(last, Some((&b"key4"[..], &b"val4"[..])));

        let next = cur.move_to_next().unwrap();
        assert_eq!(next, None);
    }

    #[test]
    fn test_move_to_last_dup() {
        let (env, db) = get_filled_db_dup();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        let last = cur.move_to_last().unwrap();
        assert_eq!(last, Some((&b"key2"[..], &b"val2c"[..])));
    }

    #[test]
    fn test_move_to_last_empty() {
        let (env, db) = get_empty_db();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        let entry = cur.move_to_last().unwrap();
        assert!(entry.is_none());

        let entry = cur.move_to_next().unwrap();
        assert!(entry.is_none());
    }

    #[test]
    fn test_move_to() {
        let (env, db) = get_filled_db();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        let entry = cur.move_to(b"key2").unwrap();
        assert_eq!(entry, Some((&b"key2"[..], &b"val2"[..])));

        let entry = cur.move_to(b"key1").unwrap();
        assert_eq!(entry, Some((&b"key1"[..], &b"val1"[..])));

        let next = cur.move_to_next().unwrap();
        assert_eq!(next, Some((&b"key2"[..], &b"val2"[..])));

        let entry = cur.move_to(b"key5").unwrap();
        assert_eq!(entry, None);
    }

    #[test]
    fn test_move_to_empty() {
        let (env, db) = get_empty_db();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        let entry = cur.move_to(b"key1").unwrap();
        assert!(entry.is_none());
        let entry = cur.move_to_next().unwrap();
        assert!(entry.is_none());
    }

    #[test]
    fn test_move_to_gte() {
        let (env, db) = get_filled_db();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        let entry = cur.move_to_gte(b"key2").unwrap();
        assert_eq!(entry, Some((&b"key2"[..], &b"val2"[..])));

        let entry = cur.move_to_gte(b"k").unwrap();
        assert_eq!(entry, Some((&b"key1"[..], &b"val1"[..])));

        let next = cur.move_to_next().unwrap();
        assert_eq!(next, Some((&b"key2"[..], &b"val2"[..])));
    }

    #[test]
    fn move_to_gte_empty() {
        let (env, db) = get_empty_db();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        let entry = cur.move_to_gte(b"key1").unwrap();
        assert!(entry.is_none());

        let entry = cur.move_to_next().unwrap();
        assert!(entry.is_none());
    }

    #[test]
    fn test_move_to_next() {
        let (env, db) = get_filled_db();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        let entry = cur.move_to_first().unwrap();
        assert_eq!(entry, Some((&b"key1"[..], &b"val1"[..])));

        let entry = cur.move_to_next().unwrap();
        assert_eq!(entry, Some((&b"key2"[..], &b"val2"[..])));
    }

    #[test]
    fn test_move_to_next_dup() {
        let (env, db) = get_filled_db_dup();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        cur.move_to_first().unwrap();
        let entry = cur.move_to_next().unwrap();
        assert_eq!(entry, Some((&b"key1"[..], &b"val1b"[..])));

        let entry = cur.move_to_next().unwrap();
        assert_eq!(entry, Some((&b"key1"[..], &b"val1c"[..])));

        let entry = cur.move_to_next().unwrap();
        assert_eq!(entry, Some((&b"key2"[..], &b"val2"[..])));
    }

    #[test]
    fn test_move_to_next_empty() {
        let (env, db) = get_empty_db();

        let txn = env.txn(false).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        let entry = cur.move_to_next().unwrap();
        assert!(entry.is_none());

        let entry = cur.move_to_next().unwrap();
        assert!(entry.is_none());
    }

    #[test]
    fn test_delete_current() {
        let (env, db) = get_filled_db();

        let txn = env.txn(true).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        cur.move_to_first().unwrap();
        cur.delete_current(false).unwrap();

        let entry = cur.move_to_first().unwrap();
        assert_eq!(entry, Some((&b"key2"[..], &b"val2"[..])));
    }

    #[test]
    fn test_delete_current_dup() {
        let (env, db) = get_filled_db_dup();

        let txn = env.txn(true).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        cur.move_to_first().unwrap();
        cur.delete_current(false).unwrap();

        let entry = cur.move_to_first().unwrap();
        assert_eq!(entry, Some((&b"key1"[..], &b"val1b"[..])));

        cur.delete_current(true).unwrap();
        let entry = cur.move_to_first().unwrap();
        assert_eq!(entry, Some((&b"key2"[..], &b"val2"[..])));
    }

    #[test]
    fn test_delete_while() {
        let (env, db) = get_filled_db();

        let txn = env.txn(true).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        let entries = Arc::new(Mutex::new(vec![(b"key1", b"val1"), (b"key2", b"val2")]));

        cur.move_to_first().unwrap();
        cur.delete_while(
            |k, v| {
                let mut entries = entries.lock().unwrap();
                if entries.is_empty() {
                    return false;
                }
                let (rk, rv) = entries.remove(0);
                assert_eq!((&rk[..], &rv[..]), (k, v));
                true
            },
            false,
        )
        .unwrap();

        let entry = cur.move_to_first().unwrap();
        assert_eq!(entry, Some((&b"key3"[..], &b"val3"[..])));
    }

    #[test]
    fn test_delete_while_dup() {
        let (env, db) = get_filled_db_dup();

        let txn = env.txn(true).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        cur.move_to_first().unwrap();
        cur.delete_current(false).unwrap();

        let entry = cur.move_to_first().unwrap();
        assert_eq!(entry, Some((&b"key1"[..], &b"val1b"[..])));

        cur.delete_current(true).unwrap();
        let entry = cur.move_to_first().unwrap();
        assert_eq!(entry, Some((&b"key2"[..], &b"val2"[..])));
    }

    #[test]
    fn test_iter() {
        let (env, db) = get_filled_db();

        let txn = env.txn(true).unwrap();
        let mut cur = db.cursor(&txn).unwrap();

        cur.move_to_first().unwrap();
        cur.move_to_next().unwrap();
        let keys = cur
            .iter()
            .map(|r| {
                let (k, _) = r.unwrap();
                k
            })
            .collect_vec();
        assert_eq!(vec![b"key2", b"key3", b"key4"], keys);
    }

    #[test]
    fn test_get_put_delete() {
        let env = get_env();
        let txn = env.txn(true).unwrap();
        let db = Db::open(&txn, "test", false, false).unwrap();
        db.put(&txn, b"key1", b"val1").unwrap();
        db.put(&txn, b"key2", b"val2").unwrap();
        db.put(&txn, b"key3", b"val3").unwrap();
        db.put(&txn, b"key2", b"val4").unwrap();
        txn.commit().unwrap();

        let txn = env.txn(true).unwrap();
        assert_eq!(b"val1", db.get(&txn, b"key1").unwrap().unwrap());
        assert_eq!(b"val4", db.get(&txn, b"key2").unwrap().unwrap());
        assert_eq!(b"val3", db.get(&txn, b"key3").unwrap().unwrap());
        assert_eq!(db.get(&txn, b"key").unwrap(), None);

        db.delete(&txn, b"key1", None).unwrap();
        assert_eq!(db.get(&txn, b"key1").unwrap(), None);
        txn.abort();
    }

    #[test]
    fn test_put_get_del_multi() {
        let env = get_env();
        let txn = env.txn(true).unwrap();
        let db = Db::open(&txn, "test", true, false).unwrap();

        db.put(&txn, b"key1", b"val1").unwrap();
        db.put(&txn, b"key1", b"val2").unwrap();
        db.put(&txn, b"key1", b"val3").unwrap();
        db.put(&txn, b"key2", b"val4").unwrap();
        db.put(&txn, b"key2", b"val5").unwrap();
        db.put(&txn, b"key2", b"val6").unwrap();
        db.put(&txn, b"key3", b"val7").unwrap();
        db.put(&txn, b"key3", b"val8").unwrap();
        db.put(&txn, b"key3", b"val9").unwrap();
        txn.commit().unwrap();

        let txn = env.txn(true).unwrap();
        {
            //let mut cur = db.cursor(&txn).unwrap();
            //assert_eq!(cur.set(b"key2").unwrap(), true);
            //let iter = cur.iter_dup();
            //let vals = iter.map(|x| x.1).collect_vec();
            //assert!(iter.error.is_none());
            //assert_eq!(vals, vec![b"val4", b"val5", b"val6"]);
        }
        txn.commit().unwrap();

        let txn = env.txn(true).unwrap();
        db.delete(&txn, b"key1", Some(b"val2")).unwrap();
        db.delete(&txn, b"key2", None).unwrap();
        txn.commit().unwrap();

        let txn = env.txn(true).unwrap();
        {
            let mut cur = db.cursor(&txn).unwrap();
            cur.move_to_first().unwrap();
            let iter = cur.iter();
            let vals: Result<Vec<&[u8]>> = iter.map_ok(|x| x.1).collect();
            assert_eq!(
                vals.unwrap(),
                vec![b"val1", b"val3", b"val7", b"val8", b"val9"]
            );
        }
        txn.commit().unwrap();
    }

    #[test]
    fn test_put_no_override() {
        let env = get_env();
        let txn = env.txn(true).unwrap();
        let db = Db::open(&txn, "test", false, false).unwrap();
        db.put(&txn, b"key", b"val").unwrap();
        txn.commit().unwrap();

        let txn = env.txn(true).unwrap();
        assert_eq!(db.put_no_override(&txn, b"key", b"err").unwrap(), false);
        assert_eq!(db.put_no_override(&txn, b"key2", b"val2").unwrap(), true);
        assert_eq!(db.get(&txn, b"key").unwrap(), Some(&b"val"[..]));
        assert_eq!(db.get(&txn, b"key2").unwrap(), Some(&b"val2"[..]));
        txn.abort();
    }

    #[test]
    fn test_put_no_dup_data() {
        let env = get_env();
        let txn = env.txn(true).unwrap();
        let db = Db::open(&txn, "test", true, false).unwrap();
        db.put(&txn, b"key", b"val").unwrap();
        txn.commit().unwrap();

        let txn = env.txn(true).unwrap();
        assert_eq!(db.put_no_dup_data(&txn, b"key", b"val").unwrap(), false);
        assert_eq!(db.put_no_dup_data(&txn, b"key2", b"val2").unwrap(), true);
        assert_eq!(db.get(&txn, b"key2").unwrap(), Some(&b"val2"[..]));
        txn.abort();
    }

    #[test]
    fn test_clear_db() {
        let env = get_env();
        let txn = env.txn(true).unwrap();
        let db = Db::open(&txn, "test", false, false).unwrap();
        db.put(&txn, b"key1", b"val1").unwrap();
        db.put(&txn, b"key2", b"val2").unwrap();
        db.put(&txn, b"key3", b"val3").unwrap();
        txn.commit().unwrap();

        let txn = env.txn(true).unwrap();
        db.clear(&txn).unwrap();
        txn.commit().unwrap();

        let txn = env.txn(false).unwrap();
        {
            let mut cursor = db.cursor(&txn).unwrap();
            assert!(cursor.move_to_first().unwrap().is_none());
        }
        txn.abort();
    }*/
}
