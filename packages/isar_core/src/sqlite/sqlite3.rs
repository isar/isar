use crate::core::error::{IsarError, Result};
use libsqlite3_sys as ffi;
use std::{
    ffi::{c_char, c_int, CStr, CString},
    ptr,
};

pub struct SQLite3 {
    db: *mut ffi::sqlite3,
}

unsafe impl Send for SQLite3 {}

impl SQLite3 {
    pub fn open(path: &str) -> Result<SQLite3> {
        let flags = ffi::SQLITE_OPEN_READWRITE | ffi::SQLITE_OPEN_CREATE | ffi::SQLITE_OPEN_NOMUTEX;
        let c_path = CString::new(path).unwrap();
        let mut db: *mut ffi::sqlite3 = ptr::null_mut();
        unsafe {
            let r = ffi::sqlite3_open_v2(c_path.as_ptr(), &mut db, flags, ptr::null());
            if r == ffi::SQLITE_OK {
                Ok(SQLite3 { db })
            } else {
                let err = sqlite_err(db, r);
                if !db.is_null() {
                    ffi::sqlite3_close(db);
                }
                Err(err)
            }
        }
    }

    pub fn prepare(&self, sql: &str) -> Result<SQLiteStatement> {
        let mut stmt: *mut ffi::sqlite3_stmt = ptr::null_mut();
        let mut c_tail = ptr::null();
        unsafe {
            let r = ffi::sqlite3_prepare_v2(
                self.db,
                sql.as_ptr() as *const c_char,
                sql.len() as c_int,
                &mut stmt,
                &mut c_tail as *mut *const c_char,
            );
            if r == ffi::SQLITE_OK {
                Ok(SQLiteStatement { stmt, sqlite: self })
            } else {
                Err(sqlite_err(self.db, r))
            }
        }
    }
}

impl Drop for SQLite3 {
    fn drop(&mut self) {
        unsafe {
            ffi::sqlite3_close(self.db);
        }
    }
}

pub struct SQLiteStatement<'sqlite> {
    stmt: *mut ffi::sqlite3_stmt,
    sqlite: &'sqlite SQLite3,
}

impl<'sqlite> SQLiteStatement<'sqlite> {
    pub fn step(&mut self) -> Result<bool> {
        unsafe {
            let r = ffi::sqlite3_step(self.stmt);
            if r == ffi::SQLITE_ROW {
                Ok(true)
            } else if r == ffi::SQLITE_DONE {
                Ok(false)
            } else {
                Err(sqlite_err(self.sqlite.db, r))
            }
        }
    }

    pub fn is_null(&self, col: usize) -> bool {
        unsafe { ffi::sqlite3_column_type(self.stmt, col as i32) == ffi::SQLITE_NULL }
    }

    pub fn get_int(&self, col: usize) -> i32 {
        unsafe { ffi::sqlite3_column_int(self.stmt, col as i32) }
    }

    pub fn get_long(&self, col: usize) -> i64 {
        unsafe { ffi::sqlite3_column_int64(self.stmt, col as i32) }
    }

    pub fn get_double(&self, col: usize) -> f64 {
        unsafe { ffi::sqlite3_column_double(self.stmt, col as i32) }
    }

    pub fn bind_null(&mut self, col: usize) -> Result<()> {
        unsafe {
            let r = ffi::sqlite3_bind_null(self.stmt, col as i32 + 1);
            if r == ffi::SQLITE_OK {
                Ok(())
            } else {
                Err(sqlite_err(self.sqlite.db, r))
            }
        }
    }

    pub fn bind_int(&mut self, col: usize, value: i32) -> Result<()> {
        unsafe {
            let r = ffi::sqlite3_bind_int(self.stmt, col as i32 + 1, value);
            if r == ffi::SQLITE_OK {
                Ok(())
            } else {
                Err(sqlite_err(self.sqlite.db, r))
            }
        }
    }

    pub fn bind_long(&mut self, col: usize, value: i64) -> Result<()> {
        unsafe {
            let r = ffi::sqlite3_bind_int64(self.stmt, col as i32 + 1, value);
            if r == ffi::SQLITE_OK {
                Ok(())
            } else {
                Err(sqlite_err(self.sqlite.db, r))
            }
        }
    }

    pub fn bind_double(&mut self, col: usize, value: f64) -> Result<()> {
        unsafe {
            let r = ffi::sqlite3_bind_double(self.stmt, col as i32 + 1, value);
            if r == ffi::SQLITE_OK {
                Ok(())
            } else {
                Err(sqlite_err(self.sqlite.db, r))
            }
        }
    }
}

impl Drop for SQLiteStatement<'_> {
    fn drop(&mut self) {
        unsafe {
            ffi::sqlite3_finalize(self.stmt);
        }
    }
}

pub unsafe fn sqlite_err(db: *mut ffi::sqlite3, code: i32) -> IsarError {
    let err_ptr = if db.is_null() {
        ffi::sqlite3_errstr(code)
    } else {
        ffi::sqlite3_errmsg(db)
    };
    let c_slice = CStr::from_ptr(err_ptr).to_bytes();
    let msg = String::from_utf8_lossy(c_slice).into_owned();
    IsarError::DbError {
        code: code,
        message: msg,
    }
}
