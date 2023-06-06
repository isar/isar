use super::schema_manager::perform_migration;
use super::sql::select_properties_sql;
use super::sqlite3::SQLite3;
use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use super::sqlite_insert::SQLiteInsert;
use super::sqlite_query::{SQLiteCursor, SQLiteQuery};
use super::sqlite_query_builder::SQLiteQueryBuilder;
use super::sqlite_reader::SQLiteReader;
use super::sqlite_txn::SQLiteTxn;
use crate::core::error::{IsarError, Result};
use crate::core::instance::{Aggregation, CompactCondition, IsarInstance};
use crate::core::schema::IsarSchema;
use crate::core::value::IsarValue;
use intmap::IntMap;
use itertools::Itertools;
use once_cell::sync::Lazy;
use std::borrow::Cow;
use std::cell::Cell;
use std::fs::remove_file;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use std::vec;

static INSTANCES: Lazy<Mutex<IntMap<Connections>>> = Lazy::new(|| Mutex::new(IntMap::new()));

struct Connections {
    info: Arc<SQLiteInstanceInfo>,
    sqlite: Vec<SQLite3>,
}

struct SQLiteInstanceInfo {
    name: String,
    dir: String,
    path: String,
    instance_id: u32,
    collections: Vec<SQLiteCollection>,
}

pub struct SQLiteInstance {
    info: Arc<SQLiteInstanceInfo>,
    sqlite: Arc<SQLite3>,
    txn_active: Cell<bool>,
}

impl SQLiteInstance {
    fn open(
        name: &str,
        dir: &str,
        instance_id: u32,
        schema: IsarSchema,
    ) -> Result<(SQLiteInstanceInfo, SQLite3)> {
        let mut path_buf = PathBuf::from(dir);
        path_buf.push(format!("{}.sqlite", name));
        let path = path_buf.as_path().to_str().unwrap().to_string();

        let sqlite = SQLite3::open(&path).unwrap();
        let sqlite = Arc::new(sqlite);
        let txn = SQLiteTxn::new(sqlite.clone(), true)?;
        perform_migration(&txn, &schema)?;
        txn.commit()?;

        let collections = Self::get_collections(&schema);
        let instance_info = SQLiteInstanceInfo {
            name: name.to_string(),
            dir: dir.to_string(),
            instance_id,
            path,
            collections,
        };

        let sqlite = Arc::into_inner(sqlite).unwrap();
        Ok((instance_info, sqlite))
    }

