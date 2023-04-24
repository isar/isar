use super::schema_manager::perform_migration;
use super::sqlite3::SQLite3;
use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use super::sqlite_insert::SQLiteInsert;
use super::sqlite_query_builder::SQLiteQueryBuilder;
use super::sqlite_txn::SQLiteTxn;
use crate::common::schema::verify_schema;
use crate::core::error::{IsarError, Result};
use crate::core::instance::{CompactCondition, IsarInstance};
use crate::core::schema::IsarSchema;
use intmap::IntMap;
use itertools::Itertools;
use once_cell::sync::Lazy;
use std::cell::Cell;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

static INSTANCES: Lazy<Mutex<IntMap<Connections>>> = Lazy::new(|| Mutex::new(IntMap::new()));

struct Connections {
    info: Arc<SQLiteInstanceInfo>,
    sqlite: Vec<SQLite3>,
}

struct SQLiteInstanceInfo {
    path: String,
    collections: Vec<SQLiteCollection>,
}

pub struct SQLiteInstance {
    info: Arc<SQLiteInstanceInfo>,
    sqlite: SQLite3,
    txn_active: Cell<bool>,
}

impl SQLiteInstance {
    fn open_instance(
        name: &str,
        dir: &str,
        schema: IsarSchema,
        _relaxed_durability: bool,
    ) -> Result<(SQLiteInstanceInfo, SQLite3)> {
        verify_schema(&schema)?;

        let mut path_buf = PathBuf::from(dir);
        path_buf.push(format!("{}.sqlite", name));
        let path = path_buf.as_path().to_str().unwrap().to_string();

        let sqlite = SQLite3::open(&path).unwrap();
        let txn = SQLiteTxn::new(&sqlite, true)?;
        perform_migration(&txn, &schema)?;
        txn.commit()?;

        let collections = Self::get_collections(&schema);
        let instance_info = SQLiteInstanceInfo { path, collections };
        Ok((instance_info, sqlite))
    }

    fn get_collections(schema: &IsarSchema) -> Vec<SQLiteCollection> {
        let mut collections = Vec::new();
        for collection_schema in &schema.collections {
            let properties = collection_schema
                .properties
                .iter()
                .filter_map(|p| {
                    if let Some(name) = &p.name {
                        let target_collection_index = p.collection.as_deref().map(|c| {
                            let position = schema
                                .collections
                                .iter()
                                .position(|c2| c2.name == c)
                                .unwrap();
                            position as u16
                        });
                        let prop = SQLiteProperty::new(name, p.data_type, target_collection_index);
                        Some(prop)
                    } else {
                        None
                    }
                })
                .collect_vec();
            let collection = SQLiteCollection::new(collection_schema.name.clone(), properties);
            collections.push(collection);
        }
        collections
    }
}

impl IsarInstance for SQLiteInstance {
    type Txn<'a> = SQLiteTxn<'a>;

    type Insert<'a> = SQLiteInsert<'a>;

    type QueryBuilder<'a> = SQLiteQueryBuilder<'a>;

    type Instance = Self;

    fn get(schema_hash: u64) -> Option<Self::Instance> {
        let mut lock = INSTANCES.lock().unwrap();
        if let Some(connections) = lock.get_mut(schema_hash) {
            let sqlite = connections
                .sqlite
                .pop()
                .or_else(|| SQLite3::open(&connections.info.path).ok());
            if let Some(sqlite) = sqlite {
                Some(Self {
                    info: connections.info.clone(),
                    sqlite: sqlite,
                    txn_active: Cell::new(false),
                })
            } else {
                None
            }
        } else {
            None
        }
    }

    fn open(
        instance_id: u64,
        name: &str,
        dir: &str,
        schema: IsarSchema,
        _max_size_mib: usize,
        relaxed_durability: bool,
        _compact_condition: Option<CompactCondition>,
    ) -> Result<Self> {
        let mut lock = INSTANCES.lock().unwrap();
        if !lock.contains_key(instance_id) {
            let (info, sqlite) = Self::open_instance(name, dir, schema, relaxed_durability)?;
            let connections = Connections {
                info: Arc::new(info),
                sqlite: vec![sqlite],
            };
            lock.insert(instance_id, connections);
        }

        let connections = lock.get_mut(instance_id).unwrap();
        let sqlite = connections.sqlite.pop().unwrap();
        Ok(Self {
            info: connections.info.clone(),
            sqlite: sqlite,
            txn_active: Cell::new(false),
        })
    }

