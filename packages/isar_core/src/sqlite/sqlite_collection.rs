use intmap::IntMap;

use crate::core::collection::IsarCollection;
use crate::core::error::{IsarError, Result};
use crate::core::object::IsarObject;
use crate::core::property::IsarProperty;
use crate::core::txn::IsarTxn;
use crate::sqlite::sqlite_object::SQLiteObject;
use crate::sqlite::sqlite_txn::SQLiteTxn;

use super::sql::insert::sql_insert_bulk;

pub struct SQLiteCollection {
    instance_id: u64,
    id: u64,
    name: String,
    properties: Vec<IsarProperty>,
    embedded_properties: IntMap<Vec<IsarProperty>>,
}

impl IsarCollection for SQLiteCollection {
    type Txn<'txn> = SQLiteTxn<'txn>;

    type Object<'txn> = SQLiteObject<'txn>;

    fn name(&self) -> &str {
        &self.name
    }

    fn id(&self) -> u64 {
        self.id
    }

    fn properties(&self) -> &[IsarProperty] {
        &self.properties
    }

    fn embedded_properties(&self) -> &IntMap<Vec<IsarProperty>> {
        &self.embedded_properties
    }

    fn get<'txn>(
        &self,
        txn: &'txn mut SQLiteTxn<'txn>,
        id: i64,
    ) -> Result<Option<SQLiteObject<'txn>>> {
        todo!()
    }

    fn put<'a>(
        &self,
        txn: &mut SQLiteTxn<'_>,
        id: Option<i64>,
        object: &impl IsarObject<'a>,
    ) -> Result<i64> {
        self.put_all(txn, &[(id, object)]).map(|ids| ids[0])
    }

    fn put_all<'a>(
        &self,
        txn: &mut SQLiteTxn<'_>,
        objects: &[(Option<i64>, &impl IsarObject<'a>)],
    ) -> Result<Vec<i64>> {
        txn.write(self.instance_id, |txn, change_set| {
            let mut ids = Vec::with_capacity(objects.len());
            while objects.len() > ids.len() {
                let remaining = objects.len() - ids.len();
                let (insert_sql, count) = sql_insert_bulk(self, remaining);
                let mut stmt = txn.prepare_cached(&insert_sql)?;
                for _ in 0..count {
                    let (id, object) = objects[ids.len()];
                    stmt.raw_bind_parameter(1, id)?;
                    for (i, property) in self.properties().iter().enumerate() {
                        //stmt.raw_bind_parameter(i + 2, object.get(property.offset));
                    }
                    stmt.raw_execute()?;
                }
            }

            Ok(ids)
        })
    }
}
