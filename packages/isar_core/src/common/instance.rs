use super::schema::hash_schema;
use crate::core::error::{IsarError, Result};
use crate::core::instance::IsarInstance;
use crate::core::schema::IsarSchema;
use intmap::IntMap;
use once_cell::sync::Lazy;
use std::sync::{Arc, RwLock};
use xxhash_rust::xxh3::xxh3_64;

pub(crate) fn get_or_open_instance<T: IsarInstance>(
    instances: &Lazy<RwLock<IntMap<Arc<T>>>>,
    name: &str,
    schema: IsarSchema,
    open_instance: impl FnOnce(IsarSchema) -> Result<T>,
) -> Result<Arc<T>> {
    let mut lock = instances.write().unwrap();
    let instance_id = xxh3_64(name.as_bytes());
    if let Some(instance) = lock.get(instance_id) {
        if instance.schema_hash() == hash_schema(schema.clone()) {
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