    fn begin_txn(&self, write: bool) -> Result<SQLiteTxn> {
        if self.txn_active.replace(true) {
            Err(IsarError::IllegalArg {
                message: "A transaction is already active.".to_string(),
            })
        } else {
            SQLiteTxn::new(&self.sqlite, write)
        }
    }

    fn commit_txn(&self, txn: SQLiteTxn) -> Result<()> {
        self.txn_active.replace(false);
        txn.commit()
    }

    fn abort_txn(&self, txn: SQLiteTxn) {
        self.txn_active.replace(false);
        txn.abort();
    }

    fn query<'a>(&'a self, collection_index: usize) -> Result<Self::QueryBuilder<'a>> {
        let collection = &self.info.collections[collection_index];
        let query_builder = SQLiteQueryBuilder::new(collection, &self.info.collections);
        Ok(query_builder)
    }

    fn insert<'a>(
        &'a self,
        txn: SQLiteTxn<'a>,
        collection_index: usize,
        count: usize,
    ) -> Result<Self::Insert<'a>> {
        let collection = &self.info.collections[collection_index];
        let insert = SQLiteInsert::new(txn, collection, &self.info.collections, count);
        Ok(insert)
    }
}

mod test {
    use super::SQLiteInstance;
    use crate::core::data_type::DataType;
    //use crate::core::filter::IsarFilterBuilder;
    use crate::core::insert::IsarInsert;
    use crate::core::instance::IsarInstance;
    use crate::core::query::IsarCursor;
    use crate::core::query::IsarQuery;
    use crate::core::query_builder::IsarQueryBuilder;
    use crate::core::reader::IsarReader;
    use crate::core::schema::{CollectionSchema, IndexSchema, IsarSchema, PropertySchema};

    use crate::core::writer::IsarWriter;
    use crate::sqlite::sqlite_filter::*;
    use crate::sqlite::sqlite_query_builder::SQLiteQueryBuilder;

    #[test]
    fn test_exec() {
        let schema = IsarSchema::new(vec![CollectionSchema::new(
            "Test",
            vec![
                PropertySchema::new("prop1", DataType::String, None),
                PropertySchema::new("prop2", DataType::Long, None),
            ],
            vec![IndexSchema::new("myindex", vec!["prop1"], false)],
            false,
        )]);
        let instance = SQLiteInstance::open(
            0,
            "test",
            "/Users/simon/Documents/GitHub/isar/packages/isar_core",
            schema,
            0,
            false,
            None,
        )
        .unwrap();

        let txn = instance.begin_txn(true).unwrap();
        let txn = {
            let mut insert = instance.insert(txn, 0, 1).unwrap();
            insert.write_string("val1");
            insert.write_long(2);
            insert.insert(Some(999)).unwrap().finish().unwrap()
        };

        let txn = {
            let mut insert = instance.insert(txn, 0, 1).unwrap();
            insert.write_string("val2");
            insert.write_long(4);
            insert.insert(Some(9999)).unwrap().finish().unwrap()
        };

        instance.commit_txn(txn).unwrap();
        /*writer.write_id(998);
        writer.write_string(Some("val3"));
        writer.write_string(Some("val4"));
        let mut writer = insert.insert(writer).unwrap().unwrap();
        writer.write_id(999);
        writer.write_string(Some("val5"));
        writer.write_string(Some("val6"));
        insert.insert(writer).unwrap();*/
        //txn.commit().unwrap();

        let mut txn = instance.begin_txn(false).unwrap();
        let mut qb = instance.query(0).unwrap();
        /*let filter = qb.not_null(1);
        qb.set_filter(filter);*/
        let q = qb.build();
        let mut cur = q.cursor(txn).unwrap();
        let next = cur.next().unwrap().unwrap();
        eprintln!("{:?}", next.read_id());
        eprintln!("{:?}", next.read_string(1));
        let next = cur.next().unwrap().unwrap();
        eprintln!("{:?}", next.read_id());
        eprintln!("{:?}", next.read_string(1));
    }
}
