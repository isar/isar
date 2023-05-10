use super::cursor::IsarCursor;
use super::error::Result;
use super::insert::IsarInsert;
use super::query_builder::IsarQueryBuilder;
use super::schema::IsarSchema;

pub struct CompactCondition {
    pub min_file_size: u32,
    pub min_bytes: u32,
    pub min_ratio: f32,
}

pub trait IsarInstance {
    type Instance;

    type Txn;

    type Insert<'a>: IsarInsert<'a, Txn = Self::Txn>
    where
        Self: 'a;

    type QueryBuilder<'a>: IsarQueryBuilder<Query = Self::Query>
    where
        Self: 'a;

    type Query;

    type Cursor<'a>: IsarCursor
    where
        Self: 'a;

    fn get(instance_id: u32) -> Option<Self::Instance>;

    fn open(
        instance_id: u32,
        name: &str,
        dir: &str,
        schema: IsarSchema,
        max_size_mib: u32,
        relaxed_durability: bool,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Self::Instance>;

    fn begin_txn(&self, write: bool) -> Result<Self::Txn>;

    fn commit_txn(&self, txn: Self::Txn) -> Result<()>;

    fn abort_txn(&self, txn: Self::Txn);

    fn get_largest_id(&self, collection_index: u16) -> Result<i64>;

    fn insert(&self, txn: Self::Txn, collection_index: u16, count: u32)
        -> Result<Self::Insert<'_>>;

    fn count(&self, txn: &Self::Txn, collection_index: u16) -> Result<u32>;

    fn get_size(
        &self,
        collection_index: Option<u16>,
        include_indexes: bool,
        include_links: bool,
    ) -> Result<u32>;

    fn query(&self, collection_index: u16) -> Result<Self::QueryBuilder<'_>>;

    fn cursor<'a>(
        &'a self,
        txn: &'a Self::Txn,
        query: &'a Self::Query,
        offset: Option<u32>,
        limit: Option<u32>,
    ) -> Result<Self::Cursor<'_>>;

    fn delete(&self, txn: &Self::Txn, query: &Self::Query) -> Result<u32>;

    fn close(instance: Self::Instance, delete: bool) -> bool;
}
