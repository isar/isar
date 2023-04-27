use super::sqlite3::SQLiteStatement;
use super::sqlite_collection::SQLiteCollection;
use super::sqlite_reader::SQLiteReader;
use super::sqlite_txn::SQLiteTxn;
use crate::core::cursor::IsarCursor;
use crate::core::error::Result;

pub struct SQLiteQuery {
    query: String,
}

impl SQLiteQuery {
    pub(crate) fn new(query: String) -> Self {
        Self { query }
    }

    pub(crate) fn cursor(&self, txn: &SQLiteTxn) -> Result<SQLiteCursor<'_>> {
        todo!()
        /*let mut sql = String::new();
        sql.push_str("SELECT _rowid_");
        for prop in &self.collection.properties {
            sql.push(',');
            sql.push_str(&prop.name);
        }
        sql.push_str(" ");
        sql.push_str(&self.query);

        let sqlite = txn.get_sqlite(false)?;
        let stmt = sqlite.prepare(&sql)?;
        Ok(SQLiteCursor {
            stmt,
            collection: self.collection,
            all_collections: self.all_collections,
        })*/
    }

    pub(crate) fn count(&self, txn: &SQLiteTxn) -> Result<usize> {
        let sql = format!("SELECT COUNT(*) {}", self.query);
        let sqlite = txn.get_sqlite(false)?;
        let mut stmt = sqlite.prepare(&sql)?;
        txn.guard(|| stmt.step())?;
        let count = stmt.get_long(0);
        Ok(count as usize)
    }

    pub(crate) fn delete(&self, txn: &SQLiteTxn) -> Result<usize> {
        let sql = format!("DELETE {}", self.query);
        let sqlite = txn.get_sqlite(true)?;
        let mut stmt = sqlite.prepare(&sql)?;
        txn.guard(|| stmt.step())?;
        let count = stmt.count_changes();
        Ok(count as usize)
    }
}

pub struct SQLiteCursor<'a> {
    stmt: SQLiteStatement<'a>,
    collection: &'a SQLiteCollection,
    all_collections: &'a Vec<SQLiteCollection>,
}

impl<'a> IsarCursor for SQLiteCursor<'a> {
    type Reader<'b> = SQLiteReader<'b> where Self: 'b;

    fn next(&mut self) -> Option<Self::Reader<'_>> {
        let has_next = self.stmt.step().ok()?;
        if has_next {
            let reader = SQLiteReader::new(&self.stmt, self.collection, self.all_collections);
            Some(reader)
        } else {
            None
        }
    }
}
