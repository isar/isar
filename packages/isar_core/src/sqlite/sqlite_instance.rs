use super::sqlite3::SQLite3;
use super::sqlite_collection::SQLiteCollection;
use super::sqlite_schema_manager::SQLiteSchemaManager;
use super::sqlite_txn::SQLiteTxn;
use crate::common::instance::get_or_open_instance;
use crate::common::schema::hash_schema;
use crate::core::error::{IsarError, Result};
use crate::core::instance::{CompactCondition, IsarInstance};
use crate::core::schema::IsarSchema;
use intmap::IntMap;
use once_cell::sync::Lazy;
use std::cell::RefCell;
use std::path::PathBuf;
use std::sync::{Arc, RwLock};
use thread_local::ThreadLocal;

static INSTANCES: Lazy<RwLock<IntMap<Arc<SqliteInstance>>>> =
    Lazy::new(|| RwLock::new(IntMap::new()));

pub struct SqliteInstance {
    path: String,
    instance_id: u64,
    sqlite: ThreadLocal<RefCell<Option<SQLite3>>>,
    collections: IntMap<SQLiteCollection>,
    schema_hash: u64,
}

//unsafe impl Send for SqliteInstance {}

//unsafe impl Sync for SqliteInstance {}

impl SqliteInstance {
    fn open_instance(
        name: &str,
        dir: Option<&str>,
        schema: IsarSchema,
        relaxed_durability: bool,
    ) -> Result<Self> {
        if let Some(dir) = dir {
            let schema_hash = hash_schema(schema.clone());

            let mut path_buf = PathBuf::from(dir);
            path_buf.push(format!("{}.sqlite", name));
            let path = path_buf.as_path().to_str().unwrap().to_string();

            let sqlite = SQLite3::open(&path).unwrap();
            let schema_manager = SQLiteSchemaManager::new(&sqlite);
            schema_manager.perform_migration(&schema)?;

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
        let sqlite = self
            .sqlite
            .get_or_try(|| -> Result<RefCell<Option<SQLite3>>> {
                let sqlite = SQLite3::open(&self.path)?;
                Ok(RefCell::new(Some(sqlite)))
            })
            .unwrap()
            .take();
        let sqlite = if let Some(sqlite) = sqlite {
            sqlite
        } else {
            SQLite3::open(&self.path)?
        };
        SQLiteTxn::new(self.instance_id, write, sqlite)
    }

    fn commit_txn(&self, txn: Self::Txn) -> Result<()> {
        let sqlite = txn.commit()?;
        if let Some(cell) = self.sqlite.get() {
            cell.replace(Some(sqlite));
        }
        Ok(())
    }

    fn abort_txn(&self, txn: Self::Txn) {
        if let Ok(sqlite) = txn.abort() {
            if let Some(cell) = self.sqlite.get() {
                cell.replace(Some(sqlite));
            }
        }
    }
}

mod test {
    use intmap::IntMap;

    use crate::{
        core::{
            data_type::DataType,
            instance::IsarInstance,
            schema::{CollectionSchema, IndexSchema, IsarSchema, PropertySchema},
            writer::IsarWriter,
        },
        sqlite::sqlite_writer::SQLiteWriter,
    };

    use super::SqliteInstance;

    #[test]
    fn test_exec() {
        let schema = IsarSchema::new(vec![CollectionSchema::new(
            "Test",
            vec![
                PropertySchema::new("mypeop", DataType::String, None),
                PropertySchema::new("myprop2", DataType::String, None),
            ],
            vec![
                IndexSchema::new("myindex", vec!["mypeop"], false),
                IndexSchema::new("myindex2", vec!["mypeop", "myprop2"], false),
            ],
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

        /*let txn = instance.begin_txn(true).unwrap();
        let sqlite = txn.get_sqlite(0, true).unwrap();
        let stmt = sqlite
            .prepare("INSERT INTO Test (mypeop, myprop2) VALUES (?, ?)")
            .unwrap();

        let props = vec![];
        let embed = IntMap::new();
        let mut writer = SQLiteWriter::new(stmt, &props, &embed);
        let mut o = writer.begin_object();
        o.write_string(Some("hello"));
        writer.end_object(o);*/
    }
}
