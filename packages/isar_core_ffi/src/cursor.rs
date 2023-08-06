use crate::{isar_to_i64, CIsarCursor, CIsarQueryCursor, CIsarReader, IsarI64};
use isar_core::core::cursor::{IsarCursor, IsarQueryCursor};
use std::ptr;

#[no_mangle]
pub unsafe extern "C" fn isar_cursor_next(
    cursor: &'static mut CIsarCursor,
    id: IsarI64,
    old_reader: *mut CIsarReader,
) -> *const CIsarReader<'static> {
    let id = isar_to_i64(id);

    if !old_reader.is_null() {
        drop(Box::from_raw(old_reader));
    }

    let reader = match cursor {
        #[cfg(feature = "native")]
        CIsarCursor::Native(cursor) => cursor.next(id).map(|reader| CIsarReader::Native(reader)),
        #[cfg(feature = "sqlite")]
        CIsarCursor::SQLite(cursor) => cursor.next(id).map(|reader| CIsarReader::SQLite(reader)),
    };
    if let Some(reader) = reader {
        Box::into_raw(Box::new(reader))
    } else {
        ptr::null()
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_cursor_free(cursor: *mut CIsarCursor, reader: *mut CIsarReader) {
    if !cursor.is_null() {
        drop(Box::from_raw(cursor));
    }
    if !reader.is_null() {
        drop(Box::from_raw(reader));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_cursor_next(
    cursor: &'static mut CIsarQueryCursor,
    old_reader: *mut CIsarReader,
) -> *const CIsarReader<'static> {
    if !old_reader.is_null() {
        drop(Box::from_raw(old_reader));
    }

    let reader = match cursor {
        #[cfg(feature = "native")]
        CIsarQueryCursor::Native(cursor) => cursor.next().map(|reader| CIsarReader::Native(reader)),
        #[cfg(feature = "sqlite")]
        CIsarQueryCursor::SQLite(cursor) => cursor.next().map(|reader| CIsarReader::SQLite(reader)),
    };
    if let Some(reader) = reader {
        Box::into_raw(Box::new(reader))
    } else {
        ptr::null()
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_cursor_free(
    cursor: *mut CIsarQueryCursor,
    reader: *mut CIsarReader,
) {
    if !cursor.is_null() {
        drop(Box::from_raw(cursor));
    }
    if !reader.is_null() {
        drop(Box::from_raw(reader));
    }
}
