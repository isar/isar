use super::mdbx::env::Env;
use super::native_collection::NativeCollection;
use super::native_cursor::NativeCursor;
use super::native_insert::NativeInsert;
use super::native_open::{get_isar_path, open_native};
use super::native_query_builder::NativeQueryBuilder;
use super::native_reader::NativeReader;
use super::native_txn::NativeTxn;
use super::native_verify::verify_native;
use super::query::{NativeQuery, NativeQueryCursor};
use crate::core::error::{IsarError, Result};
use crate::core::instance::{Aggregation, CompactCondition, IsarInstance};
use crate::core::schema::IsarSchema;
use crate::core::value::IsarValue;
use crate::core::watcher::{WatchHandle, WatcherCallback};
use intmap::IntMap;
use parking_lot::Mutex;
use std::fs::remove_file;
use std::sync::{Arc, LazyLock};

static INSTANCES: LazyLock<Mutex<IntMap<Arc<NativeInstance>>>> =
    LazyLock::new(|| Mutex::new(IntMap::new()));

pub struct NativeInstance {
    name: String,
    dir: String,
    instance_id: u32,
    collections: Vec<NativeCollection>,
    env: Arc<Env>,
}

impl NativeInstance {
    pub(crate) fn new(
        name: &str,
        dir: &str,
        instance_id: u32,
        collections: Vec<NativeCollection>,
        env: Arc<Env>,
    ) -> Self {
        Self {
            name: name.to_string(),
            dir: dir.to_string(),
            instance_id,
            collections,
            env,
        }
    }

    pub(crate) fn verify_instance_id(&self, instance_id: u32) -> Result<()> {
        if self.instance_id != instance_id {
            Err(IsarError::InstanceMismatch {})
        } else {
            Ok(())
        }
    }

    fn get_collection(&self, collection_index: u16) -> Result<&NativeCollection> {
        if let Some(collection) = self.collections.get(collection_index as usize) {
            Ok(collection)
        } else {
            Err(IsarError::IllegalArgument {})
        }
    }
}

impl IsarInstance for NativeInstance {
    type Instance = Arc<Self>;

    type Txn = NativeTxn;

    type Reader<'a> = NativeReader<'a>
    where
        Self: 'a;

    type Cursor<'a> = NativeCursor<'a>
        where
            Self: 'a;

    type Insert<'a> = NativeInsert<'a>
    where
        Self: 'a;

    type QueryBuilder<'a> = NativeQueryBuilder<'a>
    where
        Self: 'a;

    type Query = NativeQuery;

    type QueryCursor<'a> = NativeQueryCursor<'a>
    where
        Self: 'a;

    fn get_instance(instance_id: u32) -> Option<Self::Instance> {
        let mut lock = INSTANCES.lock();
        if let Some(instance) = lock.get_mut(instance_id as u64) {
            Some(Arc::clone(&instance))
        } else {
            None
        }
    }

    fn get_name(&self) -> &str {
        &self.name
    }

    fn get_dir(&self) -> &str {
        &self.dir
    }

    fn get_collections(&self) -> impl Iterator<Item = &str> {
        self.collections.iter().map(|c| c.name.as_str())
    }

    fn open_instance(
        instance_id: u32,
        name: &str,
        dir: &str,
        schemas: Vec<IsarSchema>,
        max_size_mib: u32,
        encryption_key: Option<&str>,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Self::Instance> {
        if encryption_key.is_some() {
            return Err(IsarError::IllegalArgument {});
        }
        let mut lock = INSTANCES.lock();
        if let Some(instance) = lock.get(instance_id as u64) {
            Ok(instance.clone())
        } else {
            let new_instance = open_native(
                name,
                dir,
                instance_id,
                schemas,
                max_size_mib,
                compact_condition,
            )?;
            let new_instance = Arc::new(new_instance);
            lock.insert(instance_id as u64, new_instance.clone());
            Ok(new_instance)
        }
    }

    fn begin_txn(&self, write: bool) -> Result<Self::Txn> {
        NativeTxn::new(self.instance_id, &self.env, write)
    }

    fn commit_txn(&self, txn: Self::Txn) -> Result<()> {
        self.verify_instance_id(txn.instance_id)?;
        txn.commit()
    }

    fn abort_txn(&self, txn: Self::Txn) {
        if self.verify_instance_id(txn.instance_id).is_ok() {
            txn.abort()
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
        self.verify_instance_id(txn.instance_id)?;
        let collection = self.get_collection(collection_index)?;
        NativeCursor::new(txn, collection, &self.collections)
    }

    fn insert<'a>(
        &'a self,
        txn: NativeTxn,
        collection_index: u16,
        count: u32,
    ) -> Result<NativeInsert<'a>> {
        self.verify_instance_id(txn.instance_id)?;
        let collection = self.get_collection(collection_index)?;
        NativeInsert::new(txn, collection, &self.collections, count)
    }

