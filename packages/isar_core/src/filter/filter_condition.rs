use super::filter_value::FilterValue;
use std::cmp::Ordering;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum ConditionType {
    IsNull,
    Between, // values[0] <= property <= values[1]
    StringEndsWith,
    StringContains,
    StringMatches,
    True,
    False,
}

#[derive(Clone, PartialEq, Debug)]
pub struct FilterCondition {
    property: u16,
    condition_type: ConditionType,
    values: Vec<FilterValue>,
    case_sensitive: bool,
}

impl FilterCondition {
    pub fn new_is_null(property: u16) -> Self {
        FilterCondition {
            property,
            condition_type: ConditionType::IsNull,
            values: Vec::new(),
            case_sensitive: false,
        }
    }

    pub fn new_equal_to(property: u16, value: FilterValue, case_sensitive: bool) -> Self {
        FilterCondition {
            property,
            condition_type: ConditionType::Between,
            values: vec![value.clone(), value],
            case_sensitive,
        }
    }

    pub fn new_greater_than(property: u16, value: FilterValue, case_sensitive: bool) -> Self {
        if let Some(value) = value.try_increment() {
            let max = value.get_max();
            return FilterCondition {
                property,
                condition_type: ConditionType::Between,
                values: vec![value, max],
                case_sensitive,
            };
        } else {
            return Self::new_true();
        }
    }

    pub fn new_greater_than_equal(property: u16, value: FilterValue, case_sensitive: bool) -> Self {
        let max = value.get_max();
        return FilterCondition {
            property,
            condition_type: ConditionType::Between,
            values: vec![value, max],
            case_sensitive,
        };
    }

    pub fn new_less_than(property: u16, value: FilterValue, case_sensitive: bool) -> Self {
        if let Some(value) = value.try_decrement() {
            return FilterCondition {
                property,
                condition_type: ConditionType::Between,
                values: vec![value.get_null(), value],
                case_sensitive,
            };
        } else {
            return Self::new_true();
        }
    }

    pub fn new_between(
        property: u16,
        lower: FilterValue,
        upper: FilterValue,
        case_sensitive: bool,
    ) -> Self {
        if lower.is_null() && upper.is_max() {
            return Self::new_true();
        }
        match lower.partial_cmp(&upper) {
            Some(Ordering::Less) | Some(Ordering::Equal) => FilterCondition {
                property,
                condition_type: ConditionType::Between,
                values: vec![lower, upper],
                case_sensitive,
            },
            _ => Self::new_false(),
        }
    }

    pub fn new_string_starts_with(property: u16, value: &str, case_sensitive: bool) -> Self {
        let lower = value.to_string();
        let upper = format!("{}{}", value, '\u{10FFFF}');
        FilterCondition {
            property,
            condition_type: ConditionType::Between,
            values: vec![
                FilterValue::String(Some(lower)),
                FilterValue::String(Some(upper)),
            ],
            case_sensitive,
        }
    }

    pub fn new_string_ends_with(property: u16, value: &str, case_sensitive: bool) -> Self {
        FilterCondition {
            property,
            condition_type: ConditionType::StringEndsWith,
            values: vec![FilterValue::String(Some(value.to_string()))],
            case_sensitive,
        }
    }

    pub fn new_string_contains(property: u16, value: &str, case_sensitive: bool) -> Self {
        FilterCondition {
            property,
            condition_type: ConditionType::StringContains,
            values: vec![FilterValue::String(Some(value.to_string()))],
            case_sensitive,
        }
    }

    pub fn new_string_matches(property: u16, value: &str, case_sensitive: bool) -> Self {
        FilterCondition {
            property,
            condition_type: ConditionType::StringMatches,
            values: vec![FilterValue::String(Some(value.to_string()))],
            case_sensitive,
        }
    }

    pub fn new_true() -> Self {
        FilterCondition {
            property: u16::MAX,
            condition_type: ConditionType::True,
            values: Vec::new(),
            case_sensitive: false,
        }
    }

    pub fn new_false() -> Self {
        FilterCondition {
            property: u16::MAX,
            condition_type: ConditionType::False,
            values: Vec::new(),
            case_sensitive: false,
        }
    }

    pub fn get_property(&self) -> u16 {
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

    pub fn get_case_sensitive(&self) -> bool {
        self.case_sensitive
    }
}
