use crate::{
    dart_fast_hash, i64_to_isar, isar_to_i64, CIsarCursor, CIsarInstance, CIsarTxn, IsarI64,
};
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

#[no_mangle]
pub unsafe extern "C" fn isar_version() -> *const c_char {
    ISAR_VERSION.as_ptr() as *const c_char
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_instance(instance_id: u32, sqlite: bool) -> *const CIsarInstance {
    if sqlite {
        #[cfg(feature = "sqlite")]
        if let Some(instance) = SQLiteInstance::get_instance(instance_id) {
            return Box::into_raw(Box::new(CIsarInstance::SQLite(instance)));
        }
    } else {
        #[cfg(feature = "native")]
        if let Some(instance) = NativeInstance::get_instance(instance_id) {
            return Box::into_raw(Box::new(CIsarInstance::Native(instance)));
        }
    }
    ptr::null()
}

#[no_mangle]
pub unsafe extern "C" fn isar_open_instance(
    isar: *mut *const CIsarInstance,
    instance_id: u32,
    name: *mut String,
    path: *mut String,
    sqlite: bool,
    schema_json: *mut String,
    max_size_mib: u32,
    encryption_key: *mut String,
    compact_min_file_size: u32,
    compact_min_bytes: u32,
    compact_min_ratio: f32,
) -> u8 {
    isar_try! {
        let name = *Box::from_raw(name);
        let path = *Box::from_raw(path);
        let schema_json = *Box::from_raw(schema_json);
        let schemas = IsarSchema::from_json(schema_json.as_bytes())?;

        let encryption_key = if encryption_key.is_null() {
            None
        } else {
            Some(*Box::from_raw(encryption_key))
        };

        let compact_condition = if compact_min_ratio.is_nan() {
            None
        } else {
            Some(CompactCondition {
                min_file_size: compact_min_file_size,
                min_bytes: compact_min_bytes,
                min_ratio: compact_min_ratio,
            })
        };

        let new_isar = if sqlite {
            #[cfg(feature = "sqlite")]
            {
                let instance = SQLiteInstance::open_instance(
                    instance_id,
                    &name,
                    &path,
                    schemas,
                    max_size_mib,
                    encryption_key.as_deref(),
                    compact_condition,
                )?;
                CIsarInstance::SQLite(instance)
            }
            #[cfg(not(feature = "sqlite"))]
            {
                return Err(IsarError::UnsupportedOperation {});
            }
        } else {
            #[cfg(feature = "native")]
            {
                let instance = NativeInstance::open_instance(
                    instance_id,
                    &name,
                    &path,
                    schemas,
                    max_size_mib,
                    encryption_key.as_deref(),
                    compact_condition,
                )?;
                CIsarInstance::Native(instance)
            }
            #[cfg(not(feature = "native"))]
            {
                return Err(IsarError::UnsupportedOperation {});
            }
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

unsafe fn _isar_txn_begin(
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
pub unsafe extern "C" fn isar_txn_begin(
    isar: &'static CIsarInstance,
    txn: *mut *const CIsarTxn,
    write: bool,
) -> u8 {
    isar_pause_isolate! {
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
}

#[no_mangle]
pub unsafe extern "C" fn isar_txn_commit(isar: &'static CIsarInstance, txn: *mut CIsarTxn) -> u8 {
    isar_pause_isolate! {
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
pub unsafe extern "C" fn isar_auto_increment(
    isar: &'static CIsarInstance,
    collection_index: u16,
) -> IsarI64 {
    let id = match isar {
        #[cfg(feature = "native")]
        CIsarInstance::Native(isar) => isar.auto_increment(collection_index),
        #[cfg(feature = "sqlite")]
        CIsarInstance::SQLite(isar) => isar.auto_increment(collection_index),
    };
    i64_to_isar(id)
}

#[no_mangle]
pub unsafe extern "C" fn isar_cursor(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    collection_index: u16,
    cursor: *mut *const CIsarCursor,
) -> u8 {
    isar_try! {
        let new_cursor = match (isar, txn) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                let cursor = isar.cursor(txn, collection_index)?;
                CIsarCursor::Native(cursor)
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => {
                let cursor = isar.cursor(txn, collection_index)?;
                CIsarCursor::SQLite(cursor)
            }
            _ => return Err(IsarError::IllegalArgument {}),
        };
        *cursor = Box::into_raw(Box::new(new_cursor));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_delete(
    isar: &'static CIsarInstance,
    txn: &'static CIsarTxn,
    collection_index: u16,
    id: IsarI64,
    deleted: *mut bool,
) -> u8 {
    let id = isar_to_i64(id);
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
) -> u32 {
    match (isar, txn) {
        #[cfg(feature = "native")]
        (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => isar
            .get_size(txn, collection_index, include_indexes)
            .unwrap_or(0) as u32,
        #[cfg(feature = "sqlite")]
        (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => isar
            .get_size(txn, collection_index, include_indexes)
            .unwrap_or(0) as u32,
        _ => 0,
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_import_json(
    isar: &'static CIsarInstance,
    txn: *mut *mut CIsarTxn,
    collection_index: u16,
    json: *mut String,
    count: *mut u32,
) -> u8 {
    let json = *Box::from_raw(json);
    let mut deserializer = serde_json::Deserializer::from_str(&json);
    isar_try! {
        let (new_txn, new_count) = match (isar, *Box::from_raw(*txn)) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                let (txn, count) = isar.import_json(txn, collection_index, &mut deserializer, dart_fast_hash)?;
                (CIsarTxn::Native(txn), count)
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => {
                let (txn, count) = isar.import_json(txn, collection_index, &mut deserializer, dart_fast_hash)?;
                (CIsarTxn::SQLite(txn), count)
            }
            _ => return Err(IsarError::IllegalArgument {}),
        };
        *txn = Box::into_raw(Box::new(new_txn));
        *count = new_count;
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_copy(isar: &'static CIsarInstance, path: *mut String) -> u8 {
    isar_pause_isolate! {
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
}

#[no_mangle]
pub unsafe extern "C" fn isar_verify(isar: &'static CIsarInstance, txn: &'static CIsarTxn) -> u8 {
    isar_try! {
        return match (isar, txn) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => isar.verify(txn),
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => isar.verify(txn),
            _ => Err(IsarError::IllegalArgument {}),
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_close(isar: *mut CIsarInstance, delete: bool) -> u8 {
    isar_pause_isolate! {
        let isar = *Box::from_raw(isar);
        let closed = match isar {
            #[cfg(feature = "native")]
            CIsarInstance::Native(isar) => NativeInstance::close(isar, delete),
            #[cfg(feature = "sqlite")]
            CIsarInstance::SQLite(isar) => SQLiteInstance::close(isar, delete),
        };
        if closed {
            1
        } else {
            0
        }
    }
}
