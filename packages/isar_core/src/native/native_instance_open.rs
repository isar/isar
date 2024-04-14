use super::mdbx::env::Env;
use super::native_collection::NativeCollection;
use super::native_instance::NativeInstance;
use super::native_txn::NativeTxn;
use super::schema::schema_manager::SchemaManager;
use crate::core::error::{IsarError, Result};
use crate::core::instance::CompactCondition;
use crate::core::schema::IsarSchema;
use std::fs;
use std::sync::Arc;

impl NativeInstance {
    pub(crate) fn open(
        name: &str,
        dir: &str,
        instance_id: u32,
        schemas: Vec<IsarSchema>,
        max_size_mib: u32,
        compact_condition: Option<CompactCondition>,
    ) -> Result<Self> {
        let path = Self::build_file_path(name, dir);

        let compact_schemas = if compact_condition.is_some() {
            Some(schemas.clone())
        } else {
            None
        };

        let db_count = schemas
            .iter()
            .filter(|s| !s.embedded)
            .map(|s| s.indexes.len() as u32 + 1)
            .sum::<u32>()
            + 2;
        let env = Env::create(&path, db_count, max_size_mib)?;
        let collections = SchemaManager::initialize_collections(instance_id, &env, schemas)?;

        match compact_condition {
            Some(compact_condition)
                if Self::should_compact(&env, &collections, &path, &compact_condition)? =>
            {
                Self::compact(env, &path)?;
                Self::open(
                    name,
                    dir,
                    instance_id,
                    compact_schemas.unwrap(),
                    max_size_mib,
                    None,
                )
            }
            _ => Ok(Self::new(name, dir, instance_id, collections, env)),
        }
    }

    fn should_compact(
        env: &Arc<Env>,
        collections: &[NativeCollection],
        path: &str,
        compact_condition: &CompactCondition,
    ) -> Result<bool> {
        let txn = NativeTxn::new(0, &env, true)?;
        let mut instance_size = 0;
        for collection in collections.iter() {
            instance_size += collection.get_size(&txn, true)?;
        }
        txn.abort();

        let file_size = fs::metadata(&path)
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

        Ok(should_compact)
    }

    fn compact(env: Arc<Env>, path: &str) -> Result<()> {
        let compact_file = format!("{path}.compact");
        env.copy(&compact_file)?;
        drop(env);

        fs::rename(&compact_file, &path).map_err(|_| IsarError::PathError {})
    }
}
