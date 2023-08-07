use super::sqlite3::SQLite3;
use super::sqlite_collection::SQLiteCollection;
use super::sqlite_cursor::SQLiteCursor;
use super::sqlite_insert::SQLiteInsert;
use super::sqlite_open::{close_instance, get_instance, open_instance};
use super::sqlite_query::{SQLiteQuery, SQLiteQueryCursor};
use super::sqlite_query_builder::SQLiteQueryBuilder;
use super::sqlite_reader::SQLiteReader;
use super::sqlite_txn::SQLiteTxn;
use super::sqlite_verify::verify_sqlite;
use crate::core::error::{IsarError, Result};
use crate::core::filter::{ConditionType, Filter, FilterCondition};
use crate::core::instance::{Aggregation, CompactCondition, IsarInstance};
use crate::core::query_builder::IsarQueryBuilder;
use crate::core::schema::IsarSchema;
use crate::core::value::IsarValue;
use crate::core::watcher::{WatchHandle, WatcherCallback};
use parking_lot::lock_api::RawMutex;
use std::cell::Cell;
use std::rc::Rc;
use std::sync::Arc;
use std::vec;

pub(crate) struct SQLiteInstanceInfo {
    pub(crate) instance_id: u32,
    pub(crate) name: String,
    pub(crate) dir: String,
    pub(crate) path: String,
    pub(crate) encryption_key: Option<String>,

    collections: Vec<SQLiteCollection>,
    write_mutex: parking_lot::RawMutex,
}

impl SQLiteInstanceInfo {
    pub(crate) fn new(
        instance_id: u32,
        name: &str,
        dir: &str,
        path: &str,
        encryption_key: Option<&str>,
        collections: Vec<SQLiteCollection>,
    ) -> Self {
        Self {
            instance_id,
            name: name.to_string(),
            dir: dir.to_string(),
            path: path.to_string(),
            encryption_key: encryption_key.map(|s| s.to_string()),
            collections,
            write_mutex: RawMutex::INIT,
        }
    }
}

pub struct SQLiteInstance {
    info: Arc<SQLiteInstanceInfo>,
    sqlite: Rc<SQLite3>,
    txn_active: Cell<bool>,
}

impl SQLiteInstance {
    fn get_collection(&self, collection_index: u16) -> Result<&SQLiteCollection> {
        if let Some(collection) = self.info.collections.get(collection_index as usize) {
            Ok(collection)
        } else {
            Err(IsarError::IllegalArgument {})
        }
    }
}

impl IsarInstance for SQLiteInstance {
    type Instance = Self;

    type Txn = SQLiteTxn;

    type Reader<'a> = SQLiteReader<'a>;

    type Cursor<'a> = SQLiteCursor<'a>
    where
        Self: 'a;

    type Insert<'a> = SQLiteInsert<'a>;

    type QueryBuilder<'a> = SQLiteQueryBuilder<'a>;

    type Query = SQLiteQuery;

    type QueryCursor<'a> = SQLiteQueryCursor<'a>
    where
        Self: 'a;

    fn get_name(&self) -> &str {
        &self.info.name
    }

    fn get_dir(&self) -> &str {
        &self.info.dir
    }

    fn get_collections(&self) -> impl Iterator<Item = &str> {
        self.info.collections.iter().map(|c| c.name.as_str())
    }

    fn get_instance(instance_id: u32) -> Option<Self::Instance> {
        let (info, sqlite) = get_instance(instance_id)?;
        Some(Self {
            info,
            sqlite: Rc::new(sqlite),
            txn_active: Cell::new(false),
        })
    }

    fn open_instance(
        instance_id: u32,
        name: &str,
        dir: &str,
        schemas: Vec<IsarSchema>,
        max_size_mib: u32,
        encryption_key: Option<&str>,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Self> {
        if compact_condition.is_some() {
            return Err(IsarError::IllegalArgument {});
        }
        if !cfg!(feature = "sqlcipher") && encryption_key.is_some() {
            return Err(IsarError::UnsupportedOperation {});
        }

        let (info, sqlite) = open_instance(
            instance_id,
            name,
            dir,
            schemas,
            max_size_mib,
            encryption_key,
        )?;
        Ok(Self {
            info,
            sqlite: Rc::new(sqlite),
            txn_active: Cell::new(false),
        })
    }

    fn begin_txn(&self, write: bool) -> Result<SQLiteTxn> {
        if write {
            self.info.write_mutex.lock();
        }
        if self.txn_active.replace(true) {
            Err(IsarError::TransactionActive {})
        } else {
            SQLiteTxn::new(self.sqlite.clone(), write)
        }
    }

    fn commit_txn(&self, txn: SQLiteTxn) -> Result<()> {
        self.txn_active.replace(false);
        let write = txn.is_write();
        let result = txn.commit();
        if write {
            unsafe { self.info.write_mutex.unlock() };
        }
        result
    }

    fn abort_txn(&self, txn: SQLiteTxn) {
        self.txn_active.replace(false);
        let write = txn.is_write();
        txn.abort();
        if write {
            unsafe { self.info.write_mutex.unlock() };
        }
    }

    fn auto_increment(&self, collection_index: u16) -> i64 {
        if let Ok(collection) = self.get_collection(collection_index) {
            collection.auto_increment()
        } else {
            0
        }
    }

    fn cursor<'a>(&'a self, txn: &'a Self::Txn, collection_index: u16) -> Result<Self::Cursor<'a>> {
        let collection = self.get_collection(collection_index)?;
        SQLiteCursor::new(txn, collection, &self.info.collections)
    }

    fn insert<'a>(
        &'a self,
        txn: SQLiteTxn,
        collection_index: u16,
        count: u32,
    ) -> Result<Self::Insert<'a>> {
        let collection = self.get_collection(collection_index)?;
        txn.monitor_changes(&collection.watchers);

