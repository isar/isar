use crate::dart::{dart_post_int, DartPort};
use crate::error::DartErrCode;
use crate::from_c_str;
use crate::txn::run_async;
use crate::txn::CIsarTxn;
use crate::CharsSend;
use isar_core::collection::IsarCollection;
use isar_core::error::{illegal_arg, Result};
use isar_core::instance::{CompactCondition, IsarInstance};
use isar_core::schema::Schema;
use std::ffi::CString;
use std::os::raw::c_char;
use std::sync::Arc;

include!(concat!(env!("OUT_DIR"), "/version.rs"));

struct IsarInstanceSend(*mut *const IsarInstance);

unsafe impl Send for IsarInstanceSend {}

#[no_mangle]
pub unsafe extern "C" fn isar_version() -> *const c_char {
    ISAR_VERSION.as_ptr() as *const c_char
}

#[no_mangle]
pub unsafe extern "C" fn isar_instance_create(
    isar: *mut *const IsarInstance,
    name: *const c_char,
    path: *const c_char,
    schema_json: *const c_char,
    max_size_mib: i64,
    relaxed_durability: bool,
    compact_min_file_size: u32,
    compact_min_bytes: u32,
    compact_min_ratio: f64,
) -> i64 {
    let open = || -> Result<()> {
        let name = from_c_str(name).unwrap().unwrap();
        let path = from_c_str(path).unwrap();
        let schema_json = from_c_str(schema_json).unwrap().unwrap();
        let schema = Schema::from_json(schema_json.as_bytes())?;

        let compact_condition = if compact_min_ratio.is_nan() {
            None
        } else {
            Some(CompactCondition {
                min_file_size: compact_min_file_size as u64,
                min_bytes: compact_min_bytes as u64,
                min_ratio: compact_min_ratio,
            })
        };

        let instance = IsarInstance::open(
            name,
            path,
            schema,
            max_size_mib as usize,
            relaxed_durability,
            compact_condition,
        )?;
        isar.write(Arc::into_raw(instance));
        Ok(())
    };

    open().into_dart_result_code()
}

#[no_mangle]
pub unsafe extern "C" fn isar_instance_create_async(
    isar: *mut *const IsarInstance,
    name: *const c_char,
    path: *const c_char,
    schema_json: *const c_char,
    max_size_mib: i64,
    relaxed_durability: bool,
    compact_min_file_size: u32,
    compact_min_bytes: u32,
    compact_min_ratio: f64,
    port: DartPort,
) {
    let isar = IsarInstanceSend(isar);
    let name = CharsSend(name);
    let path = CharsSend(path);
    let schema_json = CharsSend(schema_json);
    run_async(move || {
        let isar = isar;
        let name = name;
        let path = path;
        let schema_json = schema_json;
        let result = isar_instance_create(
            isar.0,
            name.0,
            path.0,
            schema_json.0,
            max_size_mib,
            relaxed_durability,
            compact_min_file_size,
            compact_min_bytes,
            compact_min_ratio,
        );
        dart_post_int(port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn isar_instance_close(isar: *const IsarInstance) -> bool {
    let isar = Arc::from_raw(isar);
    isar.close()
}

#[no_mangle]
pub unsafe extern "C" fn isar_instance_close_and_delete(isar: *const IsarInstance) -> bool {
    let isar = Arc::from_raw(isar);
    isar.close_and_delete()
}

#[no_mangle]
pub unsafe extern "C" fn isar_instance_get_path(isar: &'static IsarInstance) -> *mut c_char {
    CString::new(isar.dir.as_str()).unwrap().into_raw()
}

#[no_mangle]
pub unsafe extern "C" fn isar_instance_get_collection<'a>(
    isar: &'a IsarInstance,
    collection: *mut &'a IsarCollection,
    collection_id: u64,
) -> i64 {
    isar_try! {
        let new_collection = isar.collections.iter().find(|c| c.id == collection_id);
        if let Some(new_collection) = new_collection {
            collection.write(new_collection);
        } else {
            illegal_arg("Collection id is invalid.")?;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_instance_get_size(
    instance: &'static IsarInstance,
    txn: &mut CIsarTxn,
    include_indexes: bool,
    include_links: bool,
    size: &'static mut i64,
) -> i64 {
    isar_try_txn!(txn, move |txn| {
        *size = instance.get_size(txn, include_indexes, include_links)? as i64;
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_instance_copy_to_file(
    instance: &'static IsarInstance,
    path: *const c_char,
    port: DartPort,
) {
    let path = CharsSend(path);
    run_async(move || {
        let path = path;
        let path = from_c_str(path.0).unwrap().unwrap();
        let result = instance.copy_to_file(path);
        dart_post_int(port, result.into_dart_result_code());
    });
}

#[no_mangle]
pub unsafe extern "C" fn isar_instance_verify(
    instance: &'static IsarInstance,
    txn: &mut CIsarTxn,
) -> i64 {
    isar_try_txn!(txn, move |txn| { instance.verify(txn) })
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_offsets(
    collection: &IsarCollection,
    embedded_col_id: u64,
    offsets: *mut u32,
) -> u32 {
    let properties = if embedded_col_id == 0 {
        &collection.properties
    } else {
        collection.embedded_properties.get(embedded_col_id).unwrap()
    };
    let offsets = std::slice::from_raw_parts_mut(offsets, properties.len());
    for (i, p) in properties.iter().enumerate() {
        offsets[i] = p.offset as u32;
    }
    let property = properties.iter().max_by_key(|p| p.offset);
    property.map_or(2, |p| p.offset + p.data_type.get_static_size()) as u32
}
