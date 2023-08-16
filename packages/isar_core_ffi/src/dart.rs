use std::ffi::{c_char, c_int, c_void, CStr};
use std::mem;
use std::sync::OnceLock;

#[repr(C)]
struct DartApiEntry {
    name: *const c_char,
    function: *const c_void,
}

#[repr(C)]
struct DartApi {
    major: c_int,
    minor: c_int,
    functions: *const DartApiEntry,
}

impl DartApi {
    fn lookup_fn(&self, name: &str) -> *const c_void {
        for i in 0..usize::MAX {
            let entry = unsafe { self.functions.add(i) };
            let entry = unsafe { &*entry };
            if entry.name.is_null() {
                break;
            }
            let fn_name = unsafe { CStr::from_ptr(entry.name) };
            if name == fn_name.to_string_lossy() {
                return entry.function;
            }
        }
        panic!("FFI function {name} not found");
    }
}

static DART_FUNCTIONS: OnceLock<DartFunctions> = OnceLock::new();

pub type DartPort = i64;
type DartIsolate = *mut std::ffi::c_void;

pub struct DartFunctions {
    pub post_integer: unsafe extern "C" fn(DartPort, i64) -> bool,
    pub current_isolate: unsafe extern "C" fn() -> DartIsolate,
    pub exit_isolate: unsafe extern "C" fn(),
    pub enter_isolate: unsafe extern "C" fn(DartIsolate),
}

pub unsafe fn dart_post_int(port: DartPort, value: i64) {
    if let Some(dartfn) = DART_FUNCTIONS.get() {
        (dartfn.post_integer)(port, value);
    }
}

pub unsafe fn dart_pause_isolate<T, F: FnOnce() -> T>(callback: F) -> T {
    let dartfn = DART_FUNCTIONS.get().unwrap();
    let isolate = (dartfn.current_isolate)();
    (dartfn.exit_isolate)();
    let result = callback();
    (dartfn.enter_isolate)(isolate);
    result
}

#[no_mangle]
pub unsafe extern "C" fn isar_connect_dart_api(ptr: *mut c_void) {
    let functions = unsafe {
        let api = ptr as *const DartApi;
        let api = &*api;
        if api.major < 2 {
            panic!("unsupported Dart API version {}.{}", api.major, api.minor);
        }
        DartFunctions {
            post_integer: mem::transmute(api.lookup_fn("Dart_PostInteger")),
            current_isolate: mem::transmute(api.lookup_fn("Dart_CurrentIsolate")),
            exit_isolate: mem::transmute(api.lookup_fn("Dart_ExitIsolate")),
            enter_isolate: mem::transmute(api.lookup_fn("Dart_EnterIsolate")),
        }
    };
    let _ = DART_FUNCTIONS.set(functions);
}
