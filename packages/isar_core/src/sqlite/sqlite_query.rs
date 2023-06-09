use std::borrow::Cow;

use super::sql::{offset_limit_sql, select_properties_sql, FN_FILTER_JSON_COND_PTR_TYPE};
use super::sqlite3::SQLiteStatement;
use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use super::sqlite_reader::SQLiteReader;
use super::sqlite_txn::SQLiteTxn;
use crate::core::cursor::IsarCursor;
use crate::core::data_type::DataType;
use crate::core::error::Result;
use crate::core::filter::JsonCondition;
use crate::core::instance::Aggregation;
use crate::core::value::IsarValue;

#[derive(Debug)]
pub(crate) enum QueryParam {
    Value(IsarValue),
    JsonCondition(JsonCondition),
}

pub struct SQLiteQuery {
    collection_index: u16,
    sql: String,
    has_sort_distinct: bool,
    params: Vec<QueryParam>,
}

impl SQLiteQuery {
    pub(crate) fn new(
        collection_index: u16,
        sql: String,
        has_sort_distinct: bool,
        params: Vec<QueryParam>,
    ) -> Self {
        Self {
            collection_index,
            sql,
            has_sort_distinct,
            params,
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
        let mut stmt = txn.get_sqlite(false)?.prepare(&sql)?;
        self.bind_params(&mut stmt)?;

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
        let property_name = collection.get_property_name(property_index.unwrap_or(0));
        let property_type = collection
            .get_property(property_index.unwrap_or(0))
            .map_or(DataType::Long, |p| p.data_type);

        let aggregation_sql = match aggregation {
            Aggregation::Count => "COUNT(*)".to_string(),
            Aggregation::IsEmpty => SQLiteProperty::ID_NAME.to_string(),
            Aggregation::Min => {
                format!("MIN({})", property_name)
            }
            Aggregation::Max => {
                format!("MAX({})", property_name)
            }
            Aggregation::Sum => {
                format!("SUM({})", property_name)
            }
            Aggregation::Average => {
                format!("AVG({})", property_name)
            }
        };
        let sql = format!("SELECT {} {}", aggregation_sql, self.sql);
        let mut stmt = txn.get_sqlite(false)?.prepare(&sql)?;
        self.bind_params(&mut stmt)?;

        let has_next = stmt.step()?;
        let result = match aggregation {
            Aggregation::Count => IsarValue::Integer(stmt.get_long(0)),
            Aggregation::IsEmpty => IsarValue::Bool(!has_next),
            Aggregation::Min | Aggregation::Max | Aggregation::Sum => {
                if aggregation == Aggregation::Sum || !stmt.is_null(0) {
                    match property_type {
                        DataType::Byte | DataType::Int | DataType::Long => {
                            IsarValue::Integer(stmt.get_long(0))
                        }
                        DataType::Float | DataType::Double => IsarValue::Real(stmt.get_double(0)),
                        DataType::String => IsarValue::String(stmt.get_text(0).to_string()),
                        _ => return Ok(None),
                    }
                } else {
                    return Ok(None);
                }
            }
            Aggregation::Average => {
                if !stmt.is_null(0) {
                    IsarValue::Real(stmt.get_double(0))
                } else {
                    return Ok(None);
                }
            }
        };
        Ok(Some(result))
    }

    pub(crate) fn delete(
        &self,
        txn: &SQLiteTxn,
        all_collections: &[SQLiteCollection],
        offset: Option<u32>,
        limit: Option<u32>,
    ) -> Result<u32> {
        let sql = if offset.is_some() || limit.is_some() || self.has_sort_distinct {
            let collection = &all_collections[self.collection_index as usize];
            format!(
                "DELETE FROM {} WHERE {} IN (SELECT {} {} {})",
                collection.name,
                SQLiteProperty::ID_NAME,
                SQLiteProperty::ID_NAME,
                self.sql,
                offset_limit_sql(offset, limit)
            )
        } else {
            format!("DELETE {} {}", self.sql, offset_limit_sql(offset, limit))
        };
        let sqlite = txn.get_sqlite(true)?;
        let mut stmt = sqlite.prepare(&sql)?;
        self.bind_params(&mut stmt)?;
        stmt.step()?;
        let count = sqlite.count_changes();
        Ok(count as u32)
    }

    fn bind_params(&self, stmt: &mut SQLiteStatement) -> Result<()> {
        for (i, params) in self.params.iter().enumerate() {
            match params {
                QueryParam::Value(IsarValue::Bool(value)) => {
                    let value = if *value { 1 } else { 0 };
                    stmt.bind_int(i as u32, value)?;
                }
                QueryParam::Value(IsarValue::Integer(value)) => stmt.bind_long(i as u32, *value)?,
                QueryParam::Value(IsarValue::Real(value)) => stmt.bind_double(i as u32, *value)?,
                QueryParam::Value(IsarValue::String(value)) => stmt.bind_text(i as u32, value)?,
                QueryParam::JsonCondition(cond) => {
                    stmt.bind_object(i as u32, cond, FN_FILTER_JSON_COND_PTR_TYPE)?
                }
            }
        }
        Ok(())
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
