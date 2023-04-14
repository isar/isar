#![allow(clippy::missing_safety_doc)]

use isar_core::error::{illegal_arg, Result};
use std::ffi::CStr;
use std::ffi::CString;
use std::mem;
use std::os::raw::c_char;
use unicode_segmentation::UnicodeSegmentation;

#[macro_use]
mod error;

pub mod c_object_set;
pub mod crud;
mod dart;
pub mod filter;
pub mod index_key;
pub mod instance;
pub mod link;
pub mod query;
pub mod query_aggregation;
pub mod txn;
pub mod watchers;

pub unsafe fn from_c_str<'a>(str: *const c_char) -> Result<Option<&'a str>> {
    if !str.is_null() {
        match CStr::from_ptr(str).to_str() {
            Ok(str) => Ok(Some(str)),
            Err(_) => illegal_arg("The provided String is not valid."),
        }
    } else {
        Ok(None)
    }
}

pub struct UintSend(&'static mut u32);

unsafe impl Send for UintSend {}

pub struct BoolSend(&'static mut bool);

unsafe impl Send for BoolSend {}

pub struct CharsSend(*const c_char);

unsafe impl Send for CharsSend {}

#[no_mangle]
pub unsafe extern "C" fn isar_find_word_boundaries(
    input_bytes: *const u8,
    length: u32,
    number_words: *mut u32,
) -> *mut u32 {
    let bytes = std::slice::from_raw_parts(input_bytes, length as usize);
    let str = std::str::from_utf8_unchecked(bytes);
    let mut result = vec![];
    for (offset, word) in str.unicode_word_indices() {
        result.push(offset as u32);
        result.push((offset + word.len()) as u32);
    }
    result.shrink_to_fit();
    number_words.write((result.len() / 2) as u32);
    let result_ptr = result.as_mut_ptr();
    mem::forget(result);
    result_ptr
}

#[no_mangle]
pub unsafe extern "C" fn isar_free_word_boundaries(boundaries: *mut u32, word_count: u32) {
    let len = (word_count * 2) as usize;
    Vec::from_raw_parts(boundaries, len, len);
}

#[no_mangle]
pub unsafe extern "C" fn isar_free_string(string: *mut c_char) {
    let _ = CString::from_raw(string);
}
