use core::slice;
use isar_core::core::{
    filter::{ConditionType, Filter, FilterCondition, FilterNested},
    value::IsarValue,
};
use std::vec;

#[no_mangle]
pub unsafe extern "C" fn isar_filter_is_null(property_index: u16) -> *const Filter {
    let filter = FilterCondition::new(property_index, ConditionType::IsNull, vec![], false);
    Box::into_raw(Box::new(Filter::Condition(filter)))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_equal(
    property_index: u16,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let values = if value.is_null() {
        vec![None]
    } else {
        vec![Some(*Box::from_raw(value))]
    };
    let filter = FilterCondition::new(property_index, ConditionType::Equal, values, case_sensitive);
    Box::into_raw(Box::new(Filter::Condition(filter)))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_greater(
    property_index: u16,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let values = if value.is_null() {
        vec![None]
    } else {
        vec![Some(*Box::from_raw(value))]
    };
    let filter = FilterCondition::new(
        property_index,
        ConditionType::Greater,
        values,
        case_sensitive,
    );
    Box::into_raw(Box::new(Filter::Condition(filter)))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_greater_or_equal(
    property_index: u16,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let values = if value.is_null() {
        vec![None]
    } else {
        vec![Some(*Box::from_raw(value))]
    };
    let filter = FilterCondition::new(
        property_index,
        ConditionType::GreaterOrEqual,
        values,
        case_sensitive,
    );
    Box::into_raw(Box::new(Filter::Condition(filter)))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_less(
    property_index: u16,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let values = if value.is_null() {
        vec![None]
    } else {
        vec![Some(*Box::from_raw(value))]
    };
    let filter = FilterCondition::new(property_index, ConditionType::Less, values, case_sensitive);
    Box::into_raw(Box::new(Filter::Condition(filter)))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_less_or_equal(
    property_index: u16,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let values = if value.is_null() {
        vec![None]
    } else {
        vec![Some(*Box::from_raw(value))]
    };
    let filter = FilterCondition::new(
        property_index,
        ConditionType::LessOrEqual,
        values,
        case_sensitive,
    );
    Box::into_raw(Box::new(Filter::Condition(filter)))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_between(
    property_index: u16,
    lower: *mut IsarValue,
    upper: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let mut values = vec![];
    if lower.is_null() {
        values.push(None);
    } else {
        values.push(Some(*Box::from_raw(lower)));
    };
    if upper.is_null() {
        values.push(None);
    } else {
        values.push(Some(*Box::from_raw(upper)));
    };
    let filter = FilterCondition::new(
        property_index,
        ConditionType::Between,
        values,
        case_sensitive,
    );
    Box::into_raw(Box::new(Filter::Condition(filter)))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_starts_with(
    property_index: u16,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = Filter::Condition(FilterCondition::new(
        property_index,
        ConditionType::StringStartsWith,
        vec![Some(value)],
        case_sensitive,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_ends_with(
    property_index: u16,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = Filter::Condition(FilterCondition::new(
        property_index,
        ConditionType::StringEndsWith,
        vec![Some(value)],
        case_sensitive,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_contains(
    property_index: u16,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = Filter::Condition(FilterCondition::new(
        property_index,
        ConditionType::StringContains,
        vec![Some(value)],
        case_sensitive,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_matches(
    property_index: u16,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = Filter::Condition(FilterCondition::new(
        property_index,
        ConditionType::StringMatches,
        vec![Some(value)],
        case_sensitive,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_nested(
    property_index: u16,
    filter: *mut Filter,
) -> *const Filter {
    let filter = Filter::Nested(FilterNested::new(property_index, *Box::from_raw(filter)));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_and(filters: *mut *mut Filter, lenght: u32) -> *const Filter {
    let filters = slice::from_raw_parts(filters, lenght as usize)
        .iter()
        .map(|f| *Box::from_raw(*f))
        .collect();
    let filter = Filter::And(filters);
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_or(filters: *mut *mut Filter, lenght: u32) -> *const Filter {
    let filters = slice::from_raw_parts(filters, lenght as usize)
        .iter()
        .map(|f| *Box::from_raw(*f))
        .collect();
    let filter = Filter::Or(filters);
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_not(filter: *mut Filter) -> *const Filter {
    let filter = Filter::Not(Box::from_raw(filter));
    Box::into_raw(Box::new(filter))
}
