#![allow(clippy::missing_safety_doc)]
#![feature(local_key_cell_methods)]

use core::slice;
use isar_core::core::cursor::IsarCursor;
use isar_core::core::instance::IsarInstance;
use isar_core::core::reader::IsarReader;
use isar_core::core::value::IsarValue;
use isar_core::core::writer::IsarWriter;
use isar_core::native::native_instance::NativeInstance;

#[macro_use]
mod error;
pub mod cursor;
pub mod filter;
pub mod insert;
pub mod instance;
pub mod query;
pub mod reader;
pub mod value;
pub mod writer;

type NInstance = <NativeInstance as IsarInstance>::Instance;
type NTxn = <NativeInstance as IsarInstance>::Txn;

type NInsert<'a> = <NativeInstance as IsarInstance>::Insert<'a>;
type NObjectWriter<'a> = <NInsert<'a> as IsarWriter<'a>>::ObjectWriter;
type NListWriter<'a> = <NInsert<'a> as IsarWriter<'a>>::ListWriter;

type NCursor<'a> = <NativeInstance as IsarInstance>::Cursor<'a>;
type NReader<'a> = <NCursor<'a> as IsarCursor>::Reader<'a>;
type NListReader<'a> = <NReader<'a> as IsarReader>::ListReader<'a>;

type NQueryBuilder<'a> = <NativeInstance as IsarInstance>::QueryBuilder<'a>;
type NQuery = <NativeInstance as IsarInstance>::Query;

pub enum CIsarInstance {
    Native(NInstance),
}

pub enum CIsarTxn {
    Native(NTxn),
}

pub enum CIsarWriter<'a> {
    Native(NInsert<'a>),
    NativeObject(NObjectWriter<'a>),
    NativeList(NListWriter<'a>),
}

pub enum CIsarReader<'a> {
    Native(NReader<'a>),
    NativeList(NListReader<'a>),
}

pub enum CIsarQueryBuilder<'a> {
    Native(NQueryBuilder<'a>),
}

pub enum CIsarQuery {
    Native(NQuery),
}

pub enum CIsarCursor<'a> {
    Native(NCursor<'a>),
}

#[no_mangle]
pub unsafe extern "C" fn isar_string(chars: *const u16, length: u32) -> *const String {
    let chars = slice::from_raw_parts(chars, length as usize);
    let value = String::from_utf16_lossy(chars);
    Box::into_raw(Box::new(value))
}

#[no_mangle]
pub unsafe extern "C" fn isar_free_reader(reader: *const CIsarReader) {
    if !reader.is_null() {
        drop(Box::from_raw(reader as *mut CIsarReader));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_free_query(query: *mut CIsarQuery) {
    if !query.is_null() {
        drop(Box::from_raw(query));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_free_cursor(cursor: *mut CIsarCursor) {
    if !cursor.is_null() {
        drop(Box::from_raw(cursor));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_free_value(value: *mut IsarValue) {
    if !value.is_null() {
        drop(Box::from_raw(value));
    }
}
