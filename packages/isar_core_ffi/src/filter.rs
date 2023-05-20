use core::slice;
use isar_core::core::value::IsarValue;
use isar_core::filter::filter_condition::FilterCondition;
use isar_core::filter::filter_group::{FilterGroup, GroupType};
use isar_core::filter::Filter;
use itertools::Itertools;

#[no_mangle]
pub unsafe extern "C" fn isar_filter_is_null(property_index: u32) -> *const Filter {
    let filter = Filter::Condition(FilterCondition::new_is_null(property_index));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_equal_to(
    property_index: u32,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = Filter::Condition(FilterCondition::new_equal_to(
        property_index,
        value,
        case_sensitive,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_greater_than(
    property_index: u32,
    value: *mut IsarValue,
    include: bool,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = if !include {
        Filter::Condition(FilterCondition::new_greater_than(
            property_index,
            value,
            case_sensitive,
        ))
    } else {
        let upper = value.get_max();
        Filter::Condition(FilterCondition::new_between(
            property_index,
            value,
            upper,
            case_sensitive,
        ))
    };
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_less_than(
    property_index: u32,
    value: *mut IsarValue,
    include: bool,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = if !include {
        Filter::Condition(FilterCondition::new_less_than(
            property_index,
            value,
            case_sensitive,
        ))
    } else {
        let lower = value.get_null();
        Filter::Condition(FilterCondition::new_between(
            property_index,
            lower,
            value,
            case_sensitive,
        ))
    };
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_between(
    property_index: u32,
    lower: *mut IsarValue,
    include_lower: bool,
    upper: *mut IsarValue,
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
        property_index,
        lower,
        upper,
        case_sensitive,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_starts_with(
    property_index: u32,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = if let IsarValue::String(Some(value)) = value {
        Filter::Condition(FilterCondition::new_string_starts_with(
            property_index,
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
    property_index: u32,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = if let IsarValue::String(Some(value)) = value {
        Filter::Condition(FilterCondition::new_string_ends_with(
            property_index,
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
    property_index: u32,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = if let IsarValue::String(Some(value)) = value {
        Filter::Condition(FilterCondition::new_string_contains(
            property_index,
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
    property_index: u32,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = if let IsarValue::String(Some(value)) = value {
        Filter::Condition(FilterCondition::new_string_matches(
            property_index,
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
