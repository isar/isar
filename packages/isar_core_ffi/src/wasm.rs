use libsqlite3_sys::{
    SQLITE_IOERR, sqlite3_file, sqlite3_int64, sqlite3_io_methods, sqlite3_vfs,
    sqlite3_vfs_register,
};
use std::ffi::{c_char, c_int, c_void};
use std::ptr::null_mut;
use wasm_bindgen::prelude::*;

#[wasm_bindgen(js_namespace = ["vfs"])]
extern "C" {
    #[wasm_bindgen(js_name = "xOpen")]
    pub fn x_open(
        p_vfs: *mut sqlite3_vfs,
        z_name: *const c_char,
        file: *const sqlite3_file,
        flags: c_int,
        p_out_flags: *mut c_int,
    ) -> c_int;

    #[wasm_bindgen(js_name = "xDelete")]
    pub fn x_delete(p_vfs: *mut sqlite3_vfs, z_name: *const c_char, sync_dir: c_int) -> c_int;

    #[wasm_bindgen(js_name = "xAccess")]
    pub fn x_access(
        p_vfs: *mut sqlite3_vfs,
        z_name: *const c_char,
        flags: c_int,
        p_res_out: *mut c_int,
    ) -> c_int;

    #[wasm_bindgen(js_name = "xFullPathname")]
    pub fn x_full_pathname(
        p_vfs: *mut sqlite3_vfs,
        z_name: *const c_char,
        n_out: c_int,
        z_out: *mut c_char,
    ) -> c_int;

    #[wasm_bindgen(js_name = "xGetLastError")]
    pub fn x_get_last_error(p_vfs: *mut sqlite3_vfs, n_buf: c_int, z_buf: *mut c_char) -> c_int;

    #[wasm_bindgen(js_name = "xClose")]
    pub fn x_close(p_file: *mut sqlite3_file) -> c_int;

    #[wasm_bindgen(js_name = "xRead")]
    pub fn x_read(
        p_file: *mut sqlite3_file,
        p_data: *mut c_void,
        i_amt: c_int,
        i_offset_lo: c_int,
        i_offset_hi: c_int,
    ) -> c_int;

    #[wasm_bindgen(js_name = "xWrite")]
    pub fn x_write(
        p_file: *mut sqlite3_file,
        p_data: *const c_void,
        i_amt: c_int,
        i_offset_lo: c_int,
        i_offset_hi: c_int,
    ) -> c_int;

    #[wasm_bindgen(js_name = "xTruncate")]
    pub fn x_truncate(p_file: *mut sqlite3_file, size_lo: c_int, size_hi: c_int) -> c_int;

    #[wasm_bindgen(js_name = "xSync")]
    pub fn x_sync(p_file: *mut sqlite3_file, flags: c_int) -> c_int;

    #[wasm_bindgen(js_name = "xFileSize")]
    pub fn x_file_size(p_file: *mut sqlite3_file, p_size: *mut sqlite3_int64) -> c_int;

    #[wasm_bindgen(js_name = "xLock")]
    pub fn x_lock(p_file: *mut sqlite3_file, flags: c_int) -> c_int;

    #[wasm_bindgen(js_name = "xUnlock")]
    pub fn x_unlock(p_file: *mut sqlite3_file, flags: c_int) -> c_int;

    #[wasm_bindgen(js_name = "xCheckReservedLock")]
    pub fn x_check_reserved_lock(p_file: *mut sqlite3_file, p_res_out: *mut c_int) -> c_int;

    #[wasm_bindgen(js_name = "xFileControl")]
    pub fn x_file_control(p_file: *mut sqlite3_file, op: c_int, p_arg: *mut c_void) -> c_int;

    #[wasm_bindgen(js_name = "xSectorSize")]
    pub fn x_sector_size(p_file: *mut sqlite3_file) -> c_int;

    #[wasm_bindgen(js_name = "xDeviceCharacteristics")]
    pub fn x_device_characteristics(p_file: *mut sqlite3_file) -> c_int;

}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_open(
    p_vfs: *mut sqlite3_vfs,
    z_name: *const c_char,
    file: *mut sqlite3_file,
    flags: c_int,
    p_out_flags: *mut c_int,
) -> c_int {
    let io_methods = (*p_vfs).pAppData as *mut sqlite3_io_methods;
    (*file).pMethods = io_methods;
    x_open(p_vfs, z_name, file, flags, p_out_flags)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_delete(
    p_vfs: *mut sqlite3_vfs,
    z_name: *const c_char,
    sync_dir: c_int,
) -> c_int {
    x_delete(p_vfs, z_name, sync_dir)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_access(
    p_vfs: *mut sqlite3_vfs,
    z_name: *const c_char,
    flags: c_int,
    p_res_out: *mut c_int,
) -> c_int {
    x_access(p_vfs, z_name, flags, p_res_out)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_full_pathname(
    p_vfs: *mut sqlite3_vfs,
    z_name: *const c_char,
    n_out: c_int,
    z_out: *mut c_char,
) -> c_int {
    x_full_pathname(p_vfs, z_name, n_out, z_out)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_get_last_error(
    p_vfs: *mut sqlite3_vfs,
    n_buf: c_int,
    z_buf: *mut c_char,
) -> c_int {
    x_get_last_error(p_vfs, n_buf, z_buf)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_close(p_file: *mut sqlite3_file) -> c_int {
    x_close(p_file)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_read(
    p_file: *mut sqlite3_file,
    p_data: *mut c_void,
    i_amt: c_int,
    i_offset: sqlite3_int64,
) -> c_int {
    let offset_lo = i_offset as c_int;
    let offset_hi = (i_offset >> 32) as c_int;
    x_read(p_file, p_data, i_amt, offset_lo, offset_hi)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_write(
    p_file: *mut sqlite3_file,
    p_data: *const c_void,
    i_amt: c_int,
    i_offset: sqlite3_int64,
) -> c_int {
    let offset_lo = i_offset as c_int;
    let offset_hi = (i_offset >> 32) as c_int;
    x_write(p_file, p_data, i_amt, offset_lo, offset_hi)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_truncate(
    p_file: *mut sqlite3_file,
    size: sqlite3_int64,
) -> c_int {
    let size_lo = size as c_int;
    let size_hi = (size >> 32) as c_int;
    x_truncate(p_file, size_lo, size_hi)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_sync(p_file: *mut sqlite3_file, flags: c_int) -> c_int {
    x_sync(p_file, flags)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_file_size(
    p_file: *mut sqlite3_file,
    p_size: *mut sqlite3_int64,
) -> c_int {
    x_file_size(p_file, p_size)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_lock(p_file: *mut sqlite3_file, flags: c_int) -> c_int {
    x_lock(p_file, flags)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_unlock(p_file: *mut sqlite3_file, flags: c_int) -> c_int {
    x_unlock(p_file, flags)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_check_reserved_lock(
    p_file: *mut sqlite3_file,
    p_res_out: *mut c_int,
) -> c_int {
    x_check_reserved_lock(p_file, p_res_out)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_file_control(
    p_file: *mut sqlite3_file,
    op: c_int,
    p_arg: *mut c_void,
) -> c_int {
    x_file_control(p_file, op, p_arg)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_sector_size(p_file: *mut sqlite3_file) -> c_int {
    x_sector_size(p_file)
}

#[unsafe(no_mangle)]
unsafe extern "C" fn custom_vfs_x_device_characteristics(p_file: *mut sqlite3_file) -> c_int {
    x_device_characteristics(p_file)
}

#[wasm_bindgen(js_name = "registerCustomVfs")]
pub extern "C" fn register_custom_vfs() {
    let io = sqlite3_io_methods {
        iVersion: 1,
        xClose: Some(custom_vfs_x_close),
        xRead: Some(custom_vfs_x_read),
        xWrite: Some(custom_vfs_x_write),
        xTruncate: Some(custom_vfs_x_truncate),
        xSync: Some(custom_vfs_x_sync),
        xFileSize: Some(custom_vfs_x_file_size),
        xLock: Some(custom_vfs_x_lock),
        xUnlock: Some(custom_vfs_x_unlock),
        xCheckReservedLock: Some(custom_vfs_x_check_reserved_lock),
        xFileControl: Some(custom_vfs_x_file_control),
        xSectorSize: Some(custom_vfs_x_sector_size),
        xDeviceCharacteristics: Some(custom_vfs_x_device_characteristics),
        xShmMap: None,
        xShmLock: None,
        xShmBarrier: None,
        xShmUnmap: None,
        xFetch: None,
        xUnfetch: None,
    };
    let io_methods_ptr = Box::into_raw(Box::new(io));
    let vfs = sqlite3_vfs {
        iVersion: 1,
        szOsFile: 0,
        mxPathname: 1024,
        pNext: null_mut(),
        zName: "custom_vfs".as_ptr() as *const c_char,
        pAppData: io_methods_ptr as *mut c_void,
        xOpen: Some(custom_vfs_x_open),
        xDelete: Some(custom_vfs_x_delete),
        xAccess: Some(custom_vfs_x_access),
        xFullPathname: Some(custom_vfs_x_full_pathname),
        xDlOpen: None,
        xDlError: None,
        xDlSym: None,
        xDlClose: None,
        xRandomness: None,
        xSleep: None,
        xCurrentTime: None,
        xGetLastError: Some(custom_vfs_x_get_last_error),
        xCurrentTimeInt64: None,
        xSetSystemCall: None,
        xGetSystemCall: None,
        xNextSystemCall: None,
    };
    let vfs_ptr = Box::into_raw(Box::new(vfs));
    unsafe { sqlite3_vfs_register(vfs_ptr, 1) };
}
