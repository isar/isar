use crate::core::error::{IsarError, Result};
use ffi::sqlite3_busy_timeout;
use libsqlite3_sys as ffi;
use std::cell::Cell;
use std::ffi::{c_char, c_int, c_void, CStr, CString};
use std::{ptr, slice};

use super::sql::{sql_fn_filter_json, FN_FILTER_JSON_NAME};

pub(crate) struct SQLite3 {
    db: *mut ffi::sqlite3,
    free_update_hook: Cell<Option<unsafe extern "C" fn(*mut std::os::raw::c_void)>>,
}

unsafe impl Send for SQLite3 {}

impl SQLite3 {
    pub(crate) const MAX_PARAM_COUNT: u32 = 999;

    pub fn open(path: &str, encryption_key: Option<&str>) -> Result<SQLite3> {
        let flags = ffi::SQLITE_OPEN_READWRITE | ffi::SQLITE_OPEN_CREATE | ffi::SQLITE_OPEN_NOMUTEX;
        let c_path = CString::new(path).unwrap();
        let mut db: *mut ffi::sqlite3 = ptr::null_mut();
        unsafe {
            let r = ffi::sqlite3_open_v2(c_path.as_ptr(), &mut db, flags, ptr::null());
            if r == ffi::SQLITE_OK {
                let sqlite = SQLite3 {
                    db,
                    free_update_hook: Cell::new(None),
                };
                if let Some(encryption_key) = encryption_key {
                    sqlite
                        .key(encryption_key)
                        .map_err(|_| IsarError::EncryptionError {})?;
                }
                sqlite.initialize()?;
                Ok(sqlite)
            } else {
                let err = sqlite_err(db, r);
                if !db.is_null() {
                    ffi::sqlite3_close(db);
                }
                Err(err)
            }
        }
    }

    fn key(&self, encryption_key: &str) -> Result<()> {
        let sql = format!("PRAGMA key = \"{}\"", encryption_key);
        self.prepare(&sql)?.step()?;
        self.prepare("SELECT count(*) FROM sqlite_master")?.step()?; // check if key is correct
        Ok(())
    }

