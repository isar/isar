use super::sqlite3::SQLiteStatement;
use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use super::sqlite_txn::SQLiteTxn;
use crate::core::error::Result;
use crate::core::insert::IsarInsert;

fn get_insert_sql(name: &str, properties: &[SQLiteProperty], count: usize) -> String {
    let mut sql = String::new();
    sql.push_str("INSERT OR REPLACE INTO ");
    sql.push_str(name);
    sql.push_str(" (_rowid_");

    for property in properties {
        sql.push_str(", ");
        sql.push_str(&property.name);
    }

    sql.push_str(") VALUES ");

    let mut batch = String::new();
    batch.push_str("(?");
    for _ in 0..properties.len() {
        batch.push_str(",?");
    }
    batch.push_str(")");

    sql.push_str(&batch);
    for _ in 1..count {
        sql.push_str(",");
        sql.push_str(&batch);
    }

    sql
}

pub struct SQLiteInsert<'a> {
    pub(crate) collection: &'a SQLiteCollection,
    pub(crate) all_collections: &'a Vec<SQLiteCollection>,

    txn: SQLiteTxn,
    pub(crate) stmt: SQLiteStatement<'a>,

    remaining: usize,
    batch_remaining: usize,

    pub(crate) buffer: Option<Vec<u8>>,
    pub(crate) property: usize,
}

impl<'a> SQLiteInsert<'a> {
    pub fn new(
        txn: SQLiteTxn,
        collection: &'a SQLiteCollection,
        all_collections: &'a Vec<SQLiteCollection>,
        count: usize,
    ) -> Self {
        let sql = get_insert_sql(&collection.name, &collection.properties, count);
        let stmt = txn.get_sqlite(true).unwrap().prepare(&sql).unwrap();
        /*Self {
            collection,
            all_collections,
            txn,
            stmt,
            remaining: 0,
            batch_remaining: count,
            buffer: Some(Vec::new()),
            property: 0,
        }*/
        todo!()
    }
}

impl<'a> IsarInsert<'a> for SQLiteInsert<'a> {
    type Txn = SQLiteTxn;

    fn insert(mut self, id: Option<i64>) -> Result<Self> {
        self.batch_remaining -= 1;

        if self.batch_remaining == 0 {
            self.txn.guard(|| {
                self.stmt.step()?;
                Ok(())
            })?;
        }

        Ok(self)
    }

    fn finish(self) -> Result<Self::Txn> {
        Ok(self.txn)
    }
}
