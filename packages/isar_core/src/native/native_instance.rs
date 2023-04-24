use super::mdbx::env::Env;
use super::native_collection::NativeCollection;
use super::native_insert::NativeInsert;
use super::native_query_builder::NativeQueryBuilder;
use super::native_txn::NativeTxn;
use super::schema_manager::perform_migration;
use crate::core::error::{IsarError, Result};
use crate::core::instance::{CompactCondition, IsarInstance};
use crate::core::schema::IsarSchema;
use intmap::IntMap;
use once_cell::sync::Lazy;
use std::fs::{self};
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

static INSTANCES: Lazy<Mutex<IntMap<Arc<NativeInstance>>>> =
    Lazy::new(|| Mutex::new(IntMap::new()));

struct NativeInstance {
    dir: String,
    name: String,
    instance_id: u64,
    collections: Vec<NativeCollection>,
    env: Env,
}

impl IsarInstance for NativeInstance {
    type Txn<'a> = NativeTxn<'a>;

    type Insert<'a> = NativeInsert<'a>
    where
        Self: 'a;

    type QueryBuilder<'a> = NativeQueryBuilder
    where
        Self: 'a;

    type Instance = Arc<Self>;

    fn get(instance_id: u64) -> Option<Self::Instance> {
        let mut lock = INSTANCES.lock().unwrap();
        if let Some(instance) = lock.get_mut(instance_id) {
            Some(Arc::clone(&instance))
        } else {
            None
        }
    }

    fn open(
        instance_id: u64,
        name: &str,
        dir: &str,
        schema: IsarSchema,
        max_size_mib: usize,
        relaxed_durability: bool,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Self::Instance> {
        let mut lock = INSTANCES.lock().unwrap();
        if let Some(instance) = lock.get(instance_id) {
            Ok(instance.clone())
        } else {
            let new_instance = Self::open_internal(
                name,
                dir,
                instance_id,
                schema,
                max_size_mib,
                relaxed_durability,
                compact_condition,
            )?;
            let new_instance = Arc::new(new_instance);
            lock.insert(instance_id, new_instance.clone());
            Ok(new_instance)
        }
    }

    fn begin_txn(&self, write: bool) -> Result<Self::Txn<'_>> {
        let txn = self.env.txn(write)?;
        Ok(NativeTxn::new(self.instance_id, txn))
    }

    fn commit_txn(&self, txn: Self::Txn<'_>) -> Result<()> {
        txn.commit(self.instance_id)
    }

    fn abort_txn(&self, txn: Self::Txn<'_>) {
        txn.abort(self.instance_id)
    }

    fn query(&self, collection_index: usize) -> Result<Self::QueryBuilder<'_>> {
        todo!()
    }

    fn insert<'a>(
        &'a self,
        txn: NativeTxn<'a>,
        collection_index: usize,
        count: usize,
    ) -> Result<NativeInsert<'a>> {
        let collection = &self.collections[collection_index];
        Ok(NativeInsert::new(txn, collection, &self.collections, count))
    }
}

impl NativeInstance {
    fn get_isar_path(name: &str, dir: &str) -> String {
        let mut file_name = name.to_string();
        file_name.push_str(".isar");

        let mut path_buf = PathBuf::from(dir);
        path_buf.push(file_name);
        path_buf.as_path().to_str().unwrap().to_string()
    }

    fn open_internal(
        name: &str,
        dir: &str,
        instance_id: u64,
        schema: IsarSchema,
        max_size_mib: usize,
        relaxed_durability: bool,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Self> {
        let isar_file = Self::get_isar_path(name, dir);

        let db_count: usize = schema
            .collections
            .iter()
            .map(|c| c.indexes.len() + 1)
            .sum::<usize>()
            + 3;
        let env = Env::create(
            &isar_file,
            db_count,
            max_size_mib.max(1),
            relaxed_durability,
        )?;

        let txn = env.txn(true)?;
        let native_txn = NativeTxn::new(instance_id, txn);
        let collections = perform_migration(&native_txn, &schema)?;
        native_txn.commit(instance_id)?;

        let instance = NativeInstance {
            env,
            name: name.to_string(),
            dir: dir.to_string(),
            collections,
            instance_id,
        };

        if let Some(compact_condition) = compact_condition {
            let instance = instance.compact(compact_condition)?;
            if let Some(instance) = instance {
                Ok(instance)
            } else {
                Self::open_internal(
                    name,
                    dir,
                    instance_id,
                    schema,
                    max_size_mib,
                    relaxed_durability,
                    None,
                )
            }
        } else {
            Ok(instance)
        }
    }

    fn compact(self, compact_condition: CompactCondition) -> Result<Option<Self>> {
        let mut txn = self.begin_txn(false)?;
        let instance_size = 0; //self.get_size(&mut txn, true, true)?;
        txn.abort(self.instance_id);

        let isar_file = Self::get_isar_path(&self.name, &self.dir);
        let file_size = fs::metadata(&isar_file)
            .map_err(|_| IsarError::PathError {})?
            .len();

        let compact_bytes = file_size.saturating_sub(instance_size);
        let compact_ratio = if instance_size == 0 {
            f64::INFINITY
        } else {
            (file_size as f64) / (instance_size as f64)
        };
        let should_compact = file_size >= compact_condition.min_file_size
            && compact_bytes >= compact_condition.min_bytes
            && compact_ratio >= compact_condition.min_ratio;

        if should_compact {
            let compact_file = format!("{}.compact", &isar_file);
            self.env.copy(&compact_file)?;
            drop(self);

            let _ = fs::rename(&compact_file, &isar_file);
            Ok(None)
        } else {
            Ok(Some(self))
        }
    }
}

mod test {
    use crate::core::{
        data_type::DataType,
        insert::IsarInsert,
        schema::{CollectionSchema, PropertySchema},
        writer::IsarWriter,
    };

    use super::*;

    #[test]
    fn test_exec() {
        let schema = IsarSchema::new(vec![
            CollectionSchema::new(
                "test",
                vec![PropertySchema::new(
                    "propa",
                    DataType::Object,
                    Some("test2"),
                )],
                vec![],
                false,
            ),
            CollectionSchema::new(
                "test2",
                vec![
                    PropertySchema::new("str", DataType::String, None),
                    PropertySchema::new("str2", DataType::String, None),
                ],
                vec![],
                false,
            ),
        ]);
        let i = NativeInstance::open(
            0,
            "test",
            "/Users/simon/Documents/GitHub/isar/packages/isar_core/tests",
            schema,
            1000,
            true,
            None,
        )
        .unwrap();

        let txn = i.begin_txn(true).unwrap();
        let mut insert = i.insert(txn, 0, 100).unwrap();
        for i in 0..100 {
            let mut obj_writer = insert.begin_object();
            obj_writer.write_string("STR1!!!");
            //obj_writer.write_string("STR2!!!");
            insert.end_object(obj_writer);
            eprintln!("inserted {}", i);
            insert = insert.insert(Some(i as i64)).unwrap();
        }
        let txn = insert.finish().unwrap();
        i.commit_txn(txn).unwrap();
        i.clone();
        println!("hello");
    }
}
