use std::path::PathBuf;
use std::sync::{Arc, RwLock};

use intmap::IntMap;
use once_cell::sync::Lazy;
use xxhash_rust::xxh3::xxh3_64;

use crate::core::error::{IsarError, Result};
use crate::core::instance::IsarInstance;
use crate::core::schema::IsarSchema;

use super::schema::hash_schema;

pub(crate) fn get_or_open_instance<T: IsarInstance>(
    instances: &Lazy<RwLock<IntMap<Arc<T>>>>,
    name: &str,
    mut schema: IsarSchema,
    open_instance: impl FnOnce(IsarSchema) -> Result<T>,
) -> Result<Arc<T>> {
    let mut lock = instances.write().unwrap();
    let instance_id = xxh3_64(name.as_bytes());
    if let Some(instance) = lock.get(instance_id) {
        if instance.schema_hash() == hash_schema(&mut schema) {
            Ok(instance.clone())
        } else {
            Err(IsarError::SchemaMismatch {})
        }
    } else {
        let new_instance = open_instance(schema)?;
        let new_instance = Arc::new(new_instance);
        lock.insert(instance_id, new_instance.clone());
        Ok(new_instance)
    }
}

pub(crate) fn get_isar_path(name: &str, dir: &str) -> String {
    let mut file_name = name.to_string();
    file_name.push_str(".isar");

    let mut path_buf = PathBuf::from(dir);
    path_buf.push(file_name);
    path_buf.as_path().to_str().unwrap().to_string()
}
