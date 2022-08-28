use isar_core::object::isar_object::IsarObject;
use std::{ptr, slice};

#[repr(C)]
pub struct CObject {
    id: i64,
    buffer: *mut u8,
    buffer_length: u32,
}

unsafe impl Send for CObject {}

impl CObject {
    pub fn new() -> Self {
        CObject {
            id: i64::MIN,
            buffer: std::ptr::null_mut(),
            buffer_length: 0,
        }
    }

    #[allow(clippy::mut_from_ref)]
    pub fn get_object(&self) -> IsarObject {
        let bytes = unsafe { slice::from_raw_parts(self.buffer, self.buffer_length as usize) };
        IsarObject::from_bytes(bytes)
    }

    pub fn get_id(&mut self) -> i64 {
        self.id
    }

    pub fn set_id(&mut self, id: i64) {
        self.id = id;
    }

    pub fn set_object(&mut self, object: Option<IsarObject>) {
        if let Some(object) = object {
            let bytes = object.as_bytes();
            let buffer_length = bytes.len() as u32;
            let buffer = bytes as *const _ as *mut u8;
            self.buffer = buffer;
            self.buffer_length = buffer_length;
        } else {
            self.buffer = ptr::null_mut();
            self.buffer_length = 0;
        }
    }
}

#[repr(C)]
pub struct CObjectSet {
    objects: *mut CObject,
    length: u32,
}

unsafe impl Send for CObjectSet {}

impl CObjectSet {
    pub fn fill_from_vec(&mut self, objects: Vec<CObject>) {
        let mut objects = objects.into_boxed_slice();
        self.objects = objects.as_mut_ptr();
        self.length = objects.len() as u32;
        std::mem::forget(objects);
    }

    #[allow(clippy::mut_from_ref)]
    pub unsafe fn get_objects(&self) -> &mut [CObject] {
        std::slice::from_raw_parts_mut(self.objects, self.length as usize)
    }

    pub fn get_length(&self) -> usize {
        self.length as usize
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_free_c_object_set(ros: &mut CObjectSet) {
    Vec::from_raw_parts(ros.objects, ros.length as usize, ros.length as usize);
    ros.objects = ptr::null_mut();
    ros.length = 0;
}
