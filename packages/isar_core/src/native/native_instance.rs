use super::mdbx::env::Env;
use super::native_collection::NativeCollection;
use super::native_insert::NativeInsert;
use super::native_query_builder::NativeQueryBuilder;
use super::native_txn::NativeTxn;
use super::query::{Query, QueryCursor};
use super::schema_manager::perform_migration;
use crate::core::error::{IsarError, Result};
use crate::core::instance::{CompactCondition, IsarInstance};
use crate::core::schema::IsarSchema;
use intmap::IntMap;
use once_cell::sync::Lazy;
use std::fs::{self, remove_file};
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

static INSTANCES: Lazy<Mutex<IntMap<Arc<NativeInstance>>>> =
    Lazy::new(|| Mutex::new(IntMap::new()));

pub struct NativeInstance {
    dir: String,
    name: String,
    instance_id: u32,
    collections: Vec<NativeCollection>,
    env: Arc<Env>,
}

impl IsarInstance for NativeInstance {
    type Instance = Arc<Self>;

    type Txn = NativeTxn;

    type Insert<'a> = NativeInsert<'a>
    where
        Self: 'a;

    type QueryBuilder<'a> = NativeQueryBuilder<'a>
    where
        Self: 'a;

    type Query = Query;

    type Cursor<'a> = QueryCursor<'a>
    where
        Self: 'a;

    fn get(instance_id: u32) -> Option<Self::Instance> {
        let mut lock = INSTANCES.lock().unwrap();
        if let Some(instance) = lock.get_mut(instance_id as u64) {
            Some(Arc::clone(&instance))
        } else {
            None
        }
    }

    fn open(
        instance_id: u32,
        name: &str,
        dir: &str,
        schema: IsarSchema,
        max_size_mib: u32,
        relaxed_durability: bool,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Self::Instance> {
        let mut lock = INSTANCES.lock().unwrap();
        if let Some(instance) = lock.get(instance_id as u64) {
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
            lock.insert(instance_id as u64, new_instance.clone());
            Ok(new_instance)
        }
    }

    fn begin_txn(&self, write: bool) -> Result<Self::Txn> {
        NativeTxn::new(self.instance_id, &self.env, write)
    }

    fn commit_txn(&self, txn: Self::Txn) -> Result<()> {
        self.verify_instance_id(txn.instance_id)?;
        txn.commit()
    }

    fn abort_txn(&self, txn: Self::Txn) {
        if self.verify_instance_id(txn.instance_id).is_ok() {
            txn.abort()
        }
    }

    fn get_largest_id(&self, collection_index: u16) -> Result<i64> {
        let collection = &self.collections[collection_index as usize];
        Ok(collection.get_largest_id())
    }

    fn insert<'a>(
        &'a self,
        txn: NativeTxn,
        collection_index: u16,
        count: u32,
    ) -> Result<NativeInsert<'a>> {
        self.verify_instance_id(txn.instance_id)?;
        let collection = &self.collections[collection_index as usize];
        Ok(NativeInsert::new(txn, collection, &self.collections, count))
    }

    fn count(&self, txn: &Self::Txn, collection_index: u16) -> Result<u32> {
        self.verify_instance_id(txn.instance_id)?;
        let collection = &self.collections[collection_index as usize];
        let (count, _) = txn.stat(collection.get_db()?)?;
        Ok(count as u32)
    }

    fn get_size(
        &self,
        collection_index: Option<u16>,
        include_indexes: bool,
        include_links: bool,
    ) -> Result<u32> {
        panic!()
    }

    fn query(&self, collection_index: u16) -> Result<Self::QueryBuilder<'_>> {
        let collection = &self.collections[collection_index as usize];
        Ok(NativeQueryBuilder::new(
            self.instance_id,
            collection,
            &self.collections,
        ))
    }

    fn cursor<'a>(
        &'a self,
        txn: &'a Self::Txn,
        query: &'a Self::Query,
        offset: Option<u32>,
        limit: Option<u32>,
    ) -> Result<Self::Cursor<'a>> {
        self.verify_instance_id(txn.instance_id)?;
        self.verify_instance_id(query.instance_id)?;
        query.cursor(txn, &self.collections, offset, limit)
    }

    fn delete(&self, txn: &Self::Txn, query: &Self::Query) -> Result<u32> {
        self.verify_instance_id(txn.instance_id)?;
        let collection = &self.collections[query.collection_index];
        query.delete(txn, collection)
    }

    fn close(instance: Arc<Self>, delete: bool) -> bool {
        // Check whether all other references are gone
        if Arc::strong_count(&instance) == 2 {
            let mut lock = INSTANCES.lock().unwrap();
            // Check again to make sure there are no new references
            if Arc::strong_count(&instance) == 2 {
                lock.remove(instance.instance_id as u64);

                if delete {
                    let mut path = Self::get_isar_path(&instance.name, &instance.dir);
                    drop(instance);
                    let _ = remove_file(&path);
                    path.push_str(".lock");
                    let _ = remove_file(&path);
                }
                return true;
            }
        }
        false
    }
}

impl NativeInstance {
    pub(crate) fn verify_instance_id(&self, instance_id: u32) -> Result<()> {
        if self.instance_id != instance_id {
            Err(IsarError::InstanceMismatch {})
        } else {
            Ok(())
        }
    }

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
        instance_id: u32,
        schema: IsarSchema,
        max_size_mib: u32,
        relaxed_durability: bool,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Self> {
        let isar_file = Self::get_isar_path(name, dir);

        let db_count = schema
            .collections
            .iter()
            .filter(|c| !c.embedded)
            .map(|c| c.indexes.len() as u32 + 1)
            .sum::<u32>()
            + 1;
        let env = Env::create(
            &isar_file,
            db_count,
            max_size_mib.max(1),
            relaxed_durability,
        )?;

        let txn = NativeTxn::new(instance_id, &env, true)?;
        let collections = perform_migration(&txn, &schema)?;
        txn.commit()?;

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
        let txn = self.begin_txn(false)?;
        let instance_size = 0; //self.get_size(&mut txn, true, true)?;
        txn.abort();

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
        let should_compact = file_size >= compact_condition.min_file_size as u64
            && compact_bytes >= compact_condition.min_bytes as u64
            && compact_ratio >= compact_condition.min_ratio as f64;

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
    use crate::{
        core::{
            data_type::DataType,
            insert::IsarInsert,
            query_builder::IsarQueryBuilder,
            schema::{CollectionSchema, PropertySchema},
            writer::IsarWriter,
        },
        filter::{filter_condition::FilterCondition, filter_value::FilterValue, Filter},
    };

    use super::*;

    #[test]
    fn test_exec() {
        let schema = IsarSchema::new(vec![CollectionSchema::new(
            "test2",
            vec![
                PropertySchema::new("str", DataType::String, None),
                PropertySchema::new("str2", DataType::String, None),
            ],
            vec![],
            false,
        )]);
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
        /*let mut insert = i.insert(txn, 0, 10000000).unwrap();
        for i in 0..10000000 {
            insert.write_string(&format!("STR{}", i));
            insert.write_string("STR2!!!");
            insert = insert.insert(Some(i as i64)).unwrap();
        }
        let txn = insert.finish().unwrap();*/

        let mut builder = i.query(0).unwrap();
        builder.set_filter(Filter::Condition(FilterCondition::new_string_contains(
            0, "1", false,
        )));
        let q = builder.build();
        //eprintln!("{:?}", i.count(&txn, &q));
        i.commit_txn(txn).unwrap();
        i.clone();
        println!("hello");
    }
}
