use super::schema_manager::perform_migration;
use super::sql::{select_properties_sql, sql_fn_filter_json, FN_FILTER_JSON_NAME};
use super::sqlite3::SQLite3;
use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use super::sqlite_insert::SQLiteInsert;
use super::sqlite_query::{SQLiteCursor, SQLiteQuery};
use super::sqlite_query_builder::SQLiteQueryBuilder;
use super::sqlite_reader::SQLiteReader;
use super::sqlite_txn::SQLiteTxn;
use crate::core::error::{IsarError, Result};
use crate::core::filter::{ConditionType, Filter, FilterCondition};
use crate::core::instance::{Aggregation, CompactCondition, IsarInstance};
use crate::core::query_builder::IsarQueryBuilder;
use crate::core::schema::IsarSchema;
use crate::core::value::IsarValue;
use crate::core::watcher::{WatchHandle, WatcherCallback};
use intmap::IntMap;
use itertools::Itertools;
use parking_lot::lock_api::RawMutex;
use parking_lot::Mutex;
use std::borrow::Cow;
use std::cell::Cell;
use std::fs::remove_file;
use std::path::PathBuf;
use std::rc::Rc;
use std::sync::{Arc, LazyLock};
use std::vec;

static INSTANCES: LazyLock<Mutex<IntMap<Connections>>> =
    LazyLock::new(|| Mutex::new(IntMap::new()));

const MIB: usize = 1 << 20;

struct Connections {
    info: Arc<SQLiteInstanceInfo>,
    sqlite: Vec<SQLite3>,
}

struct SQLiteInstanceInfo {
    name: String,
    dir: String,
    path: String,
    encryption_key: Option<String>,
    instance_id: u32,
    collections: Vec<SQLiteCollection>,
    write_mutex: parking_lot::RawMutex,
}

pub struct SQLiteInstance {
    info: Arc<SQLiteInstanceInfo>,
    sqlite: Rc<SQLite3>,
    txn_active: Cell<bool>,
}

impl SQLiteInstance {
    fn open(
        instance_id: u32,
        name: &str,
        dir: &str,
        schemas: Vec<IsarSchema>,
        max_size_mib: u32,
        encryption_key: Option<&str>,
    ) -> Result<(SQLiteInstanceInfo, SQLite3)> {
        let path = if !dir.is_empty() {
            let mut path_buf = PathBuf::from(dir);
            path_buf.push(format!("{}.sqlite", name));
            path_buf.as_path().to_str().unwrap().to_string()
        } else {
            String::new()
        };

        let sqlite = Self::open_conn(&path, encryption_key)?;

        let max_size = (max_size_mib as usize).saturating_mul(MIB);
        sqlite
            .prepare(&format!("PRAGMA mmap_size={}", max_size))?
            .step()?;
        sqlite.prepare("PRAGMA journal_mode=WAL")?.step()?;

        let sqlite = Rc::new(sqlite);
        let txn = SQLiteTxn::new(sqlite.clone(), true)?;
        perform_migration(&txn, &schemas)?;
        txn.commit()?;

        let collections = Self::get_collections(&schemas);
        {
            let txn = SQLiteTxn::new(sqlite.clone(), false)?;
            for collection in &collections {
                if !collection.is_embedded() {
                    collection.init_auto_increment(&txn)?;
                }
            }
            txn.abort();
        }

        let instance_info = SQLiteInstanceInfo {
            name: name.to_string(),
            dir: dir.to_string(),
            encryption_key: encryption_key.map(|k| k.to_string()),
            instance_id,
            path,
            collections,
            write_mutex: RawMutex::INIT,
        };

        let sqlite = Rc::into_inner(sqlite).unwrap();
        Ok((instance_info, sqlite))
    }

    fn get_collections(schemas: &[IsarSchema]) -> Vec<SQLiteCollection> {
        let mut collections = Vec::new();
        for collection_schema in schemas {
            let properties = collection_schema
                .properties
                .iter()
                .filter_map(|p| {
                    if let Some(name) = &p.name {
                        let target_collection_index = p.collection.as_deref().map(|c| {
                            let position = schemas.iter().position(|c2| c2.name == c).unwrap();
                            position as u16
                        });
                        let prop = SQLiteProperty::new(name, p.data_type, target_collection_index);
                        Some(prop)
                    } else {
                        None
                    }
                })
                .collect_vec();
            let collection = SQLiteCollection::new(
                collection_schema.name.clone(),
                collection_schema.id_name.clone(),
                properties,
            );
            collections.push(collection);
        }
        collections
    }

