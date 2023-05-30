use crate::CIsarWriter;
use isar_core::core::writer::IsarWriter;
use std::slice;

#[no_mangle]
pub unsafe extern "C" fn isar_write_null(writer: &'static mut CIsarWriter) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_null(),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_null(),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_null(),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_null(),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_null(),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_null(),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_bool(writer: &'static mut CIsarWriter, value: bool) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_bool(Some(value)),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_bool(Some(value)),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_bool(Some(value)),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_bool(Some(value)),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_bool(Some(value)),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_bool(Some(value)),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_byte(writer: &'static mut CIsarWriter, value: u8) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_byte(value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_byte(value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_byte(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_byte(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_byte(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_byte(value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_int(writer: &'static mut CIsarWriter, value: i32) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_int(value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_int(value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_int(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_int(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_int(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_int(value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_float(writer: &'static mut CIsarWriter, value: f32) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_float(value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_float(value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_float(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_float(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_float(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_float(value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_long(writer: &'static mut CIsarWriter, value: i64) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_long(value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_long(value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_long(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_long(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_long(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_long(value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_double(writer: &'static mut CIsarWriter, value: f64) {
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_double(value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_double(value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_double(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_double(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_double(value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_double(value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_string(writer: &'static mut CIsarWriter, value: *mut String) {
    let value = *Box::from_raw(value);
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_string(&value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_string(&value),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_string(&value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_string(&value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_string(&value),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_string(&value),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_write_byte_list(
    writer: &'static mut CIsarWriter,
    value: *const u8,
    length: u32,
) {
    let bytes = slice::from_raw_parts(value, length as usize);
    match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => writer.write_byte_list(bytes),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => writer.write_byte_list(bytes),
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => writer.write_byte_list(bytes),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => writer.write_byte_list(bytes),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => writer.write_byte_list(bytes),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => writer.write_byte_list(bytes),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_begin_object(
    writer: &'static mut CIsarWriter,
) -> *mut CIsarWriter<'static> {
    let writer = match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => CIsarWriter::NativeObject(writer.begin_object().unwrap()),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => {
            CIsarWriter::NativeObject(writer.begin_object().unwrap())
        }
        #[cfg(feature = "native")]
        CIsarWriter::NativeList(writer) => {
            CIsarWriter::NativeObject(writer.begin_object().unwrap())
        }
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => CIsarWriter::SQLiteObject(writer.begin_object().unwrap()),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => {
            CIsarWriter::SQLiteObject(writer.begin_object().unwrap())
        }
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteList(writer) => {
            CIsarWriter::SQLiteObject(writer.begin_object().unwrap())
        }
    };
    Box::into_raw(Box::new(writer))
}

#[no_mangle]
pub unsafe extern "C" fn isar_end_object(
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
pub unsafe extern "C" fn isar_begin_list(
    writer: &'static mut CIsarWriter,
    length: u32,
) -> *mut CIsarWriter<'static> {
    let writer = match writer {
        #[cfg(feature = "native")]
        CIsarWriter::Native(writer) => CIsarWriter::NativeList(writer.begin_list(length).unwrap()),
        #[cfg(feature = "native")]
        CIsarWriter::NativeObject(writer) => {
            CIsarWriter::NativeList(writer.begin_list(length).unwrap())
        }
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLite(writer) => CIsarWriter::SQLiteList(writer.begin_list(length).unwrap()),
        #[cfg(feature = "sqlite")]
        CIsarWriter::SQLiteObject(writer) => {
            CIsarWriter::SQLiteList(writer.begin_list(length).unwrap())
        }
        _ => panic!("Cannot write nested list"),
    };
    Box::into_raw(Box::new(writer))
}

#[no_mangle]
pub unsafe extern "C" fn isar_end_list(
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
