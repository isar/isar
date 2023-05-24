use crate::{CIsarInstance, CIsarReader, CIsarTxn, CIsarWriter};
use isar_core::core::instance::{CompactCondition, IsarInstance};
use isar_core::core::schema::IsarSchema;
use isar_core::native::native_instance::NativeInstance;
use std::os::raw::c_char;
use std::ptr;

include!(concat!(env!("OUT_DIR"), "/version.rs"));

#[no_mangle]
pub unsafe extern "C" fn isar_version() -> *const c_char {
    ISAR_VERSION.as_ptr() as *const c_char
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_instance(instance_id: u32) -> *const CIsarInstance {
    if let Some(instance) = NativeInstance::get_instance(instance_id) {
        Box::into_raw(Box::new(CIsarInstance::Native(instance)))
    } else {
        ptr::null()
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_open_instance(
    isar: *mut *const CIsarInstance,
    instance_id: u32,
    name: *mut String,
    path: *mut String,
    schema_json: *mut String,
    max_size_mib: u32,
    compact_min_file_size: u32,
    compact_min_bytes: u32,
    compact_min_ratio: f32,
) -> u8 {
    isar_try! {
        let name = *Box::from_raw(name);
        let path = *Box::from_raw(path);
        let schema_json = *Box::from_raw(schema_json);
        let schema = IsarSchema::from_json(schema_json.as_bytes())?;

        let compact_condition = if compact_min_ratio.is_nan() {
            None
        } else {
            Some(CompactCondition {
                min_file_size: compact_min_file_size ,
                min_bytes: compact_min_bytes,
                min_ratio: compact_min_ratio,
            })
        };

        let native_instance = NativeInstance::open_instance(
            instance_id ,
            &name,
            &path,
            schema,
            max_size_mib,
            compact_condition,
        )?;
        let new_isar = CIsarInstance::Native(native_instance);
        *isar = Box::into_raw(Box::new(new_isar));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_name(isar: &'static CIsarInstance, name: *mut *const u8) -> u32 {
    let value = match isar {
        CIsarInstance::Native(isar) => isar.get_name(),
    };
    *name = value.as_ptr();
    value.len() as u32
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_dir(isar: &'static CIsarInstance, dir: *mut *const u8) -> u32 {
    let value = match isar {
        CIsarInstance::Native(isar) => isar.get_dir(),
    };
    *dir = value.as_ptr();
    value.len() as u32
}

#[no_mangle]
pub unsafe extern "C" fn isar_txn_begin(
    isar: &'static CIsarInstance,
    txn: *mut *const CIsarTxn,
    write: bool,
) -> u8 {
    isar_try! {
        let new_txn = match isar {
            CIsarInstance::Native(isar) =>{
                let txn = isar.begin_txn(write)?;
                CIsarTxn::Native(txn)
            },
        };
        *txn = Box::into_raw(Box::new(new_txn));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_txn_commit(isar: &'static CIsarInstance, txn: *mut CIsarTxn) -> u8 {
    isar_try! {
        let txn = *Box::from_raw(txn);
        match (isar, txn) {
           (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                isar.commit_txn(txn)?;
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_txn_abort(isar: &'static CIsarInstance, txn: *mut CIsarTxn) {
    let txn = *Box::from_raw(txn);
    match (isar, txn) {
        (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
            isar.abort_txn(txn);
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_largest_id(
    isar: &'static CIsarInstance,
    collection_index: u16,
) -> i64 {
    match isar {
        CIsarInstance::Native(isar) => isar.get_largest_id(collection_index).unwrap(),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_get(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    collection_index: u16,
    id: i64,
    reader: *mut *const CIsarReader,
) -> u8 {
    isar_try! {
        let new_reader = match (isar, txn) {
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                isar.get(txn, collection_index, id)?
            }
        };
        if let Some(new_reader) = new_reader {
            *reader = Box::into_raw(Box::new(CIsarReader::Native(new_reader)));
        } else {
            *reader = ptr::null();
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_insert(
    isar: &'static CIsarInstance,
    txn: *mut CIsarTxn,
    collection_index: u16,
    count: u32,
    insert: *mut *const CIsarWriter,
) -> u8 {
    isar_try! {
        let txn = *Box::from_raw(txn);
        let new_insert = match (isar, txn) {
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                let insert = isar.insert(txn, collection_index, count).unwrap();
                CIsarWriter::Native(insert)
            }
        };
        *insert = Box::into_raw(Box::new(new_insert));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_delete(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    collection_index: u16,
    id: i64,
    deleted: *mut bool,
) -> u8 {
    isar_try! {
        *deleted = match (isar, txn) {
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                isar.delete(txn, collection_index, id)?
            }
        };
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_count(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    collection_index: u16,
    count: *mut u32,
) -> u8 {
    isar_try! {
        let new_count = match (isar,txn) {
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                isar.count(txn, collection_index)?
            }
        };
        *count = new_count;
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_clear(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    collection_index: u16,
) -> u8 {
    isar_try! {
        match (isar,txn) {
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => isar.clear(txn, collection_index)?,
        };
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_size(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    collection_index: u16,
    include_indexes: bool,
) -> i64 {
    match (isar, txn) {
        (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => isar
            .get_size(txn, collection_index, include_indexes)
            .unwrap_or(0) as i64,
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_copy(isar: &'static CIsarInstance, path: *mut String) -> u8 {
    isar_try! {
        let path = *Box::from_raw(path);
        match isar {
            CIsarInstance::Native(isar) => isar.copy(&path)?,
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_close(isar: *mut CIsarInstance, delete: bool) -> bool {
    let isar = *Box::from_raw(isar);
    match isar {
        CIsarInstance::Native(isar) => NativeInstance::close(isar, delete),
    }
}
