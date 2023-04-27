use super::cursor::IsarCursor;
use super::error::Result;
use super::insert::IsarInsert;
use super::query_builder::IsarQueryBuilder;
use super::schema::IsarSchema;

pub struct CompactCondition {
    pub min_file_size: u64,
    pub min_bytes: u64,
    pub min_ratio: f64,
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

    fn get(instance_id: u64) -> Option<Self::Instance>;

    fn open(
        instance_id: u64,
        name: &str,
        dir: &str,
        schema: IsarSchema,
        max_size_mib: usize,
        relaxed_durability: bool,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Self::Instance>;

    fn begin_txn(&self, write: bool) -> Result<Self::Txn>;

    fn commit_txn(&self, txn: Self::Txn) -> Result<()>;

    fn abort_txn(&self, txn: Self::Txn);

    fn insert(
        &self,
        txn: Self::Txn,
        collection_index: usize,
        count: usize,
    ) -> Result<Self::Insert<'_>>;

    fn build_query(&self, collection_index: usize) -> Result<Self::QueryBuilder<'_>>;

    fn query<'a>(&'a self, txn: &'a Self::Txn, query: &'a Self::Query) -> Result<Self::Cursor<'_>>;

    fn count(&self, txn: &Self::Txn, query: &Self::Query) -> Result<usize>;

    fn delete(&self, txn: &Self::Txn, query: &Self::Query) -> Result<usize>;
}
