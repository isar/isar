#![allow(clippy::missing_safety_doc)]
#![feature(local_key_cell_methods)]
#![feature(vec_into_raw_parts)]

use core::slice;
use isar_core::core::cursor::IsarCursor;
use isar_core::core::instance::IsarInstance;
use isar_core::core::reader::IsarReader;
use isar_core::core::value::IsarValue;
use isar_core::core::writer::IsarWriter;

#[cfg(feature = "native")]
use isar_core::native::native_instance::NativeInstance;

#[cfg(feature = "sqlite")]
use isar_core::sqlite::sqlite_instance::SQLiteInstance;

#[macro_use]
mod error;
pub mod cursor;
pub mod dart;
pub mod filter;
pub mod insert;
pub mod instance;
pub mod query;
pub mod reader;
pub mod update;
pub mod value;
pub mod watcher;
pub mod writer;

#[cfg(feature = "native")]
type NInstance = <NativeInstance as IsarInstance>::Instance;
#[cfg(feature = "sqlite")]
type SInstance = <SQLiteInstance as IsarInstance>::Instance;

#[cfg(feature = "native")]
type NTxn = <NativeInstance as IsarInstance>::Txn;
#[cfg(feature = "sqlite")]
type STxn = <SQLiteInstance as IsarInstance>::Txn;

#[cfg(feature = "native")]
type NInsert<'a> = <NativeInstance as IsarInstance>::Insert<'a>;
#[cfg(feature = "sqlite")]
type SInsert<'a> = <SQLiteInstance as IsarInstance>::Insert<'a>;

#[cfg(feature = "native")]
type NObjectWriter<'a> = <NInsert<'a> as IsarWriter<'a>>::ObjectWriter;
#[cfg(feature = "sqlite")]
type SObjectWriter<'a> = <SInsert<'a> as IsarWriter<'a>>::ObjectWriter;

#[cfg(feature = "native")]
type NListWriter<'a> = <NInsert<'a> as IsarWriter<'a>>::ListWriter;
#[cfg(feature = "sqlite")]
type SListWriter<'a> = <SInsert<'a> as IsarWriter<'a>>::ListWriter;

#[cfg(feature = "native")]
type NCursor<'a> = <NativeInstance as IsarInstance>::Cursor<'a>;
#[cfg(feature = "sqlite")]
type SCursor<'a> = <SQLiteInstance as IsarInstance>::Cursor<'a>;

#[cfg(feature = "native")]
type NReader<'a> = <NCursor<'a> as IsarCursor>::Reader<'a>;
#[cfg(feature = "sqlite")]
type SReader<'a> = <SCursor<'a> as IsarCursor>::Reader<'a>;

#[cfg(feature = "sqlite")]
type SObjectReader<'a> = <SReader<'a> as IsarReader>::ObjectReader<'a>;

#[cfg(feature = "native")]
type NListReader<'a> = <NReader<'a> as IsarReader>::ListReader<'a>;
#[cfg(feature = "sqlite")]
type SListReader<'a> = <SReader<'a> as IsarReader>::ListReader<'a>;

#[cfg(feature = "native")]
type NQueryBuilder<'a> = <NativeInstance as IsarInstance>::QueryBuilder<'a>;
#[cfg(feature = "sqlite")]
type SQueryBuilder<'a> = <SQLiteInstance as IsarInstance>::QueryBuilder<'a>;

#[cfg(feature = "native")]
type NQuery = <NativeInstance as IsarInstance>::Query;
#[cfg(feature = "sqlite")]
type SQuery = <SQLiteInstance as IsarInstance>::Query;

#[cfg(feature = "native")]
type NQueryCursor<'a> = <NativeInstance as IsarInstance>::QueryCursor<'a>;
#[cfg(feature = "sqlite")]
type SQueryCursor<'a> = <SQLiteInstance as IsarInstance>::QueryCursor<'a>;

pub enum CIsarInstance {
    #[cfg(feature = "native")]
    Native(NInstance),
    #[cfg(feature = "sqlite")]
    SQLite(SInstance),
}

