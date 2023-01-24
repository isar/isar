use super::sqlite_collection::SQLiteCollection;
use super::sqlite_txn::SQLiteTxn;
use super::sqlite_writer::SQLiteWriter;
use crate::core::error::{IsarError, Result};
use crate::core::insert::IsarInsert;

pub struct SQLiteInsert<'a> {
    txn: &'a SQLiteTxn<'a>,
    collection: &'a SQLiteCollection,
    all_collections: &'a Vec<SQLiteCollection>,
    inserted_count: usize,
    count: usize,
}

impl<'a> SQLiteInsert<'a> {
    pub fn new(
        txn: &'a SQLiteTxn<'a>,
        collection: &'a SQLiteCollection,
        all_collections: &'a Vec<SQLiteCollection>,
        count: usize,
    ) -> Self {
        Self {
            txn,
            collection,
            all_collections,
            inserted_count: 0,
            count: count,
        }
    }

    fn get_writer_with_buffer(&self, buffer: Option<Vec<u8>>) -> Result<SQLiteWriter<'a>> {
        if self.inserted_count >= self.count {
            return Err(IsarError::IllegalArg {
                message: "No more objects to insert".to_string(),
            });
        }

        let mut sql = String::new();
        sql.push_str("INSERT OR REPLACE INTO ");
        sql.push_str(&self.collection.name);
        sql.push_str(" (_rowid_");

        for property in &self.collection.properties {
            sql.push_str(", ");
            sql.push_str(&property.name);
        }

        sql.push_str(") VALUES ");

        let mut batch = String::new();
        batch.push_str("(?");
        for _ in 0..self.collection.properties.len() {
            batch.push_str(",?");
        }
        batch.push_str(")");

        let remaining = self.count - self.inserted_count;
        sql.push_str(&batch);
        for _ in 1..remaining {
            sql.push_str(",");
            sql.push_str(&batch);
        }

        let statement = self.txn.get_sqlite(true)?.prepare(&sql)?;
        let writer = SQLiteWriter::new(
            statement,
            remaining,
            self.collection,
            self.all_collections,
            buffer,
        );
        Ok(writer)
    }
}

impl<'a> IsarInsert<'a> for SQLiteInsert<'a> {
    type Writer = SQLiteWriter<'a>;

    fn get_writer(&self) -> Result<Self::Writer> {
        self.get_writer_with_buffer(None)
    }

    fn insert(&mut self, writer: Self::Writer) -> Result<Option<Self::Writer>> {
        if writer.next() {
            Ok(Some(writer))
        } else {
            let (mut stmt, count, buffer) = writer.finalize();
            self.txn.guard(|| {
                stmt.step()?;
                Ok(())
            })?;
            self.inserted_count += count;

            if self.inserted_count < self.count {
                let new_writer = self.get_writer_with_buffer(Some(buffer))?;
                Ok(Some(new_writer))
            } else {
                Ok(None)
            }
        }
    }
}
