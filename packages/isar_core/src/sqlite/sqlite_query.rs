/*use crate::core::query::IsarQuery;

use super::{
    sqlite_collection::SQLiteCollection, sqlite_object::SQLiteObject, sqlite_txn::SQLiteTxn,
};

pub struct SQLiteQuery {}

impl IsarQuery for SQLiteQuery {
    type Txn<'txn> = SQLiteTxn<'txn>;

    type Collection = SQLiteCollection;

    type Cursor<'txn>;

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
}
*/
