use isar_core::core::{error::IsarError, instance::IsarInstance, watcher::WatchHandle};

use crate::dart::{dart_post_int, DartPort};
use crate::{CIsarInstance, CIsarQuery};

#[no_mangle]
pub unsafe extern "C" fn isar_watch_collection(
    isar: &'static CIsarInstance,
    collection_index: u16,
    port: DartPort,
    handle: *mut *mut WatchHandle,
) -> u8 {
    let callback = Box::new(move || {
        dart_post_int(port, 1);
    });
    isar_try! {
        let new_handle = match isar {
            #[cfg(feature = "native")]
            CIsarInstance::Native(isar) => isar.watch(collection_index, callback)?,
            #[cfg(feature = "sqlite")]
            CIsarInstance::SQLite(isar) => isar.watch(collection_index, callback)?,
        };
        *handle = Box::into_raw(Box::new(new_handle));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_watch_object(
    isar: &'static CIsarInstance,
    collection_index: u16,
    id: i64,
    port: DartPort,
    handle: *mut *mut WatchHandle,
) -> u8 {
    let callback = Box::new(move || {
        dart_post_int(port, 1);
    });
    isar_try! {
        let new_handle = match isar {
            #[cfg(feature = "native")]
            CIsarInstance::Native(isar) => isar.watch_object(collection_index, id, callback)?,
            #[cfg(feature = "sqlite")]
            CIsarInstance::SQLite(isar) => isar.watch_object(collection_index, id, callback)?,
        };
        *handle = Box::into_raw(Box::new(new_handle));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_watch_query(
    isar: &'static CIsarInstance,
    query: &CIsarQuery,
    port: DartPort,
    handle: *mut *mut WatchHandle,
) -> u8 {
    let callback = Box::new(move || {
        dart_post_int(port, 1);
    });
    isar_try! {
        let new_handle = match (isar, query) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarQuery::Native(query)) => {
                isar.watch_query(query, callback)?
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarQuery::SQLite(query)) => {
                isar.watch_query(query, callback)?
            }
            _ => return Err(IsarError::IllegalArgument {}),
        };
        *handle = Box::into_raw(Box::new(new_handle));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_stop_watching(handle: *mut WatchHandle) {
    Box::from_raw(handle).stop();
}
