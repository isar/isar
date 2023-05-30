use crate::{CIsarInstance, CIsarReader, CIsarTxn, CIsarWriter};
use isar_core::core::error::IsarError;
use isar_core::core::instance::{CompactCondition, IsarInstance};
use isar_core::core::schema::IsarSchema;
use std::os::raw::c_char;
use std::ptr;

#[cfg(feature = "native")]
use isar_core::native::native_instance::NativeInstance;

#[cfg(feature = "sqlite")]
use isar_core::sqlite::sqlite_instance::SQLiteInstance;

include!(concat!(env!("OUT_DIR"), "/version.rs"));

#[repr(u8)]
pub enum StorageEngine {
    Isar = 0,
    SQLite = 1,
    SQLCipher = 2,
}

#[no_mangle]
pub unsafe extern "C" fn isar_version() -> *const c_char {
    ISAR_VERSION.as_ptr() as *const c_char
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_instance(
    instance_id: u32,
    engine: StorageEngine,
) -> *const CIsarInstance {
    match engine {
        StorageEngine::Isar =>
        {
            #[cfg(feature = "native")]
            if let Some(instance) = NativeInstance::get_instance(instance_id) {
                return Box::into_raw(Box::new(CIsarInstance::Native(instance)));
            }
        }
        StorageEngine::SQLite =>
        {
            #[cfg(feature = "sqlite")]
            if let Some(instance) = SQLiteInstance::get_instance(instance_id) {
                return Box::into_raw(Box::new(CIsarInstance::SQLite(instance)));
            }
        }
        StorageEngine::SQLCipher => todo!(),
    }
    ptr::null()
}

#[no_mangle]
pub unsafe extern "C" fn isar_open_instance(
    isar: *mut *const CIsarInstance,
    instance_id: u32,
    name: *mut String,
    path: *mut String,
    engine: StorageEngine,
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
                min_file_size: compact_min_file_size,
                min_bytes: compact_min_bytes,
                min_ratio: compact_min_ratio,
            })
        };

        let new_isar = match engine {
            StorageEngine::Isar => {
                #[cfg(feature = "native")]
                {
                    let instance = NativeInstance::open_instance(
                        instance_id,
                        &name,
                        &path,
                        schema,
                        max_size_mib,
                        compact_condition,
                    )?;
                    CIsarInstance::Native(instance)
                }
                #[cfg(not(feature = "native"))]
                return Err(IsarError::UnsupportedOperation {});
            }
            StorageEngine::SQLite => {
                #[cfg(feature = "sqlite")]
                {
                    let instance = SQLiteInstance::open_instance(
                        instance_id,
                        &name,
                        &path,
                        schema,
                        max_size_mib,
                        compact_condition,
                    )?;
                    CIsarInstance::SQLite(instance)
                }
                #[cfg(not(feature = "sqlite"))]
                return Err(IsarError::UnsupportedOperation {});
            }
            StorageEngine::SQLCipher => todo!(),
        };
        *isar = Box::into_raw(Box::new(new_isar));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_name(isar: &'static CIsarInstance, name: *mut *const u8) -> u32 {
    let value = match isar {
        #[cfg(feature = "native")]
        CIsarInstance::Native(isar) => isar.get_name(),
        #[cfg(feature = "sqlite")]
        CIsarInstance::SQLite(isar) => isar.get_name(),
    };
    *name = value.as_ptr();
    value.len() as u32
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_dir(isar: &'static CIsarInstance, dir: *mut *const u8) -> u32 {
    let value = match isar {
        #[cfg(feature = "native")]
        CIsarInstance::Native(isar) => isar.get_dir(),
        #[cfg(feature = "sqlite")]
        CIsarInstance::SQLite(isar) => isar.get_dir(),
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
            #[cfg(feature = "native")]
            CIsarInstance::Native(isar) => CIsarTxn::Native(isar.begin_txn(write)?),
            #[cfg(feature = "sqlite")]
            CIsarInstance::SQLite(isar) => CIsarTxn::SQLite(isar.begin_txn(write)?),
        };
        *txn = Box::into_raw(Box::new(new_txn));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_txn_commit(isar: &'static CIsarInstance, txn: *mut CIsarTxn) -> u8 {
    isar_try! {
        let txn = *Box::from_raw(txn);
        match (isar, txn) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => isar.commit_txn(txn)?,
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => isar.commit_txn(txn)?,
            _ => return Err(IsarError::IllegalArgument {}),
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_txn_abort(isar: &'static CIsarInstance, txn: *mut CIsarTxn) {
    let txn = *Box::from_raw(txn);
    match (isar, txn) {
        #[cfg(feature = "native")]
        (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
            isar.abort_txn(txn);
        }
        #[cfg(feature = "sqlite")]
        (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => {
            isar.abort_txn(txn);
        }
        _ => {}
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
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => isar
                .get(txn, collection_index, id)?
                .map(|r| CIsarReader::Native(r)),
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => isar
                .get(txn, collection_index, id)?
                .map(|r| CIsarReader::SQLite(r)),
            _ => return Err(IsarError::IllegalArgument {}),
        };
        if let Some(new_reader) = new_reader {
            *reader = Box::into_raw(Box::new(new_reader));
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
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                let insert = isar.insert(txn, collection_index, count)?;
                CIsarWriter::Native(insert)
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => {
                let insert = isar.insert(txn, collection_index, count)?;
                CIsarWriter::SQLite(insert)
            }
            _ => return Err(IsarError::IllegalArgument {}),
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
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                isar.delete(txn, collection_index, id)?
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => {
                isar.delete(txn, collection_index, id)?
            }
            _ => return Err(IsarError::IllegalArgument {}),
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
        let new_count = match (isar, txn) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                isar.count(txn, collection_index)?
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => {
                isar.count(txn, collection_index)?
            }
            _ => return Err(IsarError::IllegalArgument {}),
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
        match (isar, txn) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                isar.clear(txn, collection_index)?
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => {
                isar.clear(txn, collection_index)?
            }
            _ => return Err(IsarError::IllegalArgument {}),
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
        #[cfg(feature = "native")]
        (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => isar
            .get_size(txn, collection_index, include_indexes)
            .unwrap_or(0) as i64,
        #[cfg(feature = "sqlite")]
        (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => isar
            .get_size(txn, collection_index, include_indexes)
            .unwrap_or(0) as i64,
        _ => 0,
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_copy(isar: &'static CIsarInstance, path: *mut String) -> u8 {
    isar_try! {
        let path = *Box::from_raw(path);
        match isar {
            #[cfg(feature = "native")]
            CIsarInstance::Native(isar) => isar.copy(&path)?,
            #[cfg(feature = "sqlite")]
            CIsarInstance::SQLite(isar) => isar.copy(&path)?,
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_close(isar: *mut CIsarInstance, delete: bool) -> bool {
    let isar = *Box::from_raw(isar);
    match isar {
        #[cfg(feature = "native")]
        CIsarInstance::Native(isar) => NativeInstance::close(isar, delete),
        #[cfg(feature = "sqlite")]
        CIsarInstance::SQLite(isar) => SQLiteInstance::close(isar, delete),
    }
}
