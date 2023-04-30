#![allow(clippy::missing_safety_doc)]

use core::slice;
use isar_core::core::cursor::IsarCursor;
use isar_core::core::error::IsarError;
use isar_core::core::error::Result;
use isar_core::core::instance::IsarInstance;
use isar_core::core::reader::IsarReader;
use isar_core::core::writer::IsarWriter;
use isar_core::native::native_instance::NativeInstance;
use std::ffi::CStr;
use std::os::raw::c_char;

#[macro_use]
mod error;
pub mod cursor;
pub mod filter;
pub mod insert;
pub mod instance;
pub mod query_builder;
pub mod reader;
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

pub enum CIsarInsert<'a> {
    Native(NInsert<'a>),
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

pub(crate) unsafe fn require_from_c_str<'a>(str: *const c_char) -> Result<&'a str> {
    if !str.is_null() {
        match CStr::from_ptr(str).to_str() {
            Ok(str) => Ok(str),
            Err(_) => Err(IsarError::IllegalString {}),
        }
    } else {
        Err(IsarError::IllegalString {})
    }
}

pub(crate) unsafe fn from_utf16<'a>(str: *const u16, length: u32) -> Option<String> {
    if str.is_null() {
        None
    } else {
        let chars = slice::from_raw_parts(str, length as usize);
        let value = String::from_utf16_lossy(chars);
        Some(value)
    }
}
