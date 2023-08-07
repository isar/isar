use super::{compare_keys, cursor::Cursor, KeyVal};
use crate::core::error::Result;
use std::cmp::Ordering;

pub(crate) struct CursorIterator<'txn, C: AsMut<Cursor<'txn>>> {
    cursor: C,
    lower_key: Vec<u8>,
    upper_key: Vec<u8>,
    integer_key: bool,
    ascending: bool,
    op: mdbx_sys::MDBX_cursor_op,
    next: Option<KeyVal<'txn>>,
}

impl<'txn, C: AsMut<Cursor<'txn>>> CursorIterator<'txn, C> {
    pub fn new(
        cursor: C,
        start_key: Vec<u8>,
        end_key: Vec<u8>,
        integer_key: bool,
        duplicates: bool,
        skip_duplicates: bool,
    ) -> Result<Self> {
        let ascending = compare_keys(integer_key, &start_key, &end_key) != Ordering::Greater;
        let (lower_key, upper_key) = if ascending {
            (start_key, end_key)
        } else {
            (end_key, start_key)
        };
        let op: mdbx_sys::MDBX_cursor_op = match (ascending, skip_duplicates) {
            (true, true) => mdbx_sys::MDBX_cursor_op::MDBX_NEXT_NODUP,
            (true, false) => mdbx_sys::MDBX_cursor_op::MDBX_NEXT,
            (false, true) => mdbx_sys::MDBX_cursor_op::MDBX_PREV_NODUP,
            (false, false) => mdbx_sys::MDBX_cursor_op::MDBX_PREV,
        };
        let mut iterator = Self {
            cursor,
            lower_key,
            upper_key,
            integer_key,
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
                if compare_keys(self.integer_key, &self.lower_key, &last.0) != Ordering::Greater {
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
            if compare_keys(self.integer_key, &self.upper_key, &first_entry.0) == Ordering::Less {
                if !self.ascending {
                    if let Some(prev) = self.cursor.as_mut().move_to_prev_no_dup()? {
                        if compare_keys(self.integer_key, &self.lower_key, &prev.0)
                            != Ordering::Greater
                        {
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
        let next = self
            .cursor
            .as_mut()
            .op_get(self.op, None, None)
            .ok()
            .flatten();
        if let Some((key, value)) = next {
            let abort = if self.ascending {
                compare_keys(self.integer_key, &self.upper_key, &key) == Ordering::Less
            } else {
                compare_keys(self.integer_key, &self.lower_key, &key) == Ordering::Greater
            };
            if !abort {
                self.next = Some((key, value));
                return;
            }
        }
        self.next = None;
    }

    pub fn close(self) -> C {
        self.cursor
    }
}

impl<'txn, C: AsMut<Cursor<'txn>>> Iterator for CursorIterator<'txn, C> {
    type Item = KeyVal<'txn>;

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        let value = self.next;
        self.find_next();
        value
    }
}
