use super::error::Result;
use super::insert::IsarInsert;
use super::query_builder::IsarQueryBuilder;
use super::schema::IsarSchema;
use super::txn::IsarTxn;
use std::sync::Arc;

pub struct CompactCondition {
    pub min_file_size: u64,
    pub min_bytes: u64,
    pub min_ratio: f64,
}

pub trait IsarInstance {
    type Txn<'a>: IsarTxn
    where
        Self: 'a;

    type Insert<'a>: IsarInsert
    where
        Self: 'a;

    type QueryBuilder<'a>: IsarQueryBuilder
    where
        Self: 'a;

    fn open(
        name: &str,
        dir: Option<&str>,
        schema: IsarSchema,
        max_size_mib: usize,
        relaxed_durability: bool,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Arc<Self>>;

    fn schema_hash(&self) -> u64;

    fn txn(&self, write: bool) -> Result<Self::Txn<'_>>;

    fn query(&self, collection_index: usize) -> Result<Self::QueryBuilder<'_>>;

    fn insert(&self, collection_index: usize, count: usize) -> Result<Self::Insert<'_>>;
}
