use super::sqlite3::{SQLite3, SQLiteStatement};
use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use super::sqlite_txn::SQLiteTxn;
use crate::core::error::{IsarError, Result};
use crate::core::insert::IsarInsert;
use ouroboros::self_referencing;
use std::cell::Cell;
use std::cmp::min;

fn get_insert_sql(name: &str, properties: &[SQLiteProperty], count: u32) -> (u32, String) {
    let mut sql = String::new();
    sql.push_str("INSERT OR REPLACE INTO ");
    sql.push_str(name);
    sql.push_str(" (_id");

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

    let batch_size = min(
        count,
        SQLite3::MAX_PARAM_COUNT / (properties.len() as u32 + 1),
    );
    sql.push_str(&batch);
    for _ in 1..batch_size {
        sql.push_str(",");
        sql.push_str(&batch);
    }

    (batch_size, sql)
}

#[self_referencing]
struct TxnWithStatement {
    txn: SQLiteTxn,
    #[borrows(txn)]
    #[not_covariant]
    statement: Cell<SQLiteStatement<'this>>,
}

impl TxnWithStatement {
    fn open(
        txn: SQLiteTxn,
        collection: &SQLiteCollection,
        count: u32,
    ) -> Result<(u32, TxnWithStatement)> {
        let (batch_size, sql) = get_insert_sql(&collection.name, &collection.properties, count);
        let txn_stmt = Self::try_new(txn, |txn| {
            Ok(Cell::new(txn.get_sqlite(true)?.prepare(&sql)?))
        })?;
        Ok((batch_size, txn_stmt))
    }

    fn next(&mut self, collection: &SQLiteCollection, count: u32) -> Result<u32> {
        let (batch_size, sql) = get_insert_sql(&collection.name, &collection.properties, count);

        self.with_mut(|s| {
            s.txn.guard(|| s.statement.get_mut().step())?;
            s.statement.replace(s.txn.get_sqlite(true)?.prepare(&sql)?);
            Ok(())
        })?;

        Ok(batch_size)
    }

    fn finish(mut self) -> Result<SQLiteTxn> {
        self.with_mut(|s| s.txn.guard(|| s.statement.get_mut().step()))?;
        Ok(self.into_heads().txn)
    }
}

pub struct SQLiteInsert<'a> {
    pub(crate) collection: &'a SQLiteCollection,
    pub(crate) all_collections: &'a Vec<SQLiteCollection>,

    txn_stmt: TxnWithStatement,

    remaining: u32,
    batch_remaining: u32,
    pub(crate) batch_property: u32,

    pub(crate) buffer: Option<Vec<u8>>,
}

impl<'a> SQLiteInsert<'a> {
    pub fn new(
        txn: SQLiteTxn,
        collection: &'a SQLiteCollection,
        all_collections: &'a Vec<SQLiteCollection>,
        count: u32,
    ) -> Result<Self> {
        let (batch_count, txn_stmt) = TxnWithStatement::open(txn, collection, count)?;
        let insert = Self {
            collection,
            all_collections,
            txn_stmt,
            remaining: count - batch_count,
            batch_remaining: batch_count,
            batch_property: 1, // 0 is _id
            buffer: Some(Vec::new()),
        };
        Ok(insert)
    }

    #[inline]
    pub(crate) fn with_stmt<T>(&mut self, callback: impl FnOnce(&mut SQLiteStatement) -> T) -> T {
        self.txn_stmt
            .with_statement_mut(|stmt| callback(stmt.get_mut()))
    }
}

impl<'a> IsarInsert<'a> for SQLiteInsert<'a> {
    type Txn = SQLiteTxn;

    fn save(&mut self, id: i64) -> Result<()> {
        if self.batch_remaining > 0 {
            self.batch_remaining -= 1;

            if self.batch_property % (self.collection.properties.len() as u32 + 1) > 0 {
                return Result::Err(IsarError::InsertIncomplete {});
            }

            let id_property = self.batch_property - self.collection.properties.len() as u32 - 1;

            self.with_stmt(|stmt| stmt.bind_long(id_property, id))?;

            if self.batch_remaining == 0 && self.remaining > 0 {
                let batch_size = self.txn_stmt.next(self.collection, self.remaining)?;
                self.remaining -= batch_size;
                self.batch_remaining = batch_size;
                self.batch_property = 1;
            } else {
                self.batch_property += 1; // Skip id
            }

            Ok(())
        } else {
            Err(IsarError::UnsupportedOperation {})
        }
    }

    fn finish(self) -> Result<Self::Txn> {
        self.txn_stmt.finish()
    }
}
