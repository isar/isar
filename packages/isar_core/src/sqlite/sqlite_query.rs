use crate::core::query::IsarQuery;

use super::{
    sqlite_collection::SQLiteCollection, sqlite_object::SQLiteObject, sqlite_txn::SQLiteTxn,
};

pub struct SQLiteQuery {}

impl IsarQuery for SQLiteQuery {
    type Txn<'txn> = SQLiteTxn<'txn>;

    type Object<'txn> = SQLiteObject<'txn>;

    type Collection = SQLiteCollection;

    fn find_while<'txn, F>(
        &self,
        txn: &'txn mut Self::Txn<'_>,
        callback: F,
    ) -> crate::core::error::Result<()>
    where
        F: FnMut(i64, Self::Object<'txn>) -> bool,
    {
        todo!()
    }

    fn find_all_vec<'txn>(
        &self,
        txn: &'txn mut Self::Txn<'_>,
    ) -> crate::core::error::Result<Vec<(i64, Self::Object<'txn>)>> {
        todo!()
    }

    fn count(&self, txn: &mut Self::Txn<'_>) -> crate::core::error::Result<u32> {
        todo!()
    }

    fn export_json(
        &self,
        txn: &mut Self::Txn<'_>,
        collection: &Self::Collection,
        id_name: Option<&str>,
        primitive_null: bool,
    ) -> crate::core::error::Result<serde_json::Value> {
        todo!()
    }

    fn maybe_matches(&self, id: i64, object: &Self::Object<'_>) -> bool {
        todo!()
    }
}
