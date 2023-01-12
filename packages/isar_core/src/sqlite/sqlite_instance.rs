use std::cell::RefCell;
use std::path::PathBuf;
use std::sync::{Arc, RwLock};

use intmap::IntMap;
use once_cell::sync::Lazy;
use thread_local::ThreadLocal;

use crate::common::instance::{get_isar_path, get_or_open_instance};
use crate::common::schema::hash_schema;
use crate::core::error::{IsarError, Result};
use crate::core::instance::{CompactCondition, IsarInstance};
use crate::core::schema::IsarSchema;

use super::sql::create_table::sql_create_table;
use super::sqlite3::SQLite3;
use super::sqlite_txn::SQLiteTxn;

static INSTANCES: Lazy<RwLock<IntMap<Arc<SqliteInstance>>>> =
    Lazy::new(|| RwLock::new(IntMap::new()));

pub struct SqliteInstance {
    path: String,
    instance_id: u64,
    sqlite: ThreadLocal<RefCell<Option<SQLite3>>>,
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
            let sqlite = SQLite3::open(&path).unwrap();

            let col = schema.collections.first().unwrap();
            let create_sql = sql_create_table(col);
            println!("{}", create_sql);
            {
                let mut stmt = sqlite.prepare(&create_sql).unwrap();
                stmt.step().unwrap();
            }
            //pool.add(con);
            Ok(Self {
                path,
                instance_id: 0,
                sqlite: ThreadLocal::new(),
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
    type Txn = SQLiteTxn;

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

    fn begin_txn(&self, write: bool) -> Result<Self::Txn> {
        /*let con = self
        .conn
        .get_or_try(|| {
            let con = Connection::open(&self.path)?;
            Ok(RefCell::new(Some(con)))
        })
        .unwrap()
        .take();*/
        /*if let Some(con) = con {
            Ok(SQLiteTxn::new(self.instance_id, write, con))
        } else {*/
        Err(IsarError::IllegalArg {
            message: "Connection is already in use.".to_string(),
        })
        //}
    }

    fn commit_txn(&self, txn: Self::Txn) -> Result<()> {
        todo!()
    }

    fn abort_txn(&self, txn: Self::Txn) {
        todo!()
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
