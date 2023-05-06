use isar_core::core::error::Result;
use itertools::Itertools;
use once_cell::sync::Lazy;
use std::sync::Mutex;
use std::{mem, ptr};

type ErrCounter = (Vec<(u8, String)>, u8);
static ERRORS: Lazy<Mutex<ErrCounter>> = Lazy::new(|| Mutex::new((vec![], 1)));

pub trait DartErrCode {
    fn into_dart_result_code(self) -> u8;
}

impl DartErrCode for Result<()> {
    fn into_dart_result_code(self) -> u8 {
        if let Err(err) = self {
            let mut lock = ERRORS.lock().unwrap();
            let (errors, counter) = &mut (*lock);
            if errors.len() > 10 {
                errors.remove(0);
            }
            let err_code = *counter;
            errors.push((err_code, err.to_string()));
            *counter = counter.wrapping_add(1);
            if *counter == 0 {
                *counter = 1
            }
            err_code
        } else {
            0
        }
    }
}

#[macro_export]
macro_rules! isar_try {
    { $($token:tt)* } => {{
        use crate::error::DartErrCode;
        #[allow(unused_mut)] {
            let mut l = || -> isar_core::core::error::Result<()> {
                {$($token)*}
                Ok(())
            };
            l().into_dart_result_code()
        }
    }}
}

#[macro_export]
macro_rules! isar_try_txn {
    { $txn:expr, $closure:expr } => {
        isar_try! {
            $txn.exec(Box::new($closure))?;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_get_error(err_code: u8, value: *mut *const u16) -> u32 {
    let lock = ERRORS.lock().unwrap();
    let error = lock.0.iter().find(|(code, _)| *code == err_code);
    if let Some((_, err_msg)) = error {
        let mut encoded = err_msg.encode_utf16().collect_vec();
        encoded.shrink_to_fit();
        *value = encoded.as_ptr();
        let len = encoded.len();
        mem::forget(encoded);
        len as u32
    } else {
        *value = ptr::null();
        0
    }
}
