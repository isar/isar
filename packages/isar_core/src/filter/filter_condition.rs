use super::filter_value::FilterValue;
use std::cmp::Ordering;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum ConditionType {
    Between, // values[0] <= property <= values[1]
    EndsWith,
    Contains,
    Matches,
    True,
    False,
}

#[derive(Clone, PartialEq, Debug)]
pub struct FilterCondition {
    property: usize,
    condition_type: ConditionType,
    values: Vec<FilterValue>,
    case_insensitive: bool,
}

impl FilterCondition {
    pub fn new_equal_to(property: usize, value: FilterValue, case_insensitive: bool) -> Self {
        FilterCondition {
            property,
            condition_type: ConditionType::Between,
            values: vec![value.clone(), value],
            case_insensitive,
        }
    }

    pub fn new_greater_than(property: usize, value: FilterValue, case_insensitive: bool) -> Self {
        if let Some(value) = value.try_increment() {
            let max = value.get_max();
            return FilterCondition {
                property,
                condition_type: ConditionType::Between,
                values: vec![value, max],
                case_insensitive,
            };
        } else {
            return Self::new_true();
        }
    }

    pub fn new_less_than(property: usize, value: FilterValue, case_insensitive: bool) -> Self {
        if let Some(value) = value.try_decrement() {
            return FilterCondition {
                property,
                condition_type: ConditionType::Between,
                values: vec![value.get_null(), value],
                case_insensitive,
            };
        } else {
            return Self::new_true();
        }
    }

    pub fn new_between(
        property: usize,
        lower: FilterValue,
        upper: FilterValue,
        case_insensitive: bool,
    ) -> Self {
        if lower.is_null() && upper.is_max() {
            return Self::new_true();
        }
        match lower.partial_cmp(&upper) {
            Some(Ordering::Less) | Some(Ordering::Equal) => FilterCondition {
                property,
                condition_type: ConditionType::Between,
                values: vec![lower, upper],
                case_insensitive,
            },
            _ => Self::new_false(),
        }
    }

    pub fn new_starts_with(property: usize, value: &str, case_insensitive: bool) -> Self {
        let lower = value.to_string();
        let upper = format!("{}{}", value, '\u{10FFFF}');
        FilterCondition {
            property,
            condition_type: ConditionType::Between,
            values: vec![
                FilterValue::String(Some(lower)),
                FilterValue::String(Some(upper)),
            ],
            case_insensitive,
        }
    }

    pub fn new_ends_with(property: usize, value: &str, case_insensitive: bool) -> Self {
        FilterCondition {
            property,
            condition_type: ConditionType::EndsWith,
            values: vec![FilterValue::String(Some(value.to_string()))],
            case_insensitive,
        }
    }

    pub fn new_contains(property: usize, value: &str, case_insensitive: bool) -> Self {
        FilterCondition {
            property,
            condition_type: ConditionType::Contains,
            values: vec![FilterValue::String(Some(value.to_string()))],
            case_insensitive,
        }
    }

    pub fn new_matches(property: usize, value: &str, case_insensitive: bool) -> Self {
        FilterCondition {
            property,
            condition_type: ConditionType::Matches,
            values: vec![FilterValue::String(Some(value.to_string()))],
            case_insensitive,
        }
    }

    pub(crate) fn new_true() -> Self {
        FilterCondition {
            property: usize::MAX,
            condition_type: ConditionType::True,
            values: Vec::new(),
            case_insensitive: false,
        }
    }

    pub(crate) fn new_false() -> Self {
        FilterCondition {
            property: usize::MAX,
            condition_type: ConditionType::False,
            values: Vec::new(),
            case_insensitive: false,
        }
    }

    pub fn get_property(&self) -> usize {
        self.property
    }

    pub fn get_condition_type(&self) -> ConditionType {
        self.condition_type
    }

    pub fn get_value(&self) -> &FilterValue {
        &self.values[0]
    }

    pub fn get_lower_upper(&self) -> (&FilterValue, &FilterValue) {
        (&self.values[0], &self.values[1])
    }

    pub fn get_values(&self) -> &[FilterValue] {
        &self.values
    }

    pub fn get_case_insensitive(&self) -> bool {
        self.case_insensitive
    }
}
