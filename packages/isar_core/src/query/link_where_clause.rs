use crate::cursor::IsarCursors;
use crate::error::Result;
use crate::link::IsarLink;
use crate::object::isar_object::IsarObject;
use intmap::IntMap;

#[derive(Clone)]
pub(crate) struct LinkWhereClause {
    link: IsarLink,
    id: i64,
}

impl LinkWhereClause {
    pub fn new(link: IsarLink, id: i64) -> Result<Self> {
        Ok(LinkWhereClause { link, id })
    }

    pub fn iter<'txn, 'env, F>(
        &self,
        cursors: &IsarCursors<'txn, 'env>,
        mut result_ids: Option<&mut IntMap<()>>,
        mut callback: F,
    ) -> Result<bool>
    where
        F: FnMut(i64, IsarObject<'txn>) -> Result<bool>,
    {
        self.link.iter(cursors, self.id, |id, object| {
            if let Some(result_ids) = result_ids.as_deref_mut() {
                if !result_ids.insert_checked(id as u64, ()) {
                    return Ok(true);
                }
            }
            callback(id, object)
        })
    }
}