pub enum CIsarTxn {
    #[cfg(feature = "native")]
    Native(NTxn),
    #[cfg(feature = "sqlite")]
    SQLite(STxn),
}

pub enum CIsarCursor<'a> {
    #[cfg(feature = "native")]
    Native(NCursor<'a>),
    #[cfg(feature = "sqlite")]
    SQLite(SCursor<'a>),
}

pub enum CIsarWriter<'a> {
    #[cfg(feature = "native")]
    Native(NInsert<'a>),
    #[cfg(feature = "native")]
    NativeObject(NObjectWriter<'a>),
    #[cfg(feature = "native")]
    NativeList(NListWriter<'a>),
    #[cfg(feature = "sqlite")]
    SQLite(SInsert<'a>),
    #[cfg(feature = "sqlite")]
    SQLiteObject(SObjectWriter<'a>),
    #[cfg(feature = "sqlite")]
    SQLiteList(SListWriter<'a>),
}

pub enum CIsarReader<'a> {
    #[cfg(feature = "native")]
    Native(NReader<'a>),
    #[cfg(feature = "native")]
    NativeList(NListReader<'a>),
    #[cfg(feature = "sqlite")]
    SQLite(SReader<'a>),
    #[cfg(feature = "sqlite")]
    SQLiteObject(SObjectReader<'a>),
    #[cfg(feature = "sqlite")]
    SQLiteList(SListReader<'a>),
}

pub struct CIsarUpdate(pub(crate) Vec<(u16, Option<IsarValue>)>);

pub enum CIsarQueryBuilder<'a> {
    #[cfg(feature = "native")]
    Native(NQueryBuilder<'a>),
    #[cfg(feature = "sqlite")]
    SQLite(SQueryBuilder<'a>),
}

pub enum CIsarQuery {
    #[cfg(feature = "native")]
    Native(NQuery),
    #[cfg(feature = "sqlite")]
    SQLite(SQuery),
}

pub enum CIsarQueryCursor<'a> {
    #[cfg(feature = "native")]
    Native(NQueryCursor<'a>),
    #[cfg(feature = "sqlite")]
    SQLite(SQueryCursor<'a>),
}

#[no_mangle]
pub unsafe extern "C" fn isar_string(chars: *const u16, length: u32) -> *const String {
    let chars = slice::from_raw_parts(chars, length as usize);
    let value = String::from_utf16_lossy(chars);
    Box::into_raw(Box::new(value))
}

#[no_mangle]
pub unsafe extern "C" fn isar_buffer_free(value: *mut u8, capacity: u32) {
    if !value.is_null() {
        drop(Vec::from_raw_parts(value, 0, capacity as usize));
    }
}

fn dart_fast_hash(value: &str) -> i64 {
    let mut hash = 0xcbf29ce484222325;

    let utf16 = value.encode_utf16();
    for char in utf16 {
        hash ^= (char >> 8) as u64;
        hash = hash.wrapping_mul(0x100000001b3);
        hash ^= (char & 0xFF) as u64;
        hash = hash.wrapping_mul(0x100000001b3);
    }

    hash as i64
}

#[cfg(not(target_arch = "wasm32"))]
type IsarI64 = i64;

#[cfg(not(target_arch = "wasm32"))]
#[inline]
pub(crate) fn i64_to_isar(value: i64) -> IsarI64 {
    value
}

#[cfg(not(target_arch = "wasm32"))]
#[inline]
pub(crate) fn isar_to_i64(value: IsarI64) -> i64 {
    value
}

#[cfg(target_arch = "wasm32")]
type IsarI64 = f64;

#[cfg(target_arch = "wasm32")]
#[inline]
pub(crate) fn i64_to_isar(value: i64) -> IsarI64 {
    value as f64
}

#[cfg(target_arch = "wasm32")]
#[inline]
pub(crate) fn isar_to_i64(value: IsarI64) -> i64 {
    if value.is_finite() {
        value as i64
    } else {
        i64::MIN
    }
}
