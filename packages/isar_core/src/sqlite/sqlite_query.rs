use super::sqlite3::SQLiteStatement;
use super::sqlite_collection::SQLiteCollection;
use super::sqlite_reader::SQLiteReader;
use super::sqlite_txn::SQLiteTxn;
use crate::core::error::Result;
use crate::core::query::{IsarCursor, IsarQuery};

pub struct SQLiteQuery<'a> {
    query: String,
    collection: &'a SQLiteCollection,
    all_collections: &'a Vec<SQLiteCollection>,
}

impl<'a> SQLiteQuery<'a> {
    pub fn new(
        query: String,
        collection: &'a SQLiteCollection,
        all_collections: &'a Vec<SQLiteCollection>,
    ) -> Self {
        Self {
            query,
            collection,
            all_collections,
        }
    }
}

impl<'a> IsarQuery for SQLiteQuery<'a> {
    type Txn = SQLiteTxn<'a>;

    type Cursor<'b> = SQLiteCursor<'b> where Self: 'b;

    fn cursor<'b>(&'b self, txn: &'b mut Self::Txn) -> Result<Self::Cursor<'b>> {
        let mut sql = String::new();
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
        })
    }

    fn count(&self, txn: &mut Self::Txn) -> Result<u32> {
        let sql = format!("SELECT COUNT(*) {}", self.query);
        eprintln!("SQL: {}", sql);

        let sqlite = txn.get_sqlite(false)?;
        let mut stmt = sqlite.prepare(&sql)?;
        stmt.step()?;
        let count = stmt.get_long(0);
        Ok(count as u32)
    }

    fn delete(&self, txn: &mut Self::Txn) -> Result<u32> {
        let sql = format!("DELETE {}", self.query);
        let sqlite = txn.get_sqlite(true)?;
        let mut stmt = sqlite.prepare(&sql)?;
        stmt.step()?;
        let count = stmt.count_changes();
        Ok(count as u32)
    }
}

pub struct SQLiteCursor<'a> {
    stmt: SQLiteStatement<'a>,
    collection: &'a SQLiteCollection,
    all_collections: &'a Vec<SQLiteCollection>,
}

impl<'a> IsarCursor for SQLiteCursor<'a> {
    type Reader<'b> = SQLiteReader<'b> where Self: 'b;

    fn next(&mut self) -> Result<Option<Self::Reader<'_>>> {
        let has_next = self.stmt.step()?;
        if has_next {
            let reader = SQLiteReader::new(&self.stmt, self.collection, self.all_collections);
            Ok(Some(reader))
        } else {
            Ok(None)
        }
    }
}