    fn initialize(&self) -> Result<()> {
        unsafe {
            sqlite3_busy_timeout(self.db, 5000);
        }
        self.prepare("PRAGMA case_sensitive_like = true")?.step()?;
        self.create_function(FN_FILTER_JSON_NAME, 2, sql_fn_filter_json)?;
        Ok(())
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

    pub fn get_table_names(&self) -> Result<Vec<String>> {
        let mut stmt = self.prepare("PRAGMA table_list")?;
        let mut names = vec![];
        while stmt.step()? {
            let table_type = stmt.get_text(2);
            if table_type == "table" {
                let name = stmt.get_text(1);
                if !name.to_ascii_lowercase().starts_with("sqlite_") {
                    names.push(name.to_string());
                }
            }
        }
        Ok(names)
    }

    pub fn get_table_columns(&self, table_name: &str) -> Result<Vec<(String, String)>> {
        let mut stmt = self.prepare(&format!("PRAGMA table_info({})", table_name))?;
        let mut cols = vec![];
        while stmt.step()? {
            let name = stmt.get_text(1).to_string();
            let type_ = stmt.get_text(2).to_string();
            cols.push((name, type_));
        }
        Ok(cols)
    }

    pub fn get_table_indexes(&self, table_name: &str) -> Result<Vec<(String, bool, Vec<String>)>> {
        let mut stmt = self.prepare(&format!("PRAGMA index_list({})", table_name))?;
        let mut index_names_unique = vec![];
        while stmt.step()? {
            let name = stmt.get_text(1).to_string();
            if !name.to_ascii_lowercase().starts_with("sqlite_") {
                let unique = stmt.get_int(2) == 1;
                index_names_unique.push((name, unique));
            }
        }
        let mut indexes = vec![];
        for (index_name, unique) in index_names_unique {
            let mut stmt = self.prepare(&format!("PRAGMA index_info({})", index_name))?;
            let mut cols = vec![];
            while stmt.step()? {
                cols.push(stmt.get_text(2).to_string());
            }
            indexes.push((index_name, unique, cols));
        }
        Ok(indexes)
    }

    pub fn count_changes(&self) -> i32 {
        unsafe { ffi::sqlite3_changes(self.db) }
    }

    pub fn create_function<F>(&self, name: &str, args: u32, func: F) -> Result<()>
    where
        F: FnMut(&mut SQLiteFnContext<'_>) -> Result<()> + Send + 'static,
    {
        unsafe extern "C" fn call_boxed_closure<F>(
            ctx: *mut ffi::sqlite3_context,
            argc: c_int,
            argv: *mut *mut ffi::sqlite3_value,
        ) where
            F: FnMut(&mut SQLiteFnContext<'_>) -> Result<()>,
        {
            let mut fn_ctx = SQLiteFnContext {
                ctx,
                args: slice::from_raw_parts(argv, argc as usize),
            };
            let boxed_f = ffi::sqlite3_user_data(ctx).cast::<F>();
            let result = (*boxed_f)(&mut fn_ctx);
            if let Err(err) = result {
                let err_str = err.to_string();
                ffi::sqlite3_result_error(
                    ctx,
                    err_str.as_ptr() as *const c_char,
                    err_str.len() as i32,
                );
            }
        }

        let boxed_f = Box::into_raw(Box::new(func));
        let c_name = CString::new(name).unwrap();
        let r = unsafe {
            ffi::sqlite3_create_function_v2(
                self.db,
                c_name.as_ptr(),
                args as i32,
                ffi::SQLITE_UTF8,
                boxed_f.cast(),
                Some(call_boxed_closure::<F>),
                None,
                None,
                Some(free_boxed_value::<F>),
            )
        };

        if r == ffi::SQLITE_OK {
            Ok(())
        } else {
            Err(sqlite_err(self.db, r))
        }
    }

    pub fn set_update_hook<F>(&self, func: F)
    where
        F: FnMut(i64) + 'static,
    {
        unsafe extern "C" fn call_boxed_closure<F>(
            func: *mut c_void,
            _: i32,
            _: *const c_char,
            _: *const c_char,
            id: i64,
        ) where
            F: FnMut(i64) -> (),
        {
            let boxed_f = func.cast::<F>();
            (*boxed_f)(id);
        }

        self.clear_update_hook();
        let boxed_f = Box::into_raw(Box::new(func));
        unsafe { ffi::sqlite3_update_hook(self.db, Some(call_boxed_closure::<F>), boxed_f.cast()) };
        self.free_update_hook.replace(Some(free_boxed_value::<F>));
    }

    pub fn clear_update_hook(&self) {
        let prev = unsafe { ffi::sqlite3_update_hook(self.db, None, ptr::null_mut()) };
        if !prev.is_null() {
            if let Some(free_update_hook) = self.free_update_hook.take() {
                unsafe {
                    free_update_hook(prev);
                }
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

unsafe extern "C" fn free_boxed_value<T>(p: *mut c_void) {
    drop(Box::from_raw(p.cast::<T>()));
}

pub(crate) struct SQLiteFnContext<'a> {
    ctx: *mut ffi::sqlite3_context,
    args: &'a [*mut ffi::sqlite3_value],
}

#[allow(dead_code)]
impl<'a> SQLiteFnContext<'a> {
    pub fn get_int(&self, index: usize) -> i64 {
        unsafe { ffi::sqlite3_value_int64(self.args[index]) }
    }

    pub fn get_double(&self, index: usize) -> f64 {
        unsafe { ffi::sqlite3_value_double(self.args[index]) }
    }

    pub fn get_str(&self, index: usize) -> &'static str {
        unsafe {
            let text = ffi::sqlite3_value_text(self.args[index]);
            let num = ffi::sqlite3_value_bytes(self.args[index]);
            let bytes = std::slice::from_raw_parts(text as *const u8, num as usize);
            std::str::from_utf8_unchecked(bytes)
        }
    }

    pub fn get_blob(&self, index: usize) -> &'static [u8] {
        unsafe {
            let blob = ffi::sqlite3_value_blob(self.args[index]);
            let num = ffi::sqlite3_value_bytes(self.args[index]);
            std::slice::from_raw_parts(blob as *const u8, num as usize)
        }
    }

    pub fn get_object<T>(&self, index: usize, value_type: &'static [u8]) -> Option<&'a Box<T>> {
        let ptr = unsafe {
            ffi::sqlite3_value_pointer(self.args[index], value_type.as_ptr() as *const c_char)
        };
        unsafe { ptr.cast::<Box<T>>().as_ref() }
    }

    pub fn set_int_result(&mut self, value: i64) {
        unsafe {
            ffi::sqlite3_result_int64(self.ctx, value);
        }
    }

    pub fn set_double_result(&mut self, value: f64) {
        unsafe {
            ffi::sqlite3_result_double(self.ctx, value);
        }
    }

    pub fn set_str_result(&mut self, value: &str) {
        unsafe {
            ffi::sqlite3_result_text(
                self.ctx,
                value.as_ptr() as *const c_char,
                value.len() as i32,
                ffi::SQLITE_TRANSIENT(),
            );
        }
    }

    pub fn set_blob_result(&mut self, value: &[u8]) {
        unsafe {
            ffi::sqlite3_result_blob(
                self.ctx,
                value.as_ptr() as *const c_void,
                value.len() as i32,
                ffi::SQLITE_TRANSIENT(),
            );
        }
    }

    pub fn set_object_result<T>(&mut self, value: T, value_type: &'static [u8]) {
        let ptr = Box::into_raw(Box::new(value));
        unsafe {
            ffi::sqlite3_result_pointer(
                self.ctx,
                ptr as *mut c_void,
                value_type.as_ptr() as *const c_char,
                Some(free_boxed_value::<T>),
            );
        }
    }
}

pub(crate) struct SQLiteStatement<'sqlite> {
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

    pub fn reset(&mut self) -> Result<()> {
        unsafe {
            let r = ffi::sqlite3_reset(self.stmt);
            if r == ffi::SQLITE_OK {
                Ok(())
            } else {
                Err(sqlite_err(self.sqlite.db, r))
            }
        }
    }

    pub fn is_null(&self, col: u32) -> bool {
        unsafe { ffi::sqlite3_column_type(self.stmt, col as i32) == ffi::SQLITE_NULL }
    }

    pub fn get_int(&self, col: u32) -> i32 {
        unsafe { ffi::sqlite3_column_int(self.stmt, col as i32) }
    }

    pub fn get_long(&self, col: u32) -> i64 {
        unsafe { ffi::sqlite3_column_int64(self.stmt, col as i32) }
    }

    pub fn get_double(&self, col: u32) -> f64 {
        unsafe { ffi::sqlite3_column_double(self.stmt, col as i32) }
    }

    pub fn get_text(&self, col: u32) -> &str {
        let bytes = self.get_blob(col);
        if bytes.len() > 0 {
            if let Ok(str) = std::str::from_utf8(bytes) {
                return str;
            }
        }
        ""
    }

    pub fn get_blob(&self, col: u32) -> &[u8] {
        unsafe {
            let blob = ffi::sqlite3_column_blob(self.stmt, col as i32);
            let num = ffi::sqlite3_column_bytes(self.stmt, col as i32);
            std::slice::from_raw_parts(blob as *const u8, num as usize)
        }
    }

    pub fn bind_null(&mut self, col: u32) -> Result<()> {
        unsafe {
            let r = ffi::sqlite3_bind_null(self.stmt, col as i32 + 1);
            if r == ffi::SQLITE_OK {
                Ok(())
            } else {
                Err(sqlite_err(self.sqlite.db, r))
            }
        }
    }

    pub fn bind_int(&mut self, col: u32, value: i32) -> Result<()> {
        unsafe {
            let r = ffi::sqlite3_bind_int(self.stmt, col as i32 + 1, value);
            if r == ffi::SQLITE_OK {
                Ok(())
            } else {
                Err(sqlite_err(self.sqlite.db, r))
            }
        }
    }

    pub fn bind_long(&mut self, col: u32, value: i64) -> Result<()> {
        unsafe {
            let r = ffi::sqlite3_bind_int64(self.stmt, col as i32 + 1, value);
            if r == ffi::SQLITE_OK {
                Ok(())
            } else {
                Err(sqlite_err(self.sqlite.db, r))
            }
        }
    }

    pub fn bind_double(&mut self, col: u32, value: f64) -> Result<()> {
        unsafe {
            let r = ffi::sqlite3_bind_double(self.stmt, col as i32 + 1, value);
            if r == ffi::SQLITE_OK {
                Ok(())
            } else {
                Err(sqlite_err(self.sqlite.db, r))
            }
        }
    }

    pub fn bind_text(&mut self, col: u32, value: &str) -> Result<()> {
        unsafe {
            let r = ffi::sqlite3_bind_text(
                self.stmt,
                col as i32 + 1,
                value.as_ptr() as *const c_char,
                value.len() as i32,
                ffi::SQLITE_TRANSIENT(),
            );
            if r == ffi::SQLITE_OK {
                Ok(())
            } else {
                Err(sqlite_err(self.sqlite.db, r))
            }
        }
    }

    pub fn bind_blob(&mut self, col: u32, value: &[u8]) -> Result<()> {
        unsafe {
            let r = ffi::sqlite3_bind_blob(
                self.stmt,
                col as i32 + 1,
                value.as_ptr() as *const c_void,
                value.len() as i32,
                ffi::SQLITE_TRANSIENT(),
            );
            if r == ffi::SQLITE_OK {
                Ok(())
            } else {
                Err(sqlite_err(self.sqlite.db, r))
            }
        }
    }

    pub fn bind_object<T>(&mut self, col: u32, value: T, value_type: &'static [u8]) -> Result<()> {
        let ptr = Box::into_raw(Box::new(value));
        unsafe {
            let r = ffi::sqlite3_bind_pointer(
                self.stmt,
                col as i32 + 1,
                ptr as *mut c_void,
                value_type.as_ptr() as *const c_char,
                Some(free_boxed_value::<T>),
            );
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

pub fn sqlite_err(db: *mut ffi::sqlite3, code: i32) -> IsarError {
    unsafe {
        let c_slice = CStr::from_ptr(ffi::sqlite3_errmsg(db)).to_bytes();
        let msg = String::from_utf8_lossy(c_slice).into_owned();
        IsarError::DbError {
            code: code,
            message: msg,
        }
    }
}

impl<'a> ToOwned for SQLiteStatement<'a> {
    type Owned = SQLiteStatement<'a>;

    fn to_owned(&self) -> Self::Owned {
        panic!("SQLiteStatement can't be cloned")
    }
}
