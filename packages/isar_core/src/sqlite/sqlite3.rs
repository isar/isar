use crate::core::error::{IsarError, Result};
use libc::c_void;
use libsqlite3_sys as ffi;
use std::ffi::{c_char, c_int, CStr, CString};
use std::ptr;

pub struct SQLite3 {
    db: *mut ffi::sqlite3,
}

unsafe impl Send for SQLite3 {}

impl SQLite3 {
    pub const MAX_PARAM_COUNT: u32 = 999;

    pub fn open(path: &str) -> Result<SQLite3> {
        let flags = ffi::SQLITE_OPEN_READWRITE | ffi::SQLITE_OPEN_CREATE | ffi::SQLITE_OPEN_NOMUTEX;
        let c_path = CString::new(path).unwrap();
        let mut db: *mut ffi::sqlite3 = ptr::null_mut();
        unsafe {
            let r = ffi::sqlite3_open_v2(c_path.as_ptr(), &mut db, flags, ptr::null());
            if r == ffi::SQLITE_OK {
                let sqlite = SQLite3 { db };
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

    fn initialize(&self) -> Result<()> {
        self.execute("PRAGMA case_sensitive_like = true")?;
        Ok(())
    }

    pub fn prepare(&self, sql: &str) -> Result<SQLiteStatement> {
        eprintln!("prepare: {}", sql);
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

    pub fn execute(&self, sql: &str) -> Result<()> {
        self.prepare(sql)?.step()?;
        Ok(())
    }

    pub fn get_table_names(&self) -> Result<Vec<String>> {
        let mut stmt = self.prepare("PRAGMA table_list")?;
        let mut names = vec![];
        while stmt.step()? {
            let table_type = stmt.get_text(2);
            if table_type == "table" {
                let name = stmt.get_text(1);
                if !name.to_lowercase().starts_with("sqlite_") {
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
            if name.to_lowercase().starts_with("sqlite_") {
                let unique = stmt.get_int(2) == 1;
                index_names_unique.push((name, unique));
            }
        }
        let mut indexes = vec![];
        for (index_name, unique) in index_names_unique {
            let mut stmt = self.prepare(&format!("PRAGMA schema.index_xinfo({})", index_name))?;
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

impl<'a> ToOwned for SQLiteStatement<'a> {
    type Owned = SQLiteStatement<'a>;

    fn to_owned(&self) -> Self::Owned {
        panic!("SQLiteStatement can't be cloned")
    }
}
