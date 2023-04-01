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
    type Txn<'a>;

    type Insert<'a>: IsarInsert<'a>
    where
        Self: 'a;

    type QueryBuilder<'a>: IsarQueryBuilder
    where
        Self: 'a;

    type Instance;

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

    fn begin_txn(&self, write: bool) -> Result<Self::Txn<'_>>;

    fn commit_txn(&self, txn: Self::Txn<'_>) -> Result<()>;

    fn abort_txn(&self, txn: Self::Txn<'_>);

    fn query(&self, collection_index: usize) -> Result<Self::QueryBuilder<'_>>;

    fn insert<'a>(
        &'a self,
        txn: Self::Txn<'a>,
        collection_index: usize,
        count: usize,
    ) -> Result<Self::Insert<'a>>;
}
