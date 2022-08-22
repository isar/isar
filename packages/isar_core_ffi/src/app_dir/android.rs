use jni::objects::{JClass, JString};
use jni::JNIEnv;
use once_cell::sync::OnceCell;

static PATH: OnceCell<String> = OnceCell::new();

#[no_mangle]
pub extern "C" fn Java_dev_isar_isar_1flutter_1libs_IsarInitializer_initializePath(
    env: JNIEnv,
    _class: JClass,
    path: JString,
) {
    let java_str = env.get_string(path).unwrap();
    let path = java_str.to_str().unwrap();
    let _ = PATH.set(path.to_string());
}

pub fn get_dir() -> Option<String> {
    PATH.get().map(|s| s.to_string())
}

pub fn get_app_id() -> Option<String> {
    None
}
