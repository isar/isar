use super::error::Result;
use serde_json::Value;

pub trait IsarQuery {
    type Txn<'txn>;
    type Collection;
    type Cursor<'txn>: IsarQueryCursor<'txn>;

    fn cursor<'txn>(&self, txn: &'txn mut Self::Txn<'_>) -> Result<Self::Cursor<'txn>>;

    fn count(&self, txn: &mut Self::Txn<'_>) -> Result<u32>;

    fn delete(&self, txn: &mut Self::Txn<'_>) -> Result<u32>;

    fn export_json(
        &self,
        txn: &mut Self::Txn<'_>,
        collection: &Self::Collection,
        id_name: Option<&str>,
        primitive_null: bool,
    ) -> Result<Value>;
}

pub trait IsarQueryCursor<'txn> {
    type Object;

    fn next(&mut self) -> Result<Option<Self::Object>>;
}
