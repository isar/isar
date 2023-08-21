use crate::{isar_to_i64, CIsarWriter, IsarI64};
use isar_core::core::writer::IsarWriter;
use std::slice;

#[no_mangle]
pub unsafe extern "C" fn isar_write_null(writer: &'static mut CIsarWriter, index: u32) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_null(index),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_null(index),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_null(index),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_null(index),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_null(index),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_null(index),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_bool(
    writer: &'static mut CIsarWriter,
    index: u32,
    value: bool,
) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_bool(index, value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_bool(index, value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_bool(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_bool(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_bool(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_bool(index, value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_byte(writer: &'static mut CIsarWriter, index: u32, value: u8) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_byte(index, value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_byte(index, value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_byte(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_byte(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_byte(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_byte(index, value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_int(writer: &'static mut CIsarWriter, index: u32, value: i32) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_int(index, value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_int(index, value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_int(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_int(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_int(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_int(index, value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_float(
    writer: &'static mut CIsarWriter,
    index: u32,
    value: f32,
) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_float(index, value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_float(index, value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_float(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_float(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_float(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_float(index, value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_long(
    writer: &'static mut CIsarWriter,
    index: u32,
    value: IsarI64,
) {
    let value = isar_to_i64(value);
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_long(index, value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_long(index, value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_long(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_long(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_long(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_long(index, value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_double(
    writer: &'static mut CIsarWriter,
    index: u32,
    value: f64,
) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_double(index, value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_double(index, value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_double(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_double(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_double(index, value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_double(index, value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_string(
    writer: &'static mut CIsarWriter,
    index: u32,
    value: *mut String,
) {
    let value = *Box::from_raw(value);
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_string(index, &value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_string(index, &value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_string(index, &value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_string(index, &value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_string(index, &value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_string(index, &value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_byte_list(
    writer: &'static mut CIsarWriter,
    index: u32,
    value: *const u8,
    length: u32,
) {
    let bytes = slice::from_raw_parts(value, length as usize);
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_byte_list(index, bytes),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_byte_list(index, bytes),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_byte_list(index, bytes),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_byte_list(index, bytes),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_byte_list(index, bytes),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_byte_list(index, bytes),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_object(
    writer: &'static mut CIsarWriter,
    index: u32,
) -> *mut CIsarWriter<'static> {
    let writer = match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => {
            CIsarWriter::NativeObject(writer.begin_object(index).unwrap())
        }
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => {
            CIsarWriter::NativeObject(writer.begin_object(index).unwrap())
        }
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => {
            CIsarWriter::NativeObject(writer.begin_object(index).unwrap())
        }
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => {
            CIsarWriter::SQLiteObject(writer.begin_object(index).unwrap())
        }
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => {
            CIsarWriter::SQLiteObject(writer.begin_object(index).unwrap())
        }
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => {
            CIsarWriter::SQLiteObject(writer.begin_object(index).unwrap())
        }
    };
    Box::into_raw(Box::new(writer))
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_object_end(
    writer: &'static mut CIsarWriter,
    embedded_writer: *mut CIsarWriter<'static>,
) {
    let embedded_writer = *Box::from_raw(embedded_writer);
    match (writer, embedded_writer) {
        #[cfg(feature = "native")]
        (CIsarWriter::Native(writer), CIsarWriter::NativeObject(embedded_writer)) => {
            writer.end_object(embedded_writer)
        }
        #[cfg(feature = "native")]
        (CIsarWriter::NativeObject(writer), CIsarWriter::NativeObject(embedded_writer)) => {
            writer.end_object(embedded_writer)
        }
        #[cfg(feature = "native")]
        (CIsarWriter::NativeList(writer), CIsarWriter::NativeObject(embedded_writer)) => {
            writer.end_object(embedded_writer)
        }
        #[cfg(feature = "sqlite")]
        (CIsarWriter::SQLite(writer), CIsarWriter::SQLiteObject(embedded_writer)) => {
            writer.end_object(embedded_writer)
        }
        #[cfg(feature = "sqlite")]
        (CIsarWriter::SQLiteObject(writer), CIsarWriter::SQLiteObject(embedded_writer)) => {
            writer.end_object(embedded_writer)
        }
        #[cfg(feature = "sqlite")]
        (CIsarWriter::SQLiteList(writer), CIsarWriter::SQLiteObject(embedded_writer)) => {
            writer.end_object(embedded_writer)
        }
        _ => {}
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_list(
    writer: &'static mut CIsarWriter,
    index: u32,
    length: u32,
) -> *mut CIsarWriter<'static> {
    let writer = match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => {
            CIsarWriter::NativeList(writer.begin_list(index, length).unwrap())
        }
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => {
            CIsarWriter::NativeList(writer.begin_list(index, length).unwrap())
        }
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => {
            CIsarWriter::SQLiteList(writer.begin_list(index, length).unwrap())
        }
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => {
            CIsarWriter::SQLiteList(writer.begin_list(index, length).unwrap())
        }
        _ => panic!("Cannot write nested list"),
    };
    Box::into_raw(Box::new(writer))
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_list_end(
    writer: &'static mut CIsarWriter,
    list_writer: *mut CIsarWriter<'static>,
) {
    let list_writer = *Box::from_raw(list_writer);
    match (writer, list_writer) {
        #[cfg(feature = "native")]
        (CIsarWriter::Native(writer), CIsarWriter::NativeList(list_writer)) => {
            writer.end_list(list_writer)
        }
        #[cfg(feature = "native")]
        (CIsarWriter::NativeObject(writer), CIsarWriter::NativeList(list_writer)) => {
            writer.end_list(list_writer)
        }
        #[cfg(feature = "native")]
        (CIsarWriter::NativeList(writer), CIsarWriter::NativeList(list_writer)) => {
            writer.end_list(list_writer)
        }
        #[cfg(feature = "sqlite")]
        (CIsarWriter::SQLite(writer), CIsarWriter::SQLiteList(list_writer)) => {
            writer.end_list(list_writer)
        }
        #[cfg(feature = "sqlite")]
        (CIsarWriter::SQLiteObject(writer), CIsarWriter::SQLiteList(list_writer)) => {
            writer.end_list(list_writer)
        }
        #[cfg(feature = "sqlite")]
        (CIsarWriter::SQLiteList(writer), CIsarWriter::SQLiteList(list_writer)) => {
            writer.end_list(list_writer)
        }
        _ => {}
    }
}
