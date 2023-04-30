use core::slice;
use isar_core::filter::filter_condition::FilterCondition;
use isar_core::filter::filter_group::{FilterGroup, GroupType};
use isar_core::filter::filter_value::FilterValue;
use isar_core::filter::Filter;
use itertools::Itertools;

use crate::from_utf16;

#[no_mangle]
pub unsafe extern "C" fn isar_filter_value_bool(value: bool, null: bool) -> *const FilterValue {
    let filter = if null {
        FilterValue::Bool(None)
    } else {
        FilterValue::Bool(Some(value))
    };
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_value_integer(value: i64) -> *const FilterValue {
    Box::into_raw(Box::new(FilterValue::Integer(value)))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_value_real(value: f64) -> *const FilterValue {
    Box::into_raw(Box::new(FilterValue::Real(value)))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_value_string(
    value: *const u16,
    length: u32,
) -> *const FilterValue {
    let filter_value = FilterValue::String(from_utf16(value, length));
    Box::into_raw(Box::new(filter_value))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_is_null(property: u16) -> *const Filter {
    let filter = Filter::Condition(FilterCondition::new_is_null(property));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_equal_to(
    property: u16,
    value: *mut FilterValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = Filter::Condition(FilterCondition::new_equal_to(
        property,
        value,
        case_sensitive,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_greater_than(
    property: u16,
    value: *mut FilterValue,
    include: bool,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = if !include {
        Filter::Condition(FilterCondition::new_greater_than(
            property,
            value,
            case_sensitive,
        ))
    } else {
        let upper = value.get_max();
        Filter::Condition(FilterCondition::new_between(
            property,
            value,
            upper,
            case_sensitive,
        ))
    };
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_less_than(
    property: u16,
    value: *mut FilterValue,
    include: bool,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = if !include {
        Filter::Condition(FilterCondition::new_less_than(
            property,
            value,
            case_sensitive,
        ))
    } else {
        let lower = value.get_null();
        Filter::Condition(FilterCondition::new_between(
            property,
            lower,
            value,
            case_sensitive,
        ))
    };
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_between(
    property: u16,
    lower: *mut FilterValue,
    include_lower: bool,
    upper: *mut FilterValue,
    include_upper: bool,
    case_sensitive: bool,
) -> *const Filter {
    let mut lower = *Box::from_raw(lower);
    if !include_lower {
        if let Some(new_lower) = lower.try_increment() {
            lower = new_lower;
        } else {
            return Box::into_raw(Box::new(Filter::Condition(FilterCondition::new_false())));
        }
    }
    let mut upper = *Box::from_raw(upper);
    if !include_upper {
        if let Some(new_upper) = upper.try_decrement() {
            upper = new_upper;
        } else {
            return Box::into_raw(Box::new(Filter::Condition(FilterCondition::new_false())));
        }
    }
    let filter = Filter::Condition(FilterCondition::new_between(
        property,
        lower,
        upper,
        case_sensitive,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_starts_with(
    property: u16,
    value: *mut FilterValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = if let FilterValue::String(Some(value)) = value {
        Filter::Condition(FilterCondition::new_string_starts_with(
            property,
            &value,
            case_sensitive,
        ))
    } else {
        Filter::Condition(FilterCondition::new_false())
    };
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_ends_with(
    property: u16,
    value: *mut FilterValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = if let FilterValue::String(Some(value)) = value {
        Filter::Condition(FilterCondition::new_string_ends_with(
            property,
            &value,
            case_sensitive,
        ))
    } else {
        Filter::Condition(FilterCondition::new_false())
    };
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_contains(
    property: u16,
    value: *mut FilterValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = if let FilterValue::String(Some(value)) = value {
        Filter::Condition(FilterCondition::new_string_contains(
            property,
            &value,
            case_sensitive,
        ))
    } else {
        Filter::Condition(FilterCondition::new_false())
    };
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_matches(
    property: u16,
    value: *mut FilterValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = if let FilterValue::String(Some(value)) = value {
        Filter::Condition(FilterCondition::new_string_matches(
            property,
            &value,
            case_sensitive,
        ))
    } else {
        Filter::Condition(FilterCondition::new_false())
    };
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_and(filters: *mut *mut Filter, lenght: u32) -> *const Filter {
    let filters = slice::from_raw_parts(filters, lenght as usize)
        .iter()
        .map(|f| *Box::from_raw(*f))
        .collect_vec();
    let group = FilterGroup::new(GroupType::And, filters);
    let filter = Filter::Group(group);
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_or(filters: *mut *mut Filter, lenght: u32) -> *const Filter {
    let filters = slice::from_raw_parts(filters, lenght as usize)
        .iter()
        .map(|f| *Box::from_raw(*f))
        .collect_vec();
    let group = FilterGroup::new(GroupType::Or, filters.to_vec());
    let filter = Filter::Group(group);
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_not(filter: *mut Filter) -> *const Filter {
    let filter = Filter::Group(FilterGroup::new(
        GroupType::Not,
        vec![*Box::from_raw(filter)],
    ));
    Box::into_raw(Box::new(filter))
}
