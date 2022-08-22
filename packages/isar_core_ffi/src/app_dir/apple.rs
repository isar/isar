use objc::runtime::Object;
use objc::{class, msg_send, sel, sel_impl};
use objc_foundation::{INSString, NSArray, NSString};
use std::os::raw::c_ulong;

#[allow(improper_ctypes)]
#[allow(dead_code)]
extern "C" {
    pub fn NSSearchPathForDirectoriesInDomains(
        directory: c_ulong,
        domain_mask: c_ulong,
        expand_tilde: bool,
    ) -> *mut NSArray<*mut NSString>;
}

const APPLICATION_SUPPORT_DIRECTORY: u8 = 14;

pub fn get_dir() -> Option<String> {
    unsafe {
        let directories =
            NSSearchPathForDirectoriesInDomains(APPLICATION_SUPPORT_DIRECTORY as c_ulong, 1, true);
        let first_object: &mut NSString = msg_send![directories, firstObject];
        Some(first_object.as_str().to_string())
    }
}

pub fn get_app_id() -> Option<String> {
    if cfg!(target_os = "ios") {
        return None;
    }

    unsafe {
        let bundle_cls = class!(NSBundle);
        let main_bundle: &mut Object = msg_send![bundle_cls, mainBundle];
        let bundle_id: &mut NSString = msg_send![main_bundle, bundleIdentifier];
        Some(bundle_id.as_str().to_string())
    }
}
