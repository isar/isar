use core::slice;
use isar_core::core::{
    filter::{ConditionType, Filter, FilterCondition},
    value::IsarValue,
};
use itertools::Itertools;

#[no_mangle]
pub unsafe extern "C" fn isar_filter_is_null(property_index: u32) -> *const Filter {
    let filter = Filter::Condition(FilterCondition::new(
        property_index,
        ConditionType::IsNull,
        vec![],
        false,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_list_is_empty(property_index: u32) -> *const Filter {
    let filter = Filter::Condition(FilterCondition::new(
        property_index,
        ConditionType::ListIsEmpty,
        vec![],
        false,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_equal_to(
    property_index: u32,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let values = if value.is_null() {
        vec![]
    } else {
        vec![*Box::from_raw(value)]
    };
    let filter = Filter::Condition(FilterCondition::new(
        property_index,
        ConditionType::Equal,
        values,
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
    let filter = if include {
        FilterCondition::new(
            property_index,
            ConditionType::GreaterOrEqual,
            vec![value],
            case_sensitive,
        )
    } else {
        FilterCondition::new(
            property_index,
            ConditionType::Greater,
            vec![value],
            case_sensitive,
        )
    };
    let filter = Filter::Condition(filter);
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
    let filter = if include {
        FilterCondition::new(
            property_index,
            ConditionType::LessOrEqual,
            vec![value],
            case_sensitive,
        )
    } else {
        FilterCondition::new(
            property_index,
            ConditionType::Less,
            vec![value],
            case_sensitive,
        )
    };
    let filter = Filter::Condition(filter);
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
    let lower = *Box::from_raw(lower);
    let upper = *Box::from_raw(upper);
    let adjusted_lower = if include_lower {
        Some(lower)
    } else {
        lower.try_increment()
    };
    let adjusted_upper = if include_upper {
        Some(upper)
    } else {
        upper.try_decrement()
    };
    let filter = if let (Some(lower), Some(upper)) = (adjusted_lower, adjusted_upper) {
        FilterCondition::new(
            property_index,
            ConditionType::Between,
            vec![lower, upper],
            case_sensitive,
        )
    } else {
        FilterCondition::new(
            property_index,
            ConditionType::Between,
            vec![],
            case_sensitive,
        )
    };
    let filter = Filter::Condition(filter);
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_starts_with(
    property_index: u32,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = Filter::Condition(FilterCondition::new(
        property_index,
        ConditionType::StringStartsWith,
        vec![value],
        case_sensitive,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_ends_with(
    property_index: u32,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = Filter::Condition(FilterCondition::new(
        property_index,
        ConditionType::StringEndsWith,
        vec![value],
        case_sensitive,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_contains(
    property_index: u32,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = Filter::Condition(FilterCondition::new(
        property_index,
        ConditionType::StringContains,
        vec![value],
        case_sensitive,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_string_matches(
    property_index: u32,
    value: *mut IsarValue,
    case_sensitive: bool,
) -> *const Filter {
    let value = *Box::from_raw(value);
    let filter = Filter::Condition(FilterCondition::new(
        property_index,
        ConditionType::StringMatches,
        vec![value],
        case_sensitive,
    ));
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_and(filters: *mut *mut Filter, lenght: u32) -> *const Filter {
    let filters = slice::from_raw_parts(filters, lenght as usize)
        .iter()
        .map(|f| *Box::from_raw(*f))
        .collect_vec();
    let filter = Filter::And(filters);
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_or(filters: *mut *mut Filter, lenght: u32) -> *const Filter {
    let filters = slice::from_raw_parts(filters, lenght as usize)
        .iter()
        .map(|f| *Box::from_raw(*f))
        .collect_vec();
    let filter = Filter::Or(filters);
    Box::into_raw(Box::new(filter))
}

#[no_mangle]
pub unsafe extern "C" fn isar_filter_not(filter: *mut Filter) -> *const Filter {
    let filter = Filter::Not(Box::from_raw(filter));
    Box::into_raw(Box::new(filter))
}
