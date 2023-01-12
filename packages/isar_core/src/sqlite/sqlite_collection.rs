use intmap::IntMap;

use super::sql::insert::sql_insert_bulk;
use super::sqlite_object_builder::SQLiteObjectBuilder;
use crate::core::collection::IsarCollection;
use crate::core::error::Result;
use crate::core::property::IsarProperty;
use crate::sqlite::sqlite_txn::SQLiteTxn;

pub struct SQLiteCollection {
    instance_id: u64,
    id: u64,
    name: String,
    properties: Vec<IsarProperty>,
    embedded_properties: IntMap<Vec<IsarProperty>>,
}

impl IsarCollection for SQLiteCollection {
    type Txn = SQLiteTxn;

    type ObjectBuilder<'txn> = SQLiteObjectBuilder<'txn>;

    fn name(&self) -> &str {
        &self.name
    }

    fn id(&self) -> u64 {
        self.id
    }

    fn prepare_put<'txn>(
        &self,
        txn: &'txn mut Self::Txn,
        count: usize,
    ) -> Result<Self::ObjectBuilder<'txn>> {
        let sqlite = txn.get_sqlite(self.instance_id, true)?;
        let sql = sql_insert_bulk(&self.name, &self.properties, count);
        let stmt = sqlite.prepare(&sql)?;
        let builder = SQLiteObjectBuilder::new(stmt);
        Ok(builder)
    }

    fn put(&self, txn: &mut Self::Txn, builder: Self::ObjectBuilder<'_>) -> Result<()> {
        txn.guard(|| {
            let mut stmt = builder.finalize();
            stmt.step()?;
            Ok(())
        })
    }

    /*fn get<'txn>(&self, txn: &'txn mut SQLiteTxn<'txn>, id: i64) -> Result<Option<SQLiteObject>> {
        txn.read(self.instance_id, |txn| {
            let mut stmt =
                txn.prepare_cached(&format!("SELECT * FROM {} WHERE _id = {}", self.name(), id))?;
            let mut rows = stmt.raw_query();
            if let Some(row) = rows.next()? {
                let obj = SQLiteObject::from_row(row, stmt.column_count())?;
                Ok(Some(obj))
            } else {
                Ok(None)
            }
        })
    }*/

    /*fn put(
        &self,
        txn: &mut SQLiteTxn<'_>,
        id: Option<i64>,
        object: &Self::Object<'_>,
    ) -> Result<i64> {
        self.put_all(txn, &[(id, object)]).map(|ids| ids[0])
    }

    fn put_all(
        &self,
        txn: &mut SQLiteTxn<'_>,
        objects: &[(Option<i64>, &Self::Object<'_>)],
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
    }*/
}
