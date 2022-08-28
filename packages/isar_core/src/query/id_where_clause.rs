use crate::cursor::IsarCursors;
use crate::error::Result;
use crate::mdbx::db::Db;
use crate::object::id::BytesToId;
use crate::object::isar_object::IsarObject;
use crate::query::Sort;
use intmap::IntMap;

#[derive(Clone)]
pub(crate) struct IdWhereClause {
    db: Db,
    lower: i64,
    upper: i64,
    sort: Sort,
}

impl IdWhereClause {
    pub(crate) fn new(db: Db, lower: i64, upper: i64, sort: Sort) -> Self {
        IdWhereClause {
            db,
            lower,
            upper,
            sort,
        }
    }

    pub fn is_empty(&self) -> bool {
        self.upper < self.lower
    }

    pub(crate) fn id_matches(&self, id: i64) -> bool {
        self.lower <= id && self.upper >= id
    }

    pub(crate) fn iter<'txn, 'env, F>(
        &self,
        cursors: &IsarCursors<'txn, 'env>,
        mut result_ids: Option<&mut IntMap<()>>,
        mut callback: F,
    ) -> Result<bool>
    where
        F: FnMut(i64, IsarObject<'txn>) -> Result<bool>,
    {
        let mut cursor = cursors.get_cursor(self.db)?;
        cursor.iter_between(
            &self.lower,
            &self.upper,
            false,
            false,
            self.sort == Sort::Ascending,
            |_, id_bytes, object| {
                let id = id_bytes.to_id();
                if let Some(result_ids) = result_ids.as_deref_mut() {
                    if !result_ids.insert_checked(id as u64, ()) {
                        return Ok(true);
                    }
                }
                let object = IsarObject::from_bytes(object);
                callback(id, object)
            },
        )
    }

    pub(crate) fn is_overlapping(&self, other: &Self) -> bool {
        (self.lower <= other.lower && self.upper >= other.upper)
            || (other.lower <= self.lower && other.upper >= self.upper)
    }
}
