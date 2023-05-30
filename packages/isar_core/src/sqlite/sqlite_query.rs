use std::borrow::Cow;

use super::sql::{offset_limit_sql, select_properties_sql};
use super::sqlite3::SQLiteStatement;
use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use super::sqlite_reader::SQLiteReader;
use super::sqlite_txn::SQLiteTxn;
use crate::core::cursor::IsarCursor;
use crate::core::data_type::DataType;
use crate::core::error::Result;
use crate::core::instance::Aggregation;
use crate::core::value::IsarValue;

pub struct SQLiteQuery {
    sql: String,
    collection_index: u16,
}

impl SQLiteQuery {
    pub(crate) fn new(sql: String, collection_index: u16) -> Self {
        Self {
            sql,
            collection_index,
        }
    }

    pub(crate) fn cursor<'a>(
        &'a self,
        txn: &'a SQLiteTxn,
        all_collections: &'a [SQLiteCollection],
        offset: Option<u32>,
        limit: Option<u32>,
    ) -> Result<SQLiteCursor<'a>> {
        let collection = &all_collections[self.collection_index as usize];
        let sql = format!(
            "SELECT {} {} {}",
            select_properties_sql(collection),
            self.sql,
            offset_limit_sql(offset, limit)
        );
        let stmt = txn.get_sqlite(false)?.prepare(&sql)?;
        Ok(SQLiteCursor {
            stmt,
            collection,
            all_collections,
        })
    }

    pub(crate) fn aggregate(
        &self,
        txn: &SQLiteTxn,
        all_collections: &[SQLiteCollection],
        aggregation: Aggregation,
        property_index: Option<u16>,
    ) -> Result<Option<IsarValue>> {
        let collection = &all_collections[self.collection_index as usize];
        let property = if let Some(property_index) = property_index {
            collection.get_property(property_index)
        } else {
            None
        };
        let aggregation_sql = match aggregation {
            Aggregation::Count => "COUNT(*)".to_string(),
            Aggregation::IsEmpty => SQLiteProperty::ID_NAME.to_string(),
            Aggregation::Min => {
                if let Some(property) = property {
                    format!("MIN({})", property.name)
                } else {
                    return Ok(None);
                }
            }
            Aggregation::Max => {
                if let Some(property) = property {
                    format!("MAX({})", property.name)
                } else {
                    return Ok(None);
                }
            }
            Aggregation::Sum => {
                if let Some(property) = property {
                    format!("SUM({})", property.name)
                } else {
                    return Ok(None);
                }
            }
            Aggregation::Average => {
                if let Some(property) = property {
                    format!("AVG({})", property.name)
                } else {
                    return Ok(None);
                }
            }
        };
        let sql = format!("SELECT {} {}", aggregation_sql, self.sql);
        let mut stmt = txn.get_sqlite(false)?.prepare(&sql)?;

        let has_next = stmt.step()?;
        let result = match aggregation {
            Aggregation::Count => IsarValue::Integer(stmt.get_long(0)),
            Aggregation::IsEmpty => IsarValue::Bool(Some(!has_next)),
            Aggregation::Min | Aggregation::Max | Aggregation::Sum => {
                if let Some(property) = property {
                    match property.data_type {
                        DataType::Byte | DataType::Int | DataType::Long => {
                            IsarValue::Integer(stmt.get_long(0))
                        }
                        DataType::Float | DataType::Double => IsarValue::Real(stmt.get_double(0)),
                        DataType::String => IsarValue::String(Some(stmt.get_text(0).to_string())),
                        _ => return Ok(None),
                    }
                } else {
                    return Ok(None);
                }
            }
            Aggregation::Average => IsarValue::Real(stmt.get_double(0)),
        };
        Ok(Some(result))
    }

    pub(crate) fn delete(
        &self,
        txn: &SQLiteTxn,
        offset: Option<u32>,
        limit: Option<u32>,
    ) -> Result<u32> {
        let sql = format!("DELETE {} {}", self.sql, offset_limit_sql(offset, limit));
        let sqlite = txn.get_sqlite(true)?;
        let mut stmt = sqlite.prepare(&sql)?;
        stmt.step()?;
        let count = sqlite.count_changes();
        Ok(count as u32)
    }
}
pub struct SQLiteCursor<'a> {
    stmt: SQLiteStatement<'a>,
    collection: &'a SQLiteCollection,
    all_collections: &'a [SQLiteCollection],
}

impl<'a> IsarCursor for SQLiteCursor<'a> {
    type Reader<'b> = SQLiteReader<'b> where Self: 'b;

    fn next(&mut self) -> Option<Self::Reader<'_>> {
        let has_next = self.stmt.step().ok()?;
        if has_next {
            let reader = SQLiteReader::new(
                Cow::Borrowed(&self.stmt),
                self.collection,
                self.all_collections,
            );
            Some(reader)
        } else {
            None
        }
    }
}
