use std::sync::atomic::AtomicU64;
use std::sync::Arc;

use super::collection::IsarCollection;
use super::error::Result;
use super::schema::IsarSchema;
use super::txn::IsarTxn;

//static INSTANCES: Lazy<RwLock<IntMap<Arc<IsarInstance>>>> = Lazy::new(|| RwLock::new(IntMap::new()));

static WATCHER_ID: AtomicU64 = AtomicU64::new(0);

pub struct CompactCondition {
    pub min_file_size: u64,
    pub min_bytes: u64,
    pub min_ratio: f64,
}

pub trait IsarInstance {
    fn open(
        name: &str,
        dir: Option<&str>,
        schema: IsarSchema,
        max_size_mib: usize,
        relaxed_durability: bool,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Arc<Self>>;

    fn schema_hash(&self) -> u64;

    /*fn name(&self) -> &str;

    fn dir(&self) -> Option<&str>;

    fn collection(&self, name: &str) -> Option<&impl IsarCollection>;

    fn begin_txn(&self, write: bool, silent: bool) -> Result<impl IsarTxn>;

    fn get_size(
        &self,
        txn: &mut impl IsarTxn,
        include_indexes: bool,
        include_links: bool,
    ) -> Result<u64>;

    fn copy_to_file(&self, path: &str) -> Result<()>;

    fn new_watcher(&self, start: WatcherModifier, stop: WatcherModifier) -> WatchHandle;

    fn watch_collection(
        &self,
        collection: &IsarCollection,
        callback: WatcherCallback,
    ) -> WatchHandle;

    fn watch_object(
        &self,
        collection: &IsarCollection,
        oid: i64,
        callback: WatcherCallback,
    ) -> WatchHandle;

    fn watch_query(
        &self,
        collection: &IsarCollection,
        query: Query,
        callback: WatcherCallback,
    ) -> WatchHandle;

    fn close(self: Arc<Self>) -> bool;

    fn close_and_delete(self: Arc<Self>) -> bool;

    fn verify(&self, txn: &mut impl IsarTxn) -> Result<()>;*/
}
