use once_cell::sync::OnceCell;

static DART_POST_C_OBJECT: OnceCell<DartPostCObjectFnType> = OnceCell::new();

pub fn dart_post_int(port: DartPort, value: i64) {
    let dart_post = DART_POST_C_OBJECT.get().unwrap();
    dart_post(port, &mut DartCObject::new(value));
}

pub type DartPort = i64;

pub type DartPostCObjectFnType = extern "C" fn(port_id: DartPort, message: *mut DartCObject) -> i8;

#[repr(C)]
pub struct DartCObject {
    ty: i32,
    value: DartCObjectValue,
}

impl DartCObject {
    fn new(value: i64) -> Self {
        DartCObject {
            ty: 3,
            value: DartCObjectValue { value },
        }
    }
}

#[repr(C)]
union DartCObjectValue {
    pub value: i64,
    _union_align: [u64; 5usize],
}

#[no_mangle]
pub unsafe extern "C" fn isar_connect_dart_api(ptr: DartPostCObjectFnType) {
    let _ = DART_POST_C_OBJECT.set(ptr);
}
