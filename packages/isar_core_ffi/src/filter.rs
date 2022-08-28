use crate::from_c_str;
use isar_core::collection::IsarCollection;
use isar_core::error::illegal_arg;
use isar_core::error::Result;
use isar_core::object::data_type::DataType;
use isar_core::object::property::Property;
use isar_core::query::filter::*;
use std::os::raw::c_char;
use std::slice;

#[no_mangle]
pub unsafe extern "C" fn isar_filter_static(filter: *mut *const Filter, value: bool) {
    let query_filter = Filter::stat(value);
    let ptr = Box::into_raw(Box::new(query_filter));
    filter.write(ptr);
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_and_or_xor(
    filter: *mut *const Filter,
    and: bool,
    exclusive: bool,
    conditions: *mut *mut Filter,
    length: u32,
) {
    let filters = slice::from_raw_parts(conditions, length as usize)
        .iter()
        .map(|f| *Box::from_raw(*f))
        .collect();
    let and_or = if and {
        Filter::and(filters)
    } else if exclusive {
        Filter::xor(filters)
    } else {
        Filter::or(filters)
    };
    let ptr = Box::into_raw(Box::new(and_or));
    filter.write(ptr);
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_not(filter: *mut *const Filter, condition: *mut Filter) {
    let condition = *Box::from_raw(condition);
    let not = Filter::not(condition);
    let ptr = Box::into_raw(Box::new(not));
    filter.write(ptr);
}

pub fn get_property(
    collection: &IsarCollection,
    embedded_col_id: u64,
    property_id: u64,
) -> Result<&Property> {
    let properties = if embedded_col_id != 0 {
        if let Some(properties) = collection.embedded_properties.get(embedded_col_id) {
            properties
        } else {
            return illegal_arg("Embedded collection does not exist.");
        }
    } else {
        &collection.properties
    };
    if let Some(property) = properties.get(property_id as usize) {
        Ok(property)
    } else {
        illegal_arg("Property does not exist.")
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_object(
    collection: &IsarCollection,
    filter: *mut *const Filter,
    condition: *mut Filter,
    embedded_col_id: u64,
    property_id: u64,
) -> i64 {
    isar_try! {
        let property = get_property(collection, embedded_col_id, property_id)?;
        let condition = if !condition.is_null() {
            Some(*Box::from_raw(condition))
        } else {
            None
        };
        let query_filter = Filter::object(property, condition)?;
        let ptr = Box::into_raw(Box::new(query_filter));
        filter.write(ptr);
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_link(
    collection: &IsarCollection,
    filter: *mut *const Filter,
    condition: *mut Filter,
    link_id: u64,
) -> i64 {
    isar_try! {
        let condition = *Box::from_raw(condition);
        let query_filter = Filter::link(collection, link_id, condition)?;
        let ptr = Box::into_raw(Box::new(query_filter));
        filter.write(ptr);
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_link_length(
    collection: &IsarCollection,
    filter: *mut *const Filter,
    lower: u32,
    upper: u32,
    link_id: u64,
) -> i64 {
    isar_try! {
        let query_filter = Filter::link_length(collection, link_id, lower as usize,upper as usize)?;
        let ptr = Box::into_raw(Box::new(query_filter));
        filter.write(ptr);
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_list_length(
    collection: &IsarCollection,
    filter: *mut *const Filter,
    lower: u32,
    upper: u32,
    embedded_col_id: u64,
    property_id: u64,
) -> i64 {
    isar_try! {
        let property = get_property(collection, embedded_col_id, property_id)?;
        let query_filter = Filter::list_length(property, lower as usize,upper as usize)?;
        let ptr = Box::into_raw(Box::new(query_filter));
        filter.write(ptr);
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_null(
    collection: &IsarCollection,
    filter: *mut *const Filter,
    embedded_col_id: u64,
    property_id: u64,
) -> i64 {
    isar_try! {
        let property = get_property(collection, embedded_col_id, property_id)?;
        let query_filter = Filter::null(property);
        let ptr = Box::into_raw(Box::new(query_filter));
        filter.write(ptr);
    }
}

#[macro_export]
macro_rules! include_num {
    ($type:ident, $lower:ident, $include_lower:expr, $upper:ident, $include_upper:expr) => {{
        let lower = $lower.clamp($type::MIN as i64, $type::MAX as i64) as $type;
        let lower = if !$include_lower {
            lower.checked_add(1)
        } else {
            Some(lower)
        };

        let upper = $upper.clamp($type::MIN as i64, $type::MAX as i64) as $type;
        let upper = if !$include_upper {
            upper.checked_sub(1)
        } else {
            Some(upper)
        };

        (lower, upper)
    }};
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_id(
    filter: *mut *const Filter,
    lower: i64,
    include_lower: bool,
    upper: i64,
    include_upper: bool,
) {
    let query_filter = if let (Some(lower), Some(upper)) =
        include_num!(i64, lower, include_lower, upper, include_upper)
    {
        Filter::id(lower, upper)
    } else {
        Filter::stat(false)
    };
    let ptr = Box::into_raw(Box::new(query_filter));
    filter.write(ptr);
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_long(
    collection: &IsarCollection,
    filter: *mut *const Filter,
    lower: i64,
    include_lower: bool,
    upper: i64,
    include_upper: bool,
    embedded_col_id: u64,
    property_id: u64,
) -> i64 {
    isar_try! {
        let property = get_property(collection, embedded_col_id, property_id)?;
        let query_filter = if property.data_type == DataType::Byte
            || property.data_type == DataType::ByteList
            || property.data_type == DataType::Bool
            || property.data_type == DataType::BoolList
        {
            if let (Some(lower), Some(upper)) =
                include_num!(u8, lower, include_lower, upper, include_upper)
            {
                Filter::byte(property, lower, upper)?
            } else {
                Filter::stat(false)
            }
        } else if property.data_type == DataType::Int || property.data_type == DataType::IntList {
            if let (Some(lower), Some(upper)) =
                include_num!(i32, lower, include_lower, upper, include_upper)
            {
                Filter::int(property, lower, upper)?
            } else {
                Filter::stat(false)
            }
        } else {
            if let (Some(lower), Some(upper)) =
                include_num!(i64, lower, include_lower, upper, include_upper)
            {
                Filter::long(property, lower, upper)?
            } else {
                Filter::stat(false)
            }
        };
        let ptr = Box::into_raw(Box::new(query_filter));
        filter.write(ptr);
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_double(
    collection: &IsarCollection,
    filter: *mut *const Filter,
    lower: f64,
    upper: f64,
    embedded_col_id: u64,
    property_id: u64,
) -> i64 {
    isar_try! {
        let property = get_property(collection, embedded_col_id, property_id)?;
        let query_filter = if property.data_type == DataType::Float || property.data_type == DataType::FloatList {
            let lower = if lower.is_finite() {
                lower.clamp(f32::MIN as f64, f32::MAX as f64)
            } else {
                lower
            };
            let upper = if upper.is_finite() {
                upper.clamp(f32::MIN as f64, f32::MAX as f64)
            } else {
                upper
            };
            Filter::float(property, lower as f32, upper as f32)?
        } else {
            Filter::double(property, lower, upper)?
        };
        let ptr = Box::into_raw(Box::new(query_filter));
        filter.write(ptr);
    }
}

unsafe fn get_lower_str(lower: Option<Vec<u8>>, include_lower: bool) -> Option<Vec<u8>> {
    if include_lower {
        lower
    } else if let Some(mut lower) = lower {
        if let Some(last) = lower.pop() {
            if last < 255 {
                lower.push(last + 1);
            } else {
                lower.push(255);
                lower.push(0);
            }
        } else {
            lower.push(0);
        }
        Some(lower)
    } else {
        Some(vec![])
    }
}

unsafe fn get_upper_str(upper: Option<Vec<u8>>, include_upper: bool) -> Option<Option<Vec<u8>>> {
    if include_upper {
        Some(upper)
    } else if let Some(mut upper) = upper {
        if upper.is_empty() {
            Some(None)
        } else {
            for i in (upper.len() - 1)..0 {
                if upper[i] > 0 {
                    upper[i] -= 1;
                    return Some(Some(upper));
                }
            }
            Some(Some(vec![]))
        }
    } else {
        // cannot exclude upper limit
        None
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string(
    collection: &IsarCollection,
    filter: *mut *const Filter,
    lower: *const c_char,
    include_lower: bool,
    upper: *const c_char,
    include_upper: bool,
    case_sensitive: bool,
    embedded_col_id: u64,
    property_id: u64,
) -> i64 {
    isar_try! {
        let property = get_property(collection, embedded_col_id, property_id)?;

        let lower_bytes = Filter::string_to_bytes(from_c_str(lower)?, case_sensitive);
        let lower = get_lower_str(lower_bytes, include_lower);

        let upper_bytes = Filter::string_to_bytes(from_c_str(upper)?, case_sensitive);
        let upper = get_upper_str(upper_bytes, include_upper);

        let query_filter = if let Some(upper) = upper {
            Filter::byte_string(property, lower, upper, case_sensitive)?
        } else {
            Filter::stat(false)
        };
        let ptr = Box::into_raw(Box::new(query_filter));
        filter.write(ptr);
    }
}

#[macro_export]
macro_rules! filter_string_ffi {
    ($filter_name:ident, $function_name:ident) => {
        #[no_mangle]
        pub unsafe extern "C" fn $function_name(
            collection: &IsarCollection,
            filter: *mut *const Filter,
            value: *const c_char,
            case_sensitive: bool,
            embedded_col_id: u64,
            property_id: u64,
        ) -> i64 {
            isar_try! {
                let property = get_property(collection, embedded_col_id, property_id)?;
                let str = from_c_str(value)?.unwrap();
                let query_filter = isar_core::query::filter::Filter::$filter_name(property, str, case_sensitive)?;
                let ptr = Box::into_raw(Box::new(query_filter));
                filter.write(ptr);
            }
        }
    }
}

filter_string_ffi!(string_starts_with, isar_filter_string_starts_with);
filter_string_ffi!(string_ends_with, isar_filter_string_ends_with);
filter_string_ffi!(string_contains, isar_filter_string_contains);
filter_string_ffi!(string_matches, isar_filter_string_matches);