        SQLiteInsert::new(txn, collection, &self.info.collections, count)
    }

    fn update(
        &self,
        txn: &Self::Txn,
        collection_index: u16,
        id: i64,
        updates: &[(u16, Option<IsarValue>)],
    ) -> Result<bool> {
        let mut qb = self.query(collection_index)?;
        qb.set_filter(Filter::Condition(FilterCondition::new(
            0,
            ConditionType::Equal,
            vec![Some(IsarValue::Integer(id))],
            false,
        )));
        let q = qb.build();
        let count = self.query_update(txn, &q, None, None, updates)?;
        Ok(count > 0)
    }

    fn delete<'a>(&'a self, txn: &'a Self::Txn, collection_index: u16, id: i64) -> Result<bool> {
        let mut qb = self.query(collection_index)?;
        qb.set_filter(Filter::Condition(FilterCondition::new(
            0,
            ConditionType::Equal,
            vec![Some(IsarValue::Integer(id))],
            false,
        )));
        let q = qb.build();
        let count = self.query_delete(txn, &q, None, None)?;
        Ok(count > 0)
    }

    fn count(&self, txn: &Self::Txn, collection_index: u16) -> Result<u32> {
        let q = self.query(collection_index)?.build();
        let result = self.query_aggregate(txn, &q, Aggregation::Count, None)?;
        if let Some(IsarValue::Integer(count)) = result {
            Ok(count as u32)
        } else {
            Ok(0)
        }
    }

    fn clear(&self, txn: &Self::Txn, collection_index: u16) -> Result<()> {
        let q = self.query(collection_index)?.build();
        self.query_delete(txn, &q, None, None)?;
        Ok(())
    }

    fn get_size(
        &self,
        _txn: &Self::Txn,
        _collection_index: u16,
        _include_indexes: bool,
    ) -> Result<u64> {
        Err(IsarError::UnsupportedOperation {})
    }

    fn query(&self, collection_index: u16) -> Result<Self::QueryBuilder<'_>> {
        self.get_collection(collection_index)?;
        Ok(SQLiteQueryBuilder::new(
            &self.info.collections,
            collection_index,
        ))
    }

    fn query_cursor<'a>(
        &'a self,
        txn: &'a Self::Txn,
        query: &'a Self::Query,
        offset: Option<u32>,
        limit: Option<u32>,
    ) -> Result<Self::QueryCursor<'_>> {
        query.cursor(txn, &self.info.collections, offset, limit)
    }

    fn query_aggregate(
        &self,
        txn: &Self::Txn,
        query: &Self::Query,
        aggregation: Aggregation,
        property_index: Option<u16>,
    ) -> Result<Option<IsarValue>> {
        query.aggregate(txn, &self.info.collections, aggregation, property_index)
    }

    fn query_update(
        &self,
        txn: &Self::Txn,
        query: &Self::Query,
        offset: Option<u32>,
        limit: Option<u32>,
        updates: &[(u16, Option<IsarValue>)],
    ) -> Result<u32> {
        let collection = self.get_collection(query.collection_index)?;
        txn.monitor_changes(&collection.watchers);
        let result =
            txn.guard(|| query.update(txn, &self.info.collections, offset, limit, updates))?;
        txn.stop_monitor_changes();
        Ok(result)
    }

    fn query_delete(
        &self,
        txn: &Self::Txn,
        query: &Self::Query,
        offset: Option<u32>,
        limit: Option<u32>,
    ) -> Result<u32> {
        let collection = self.get_collection(query.collection_index)?;
        txn.monitor_changes(&collection.watchers);
        let result = txn.guard(|| query.delete(txn, &self.info.collections, offset, limit))?;
        txn.stop_monitor_changes();
        Ok(result)
    }

    fn watch(&self, collection_index: u16, callback: WatcherCallback) -> Result<WatchHandle> {
        let collection = self.get_collection(collection_index)?;
        let handle = collection.watchers.watch(callback);
        Ok(handle)
    }

    fn watch_object(
        &self,
        collection_index: u16,
        id: i64,
        callback: WatcherCallback,
    ) -> Result<WatchHandle> {
        let collection = self.get_collection(collection_index)?;
        let handle = collection.watchers.watch_object(id, callback);
        Ok(handle)
    }

    fn watch_query(&self, query: &Self::Query, callback: WatcherCallback) -> Result<WatchHandle> {
        let collection = self.get_collection(query.collection_index)?;
        let handle = collection.watchers.watch_query(query, callback);
        Ok(handle)
    }

    fn copy(&self, path: &str) -> Result<()> {
        if Rc::strong_count(&self.sqlite) > 1 {
            return Err(IsarError::UnsupportedOperation {});
        }

        let sql = format!("VACUUM INTO '{}'", path);
        self.sqlite.prepare(&sql)?.step()?;
        Ok(())
    }

    fn verify(&self, _txn: &Self::Txn) -> Result<()> {
        verify_sqlite(&self.sqlite, &self.info.collections)
    }

    fn close(instance: Self::Instance, delete: bool) -> bool {
        close_instance(instance.info, instance.sqlite, delete)
    }
}
