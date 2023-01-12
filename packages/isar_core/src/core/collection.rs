use intmap::IntMap;
use serde_json::Value;

use crate::core::error::Result;

use super::object::IsarObject;
use super::object_builder::IsarObjectBuilder;
use super::property::IsarProperty;

pub trait IsarCollection {
    type Txn;
    type ObjectBuilder<'txn>: IsarObjectBuilder<'txn>;

    fn name(&self) -> &str;

    fn id(&self) -> u64;

    //fn new_query_builder(&self) -> QueryBuilder;

    fn prepare_put<'txn>(
        &self,
        txn: &'txn mut Self::Txn,
        count: usize,
    ) -> Result<Self::ObjectBuilder<'txn>>;

    fn put<'a>(&self, txn: &mut Self::Txn, builder: Self::ObjectBuilder<'_>) -> Result<()>;

    /*fn get_by_index<'txn>(
        &self,
        txn: &'txn mut IsarTxn,
        index_id: u64,
        key: &IndexKey,
    ) -> Result<Option<(i64, IsarObject<'txn>)>>;*/

    /*

    fn put_by_index<'a>(
        &self,
        txn: &mut impl IsarTxn,
        index_id: u64,
        object: impl IsarObject<'a>,
    ) -> Result<i64>;

    fn delete(&self, txn: &mut impl IsarTxn, id: i64) -> Result<bool>;

    //fn delete_by_index(&self, txn: &mut IsarTxn, index_id: u64, key: &IndexKey) -> Result<bool>;

    fn link(&self, txn: &mut impl IsarTxn, link_id: u64, id: i64, target_id: i64) -> Result<bool>;

    fn unlink(&self, txn: &mut impl IsarTxn, link_id: u64, id: i64, target_id: i64)
        -> Result<bool>;

    fn unlink_all(&self, txn: &mut impl IsarTxn, link_id: u64, id: i64) -> Result<()>;

    fn clear(&self, txn: &mut impl IsarTxn) -> Result<()>;

    fn count(&self, txn: &mut impl IsarTxn) -> Result<u64>;

    fn get_size(
        &self,
        txn: &mut impl IsarTxn,
        include_indexes: bool,
        include_links: bool,
    ) -> Result<u64>;

    fn import_json(&self, txn: &mut impl IsarTxn, id_name: Option<&str>, json: Value)
        -> Result<()>;

    fn verify<'a>(
        &self,
        txn: &mut impl IsarTxn,
        objects: &IntMap<impl IsarObject<'a>>,
    ) -> Result<()>;

    fn verify_link(&self, txn: &mut impl IsarTxn, link_id: u64, links: &[(i64, i64)])
        -> Result<()>;*/
}
