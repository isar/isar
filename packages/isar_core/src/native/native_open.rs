use super::mdbx::env::Env;
use super::native_collection::NativeCollection;
use super::native_instance::NativeInstance;
use super::native_txn::NativeTxn;
use super::schema_manager::perform_migration;
use crate::core::error::{IsarError, Result};
use crate::core::instance::CompactCondition;
use crate::core::schema::IsarSchema;
use std::fs;
use std::path::PathBuf;
use std::sync::Arc;

pub(crate) fn open_native(
    name: &str,
    dir: &str,
    instance_id: u32,
    schemas: Vec<IsarSchema>,
    max_size_mib: u32,
    compact_condition: Option<CompactCondition>,
) -> Result<NativeInstance> {
    let path = get_isar_path(name, dir);

    // clone the schema in case we need to compact
    let compact_schemas = if compact_condition.is_some() {
        Some(schemas.clone())
    } else {
        None
    };

    // _info + collections + indexes + 1 (to delete old dbs)
    let db_count = schemas
        .iter()
        .filter(|c| !c.embedded)
        .map(|c| c.indexes.len() as u32 + 1)
        .sum::<u32>()
        + 2;
    let env = Env::create(&path, db_count, max_size_mib)?;
    let collections = perform_migration(instance_id, &env, schemas)?;

    let env_collections = if let Some(compact_condition) = &compact_condition {
        compact_instance(env, collections, &path, compact_condition)?
    } else {
        Some((env, collections))
    };

    if let Some((env, collections)) = env_collections {
        let instance = NativeInstance::new(name, dir, instance_id, collections, env);
        Ok(instance)
    } else {
        open_native(
            name,
            dir,
            instance_id,
            compact_schemas.unwrap(),
            max_size_mib,
            None,
        )
    }
}

fn compact_instance(
    env: Arc<Env>,
    collections: Vec<NativeCollection>,
    path: &str,
    compact_condition: &CompactCondition,
) -> Result<Option<(Arc<Env>, Vec<NativeCollection>)>> {
    let txn = NativeTxn::new(0, &env, true)?;
    let mut instance_size = 0;
    for collection in &collections {
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

    if should_compact {
        let compact_file = format!("{}.compact", &path);
        env.copy(&compact_file)?;
        drop(env);

        let _ = fs::rename(&compact_file, &path);
        Ok(None)
    } else {
        Ok(Some((env, collections)))
    }
}

pub(crate) fn get_isar_path(name: &str, dir: &str) -> String {
    let mut file_name = name.to_string();
    file_name.push_str(".isar");

    let mut path_buf = PathBuf::from(dir);
    path_buf.push(file_name);
    path_buf.as_path().to_str().unwrap().to_string()
}
