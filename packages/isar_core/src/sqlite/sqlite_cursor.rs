use super::sql::select_properties_sql;
use super::sqlite3::SQLiteStatement;
use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use super::sqlite_reader::SQLiteReader;
use super::sqlite_txn::SQLiteTxn;
use crate::core::cursor::IsarCursor;
use crate::core::error::Result;
use std::borrow::Cow;

pub struct SQLiteCursor<'a> {
    stmt: SQLiteStatement<'a>,
    collection: &'a SQLiteCollection,
    collections: &'a Vec<SQLiteCollection>,
}

impl<'a> SQLiteCursor<'a> {
    pub(crate) fn new(
        txn: &'a SQLiteTxn,
        collection: &'a SQLiteCollection,
        collections: &'a Vec<SQLiteCollection>,
    ) -> Result<Self> {
        let sql = format!(
            "SELECT {} FROM {} WHERE {} = ?",
            select_properties_sql(collection),
            collection.name,
            SQLiteProperty::ID_NAME,
        );
        let stmt = txn.get_sqlite(false)?.prepare(&sql)?;
        let cursor = Self {
            stmt,
            collection,
            collections,
        };
        Ok(cursor)
    }
}

impl<'a> IsarCursor for SQLiteCursor<'a> {
    type Reader<'b> = SQLiteReader<'b> where Self: 'b;

    fn next(&mut self, id: i64) -> Option<Self::Reader<'_>> {
        self.stmt.reset().ok()?;
        self.stmt.bind_long(0, id).ok()?;
        let has_next = self.stmt.step().ok()?;
        if has_next {
            let reader =
                SQLiteReader::new(Cow::Borrowed(&self.stmt), self.collection, self.collections);
            Some(reader)
        } else {
            None
        }
    }
}