    fn get_collection(&self, collection_index: u16) -> Result<&SQLiteCollection> {
        if let Some(collection) = self.info.collections.get(collection_index as usize) {
            Ok(collection)
        } else {
            Err(IsarError::IllegalArgument {})
        }
    }

    fn open_conn(path: &str, encryption_key: Option<&str>) -> Result<SQLite3> {
        let mut sqlite = SQLite3::open(path, encryption_key)?;
        sqlite.create_function(FN_FILTER_JSON_NAME, 2, sql_fn_filter_json)?;
        Ok(sqlite)
    }
}

impl IsarInstance for SQLiteInstance {
    type Instance = Self;

    type Txn = SQLiteTxn;

    type Reader<'a> = SQLiteReader<'a>;

    type Insert<'a> = SQLiteInsert<'a>;

    type QueryBuilder<'a> = SQLiteQueryBuilder<'a>;

    type Query = SQLiteQuery;

    type Cursor<'a> = SQLiteCursor<'a>
    where
        Self: 'a;

    fn get_instance(instance_id: u32) -> Option<Self::Instance> {
        let mut lock = INSTANCES.lock();
        if let Some(connections) = lock.get_mut(instance_id as u64) {
            let sqlite = connections.sqlite.pop().or_else(|| {
                Self::open_conn(
                    &connections.info.path,
                    connections.info.encryption_key.as_deref(),
                )
                .ok()
            });
            if let Some(sqlite) = sqlite {
                Some(Self {
                    info: connections.info.clone(),
                    sqlite: Rc::new(sqlite),
                    txn_active: Cell::new(false),
                })
            } else {
                None
            }
        } else {
            None
        }
    }

    fn get_name(&self) -> &str {
        &self.info.name
    }

    fn get_dir(&self) -> &str {
        &self.info.dir
    }

    fn get_collections(&self) -> impl Iterator<Item = &str> {
        self.info.collections.iter().map(|c| c.name.as_str())
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

        let mut lock = INSTANCES.lock();
        if !lock.contains_key(instance_id as u64) {
            let (info, sqlite) = Self::open(
                instance_id,
                name,
                dir,
                schemas,
                max_size_mib,
                encryption_key,
            )?;

            let connections = Connections {
                info: Arc::new(info),
                sqlite: vec![sqlite],
            };
            lock.insert(instance_id as u64, connections);
        }

        let connections = lock.get_mut(instance_id as u64).unwrap();
        let sqlite = if let Some(sqlite) = connections.sqlite.pop() {
            sqlite
        } else {
            Self::open_conn(
                &connections.info.path,
                connections.info.encryption_key.as_deref(),
            )?
        };
        Ok(Self {
            info: connections.info.clone(),
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

    fn get<'a>(
        &'a self,
        txn: &'a Self::Txn,
        collection_index: u16,
        id: i64,
    ) -> Result<Option<Self::Reader<'a>>> {
        let collection = self.get_collection(collection_index)?;

        let sql = format!(
            "SELECT {} FROM {} WHERE {} = {}",
            select_properties_sql(collection),
            collection.name,
            SQLiteProperty::ID_NAME,
            id
        );
        let mut stmt = txn.get_sqlite(false)?.prepare(&sql)?;
        if stmt.step()? {
            Ok(Some(SQLiteReader::new(
                Cow::Owned(stmt),
                collection,
                &self.info.collections,
            )))
        } else {
            Ok(None)
        }
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
    ) -> Result<Self::Cursor<'_>> {
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
        let handle = collection.watchers.watch_query(query.clone(), callback);
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

    fn verify(&self, txn: &Self::Txn) -> Result<()> {
        Ok(())
    }

    fn close(instance: Self::Instance, delete: bool) -> bool {
        // Check whether all other references are gone
        if Arc::strong_count(&instance.info) == 2 {
            let mut lock = INSTANCES.lock();
            // Check again to make sure there are no new references
            if Arc::strong_count(&instance.info) == 2 {
                lock.remove(instance.info.instance_id as u64);

                if delete {
                    let path = instance.info.path.to_string();
                    drop(instance);
                    let _ = remove_file(&path);
                    let _ = remove_file(&format!("{}-wal", path));
                    let _ = remove_file(&format!("{}-shm", path));
                }
                return true;
            }
        }

        // Return connection to pool
        if let Some(sqlite) = Rc::into_inner(instance.sqlite) {
            let mut lock = INSTANCES.lock();
            let connections = lock.get_mut(instance.info.instance_id as u64).unwrap();
            connections.sqlite.push(sqlite);
        }

        false
    }
}
