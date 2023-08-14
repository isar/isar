use super::schema_manager::perform_migration;
use super::sqlite3::SQLite3;
use super::sqlite_collection::{SQLiteCollection, SQLiteProperty};
use super::sqlite_instance::SQLiteInstanceInfo;
use super::sqlite_txn::SQLiteTxn;
use crate::core::error::Result;
use crate::core::schema::IsarSchema;
use crate::SQLITE_MEMORY_DIR;
use intmap::IntMap;
use itertools::Itertools;
use parking_lot::Mutex;
use std::fs::remove_file;
use std::path::PathBuf;
use std::rc::Rc;
use std::sync::{Arc, LazyLock};

static INSTANCES: LazyLock<Mutex<IntMap<Connections>>> =
    LazyLock::new(|| Mutex::new(IntMap::new()));

const MIB: usize = 1 << 20;

struct Connections {
    info: Arc<SQLiteInstanceInfo>,
    sqlite: Vec<SQLite3>,
}

impl Connections {
    fn get_sqlite(&mut self) -> Result<SQLite3> {
        if let Some(sqlite) = self.sqlite.pop() {
            Ok(sqlite)
        } else {
            SQLite3::open(&self.info.path, self.info.encryption_key.as_deref())
        }
    }
}

pub(crate) fn open_sqlite(
    instance_id: u32,
    name: &str,
    dir: &str,
    schemas: Vec<IsarSchema>,
    max_size_mib: u32,
    encryption_key: Option<&str>,
) -> Result<(SQLiteInstanceInfo, SQLite3)> {
    let path = if dir == SQLITE_MEMORY_DIR {
        format!("file:{}?mode=memory", name)
    } else {
        let mut path_buf = PathBuf::from(dir);
        path_buf.push(format!("{}.sqlite", name));
        path_buf.as_path().to_str().unwrap().to_string()
    };

    let sqlite = SQLite3::open(&path, encryption_key)?;

    let max_size = (max_size_mib as usize).saturating_mul(MIB);
    sqlite
        .prepare(&format!("PRAGMA mmap_size={}", max_size))?
        .step()?;
    sqlite.prepare("PRAGMA journal_mode=WAL")?.step()?;

    let sqlite = Rc::new(sqlite);
    let txn = SQLiteTxn::new(sqlite.clone(), true)?;
    perform_migration(&txn, &schemas)?;
    txn.commit()?;

    let collections = get_collections(&schemas);
    {
        let txn = SQLiteTxn::new(sqlite.clone(), false)?;
        for collection in &collections {
            if !collection.is_embedded() {
                collection.init_auto_increment(&txn)?;
            }
        }
        txn.abort();
    }

    let instance_info =
        SQLiteInstanceInfo::new(instance_id, name, dir, &path, encryption_key, collections);
    let sqlite = Rc::into_inner(sqlite).unwrap();
    Ok((instance_info, sqlite))
}

fn get_collections(schemas: &[IsarSchema]) -> Vec<SQLiteCollection> {
    let mut collections = Vec::new();
    for collection_schema in schemas {
        let properties = collection_schema
            .properties
            .iter()
            .filter_map(|p| {
                if let Some(name) = &p.name {
                    let target_collection_index = p.collection.as_deref().map(|c| {
                        let position = schemas.iter().position(|c2| c2.name == c).unwrap();
                        position as u16
                    });
                    let prop = SQLiteProperty::new(name, p.data_type, target_collection_index);
                    Some(prop)
                } else {
                    None
                }
            })
            .collect_vec();
        let collection = SQLiteCollection::new(
            collection_schema.name.clone(),
            collection_schema.id_name.clone(),
            properties,
            collection_schema.indexes.clone(),
        );
        collections.push(collection);
    }
    collections
}

pub(crate) fn get_instance(instance_id: u32) -> Option<(Arc<SQLiteInstanceInfo>, SQLite3)> {
    let mut lock = INSTANCES.lock();
    if let Some(connections) = lock.get_mut(instance_id as u64) {
        let sqlite = connections.get_sqlite().ok()?;
        Some((connections.info.clone(), sqlite))
    } else {
        None
    }
}

pub(crate) fn open_instance(
    instance_id: u32,
    name: &str,
    dir: &str,
    schemas: Vec<IsarSchema>,
    max_size_mib: u32,
    encryption_key: Option<&str>,
) -> Result<(Arc<SQLiteInstanceInfo>, SQLite3)> {
    let mut lock = INSTANCES.lock();
    if !lock.contains_key(instance_id as u64) {
        let (info, sqlite) = open_sqlite(
            instance_id,
            name,
            dir,
            schemas,
            max_size_mib,
            encryption_key,
        )?;

        let connections = Connections {
            info: Arc::new(info),
            sqlite: vec![sqlite],
        };
        lock.insert(instance_id as u64, connections);
    }

    let connections = lock.get_mut(instance_id as u64).unwrap();
    Ok((connections.info.clone(), connections.get_sqlite()?))
}

pub(crate) fn close_instance(
    info: Arc<SQLiteInstanceInfo>,
    sqlite: Rc<SQLite3>,
    delete: bool,
) -> bool {
    // Check whether all other references are gone
    if Arc::strong_count(&info) == 2 {
        let mut lock = INSTANCES.lock();
        // Check again to make sure there are no new references
        if Arc::strong_count(&info) == 2 {
            lock.remove(info.instance_id as u64);

            if delete && &info.dir != SQLITE_MEMORY_DIR {
                let path = info.path.to_string();
                drop(sqlite);
                let _ = remove_file(&path);
                let _ = remove_file(&format!("{}-wal", path));
                let _ = remove_file(&format!("{}-shm", path));
            }
            return true;
        }
    }

    // Return connection to pool
    if let Some(sqlite) = Rc::into_inner(sqlite) {
        let mut lock = INSTANCES.lock();
        let connections = lock.get_mut(info.instance_id as u64).unwrap();
        connections.sqlite.push(sqlite);
    }

    false
}
