use isar_core::collection::IsarCollection;
use isar_core::instance::IsarInstance;
use isar_core::query::Query;
use isar_core::watch::WatchHandle;
use crate::dart::{dart_post_int, DartPort};

#[no_mangle]
pub extern "C" fn isar_watch_collection(
    isar: &IsarInstance,
    collection: &IsarCollection,
    port: DartPort,
) -> *mut WatchHandle {
    let handle = isar.watch_collection(
        collection,
        Box::new(move ||  {
            dart_post_int(port, 1);
        }),
    );
    Box::into_raw(Box::new(handle))
}

#[no_mangle]
pub unsafe extern "C" fn isar_watch_object(
    isar: &IsarInstance,
    collection: &IsarCollection,
    id: i64,
    port: DartPort,
) -> *mut WatchHandle {
    let handle = isar.watch_object(
        collection,
        id,
        Box::new(move || {
            dart_post_int(port, 1);
        }),
    );
    Box::into_raw(Box::new(handle))
}

#[no_mangle]
pub extern "C" fn isar_watch_query(
    isar: &IsarInstance,
    collection: &IsarCollection,
    query: &Query,
    port: DartPort,
) -> *mut WatchHandle {
    let handle = isar.watch_query(
        collection,
        query.clone(),
        Box::new(move ||  {
            dart_post_int(port, 1);
        }),
    );
    Box::into_raw(Box::new(handle))
}

#[no_mangle]
pub unsafe extern "C" fn isar_stop_watching(handle: *mut WatchHandle) {
    Box::from_raw(handle).stop();
}