    fn update(
        &self,
        txn: &Self::Txn,
        collection_index: u16,
        id: i64,
        updates: &[(u16, Option<IsarValue>)],
    ) -> Result<bool> {
        self.verify_instance_id(txn.instance_id)?;
        let collection = self.get_collection(collection_index)?;
        let mut cursor = collection.get_cursor(txn)?;
        txn.guard(|| collection.update(txn, &mut txn.get_change_set(), &mut cursor, id, updates))
    }

    fn delete<'a>(&'a self, txn: &'a Self::Txn, collection_index: u16, id: i64) -> Result<bool> {
        self.verify_instance_id(txn.instance_id)?;
        let collection = self.get_collection(collection_index)?;
        let mut cursor = collection.get_cursor(txn)?;
        txn.guard(|| collection.delete(txn, &mut txn.get_change_set(), &mut cursor, id))
    }

    fn count(&self, txn: &Self::Txn, collection_index: u16) -> Result<u32> {
        self.verify_instance_id(txn.instance_id)?;
        let collection = self.get_collection(collection_index)?;
        collection.count(txn)
    }

    fn clear(&self, txn: &Self::Txn, collection_index: u16) -> Result<()> {
        self.verify_instance_id(txn.instance_id)?;
        let collection = self.get_collection(collection_index)?;
        txn.guard(|| collection.clear(txn))
    }

    fn get_size(
        &self,
        txn: &Self::Txn,
        collection_index: u16,
        include_indexes: bool,
    ) -> Result<u64> {
        self.verify_instance_id(txn.instance_id)?;
        let collection = self.get_collection(collection_index)?;
        collection.get_size(txn, include_indexes)
    }

    fn query(&self, collection_index: u16) -> Result<Self::QueryBuilder<'_>> {
        let collection = self.get_collection(collection_index)?;
        Ok(NativeQueryBuilder::new(
            self.instance_id,
            collection,
            &self.collections,
        ))
    }

    fn query_cursor<'a>(
        &'a self,
        txn: &'a Self::Txn,
        query: &'a Self::Query,
        offset: Option<u32>,
        limit: Option<u32>,
    ) -> Result<Self::QueryCursor<'a>> {
        self.verify_instance_id(txn.instance_id)?;
        self.verify_instance_id(query.instance_id)?;
        let result = query.cursor(txn, &self.collections, offset, limit);
        Ok(result)
    }

    fn query_aggregate(
        &self,
        txn: &Self::Txn,
        query: &Self::Query,
        aggregation: Aggregation,
        property_index: Option<u16>,
    ) -> Result<Option<IsarValue>> {
        self.verify_instance_id(txn.instance_id)?;
        self.verify_instance_id(query.instance_id)?;
        let result = query.aggregate(txn, &self.collections, aggregation, property_index);
        Ok(result)
    }

    fn query_update(
        &self,
        txn: &Self::Txn,
        query: &Self::Query,
        offset: Option<u32>,
        limit: Option<u32>,
        updates: &[(u16, Option<IsarValue>)],
    ) -> Result<u32> {
        self.verify_instance_id(txn.instance_id)?;
        self.verify_instance_id(query.instance_id)?;
        let collection = self.get_collection(query.collection_index)?;
        let ids = query.get_matching_ids(txn, collection, offset, limit);

        txn.guard(|| {
            let change_set = &mut txn.get_change_set();
            let mut cursor = collection.get_cursor(txn)?;
            for id in &ids {
                collection.update(txn, change_set, &mut cursor, *id, updates)?;
            }
            Ok(ids.len() as u32)
        })
    }

    fn query_delete(
        &self,
        txn: &Self::Txn,
        query: &Self::Query,
        offset: Option<u32>,
        limit: Option<u32>,
    ) -> Result<u32> {
        self.verify_instance_id(txn.instance_id)?;
        self.verify_instance_id(query.instance_id)?;
        let collection = self.get_collection(query.collection_index)?;
        let ids = query.get_matching_ids(txn, collection, offset, limit);

        txn.guard(|| {
            let change_set = &mut txn.get_change_set();
            let mut cursor = collection.get_cursor(txn)?;
            for id in &ids {
                collection.delete(txn, change_set, &mut cursor, *id)?;
            }
            Ok(ids.len() as u32)
        })
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
        self.verify_instance_id(query.instance_id)?;
        let collection = self.get_collection(query.collection_index)?;
        let handle = collection.watchers.watch_query(query, callback);
        Ok(handle)
    }

    fn copy(&self, path: &str) -> Result<()> {
        self.env.copy(path)
    }

    fn verify(&self, txn: &Self::Txn) -> Result<()> {
        verify_native(txn, &self.collections)
    }

    fn close(instance: Arc<Self>, delete: bool) -> bool {
        // Check whether all other references are gone
        if Arc::strong_count(&instance) == 2 {
            let mut lock = INSTANCES.lock();
            // Check again to make sure there are no new references
            if Arc::strong_count(&instance) == 2 {
                lock.remove(instance.instance_id as u64);

                if delete {
                    let mut path = get_isar_path(&instance.name, &instance.dir);
                    drop(instance);
                    let _ = remove_file(&path);
                    path.push_str(".lock");
                    let _ = remove_file(&path);
                }
                return true;
            }
        }
        false
    }
}