    fn get_collections(schema: &IsarSchema) -> Vec<SQLiteCollection> {
        let mut collections = Vec::new();
        for collection_schema in &schema.collections {
            let properties = collection_schema
                .properties
                .iter()
                .filter_map(|p| {
                    if let Some(name) = &p.name {
                        let target_collection_index = p.collection.as_deref().map(|c| {
                            let position = schema
                                .collections
                                .iter()
                                .position(|c2| c2.name == c)
                                .unwrap();
                            position as u16
                        });
                        let prop = SQLiteProperty::new(name, p.data_type, target_collection_index);
                        Some(prop)
                    } else {
                        None
                    }
                })
                .collect_vec();
            let collection = SQLiteCollection::new(collection_schema.name.clone(), properties);
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
        let mut lock = INSTANCES.lock().unwrap();
        if let Some(connections) = lock.get_mut(instance_id as u64) {
            let sqlite = connections
                .sqlite
                .pop()
                .or_else(|| SQLite3::open(&connections.info.path).ok());
            if let Some(sqlite) = sqlite {
                Some(Self {
                    info: connections.info.clone(),
                    sqlite: Arc::new(sqlite),
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

    fn open_instance(
        instance_id: u32,
        name: &str,
        dir: &str,
        schema: IsarSchema,
        _max_size_mib: u32,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Self> {
        let mut lock = INSTANCES.lock().unwrap();
        if !lock.contains_key(instance_id as u64) {
            let (info, sqlite) = Self::open(name, dir, instance_id, schema)?;
            let connections = Connections {
                info: Arc::new(info),
                sqlite: vec![sqlite],
            };
            lock.insert(instance_id as u64, connections);
        }

        let connections = lock.get_mut(instance_id as u64).unwrap();
        let sqlite = connections.sqlite.pop().unwrap();
        Ok(Self {
            info: connections.info.clone(),
            sqlite: Arc::new(sqlite),
            txn_active: Cell::new(false),
        })
    }

    fn begin_txn(&self, write: bool) -> Result<SQLiteTxn> {
        if self.txn_active.replace(true) {
            Err(IsarError::TransactionActive {})
        } else {
            SQLiteTxn::new(self.sqlite.clone(), write)
        }
    }

    fn commit_txn(&self, txn: SQLiteTxn) -> Result<()> {
        self.txn_active.replace(false);
        txn.commit()
    }

    fn abort_txn(&self, txn: SQLiteTxn) {
        self.txn_active.replace(false);
        txn.abort();
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
        SQLiteInsert::new(txn, collection, &self.info.collections, count)
    }

    fn delete<'a>(&'a self, txn: &'a Self::Txn, collection_index: u16, id: i64) -> Result<bool> {
        let collection = self.get_collection(collection_index)?;
        let sql = format!(
            "DELETE FROM {} WHERE {} = {}",
            collection.name,
            SQLiteProperty::ID_NAME,
            id
        );
        let sqlite = txn.get_sqlite(true)?;
        txn.guard(|| {
            sqlite.prepare(&sql)?.step()?;
            Ok(sqlite.count_changes() > 0)
        })
    }

    fn count(&self, txn: &Self::Txn, collection_index: u16) -> Result<u32> {
        let collection = self.get_collection(collection_index)?;
        let sql = format!("SELECT COUNT(*) FROM {}", collection.name);
        let mut stmt = txn.get_sqlite(false)?.prepare(&sql)?;
        stmt.step()?;
        Ok(stmt.get_int(0) as u32)
    }

    fn clear(&self, txn: &Self::Txn, collection_index: u16) -> Result<()> {
        let collection = self.get_collection(collection_index)?;
        let sql = format!("DELETE FROM {}", collection.name,);
        txn.guard(|| txn.get_sqlite(true)?.prepare(&sql)?.step())?;
        Ok(())
    }

    fn get_size(
        &self,
        txn: &Self::Txn,
        collection_index: u16,
        include_indexes: bool,
    ) -> Result<u64> {
        Ok(0)
    }

    fn query(&self, collection_index: u16) -> Result<Self::QueryBuilder<'_>> {
        let collection = self.get_collection(collection_index)?;
        Ok(SQLiteQueryBuilder::new(collection, collection_index))
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

    fn query_aggregate<'a>(
        &'a self,
        txn: &'a Self::Txn,
        query: &'a Self::Query,
        aggregation: Aggregation,
        property_index: Option<u16>,
    ) -> Result<Option<IsarValue>> {
        query.aggregate(txn, &self.info.collections, aggregation, property_index)
    }

    fn query_delete(
        &self,
        txn: &Self::Txn,
        query: &Self::Query,
        offset: Option<u32>,
        limit: Option<u32>,
    ) -> Result<u32> {
        query.delete(txn, &self.info.collections, offset, limit)
    }

    fn copy(&self, path: &str) -> Result<()> {
        if Arc::strong_count(&self.sqlite) > 1 {
            return Err(IsarError::UnsupportedOperation {});
        }

        let sql = format!("VACUUM INTO '{}'", path);
        self.sqlite.prepare(&sql)?.step()?;
        Ok(())
    }

    fn close(instance: Self::Instance, delete: bool) -> bool {
        // Check whether all other references are gone
        if Arc::strong_count(&instance.info) == 2 {
            let mut lock = INSTANCES.lock().unwrap();
            // Check again to make sure there are no new references
            if Arc::strong_count(&instance.info) == 2 {
                lock.remove(instance.info.instance_id as u64);

                if delete {
                    let path = instance.info.path.to_string();
                    drop(instance);
                    let _ = remove_file(&path);
                }
                return true;
            }
        }

        // Return connection to pool
        if let Some(sqlite) = Arc::into_inner(instance.sqlite) {
            let mut lock = INSTANCES.lock().unwrap();
            let connections = lock.get_mut(instance.info.instance_id as u64).unwrap();
            connections.sqlite.push(sqlite);
        }

        false
    }
}
