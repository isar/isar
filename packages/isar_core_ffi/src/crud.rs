use crate::c_object_set::{CObject, CObjectSet};
use crate::txn::CIsarTxn;
use crate::{from_c_str, BoolSend, UintSend};
use intmap::IntMap;
use isar_core::collection::IsarCollection;
use isar_core::error::IsarError;
use isar_core::index::index_key::IndexKey;
use serde_json::Value;
use std::os::raw::c_char;

#[no_mangle]
pub unsafe extern "C" fn isar_get(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    object: &'static mut CObject,
) -> i64 {
    isar_try_txn!(txn, move |txn| {
        let id = object.get_id();
        let result = collection.get(txn, id)?;
        object.set_object(result);
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_by_index(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    index_id: u64,
    key: *mut IndexKey,
    object: &'static mut CObject,
) -> i64 {
    let key = *Box::from_raw(key);
    isar_try_txn!(txn, move |txn| {
        let result = collection.get_by_index(txn, index_id, &key)?;
        if let Some((id, obj)) = result {
            object.set_id(id);
            object.set_object(Some(obj));
        } else {
            object.set_object(None);
        }
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_all(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    objects: &'static mut CObjectSet,
) -> i64 {
    isar_try_txn!(txn, move |txn| {
        for object in objects.get_objects() {
            let id = object.get_id();
            let result = collection.get(txn, id)?;
            object.set_object(result);
        }
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_all_by_index(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    index_id: u64,
    keys: *const *mut IndexKey,
    objects: &'static mut CObjectSet,
) -> i64 {
    let slice = std::slice::from_raw_parts(keys, objects.get_length());
    let keys: Vec<IndexKey> = slice.iter().map(|k| *Box::from_raw(*k)).collect();
    isar_try_txn!(txn, move |txn| {
        for (object, key) in objects.get_objects().iter_mut().zip(keys) {
            let result = collection.get_by_index(txn, index_id, &key)?;
            if let Some((id, obj)) = result {
                object.set_id(id);
                object.set_object(Some(obj));
            } else {
                object.set_object(None);
            }
        }
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_put(
    collection: &'static mut IsarCollection,
    txn: &mut CIsarTxn,
    object: &'static mut CObject,
) -> i64 {
    isar_try_txn!(txn, move |txn| {
        let id = if object.get_id() != i64::MIN {
            Some(object.get_id())
        } else {
            None
        };
        let id = collection.put(txn, id, object.get_object())?;
        object.set_id(id);
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_put_by_index(
    collection: &'static mut IsarCollection,
    txn: &mut CIsarTxn,
    index_id: u64,
    object: &'static mut CObject,
) -> i64 {
    isar_try_txn!(txn, move |txn| {
        let id = collection.put_by_index(txn, index_id, object.get_object())?;
        object.set_id(id);
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_put_all(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    objects: &'static mut CObjectSet,
) -> i64 {
    isar_try_txn!(txn, move |txn| {
        for object in objects.get_objects() {
            let id = if object.get_id() != i64::MIN {
                Some(object.get_id())
            } else {
                None
            };
            let id = collection.put(txn, id, object.get_object())?;
            object.set_id(id)
        }
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_put_all_by_index(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    index_id: u64,
    objects: &'static mut CObjectSet,
) -> i64 {
    isar_try_txn!(txn, move |txn| {
        for object in objects.get_objects() {
            let id = collection.put_by_index(txn, index_id, object.get_object())?;
            object.set_id(id)
        }
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_delete(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    id: i64,
    deleted: &'static mut bool,
) -> i64 {
    let deleted = BoolSend(deleted);
    isar_try_txn!(txn, move |txn| {
        *deleted.0 = collection.delete(txn, id)?;
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_delete_by_index(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    index_id: u64,
    key: *mut IndexKey,
    deleted: &'static mut bool,
) -> i64 {
    let deleted = BoolSend(deleted);
    let key = *Box::from_raw(key);
    isar_try_txn!(txn, move |txn| {
        *deleted.0 = collection.delete_by_index(txn, index_id, &key)?;
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_delete_all(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    ids: *const i64,
    ids_length: u32,
    count: &'static mut u32,
) -> i64 {
    let ids = std::slice::from_raw_parts(ids, ids_length as usize);
    let count = UintSend(count);
    isar_try_txn!(txn, move |txn| {
        let mut n = 0u32;
        for id in ids {
            if collection.delete(txn, *id)? {
                n += 1;
            }
        }
        *count.0 = n;
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_delete_all_by_index(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    index_id: u64,
    keys: *const *mut IndexKey,
    keys_length: u32,
    count: &'static mut u32,
) -> i64 {
    let slice = std::slice::from_raw_parts(keys, keys_length as usize);
    let keys: Vec<IndexKey> = slice.iter().map(|k| *Box::from_raw(*k)).collect();
    let count = UintSend(count);
    isar_try_txn!(txn, move |txn| {
        let mut n = 0u32;
        for key in keys {
            if collection.delete_by_index(txn, index_id, &key)? {
                n += 1;
            }
        }
        *count.0 = n;
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_clear(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
) -> i64 {
    isar_try_txn!(txn, move |txn| collection.clear(txn))
}

#[no_mangle]
pub unsafe extern "C" fn isar_json_import(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    id_name: *const c_char,
    json_bytes: *const u8,
    json_length: u32,
) -> i64 {
    let id_name = from_c_str(id_name).unwrap();
    let bytes = std::slice::from_raw_parts(json_bytes, json_length as usize);
    isar_try_txn!(txn, move |txn| {
        let json: Value = serde_json::from_slice(bytes).map_err(|_| IsarError::InvalidJson {})?;
        collection.import_json(txn, id_name, json)
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_count(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    count: &'static mut i64,
) -> i64 {
    isar_try_txn!(txn, move |txn| {
        *count = collection.count(txn)? as i64;
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_size(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    include_indexes: bool,
    include_links: bool,
    size: &'static mut i64,
) -> i64 {
    isar_try_txn!(txn, move |txn| {
        *size = collection.get_size(txn, include_indexes, include_links)? as i64;
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_verify(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    objects: &'static mut CObjectSet,
) -> i64 {
    let mut objects_map = IntMap::new();
    for object in objects.get_objects() {
        objects_map.insert(object.get_id() as u64, object.get_object());
    }
    isar_try_txn!(txn, move |txn| { collection.verify(txn, &objects_map) })
}
