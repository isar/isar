use super::c_object_set::{CObject, CObjectSet};
use crate::filter::get_property;
use crate::txn::CIsarTxn;
use crate::{from_c_str, UintSend};
use isar_core::collection::IsarCollection;
use isar_core::index::index_key::IndexKey;
use isar_core::query::filter::Filter;
use isar_core::query::query_builder::QueryBuilder;
use isar_core::query::{Query, Sort};
use std::os::raw::c_char;

#[no_mangle]
pub extern "C" fn isar_qb_create(collection: &IsarCollection) -> *mut QueryBuilder {
    let builder = collection.new_query_builder();
    Box::into_raw(Box::new(builder))
}

#[no_mangle]
pub unsafe extern "C" fn isar_qb_add_id_where_clause(
    builder: &mut QueryBuilder,
    start_id: i64,
    end_id: i64,
) -> i64 {
    isar_try! {
        builder.add_id_where_clause(start_id, end_id)?;
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_qb_add_index_where_clause(
    builder: &mut QueryBuilder,
    index_id: u64,
    lower_key: *mut IndexKey,
    upper_key: *mut IndexKey,
    sort_asc: bool,
    skip_duplicates: bool,
) -> i64 {
    let lower_key = *Box::from_raw(lower_key);
    let upper_key = *Box::from_raw(upper_key);
    let sort = if sort_asc {
        Sort::Ascending
    } else {
        Sort::Descending
    };
    isar_try! {
        builder.add_index_where_clause(
            index_id ,
            lower_key,
            upper_key,
            sort,
            skip_duplicates,
        )?;
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_qb_add_link_where_clause(
    builder: &mut QueryBuilder,
    source_collection: &IsarCollection,
    link_id: u64,
    id: i64,
) -> i64 {
    isar_try! {
        builder.add_link_where_clause(source_collection, link_id, id)?;
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_qb_set_filter(builder: &mut QueryBuilder, filter: *mut Filter) {
    let filter = *Box::from_raw(filter);
    builder.set_filter(filter);
}

#[no_mangle]
pub unsafe extern "C" fn isar_qb_add_sort_by(
    builder: &mut QueryBuilder,
    property_id: u64,
    asc: bool,
) -> i64 {
    let sort = if asc {
        Sort::Ascending
    } else {
        Sort::Descending
    };
    isar_try! {
        let property = get_property(builder.collection, 0, property_id)?;
        builder.add_sort(property, sort)?;
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_qb_add_distinct_by(
    builder: &mut QueryBuilder,
    property_id: u64,
    case_sensitive: bool,
) -> i64 {
    isar_try! {
        let property = get_property(builder.collection, 0, property_id)?;
            builder.add_distinct(property, case_sensitive);
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_qb_set_offset_limit(
    builder: &mut QueryBuilder,
    offset: i64,
    limit: i64,
) {
    let offset = if offset < 0 { 0 } else { offset as usize };
    let limit = if limit < 0 {
        usize::MAX
    } else {
        limit as usize
    };
    builder.set_offset(offset);
    builder.set_limit(limit);
}

#[no_mangle]
pub unsafe extern "C" fn isar_qb_build(builder: *mut QueryBuilder) -> *mut Query {
    let query = Box::from_raw(builder).build();
    Box::into_raw(Box::new(query))
}

#[no_mangle]
pub unsafe extern "C" fn isar_q_free(query: *mut Query) {
    let _ = Box::from_raw(query);
}

#[no_mangle]
pub unsafe extern "C" fn isar_q_find(
    query: &'static Query,
    txn: &mut CIsarTxn,
    result: &'static mut CObjectSet,
    limit: u32,
) -> i64 {
    isar_try_txn!(txn, move |txn| {
        let mut objects = vec![];
        let mut count = 0;
        query.find_while(txn, |id, object| {
            let mut raw_obj = CObject::new();
            raw_obj.set_id(id);
            raw_obj.set_object(Some(object));
            objects.push(raw_obj);
            count += 1;
            count < limit
        })?;

        result.fill_from_vec(objects);
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_q_delete(
    query: &'static Query,
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    limit: u32,
    count: &'static mut u32,
) -> i64 {
    let limit = limit as usize;
    let count = UintSend(count);
    isar_try_txn!(txn, move |txn| {
        let mut ids_to_delete = vec![];
        query.find_while(txn, |id, _| {
            ids_to_delete.push(id);
            ids_to_delete.len() <= limit
        })?;
        *count.0 = ids_to_delete.len() as u32;
        for id in ids_to_delete {
            collection.delete(txn, id)?;
        }
        Ok(())
    })
}

struct JsonBytes(*mut *mut u8);
unsafe impl Send for JsonBytes {}

struct JsonLen(*mut u32);
unsafe impl Send for JsonLen {}

#[no_mangle]
pub unsafe extern "C" fn isar_q_export_json(
    query: &'static Query,
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    id_name: *const c_char,
    json_bytes: *mut *mut u8,
    json_length: *mut u32,
) -> i64 {
    let id_name = from_c_str(id_name).unwrap();
    let json = JsonBytes(json_bytes);
    let json_length = JsonLen(json_length);
    isar_try_txn!(txn, move |txn| {
        let json = json;
        let json_length = json_length;
        let exported_json = query.export_json(txn, collection, id_name, true)?;
        let bytes = serde_json::to_vec(&exported_json).unwrap();
        let mut bytes = bytes.into_boxed_slice();
        json_length.0.write(bytes.len() as u32);
        json.0.write(bytes.as_mut_ptr());
        std::mem::forget(bytes);
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_free_json(json_bytes: *mut u8, json_length: u32) {
    Vec::from_raw_parts(json_bytes, json_length as usize, json_length as usize);
}
