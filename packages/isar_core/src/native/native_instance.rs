use super::native_insert::NativeInsert;
use super::native_query_builder::NativeQueryBuilder;
use super::native_txn::NativeTxn;
use crate::core::error::Result;
use crate::core::instance::{CompactCondition, IsarInstance};
use crate::core::schema::IsarSchema;
use std::sync::Arc;

struct NativeInstance {}

/*impl IsarInstance for NativeInstance {
    type Txn = NativeTxn;

    type Insert<'a> = NativeInsert
    where
        Self: 'a;

    type QueryBuilder<'a> = NativeQueryBuilder
    where
        Self: 'a;

    fn open(
        name: &str,
        dir: Option<&str>,
        schema: IsarSchema,
        max_size_mib: usize,
        relaxed_durability: bool,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Arc<Self>> {
        todo!()
    }

    fn schema_hash(&self) -> u64 {
        todo!()
    }

    fn begin_txn(&self, write: bool) -> Result<Self::Txn> {
        todo!()
    }

    fn commit_txn(&self, txn: Self::Txn) -> Result<()> {
        todo!()
    }

    fn abort_txn(&self, txn: Self::Txn) {
        todo!()
    }

    fn query(&self, collection_index: usize) -> Result<Self::QueryBuilder<'_>> {
        todo!()
    }

    fn insert<'a>(
        &'a self,
        txn: &'a mut Self::Txn,
        collection_index: usize,
        count: usize,
    ) -> Result<Self::Insert<'a>> {
        todo!()
    }
}*/
