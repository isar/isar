use std::path::PathBuf;
use std::sync::{Arc, RwLock};

use deadpool::unmanaged::Pool;
use intmap::IntMap;
use once_cell::sync::Lazy;
use rusqlite::Connection;

use crate::common::instance::{get_isar_path, get_or_open_instance};
use crate::common::schema::hash_schema;
use crate::core::error::{IsarError, Result};
use crate::core::instance::{CompactCondition, IsarInstance};
use crate::core::schema::IsarSchema;

use super::sql::create_table::sql_create_table;

static INSTANCES: Lazy<RwLock<IntMap<Arc<SqliteInstance>>>> =
    Lazy::new(|| RwLock::new(IntMap::new()));

pub struct SqliteInstance {
    con_pool: Pool<Connection>,
    schema_hash: u64,
}

//unsafe impl Send for SqliteInstance {}

//unsafe impl Sync for SqliteInstance {}

impl SqliteInstance {
    fn open_instance(
        name: &str,
        dir: Option<&str>,
        mut schema: IsarSchema,
        relaxed_durability: bool,
    ) -> Result<Self> {
        if let Some(dir) = dir {
            let schema_hash = hash_schema(&mut schema);
            let mut path_buf = PathBuf::from(dir);
            path_buf.push(format!("{}.sqlite", name));
            let path = path_buf.as_path().to_str().unwrap().to_string();
            let con = Connection::open(path).unwrap();

            let col = schema.collections.first().unwrap();
            let create_sql = sql_create_table(col);
            println!("{}", create_sql);
            let txn = con.unchecked_transaction().unwrap();
            {
                let mut stmt = txn.prepare(&create_sql).unwrap();
                stmt.raw_execute().unwrap();
            }
            txn.commit().unwrap();
            let pool = Pool::new(10);
            //pool.add(con);
            Ok(Self {
                con_pool: pool,
                schema_hash,
            })
        } else {
            Err(IsarError::IllegalArg {
                message: "Please provide a valid directory.".to_string(),
            })
        }
    }
}

impl IsarInstance for SqliteInstance {
    fn open(
        name: &str,
        dir: Option<&str>,
        schema: IsarSchema,
        _max_size_mib: usize,
        relaxed_durability: bool,
        _compact_condition: Option<CompactCondition>,
    ) -> Result<Arc<Self>> {
        get_or_open_instance(&INSTANCES, name, schema, move |schema| {
            Self::open_instance(name, dir, schema, relaxed_durability)
        })
    }

    fn schema_hash(&self) -> u64 {
        self.schema_hash
    }
}

mod test {
    use crate::core::{
        data_type::DataType,
        instance::IsarInstance,
        schema::{CollectionSchema, IsarSchema, PropertySchema},
    };

    use super::SqliteInstance;

    #[test]
    fn test_exec() {
        let schema = IsarSchema::new(vec![CollectionSchema::new(
            "Test",
            vec![PropertySchema::new("mypeop", DataType::String, None)],
            vec![],
            vec![],
            false,
        )]);
        let instance = SqliteInstance::open(
            "test",
            Some("/Users/simon/Documents/GitHub/isar/packages/isar_core"),
            schema,
            0,
            false,
            None,
        )
        .unwrap();
    }
}
