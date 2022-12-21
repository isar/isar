use super::error::Result;
use serde_json::Value;

pub trait IsarQuery {
    type Txn<'txn>;
    type Object<'txn>;
    type Collection;

    fn find_while<'txn, F>(&self, txn: &'txn mut Self::Txn<'_>, callback: F) -> Result<()>
    where
        F: FnMut(i64, Self::Object<'txn>) -> bool;

    fn find_all_vec<'txn>(
        &self,
        txn: &'txn mut Self::Txn<'_>,
    ) -> Result<Vec<(i64, Self::Object<'txn>)>>;

    fn count(&self, txn: &mut Self::Txn<'_>) -> Result<u32>;

    fn export_json(
        &self,
        txn: &mut Self::Txn<'_>,
        collection: &Self::Collection,
        id_name: Option<&str>,
        primitive_null: bool,
    ) -> Result<Value>;

    fn maybe_matches(&self, id: i64, object: &Self::Object<'_>) -> bool;
}
