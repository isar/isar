use super::{cursor::Cursor, Key, KeyVal};
use crate::core::error::Result;
use std::cmp::Ordering;

pub struct CursorIterator<'txn, C: AsMut<Cursor<'txn>>> {
    cursor: C,
    op: ffi::MDBX_cursor_op,
    next: Option<KeyVal<'txn>>,
}

impl<'txn, C: AsMut<Cursor<'txn>>> CursorIterator<'txn, C> {
    pub fn new(mut cursor: C, ascending: bool) -> Result<Self> {
        let first = if ascending {
            cursor.as_mut().move_to_first()?
        } else {
            cursor.as_mut().move_to_last()?
        };
        let op = if ascending {
            ffi::MDBX_cursor_op::MDBX_NEXT
        } else {
            ffi::MDBX_cursor_op::MDBX_PREV
        };
        let iterator = Self {
            cursor,
            op,
            next: first,
        };
        Ok(iterator)
    }
}

impl<'txn, C: AsMut<Cursor<'txn>>> Iterator for CursorIterator<'txn, C> {
    type Item = KeyVal<'txn>;

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        let value = self.next;
        self.next = self
            .cursor
            .as_mut()
            .op_get(self.op, None, None)
            .ok()
            .flatten();
        value
    }
}

pub struct CursorBetweenIterator<'txn, C: AsMut<Cursor<'txn>>, K: Key> {
    cursor: C,
    lower_key: K,
    upper_key: K,
    ascending: bool,
    op: ffi::MDBX_cursor_op,
    next: Option<KeyVal<'txn>>,
}

impl<'txn, C: AsMut<Cursor<'txn>>, K: Key> CursorBetweenIterator<'txn, C, K> {
    pub fn new(
        cursor: C,
        lower_key: K,
        upper_key: K,
        duplicates: bool,
        skip_duplicates: bool,
    ) -> Result<Self> {
        let ascending = lower_key.cmp_bytes(&upper_key.as_bytes()) != Ordering::Greater;
        let (lower_key, upper_key) = if ascending {
            (lower_key, upper_key)
        } else {
            (upper_key, lower_key)
        };
        let op: ffi::MDBX_cursor_op = match (ascending, skip_duplicates) {
            (true, true) => ffi::MDBX_cursor_op::MDBX_NEXT_NODUP,
            (true, false) => ffi::MDBX_cursor_op::MDBX_NEXT,
            (false, true) => ffi::MDBX_cursor_op::MDBX_PREV_NODUP,
            (false, false) => ffi::MDBX_cursor_op::MDBX_PREV,
        };
        let mut iterator = Self {
            cursor,
            lower_key,
            upper_key,
            ascending,
            op,
            next: None,
        };
        iterator.move_to_first(duplicates)?;
        Ok(iterator)
    }

    fn move_to_first(&mut self, duplicates: bool) -> Result<()> {
        let first_entry = if !self.ascending {
            if let Some(first_entry) = self.cursor.as_mut().move_to_gte(&self.upper_key)? {
                if duplicates {
                    self.cursor
                        .as_mut()
                        .move_to_last_dup()?
                        .or(Some(first_entry))
                } else {
                    Some(first_entry)
                }
            } else if let Some(last) = self.cursor.as_mut().move_to_last()? {
                // If some key between upper_key and lower_key happens to be the last key in the db
                if self.lower_key.cmp_bytes(&last.0) != Ordering::Greater {
                    Some(last)
                } else {
                    None
                }
            } else {
                None
            }
        } else {
            self.cursor.as_mut().move_to_gte(&self.lower_key)?
        };

        if let Some(first_entry) = first_entry {
            if self.upper_key.cmp_bytes(&first_entry.0) == Ordering::Less {
                if !self.ascending {
                    if let Some(prev) = self.cursor.as_mut().move_to_prev_no_dup()? {
                        if self.lower_key.cmp_bytes(&prev.0) != Ordering::Greater {
                            self.next = Some(prev);
                            return Ok(());
                        }
                    }
                }
                self.next = None;
            } else {
                self.next = Some(first_entry)
            }
        } else {
            self.next = None;
        }
        Ok(())
    }

    #[inline]
    fn find_next(&mut self) {
        if let Some((key, value)) = self.cursor.as_mut().op_get(self.op, None, None).unwrap() {
            let abort = if self.ascending {
                self.upper_key.cmp_bytes(&key) == Ordering::Less
            } else {
                self.lower_key.cmp_bytes(&key) == Ordering::Greater
            };
            if !abort {
                self.next = Some((key, value));
                return;
            }
        }
        self.next = None;
    }
}

impl<'txn, C: AsMut<Cursor<'txn>>, K: Key> Iterator for CursorBetweenIterator<'txn, C, K> {
    type Item = KeyVal<'txn>;

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        let value = self.next;
        self.find_next();
        value
    }
}
