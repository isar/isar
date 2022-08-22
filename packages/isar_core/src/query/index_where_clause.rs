use crate::cursor::IsarCursors;
use crate::error::{IsarError, Result};
use crate::index::index_key::IndexKey;
use crate::index::index_key_builder::IndexKeyBuilder;
use crate::index::IsarIndex;
use crate::mdbx::db::Db;
use crate::object::isar_object::IsarObject;
use crate::query::Sort;
use intmap::IntMap;

#[derive(Clone)]
pub(crate) struct IndexWhereClause {
    db: Db,
    index: IsarIndex,
    lower_key: IndexKey,
    upper_key: IndexKey,
    skip_duplicates: bool,
    sort: Sort,
}

impl IndexWhereClause {
    pub fn new(
        db: Db,
        index: IsarIndex,
        lower_key: IndexKey,
        upper_key: IndexKey,
        skip_duplicates: bool,
        sort: Sort,
    ) -> Result<Self> {
        Ok(IndexWhereClause {
            db,
            index,
            lower_key,
            upper_key,
            skip_duplicates,
            sort,
        })
    }

    pub fn object_matches(&self, object: IsarObject) -> bool {
        let mut key_matches = false;
        let key_builder = IndexKeyBuilder::new(&self.index.properties);
        key_builder
            .create_keys(object, |key| {
                key_matches = key >= &self.lower_key && key <= &self.upper_key;
                Ok(!key_matches)
            })
            .unwrap();
        key_matches
    }

    pub fn iter_ids<'txn, 'env, F>(
        &self,
        cursors: &IsarCursors<'txn, 'env>,
        callback: F,
    ) -> Result<bool>
    where
        F: FnMut(i64) -> Result<bool>,
    {
        self.index.iter_between(
            cursors,
            &self.lower_key,
            &self.upper_key,
            self.skip_duplicates,
            self.sort == Sort::Ascending,
            callback,
        )
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
        let mut data_cursor = cursors.get_cursor(self.db)?;
        self.iter_ids(cursors, |id| {
            if let Some(result_ids) = result_ids.as_deref_mut() {
                if !result_ids.insert_checked(id as u64, ()) {
                    return Ok(true);
                }
            }

            let entry = data_cursor.move_to(&id)?;
            let (_, object) = entry.ok_or(IsarError::DbCorrupted {
                message: "Could not find object specified in index.".to_string(),
            })?;
            let object = IsarObject::from_bytes(&object);

            callback(id, object)
        })
    }

    pub fn is_overlapping(&self, other: &Self) -> bool {
        self.index != other.index
            || ((self.lower_key <= other.lower_key && self.upper_key >= other.upper_key)
                || (other.lower_key <= self.lower_key && other.upper_key >= self.upper_key))
    }

    pub fn has_duplicates(&self) -> bool {
        self.index.multi_entry
    }
}

/*#[cfg(test)]
mod tests {
    //use super::*;
    //use itertools::Itertools;

    #[macro_export]
    macro_rules! exec_wc (
        ($txn:ident, $col:ident, $wc:ident, $res:ident) => {
            let mut cursor = $col.debug_get_index(0).debug_get_db().cursor(&$txn).unwrap();
            let $res = $wc.iter(&mut cursor)
                .unwrap()
                .map(Result::unwrap)
                .map(|(_, v)| v)
                .collect_vec();
        };
    );

    /*fn get_str_obj(col: &IsarCollection, str: &str) -> Vec<u8> {
        let mut ob = col.new_object_builder();
        ob.write_string(Some(str));
        ob.finish()
    }*/

    #[test]
    fn test_iter() {
        /*isar!(isar, col => col!(field => String; ind!(field)));

        let txn = isar.begin_txn(true, false).unwrap();
        let oid1 = col.put(&txn, None, &get_str_obj(&col, "aaaa")).unwrap();
        let oid2 = col.put(&txn, None, &get_str_obj(&col, "aabb")).unwrap();
        let oid3 = col.put(&txn, None, &get_str_obj(&col, "bbaa")).unwrap();
        let oid4 = col.put(&txn, None, &get_str_obj(&col, "bbbb")).unwrap();

        let all_oids = &[
            oid1.as_ref(),
            oid2.as_ref(),
            oid3.as_ref(),
            oid4.as_ref(),
        ];

        let mut wc = col.new_where_clause(Some(0)).unwrap();
        exec_wc!(txn, col, wc, oids);
        assert_eq!(&oids, all_oids);

        wc.add_lower_string_value(Some("aa"), true);
        exec_wc!(txn, col, wc, oids);
        assert_eq!(&oids, all_oids);

        let mut wc = col.new_where_clause(Some(0)).unwrap();
        wc.add_lower_string_value(Some("aa"), false);
        exec_wc!(txn, col, wc, oids);
        assert_eq!(&oids, &[oid3.as_ref(), oid4.as_ref()]);

        wc.add_upper_string_value(Some("bba"), true);
        exec_wc!(txn, col, wc, oids);
        assert_eq!(&oids, &[oid3.as_ref()]);

        let mut wc = col.new_where_clause(Some(0)).unwrap();
        wc.add_lower_string_value(Some("x"), false);
        exec_wc!(txn, col, wc, oids);
        assert_eq!(&oids, &[] as &[&[u8]]);*/
    }

    #[test]
    fn test_add_upper_oid() {}
}
*/
