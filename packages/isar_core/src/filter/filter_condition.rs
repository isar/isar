use crate::core::value::IsarValue;
use std::cmp::Ordering;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum ConditionType {
    IsNull,
    Between, // values[0] <= property <= values[1]
    StringEndsWith,
    StringContains,
    StringMatches,
    StringLength,
    ListLength,
    True,
    False,
}

#[derive(Clone, PartialEq, Debug)]
pub struct FilterCondition {
    property_index: u32,
    condition_type: ConditionType,
    values: Vec<IsarValue>,
    case_sensitive: bool,
}

impl FilterCondition {
    pub fn new_is_null(property_index: u32) -> Self {
        FilterCondition {
            property_index,
            condition_type: ConditionType::IsNull,
            values: Vec::new(),
            case_sensitive: false,
        }
    }

    pub fn new_equal_to(property_index: u32, value: IsarValue, case_sensitive: bool) -> Self {
        FilterCondition {
            property_index,
            condition_type: ConditionType::Between,
            values: vec![value.clone(), value],
            case_sensitive,
        }
    }

    pub fn new_greater_than(property_index: u32, value: IsarValue, case_sensitive: bool) -> Self {
        if let Some(value) = value.try_increment() {
            let max = value.get_max();
            FilterCondition {
                property_index,
                condition_type: ConditionType::Between,
                values: vec![value, max],
                case_sensitive,
            }
        } else {
            Self::new_false()
        }
    }

    pub fn new_greater_than_equal(
        property_index: u32,
        value: IsarValue,
        case_sensitive: bool,
    ) -> Self {
        if value.is_null() {
            Self::new_true()
        } else {
            let max = value.get_max();
            FilterCondition {
                property_index,
                condition_type: ConditionType::Between,
                values: vec![value, max],
                case_sensitive,
            }
        }
    }

    pub fn new_less_than(property_index: u32, value: IsarValue, case_sensitive: bool) -> Self {
        if let Some(value) = value.try_decrement() {
            FilterCondition {
                property_index,
                condition_type: ConditionType::Between,
                values: vec![value.get_null(), value],
                case_sensitive,
            }
        } else {
            Self::new_false()
        }
    }

    pub fn new_less_than_equal(
        property_index: u32,
        value: IsarValue,
        case_sensitive: bool,
    ) -> Self {
        if value.is_max() {
            Self::new_true()
        } else {
            FilterCondition {
                property_index,
                condition_type: ConditionType::Between,
                values: vec![value.get_null(), value],
                case_sensitive,
            }
        }
    }

    pub fn new_between(
        property_index: u32,
        lower: IsarValue,
        upper: IsarValue,
        case_sensitive: bool,
    ) -> Self {
        match lower.partial_cmp(&upper) {
            Some(Ordering::Less | Ordering::Equal) => FilterCondition {
                property_index,
                condition_type: ConditionType::Between,
                values: vec![lower, upper],
                case_sensitive,
            },
            _ => Self::new_false(),
        }
    }

    pub fn new_string_starts_with(property_index: u32, value: &str, case_sensitive: bool) -> Self {
        let lower = value.to_string();
        let upper = format!("{}{}", value, '\u{10FFFF}');
        FilterCondition {
            property_index,
            condition_type: ConditionType::Between,
            values: vec![
                IsarValue::String(Some(lower)),
                IsarValue::String(Some(upper)),
            ],
            case_sensitive,
        }
    }

    pub fn new_string_ends_with(property_index: u32, value: &str, case_sensitive: bool) -> Self {
        FilterCondition {
            property_index,
            condition_type: ConditionType::StringEndsWith,
            values: vec![IsarValue::String(Some(value.to_string()))],
            case_sensitive,
        }
    }

    pub fn new_string_contains(property_index: u32, value: &str, case_sensitive: bool) -> Self {
        FilterCondition {
            property_index,
            condition_type: ConditionType::StringContains,
            values: vec![IsarValue::String(Some(value.to_string()))],
            case_sensitive,
        }
    }

    pub fn new_string_matches(property_index: u32, value: &str, case_sensitive: bool) -> Self {
        FilterCondition {
            property_index,
            condition_type: ConditionType::StringMatches,
            values: vec![IsarValue::String(Some(value.to_string()))],
            case_sensitive,
        }
    }

    pub fn new_string_length(property_index: u32, lower: u32, upper: u32) -> Self {
        match lower.partial_cmp(&upper) {
            Some(Ordering::Less | Ordering::Equal) => FilterCondition {
                property_index,
                condition_type: ConditionType::StringLength,
                values: vec![
                    IsarValue::Integer(lower as i64),
                    IsarValue::Integer(upper as i64),
                ],
                case_sensitive: false,
            },
            _ => Self::new_false(),
        }
    }

    pub fn new_list_length(property_index: u32, lower: u32, upper: u32) -> Self {
        match lower.partial_cmp(&upper) {
            Some(Ordering::Less | Ordering::Equal) => FilterCondition {
                property_index,
                condition_type: ConditionType::ListLength,
                values: vec![
                    IsarValue::Integer(lower as i64),
                    IsarValue::Integer(upper as i64),
                ],
                case_sensitive: false,
            },
            _ => Self::new_false(),
        }
    }

    pub fn new_true() -> Self {
        FilterCondition {
            property_index: u32::MAX,
            condition_type: ConditionType::True,
            values: Vec::new(),
            case_sensitive: false,
        }
    }

    pub fn new_false() -> Self {
        FilterCondition {
            property_index: u32::MAX,
            condition_type: ConditionType::False,
            values: Vec::new(),
            case_sensitive: false,
        }
    }

    pub fn get_property_index(&self) -> u32 {
        self.property_index
    }

    pub fn get_condition_type(&self) -> ConditionType {
        self.condition_type
    }

    pub fn get_value(&self) -> &IsarValue {
        &self.values[0]
    }

    pub fn get_lower_upper(&self) -> (&IsarValue, &IsarValue) {
        (&self.values[0], &self.values[1])
    }

    pub fn get_values(&self) -> &[IsarValue] {
        &self.values
    }

    pub fn get_case_sensitive(&self) -> bool {
        self.case_sensitive
    }
}

#[cfg(test)]
mod tests {
    use super::{ConditionType, FilterCondition, IsarValue};

    mod is_null {
        use super::*;

        #[test]
        fn test_new_is_null() {
            assert_eq!(
                FilterCondition::new_is_null(0),
                FilterCondition {
                    property_index: 0,
                    condition_type: ConditionType::IsNull,
                    values: vec![],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_is_null(1),
                FilterCondition {
                    property_index: 1,
                    condition_type: ConditionType::IsNull,
                    values: vec![],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_is_null(42),
                FilterCondition {
                    property_index: 42,
                    condition_type: ConditionType::IsNull,
                    values: vec![],
                    case_sensitive: false,
                }
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(FilterCondition::new_is_null(0).get_property_index(), 0);
            assert_eq!(FilterCondition::new_is_null(1).get_property_index(), 1);
            assert_eq!(FilterCondition::new_is_null(42).get_property_index(), 42);
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_is_null(0).get_condition_type(),
                ConditionType::IsNull
            );
            assert_eq!(
                FilterCondition::new_is_null(1).get_condition_type(),
                ConditionType::IsNull
            );
            assert_eq!(
                FilterCondition::new_is_null(42).get_condition_type(),
                ConditionType::IsNull
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(FilterCondition::new_is_null(0).get_values(), vec![]);
            assert_eq!(FilterCondition::new_is_null(1).get_values(), vec![]);
            assert_eq!(FilterCondition::new_is_null(42).get_values(), vec![]);
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(FilterCondition::new_is_null(0).get_case_sensitive(), false);
            assert_eq!(FilterCondition::new_is_null(1).get_case_sensitive(), false);
            assert_eq!(FilterCondition::new_is_null(42).get_case_sensitive(), false);
        }
    }

    mod equal_to {
        use super::*;

        #[test]
        fn test_new_equal_to() {
            assert_eq!(
                FilterCondition::new_equal_to(0, IsarValue::Bool(Some(true)), false),
                FilterCondition {
                    property_index: 0,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Bool(Some(true)); 2],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_equal_to(1, IsarValue::Integer(2), false),
                FilterCondition {
                    property_index: 1,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Integer(2); 2],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_equal_to(42, IsarValue::String(Some("foo".to_string())), true),
                FilterCondition {
                    property_index: 42,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::String(Some("foo".to_string())); 2],
                    case_sensitive: true,
                }
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(
                FilterCondition::new_equal_to(0, IsarValue::Bool(Some(true)), false)
                    .get_property_index(),
                0
            );
            assert_eq!(
                FilterCondition::new_equal_to(1, IsarValue::Integer(2), false).get_property_index(),
                1
            );
            assert_eq!(
                FilterCondition::new_equal_to(42, IsarValue::String(Some("foo".to_string())), true)
                    .get_property_index(),
                42
            );
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_equal_to(0, IsarValue::Bool(Some(true)), false)
                    .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_equal_to(1, IsarValue::Integer(2), false).get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_equal_to(42, IsarValue::String(Some("foo".to_string())), true)
                    .get_condition_type(),
                ConditionType::Between
            );
        }

        #[test]
        fn test_get_lower_upper() {
            assert_eq!(
                FilterCondition::new_equal_to(0, IsarValue::Bool(Some(true)), false)
                    .get_lower_upper(),
                (&IsarValue::Bool(Some(true)), &IsarValue::Bool(Some(true)))
            );
            assert_eq!(
                FilterCondition::new_equal_to(1, IsarValue::Integer(2), false).get_lower_upper(),
                (&IsarValue::Integer(2), &IsarValue::Integer(2))
            );
            assert_eq!(
                FilterCondition::new_equal_to(42, IsarValue::String(Some("foo".to_string())), true)
                    .get_lower_upper(),
                (
                    &IsarValue::String(Some("foo".to_string())),
                    &IsarValue::String(Some("foo".to_string()))
                )
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(
                FilterCondition::new_equal_to(0, IsarValue::Bool(Some(true)), false).get_values(),
                vec![IsarValue::Bool(Some(true)), IsarValue::Bool(Some(true))]
            );
            assert_eq!(
                FilterCondition::new_equal_to(1, IsarValue::Integer(2), false).get_values(),
                vec![IsarValue::Integer(2), IsarValue::Integer(2)]
            );
            assert_eq!(
                FilterCondition::new_equal_to(42, IsarValue::String(Some("foo".to_string())), true)
                    .get_values(),
                vec![
                    IsarValue::String(Some("foo".to_string())),
                    IsarValue::String(Some("foo".to_string()))
                ]
            );
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(
                FilterCondition::new_equal_to(0, IsarValue::Bool(Some(true)), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_equal_to(1, IsarValue::Integer(2), false).get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_equal_to(42, IsarValue::String(Some("foo".to_string())), true)
                    .get_case_sensitive(),
                true
            );
            assert_eq!(
                FilterCondition::new_equal_to(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    false
                )
                .get_case_sensitive(),
                false
            );
        }
    }

    mod greater_than {
        use super::*;

        #[test]
        fn test_new_greater_than() {
            assert_eq!(
                FilterCondition::new_greater_than(0, IsarValue::Bool(Some(true)), false),
                FilterCondition::new_false()
            );
            assert_eq!(
                FilterCondition::new_greater_than(1, IsarValue::Integer(2), false),
                FilterCondition {
                    property_index: 1,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Integer(3), IsarValue::Integer(i64::MAX)],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_greater_than(2, IsarValue::Integer(i64::MAX), false),
                FilterCondition::new_false()
            );
            assert_eq!(
                FilterCondition::new_greater_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                ),
                FilterCondition {
                    property_index: 42,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::String(Some("fop".to_string())),
                        IsarValue::String(Some("\u{10ffff}".to_string()))
                    ],
                    case_sensitive: true,
                }
            );
            assert_eq!(
                FilterCondition::new_greater_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    false
                ),
                FilterCondition {
                    property_index: 42,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::String(Some("fop".to_string())),
                        IsarValue::String(Some("\u{10ffff}".to_string()))
                    ],
                    case_sensitive: false,
                }
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(
                FilterCondition::new_greater_than(0, IsarValue::Bool(Some(true)), false)
                    .get_property_index(),
                u32::MAX
            );
            assert_eq!(
                FilterCondition::new_greater_than(1, IsarValue::Integer(2), false)
                    .get_property_index(),
                1
            );
            assert_eq!(
                FilterCondition::new_greater_than(2, IsarValue::Integer(i64::MAX), false)
                    .get_property_index(),
                u32::MAX
            );
            assert_eq!(
                FilterCondition::new_greater_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_property_index(),
                42
            );
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_greater_than(0, IsarValue::Bool(Some(true)), false)
                    .get_condition_type(),
                ConditionType::False,
            );
            assert_eq!(
                FilterCondition::new_greater_than(1, IsarValue::Integer(2), false)
                    .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_greater_than(2, IsarValue::Integer(i64::MAX), false)
                    .get_condition_type(),
                ConditionType::False
            );
            assert_eq!(
                FilterCondition::new_greater_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_condition_type(),
                ConditionType::Between
            );
        }

        #[test]
        fn test_get_lower_upper() {
            assert_eq!(
                FilterCondition::new_greater_than(0, IsarValue::Bool(Some(false)), false)
                    .get_lower_upper(),
                (&IsarValue::Bool(Some(true)), &IsarValue::Bool(Some(true)),)
            );
            assert_eq!(
                FilterCondition::new_greater_than(1, IsarValue::Integer(2), false)
                    .get_lower_upper(),
                (&IsarValue::Integer(3), &IsarValue::Integer(i64::MAX))
            );
            assert_eq!(
                FilterCondition::new_greater_than(2, IsarValue::Integer(i64::MAX - 1), false)
                    .get_lower_upper(),
                (&IsarValue::Integer(i64::MAX), &IsarValue::Integer(i64::MAX),)
            );
            assert_eq!(
                FilterCondition::new_greater_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_lower_upper(),
                (
                    &IsarValue::String(Some("fop".to_string())),
                    &IsarValue::String(Some("\u{10ffff}".to_string())),
                )
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(
                FilterCondition::new_greater_than(0, IsarValue::Bool(Some(true)), false)
                    .get_values(),
                vec![]
            );
            assert_eq!(
                FilterCondition::new_greater_than(1, IsarValue::Integer(2), false).get_values(),
                vec![IsarValue::Integer(3), IsarValue::Integer(i64::MAX)]
            );
            assert_eq!(
                FilterCondition::new_greater_than(2, IsarValue::Integer(i64::MAX), false)
                    .get_values(),
                vec![]
            );
            assert_eq!(
                FilterCondition::new_greater_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_values(),
                vec![
                    IsarValue::String(Some("fop".to_string())),
                    IsarValue::String(Some("\u{10ffff}".to_string())),
                ]
            );
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(
                FilterCondition::new_greater_than(0, IsarValue::Bool(Some(true)), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_greater_than(1, IsarValue::Integer(2), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_greater_than(2, IsarValue::Integer(i64::MAX), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_greater_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_case_sensitive(),
                true
            );
            assert_eq!(
                FilterCondition::new_greater_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    false
                )
                .get_case_sensitive(),
                false
            );
        }
    }

    mod greater_than_equal {
        use super::*;

        #[test]
        fn test_new_greater_than_equal() {
            assert_eq!(
                FilterCondition::new_greater_than_equal(0, IsarValue::Bool(Some(true)), false),
                FilterCondition {
                    property_index: 0,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Bool(Some(true)); 2],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(0, IsarValue::Bool(None), false),
                FilterCondition::new_true()
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(1, IsarValue::Integer(2), false),
                FilterCondition {
                    property_index: 1,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Integer(2), IsarValue::Integer(i64::MAX)],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(2, IsarValue::Integer(i64::MAX), false),
                FilterCondition {
                    property_index: 2,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Integer(i64::MAX); 2],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                ),
                FilterCondition {
                    property_index: 42,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::String(Some("foo".to_string())),
                        IsarValue::String(Some("\u{10ffff}".to_string()))
                    ],
                    case_sensitive: true,
                }
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    false
                ),
                FilterCondition {
                    property_index: 42,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::String(Some("foo".to_string())),
                        IsarValue::String(Some("\u{10ffff}".to_string()))
                    ],
                    case_sensitive: false,
                }
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(
                FilterCondition::new_greater_than_equal(0, IsarValue::Bool(Some(true)), false)
                    .get_property_index(),
                0
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(1, IsarValue::Integer(2), false)
                    .get_property_index(),
                1
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(1, IsarValue::Integer(i64::MAX), false)
                    .get_property_index(),
                1
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_property_index(),
                42
            );
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_greater_than_equal(0, IsarValue::Bool(Some(true)), false)
                    .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(1, IsarValue::Integer(2), false)
                    .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(2, IsarValue::Integer(i64::MAX), false)
                    .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_condition_type(),
                ConditionType::Between
            );
        }

        #[test]
        fn test_get_lower_upper() {
            assert_eq!(
                FilterCondition::new_greater_than_equal(0, IsarValue::Bool(Some(false)), false)
                    .get_lower_upper(),
                (&IsarValue::Bool(Some(false)), &IsarValue::Bool(Some(true)),)
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(1, IsarValue::Integer(2), false)
                    .get_lower_upper(),
                (&IsarValue::Integer(2), &IsarValue::Integer(i64::MAX))
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(1, IsarValue::Integer(i64::MAX - 1), false)
                    .get_lower_upper(),
                (
                    &IsarValue::Integer(i64::MAX - 1),
                    &IsarValue::Integer(i64::MAX),
                )
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_lower_upper(),
                (
                    &IsarValue::String(Some("foo".to_string())),
                    &IsarValue::String(Some("\u{10ffff}".to_string())),
                )
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(
                FilterCondition::new_greater_than_equal(0, IsarValue::Bool(Some(true)), false)
                    .get_values(),
                vec![IsarValue::Bool(Some(true)); 2]
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(1, IsarValue::Integer(2), false)
                    .get_values(),
                vec![IsarValue::Integer(2), IsarValue::Integer(i64::MAX)]
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(2, IsarValue::Integer(i64::MAX), false)
                    .get_values(),
                vec![IsarValue::Integer(i64::MAX); 2]
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_values(),
                vec![
                    IsarValue::String(Some("foo".to_string())),
                    IsarValue::String(Some("\u{10ffff}".to_string())),
                ]
            );
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(
                FilterCondition::new_greater_than_equal(0, IsarValue::Bool(Some(true)), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(1, IsarValue::Integer(2), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(2, IsarValue::Integer(i64::MAX), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_case_sensitive(),
                true
            );
            assert_eq!(
                FilterCondition::new_greater_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    false
                )
                .get_case_sensitive(),
                false
            );
        }
    }

    mod less_than {
        use super::*;

        #[test]
        fn test_new_less_than() {
            assert_eq!(
                FilterCondition::new_less_than(0, IsarValue::Bool(Some(true)), false),
                FilterCondition {
                    property_index: 0,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Bool(None), IsarValue::Bool(Some(false))],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_less_than(0, IsarValue::Bool(None), false),
                FilterCondition::new_false()
            );
            assert_eq!(
                FilterCondition::new_less_than(1, IsarValue::Integer(2), false),
                FilterCondition {
                    property_index: 1,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Integer(i64::MIN), IsarValue::Integer(1)],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_less_than(2, IsarValue::Integer(i64::MIN), false),
                FilterCondition::new_false()
            );
            assert_eq!(
                FilterCondition::new_less_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                ),
                FilterCondition {
                    property_index: 42,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::String(None),
                        IsarValue::String(Some("fon".to_string()))
                    ],
                    case_sensitive: true,
                }
            );
            assert_eq!(
                FilterCondition::new_less_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    false
                ),
                FilterCondition {
                    property_index: 42,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::String(None),
                        IsarValue::String(Some("fon".to_string()))
                    ],
                    case_sensitive: false,
                }
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(
                FilterCondition::new_less_than(0, IsarValue::Bool(Some(true)), false)
                    .get_property_index(),
                0
            );
            assert_eq!(
                FilterCondition::new_less_than(0, IsarValue::Bool(None), false)
                    .get_property_index(),
                u32::MAX
            );
            assert_eq!(
                FilterCondition::new_less_than(1, IsarValue::Integer(2), false)
                    .get_property_index(),
                1
            );
            assert_eq!(
                FilterCondition::new_less_than(2, IsarValue::Integer(i64::MAX), false)
                    .get_property_index(),
                2
            );
            assert_eq!(
                FilterCondition::new_less_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_property_index(),
                42
            );
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_less_than(0, IsarValue::Bool(Some(true)), false)
                    .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_less_than(0, IsarValue::Bool(None), false)
                    .get_condition_type(),
                ConditionType::False
            );
            assert_eq!(
                FilterCondition::new_less_than(1, IsarValue::Integer(2), false)
                    .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_less_than(2, IsarValue::Integer(i64::MAX), false)
                    .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_less_than(2, IsarValue::Integer(i64::MIN), false)
                    .get_condition_type(),
                ConditionType::False
            );
            assert_eq!(
                FilterCondition::new_less_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_condition_type(),
                ConditionType::Between
            );
        }

        #[test]
        fn test_get_lower_upper() {
            assert_eq!(
                FilterCondition::new_less_than(0, IsarValue::Bool(Some(false)), false)
                    .get_lower_upper(),
                (&IsarValue::Bool(None), &IsarValue::Bool(None))
            );
            assert_eq!(
                FilterCondition::new_less_than(1, IsarValue::Integer(2), false).get_lower_upper(),
                (&IsarValue::Integer(i64::MIN), &IsarValue::Integer(1))
            );
            assert_eq!(
                FilterCondition::new_less_than(2, IsarValue::Integer(i64::MIN + 1), false)
                    .get_lower_upper(),
                (&IsarValue::Integer(i64::MIN), &IsarValue::Integer(i64::MIN),)
            );
            assert_eq!(
                FilterCondition::new_less_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_lower_upper(),
                (
                    &IsarValue::String(None),
                    &IsarValue::String(Some("fon".to_string())),
                )
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(
                FilterCondition::new_less_than(0, IsarValue::Bool(Some(true)), false).get_values(),
                vec![IsarValue::Bool(None), IsarValue::Bool(Some(false))]
            );
            assert_eq!(
                FilterCondition::new_less_than(0, IsarValue::Bool(None), false).get_values(),
                vec![]
            );
            assert_eq!(
                FilterCondition::new_less_than(1, IsarValue::Integer(2), false).get_values(),
                vec![IsarValue::Integer(i64::MIN), IsarValue::Integer(1)]
            );
            assert_eq!(
                FilterCondition::new_less_than(2, IsarValue::Integer(i64::MAX), false).get_values(),
                vec![
                    IsarValue::Integer(i64::MIN),
                    IsarValue::Integer(i64::MAX - 1),
                ]
            );
            assert_eq!(
                FilterCondition::new_less_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_values(),
                vec![
                    IsarValue::String(None),
                    IsarValue::String(Some("fon".to_string())),
                ]
            );
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(
                FilterCondition::new_less_than(0, IsarValue::Bool(Some(true)), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_less_than(1, IsarValue::Integer(2), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_less_than(2, IsarValue::Integer(i64::MAX), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_less_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_case_sensitive(),
                true
            );
            assert_eq!(
                FilterCondition::new_less_than(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    false
                )
                .get_case_sensitive(),
                false
            );
        }
    }

    mod less_than_equal {
        use super::*;

        #[test]
        fn test_new_less_than_equal() {
            assert_eq!(
                FilterCondition::new_less_than_equal(0, IsarValue::Bool(Some(true)), false),
                FilterCondition::new_true()
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(0, IsarValue::Bool(None), false),
                FilterCondition {
                    property_index: 0,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Bool(None); 2],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(1, IsarValue::Integer(2), false),
                FilterCondition {
                    property_index: 1,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Integer(i64::MIN), IsarValue::Integer(2)],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(2, IsarValue::Integer(i64::MIN), false),
                FilterCondition {
                    property_index: 2,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Integer(i64::MIN); 2],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                ),
                FilterCondition {
                    property_index: 42,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::String(None),
                        IsarValue::String(Some("foo".to_string())),
                    ],
                    case_sensitive: true
                }
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    false
                ),
                FilterCondition {
                    property_index: 42,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::String(None),
                        IsarValue::String(Some("foo".to_string())),
                    ],
                    case_sensitive: false
                }
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(
                FilterCondition::new_less_than_equal(0, IsarValue::Bool(Some(true)), false)
                    .get_property_index(),
                u32::MAX
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(0, IsarValue::Bool(None), false)
                    .get_property_index(),
                0
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(1, IsarValue::Integer(2), false)
                    .get_property_index(),
                1
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(2, IsarValue::Integer(i64::MAX), false)
                    .get_property_index(),
                u32::MAX
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_property_index(),
                42
            );
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_less_than_equal(0, IsarValue::Bool(Some(true)), false)
                    .get_condition_type(),
                ConditionType::True
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(0, IsarValue::Bool(None), false)
                    .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(1, IsarValue::Integer(2), false)
                    .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(2, IsarValue::Integer(i64::MAX), false)
                    .get_condition_type(),
                ConditionType::True
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(2, IsarValue::Integer(i64::MIN), false)
                    .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_condition_type(),
                ConditionType::Between
            );
        }

        #[test]
        fn test_get_lower_upper() {
            assert_eq!(
                FilterCondition::new_less_than_equal(0, IsarValue::Bool(Some(false)), false)
                    .get_lower_upper(),
                (&IsarValue::Bool(None), &IsarValue::Bool(Some(false)))
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(1, IsarValue::Integer(2), false)
                    .get_lower_upper(),
                (&IsarValue::Integer(i64::MIN), &IsarValue::Integer(2))
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(2, IsarValue::Integer(i64::MIN + 1), false)
                    .get_lower_upper(),
                (
                    &IsarValue::Integer(i64::MIN),
                    &IsarValue::Integer(i64::MIN + 1),
                )
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_lower_upper(),
                (
                    &IsarValue::String(None),
                    &IsarValue::String(Some("foo".to_string())),
                )
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(
                FilterCondition::new_less_than_equal(0, IsarValue::Bool(Some(true)), false)
                    .get_values(),
                vec![]
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(0, IsarValue::Bool(None), false).get_values(),
                vec![IsarValue::Bool(None); 2]
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(1, IsarValue::Integer(2), false).get_values(),
                vec![IsarValue::Integer(i64::MIN), IsarValue::Integer(2)]
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(2, IsarValue::Integer(i64::MAX), false)
                    .get_values(),
                vec![]
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_values(),
                vec![
                    IsarValue::String(None),
                    IsarValue::String(Some("foo".to_string())),
                ]
            );
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(
                FilterCondition::new_less_than_equal(0, IsarValue::Bool(Some(true)), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(1, IsarValue::Integer(2), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(2, IsarValue::Integer(i64::MAX), false)
                    .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    true
                )
                .get_case_sensitive(),
                true
            );
            assert_eq!(
                FilterCondition::new_less_than_equal(
                    42,
                    IsarValue::String(Some("foo".to_string())),
                    false
                )
                .get_case_sensitive(),
                false
            );
        }
    }

    mod between {
        use super::*;

        #[test]
        fn test_new_between() {
            assert_eq!(
                FilterCondition::new_between(
                    0,
                    IsarValue::Bool(Some(false)),
                    IsarValue::Bool(Some(true)),
                    false
                ),
                FilterCondition {
                    property_index: 0,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Bool(Some(false)), IsarValue::Bool(Some(true)),],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_between(
                    1,
                    IsarValue::Integer(1),
                    IsarValue::Integer(2),
                    false
                ),
                FilterCondition {
                    property_index: 1,
                    condition_type: ConditionType::Between,
                    values: vec![IsarValue::Integer(1), IsarValue::Integer(2)],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_between(
                    1,
                    IsarValue::Integer(2),
                    IsarValue::Integer(1),
                    false
                ),
                FilterCondition::new_false()
            );
            assert_eq!(
                FilterCondition::new_between(
                    2,
                    IsarValue::Integer(i64::MIN + 1),
                    IsarValue::Integer(i64::MAX),
                    false
                ),
                FilterCondition {
                    property_index: 2,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::Integer(i64::MIN + 1),
                        IsarValue::Integer(i64::MAX)
                    ],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_between(
                    3,
                    IsarValue::String(Some("bar".to_string())),
                    IsarValue::String(Some("foo".to_string())),
                    false
                ),
                FilterCondition {
                    property_index: 3,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::String(Some("bar".to_string())),
                        IsarValue::String(Some("foo".to_string())),
                    ],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_between(
                    3,
                    IsarValue::String(Some("foo".to_string())),
                    IsarValue::String(Some("bar".to_string())),
                    false
                ),
                FilterCondition::new_false()
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(
                FilterCondition::new_between(
                    0,
                    IsarValue::Bool(Some(false)),
                    IsarValue::Bool(Some(true)),
                    false
                )
                .get_property_index(),
                0
            );
            assert_eq!(
                FilterCondition::new_between(
                    1,
                    IsarValue::Integer(1),
                    IsarValue::Integer(2),
                    false
                )
                .get_property_index(),
                1
            );
            assert_eq!(
                FilterCondition::new_between(
                    2,
                    IsarValue::Integer(i64::MIN + 1),
                    IsarValue::Integer(i64::MAX),
                    false
                )
                .get_property_index(),
                2
            );
            assert_eq!(
                FilterCondition::new_between(
                    3,
                    IsarValue::String(Some("bar".to_string())),
                    IsarValue::String(Some("foo".to_string())),
                    false
                )
                .get_property_index(),
                3
            );
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_between(
                    0,
                    IsarValue::Bool(Some(false)),
                    IsarValue::Bool(Some(true)),
                    false
                )
                .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_between(
                    1,
                    IsarValue::Integer(1),
                    IsarValue::Integer(2),
                    false
                )
                .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_between(
                    2,
                    IsarValue::Integer(i64::MIN + 1),
                    IsarValue::Integer(i64::MAX),
                    false
                )
                .get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_between(
                    3,
                    IsarValue::String(Some("bar".to_string())),
                    IsarValue::String(Some("foo".to_string())),
                    false
                )
                .get_condition_type(),
                ConditionType::Between
            );
        }

        #[test]
        fn get_lower_upper() {
            assert_eq!(
                FilterCondition::new_between(
                    0,
                    IsarValue::Bool(Some(false)),
                    IsarValue::Bool(Some(true)),
                    false
                )
                .get_lower_upper(),
                (&IsarValue::Bool(Some(false)), &IsarValue::Bool(Some(true)),)
            );
            assert_eq!(
                FilterCondition::new_between(
                    1,
                    IsarValue::Integer(1),
                    IsarValue::Integer(2),
                    false
                )
                .get_lower_upper(),
                (&IsarValue::Integer(1), &IsarValue::Integer(2),)
            );
            assert_eq!(
                FilterCondition::new_between(
                    2,
                    IsarValue::Integer(i64::MIN + 1),
                    IsarValue::Integer(i64::MAX),
                    false
                )
                .get_lower_upper(),
                (
                    &IsarValue::Integer(i64::MIN + 1),
                    &IsarValue::Integer(i64::MAX),
                )
            );
            assert_eq!(
                FilterCondition::new_between(
                    3,
                    IsarValue::String(Some("bar".to_string())),
                    IsarValue::String(Some("foo".to_string())),
                    false
                )
                .get_lower_upper(),
                (
                    &IsarValue::String(Some("bar".to_string())),
                    &IsarValue::String(Some("foo".to_string())),
                )
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(
                FilterCondition::new_between(
                    0,
                    IsarValue::Bool(Some(false)),
                    IsarValue::Bool(Some(true)),
                    false
                )
                .get_values(),
                vec![IsarValue::Bool(Some(false)), IsarValue::Bool(Some(true)),]
            );
            assert_eq!(
                FilterCondition::new_between(
                    1,
                    IsarValue::Integer(1),
                    IsarValue::Integer(2),
                    false
                )
                .get_values(),
                vec![IsarValue::Integer(1), IsarValue::Integer(2)]
            );
            assert_eq!(
                FilterCondition::new_between(
                    2,
                    IsarValue::Integer(i64::MIN + 1),
                    IsarValue::Integer(i64::MAX),
                    false
                )
                .get_values(),
                vec![
                    IsarValue::Integer(i64::MIN + 1),
                    IsarValue::Integer(i64::MAX),
                ]
            );
            assert_eq!(
                FilterCondition::new_between(
                    3,
                    IsarValue::String(Some("bar".to_string())),
                    IsarValue::String(Some("foo".to_string())),
                    false
                )
                .get_values(),
                vec![
                    IsarValue::String(Some("bar".to_string())),
                    IsarValue::String(Some("foo".to_string())),
                ]
            );
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(
                FilterCondition::new_between(
                    0,
                    IsarValue::Bool(Some(false)),
                    IsarValue::Bool(Some(true)),
                    false
                )
                .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_between(
                    1,
                    IsarValue::Integer(1),
                    IsarValue::Integer(2),
                    false
                )
                .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_between(
                    2,
                    IsarValue::Integer(i64::MIN + 1),
                    IsarValue::Integer(i64::MAX),
                    false
                )
                .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_between(
                    3,
                    IsarValue::String(Some("bar".to_string())),
                    IsarValue::String(Some("foo".to_string())),
                    false
                )
                .get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_between(
                    3,
                    IsarValue::String(Some("doe".to_string())),
                    IsarValue::String(Some("john".to_string())),
                    true
                )
                .get_case_sensitive(),
                true
            );
        }
    }

    mod string_starts_with {
        use super::*;

        #[test]
        fn test_new_string_starts_with() {
            assert_eq!(
                FilterCondition::new_string_starts_with(0, "foo", true),
                FilterCondition {
                    property_index: 0,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::String(Some("foo".to_string())),
                        IsarValue::String(Some("foo\u{10ffff}".to_string()))
                    ],
                    case_sensitive: true,
                }
            );
            assert_eq!(
                FilterCondition::new_string_starts_with(1, "bar", false),
                FilterCondition {
                    property_index: 1,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::String(Some("bar".to_string())),
                        IsarValue::String(Some("bar\u{10ffff}".to_string()))
                    ],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_string_starts_with(2, "", false),
                FilterCondition {
                    property_index: 2,
                    condition_type: ConditionType::Between,
                    values: vec![
                        IsarValue::String(Some("".to_string())),
                        IsarValue::String(Some("\u{10ffff}".to_string()))
                    ],
                    case_sensitive: false,
                }
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(
                FilterCondition::new_string_starts_with(0, "foo", true).get_property_index(),
                0
            );
            assert_eq!(
                FilterCondition::new_string_starts_with(1, "bar", false).get_property_index(),
                1
            );
            assert_eq!(
                FilterCondition::new_string_starts_with(2, "", false).get_property_index(),
                2
            );
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_string_starts_with(0, "foo", true).get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_string_starts_with(1, "bar", false).get_condition_type(),
                ConditionType::Between
            );
            assert_eq!(
                FilterCondition::new_string_starts_with(2, "", false).get_condition_type(),
                ConditionType::Between
            );
        }

        #[test]
        fn test_get_lower_upper() {
            assert_eq!(
                FilterCondition::new_string_starts_with(0, "foo", true).get_lower_upper(),
                (
                    &IsarValue::String(Some("foo".to_string())),
                    &IsarValue::String(Some("foo\u{10ffff}".to_string())),
                )
            );
            assert_eq!(
                FilterCondition::new_string_starts_with(1, "bar", false).get_lower_upper(),
                (
                    &IsarValue::String(Some("bar".to_string())),
                    &IsarValue::String(Some("bar\u{10ffff}".to_string())),
                )
            );
            assert_eq!(
                FilterCondition::new_string_starts_with(2, "", false).get_lower_upper(),
                (
                    &IsarValue::String(Some("".to_string())),
                    &IsarValue::String(Some("\u{10ffff}".to_string())),
                )
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(
                FilterCondition::new_string_starts_with(0, "foo", true).get_values(),
                vec![
                    IsarValue::String(Some("foo".to_string())),
                    IsarValue::String(Some("foo\u{10ffff}".to_string())),
                ]
            );
            assert_eq!(
                FilterCondition::new_string_starts_with(1, "bar", false).get_values(),
                vec![
                    IsarValue::String(Some("bar".to_string())),
                    IsarValue::String(Some("bar\u{10ffff}".to_string())),
                ]
            );
            assert_eq!(
                FilterCondition::new_string_starts_with(2, "", false).get_values(),
                vec![
                    IsarValue::String(Some("".to_string())),
                    IsarValue::String(Some("\u{10ffff}".to_string())),
                ]
            );
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(
                FilterCondition::new_string_starts_with(0, "foo", true).get_case_sensitive(),
                true
            );
            assert_eq!(
                FilterCondition::new_string_starts_with(1, "bar", false).get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_string_starts_with(2, "", false).get_case_sensitive(),
                false
            );
        }
    }

    mod string_ends_with {
        use super::*;

        #[test]
        fn test_new_string_ends_with() {
            assert_eq!(
                FilterCondition::new_string_ends_with(0, "foo", true),
                FilterCondition {
                    property_index: 0,
                    condition_type: ConditionType::StringEndsWith,
                    values: vec![IsarValue::String(Some("foo".to_string())),],
                    case_sensitive: true,
                }
            );
            assert_eq!(
                FilterCondition::new_string_ends_with(1, "bar", false),
                FilterCondition {
                    property_index: 1,
                    condition_type: ConditionType::StringEndsWith,
                    values: vec![IsarValue::String(Some("bar".to_string())),],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_string_ends_with(2, "", false),
                FilterCondition {
                    property_index: 2,
                    condition_type: ConditionType::StringEndsWith,
                    values: vec![IsarValue::String(Some("".to_string())),],
                    case_sensitive: false,
                }
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(
                FilterCondition::new_string_ends_with(0, "foo", true).get_property_index(),
                0
            );
            assert_eq!(
                FilterCondition::new_string_ends_with(1, "bar", false).get_property_index(),
                1
            );
            assert_eq!(
                FilterCondition::new_string_ends_with(2, "", false).get_property_index(),
                2
            );
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_string_ends_with(0, "foo", true).get_condition_type(),
                ConditionType::StringEndsWith
            );
            assert_eq!(
                FilterCondition::new_string_ends_with(1, "bar", false).get_condition_type(),
                ConditionType::StringEndsWith
            );
            assert_eq!(
                FilterCondition::new_string_ends_with(2, "", false).get_condition_type(),
                ConditionType::StringEndsWith
            );
        }

        #[test]
        fn test_get_value() {
            assert_eq!(
                FilterCondition::new_string_ends_with(0, "foo", true).get_value(),
                &IsarValue::String(Some("foo".to_string()))
            );
            assert_eq!(
                FilterCondition::new_string_ends_with(1, "bar", false).get_value(),
                &IsarValue::String(Some("bar".to_string()))
            );
            assert_eq!(
                FilterCondition::new_string_ends_with(2, "", false).get_value(),
                &IsarValue::String(Some("".to_string()))
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(
                FilterCondition::new_string_ends_with(0, "foo", true).get_values(),
                vec![IsarValue::String(Some("foo".to_string()))]
            );
            assert_eq!(
                FilterCondition::new_string_ends_with(1, "bar", false).get_values(),
                vec![IsarValue::String(Some("bar".to_string()))]
            );
            assert_eq!(
                FilterCondition::new_string_ends_with(2, "", false).get_values(),
                vec![IsarValue::String(Some("".to_string()))]
            );
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(
                FilterCondition::new_string_ends_with(0, "foo", true).get_case_sensitive(),
                true
            );
            assert_eq!(
                FilterCondition::new_string_ends_with(1, "bar", false).get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_string_ends_with(2, "", false).get_case_sensitive(),
                false
            );
        }
    }

    mod string_contains {
        use super::*;

        #[test]
        fn test_new_string_contains() {
            assert_eq!(
                FilterCondition::new_string_contains(0, "foo", true),
                FilterCondition {
                    property_index: 0,
                    condition_type: ConditionType::StringContains,
                    values: vec![IsarValue::String(Some("foo".to_string())),],
                    case_sensitive: true,
                }
            );
            assert_eq!(
                FilterCondition::new_string_contains(1, "bar", false),
                FilterCondition {
                    property_index: 1,
                    condition_type: ConditionType::StringContains,
                    values: vec![IsarValue::String(Some("bar".to_string())),],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_string_contains(2, "", false),
                FilterCondition {
                    property_index: 2,
                    condition_type: ConditionType::StringContains,
                    values: vec![IsarValue::String(Some("".to_string())),],
                    case_sensitive: false,
                }
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(
                FilterCondition::new_string_contains(0, "foo", true).get_property_index(),
                0
            );
            assert_eq!(
                FilterCondition::new_string_contains(1, "bar", false).get_property_index(),
                1
            );
            assert_eq!(
                FilterCondition::new_string_contains(2, "", false).get_property_index(),
                2
            );
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_string_contains(0, "foo", true).get_condition_type(),
                ConditionType::StringContains
            );
            assert_eq!(
                FilterCondition::new_string_contains(1, "bar", false).get_condition_type(),
                ConditionType::StringContains
            );
            assert_eq!(
                FilterCondition::new_string_contains(2, "", false).get_condition_type(),
                ConditionType::StringContains
            );
        }

        #[test]
        fn test_get_value() {
            assert_eq!(
                FilterCondition::new_string_contains(0, "foo", true).get_value(),
                &IsarValue::String(Some("foo".to_string()))
            );
            assert_eq!(
                FilterCondition::new_string_contains(1, "bar", false).get_value(),
                &IsarValue::String(Some("bar".to_string()))
            );
            assert_eq!(
                FilterCondition::new_string_contains(2, "", false).get_value(),
                &IsarValue::String(Some("".to_string()))
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(
                FilterCondition::new_string_contains(0, "foo", true).get_values(),
                vec![IsarValue::String(Some("foo".to_string()))]
            );
            assert_eq!(
                FilterCondition::new_string_contains(1, "bar", false).get_values(),
                vec![IsarValue::String(Some("bar".to_string()))]
            );
            assert_eq!(
                FilterCondition::new_string_contains(2, "", false).get_values(),
                vec![IsarValue::String(Some("".to_string()))]
            );
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(
                FilterCondition::new_string_contains(0, "foo", true).get_case_sensitive(),
                true
            );
            assert_eq!(
                FilterCondition::new_string_contains(1, "bar", false).get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_string_contains(2, "", false).get_case_sensitive(),
                false
            );
        }
    }

    mod string_matches {
        use super::*;

        #[test]
        fn test_new_string_matches() {
            assert_eq!(
                FilterCondition::new_string_matches(0, "foo", true),
                FilterCondition {
                    property_index: 0,
                    condition_type: ConditionType::StringMatches,
                    values: vec![IsarValue::String(Some("foo".to_string())),],
                    case_sensitive: true,
                }
            );
            assert_eq!(
                FilterCondition::new_string_matches(1, "bar", false),
                FilterCondition {
                    property_index: 1,
                    condition_type: ConditionType::StringMatches,
                    values: vec![IsarValue::String(Some("bar".to_string())),],
                    case_sensitive: false,
                }
            );
            assert_eq!(
                FilterCondition::new_string_matches(2, "", false),
                FilterCondition {
                    property_index: 2,
                    condition_type: ConditionType::StringMatches,
                    values: vec![IsarValue::String(Some("".to_string())),],
                    case_sensitive: false,
                }
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(
                FilterCondition::new_string_matches(0, "foo", true).get_property_index(),
                0
            );
            assert_eq!(
                FilterCondition::new_string_matches(1, "bar", false).get_property_index(),
                1
            );
            assert_eq!(
                FilterCondition::new_string_matches(2, "", false).get_property_index(),
                2
            );
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_string_matches(0, "foo", true).get_condition_type(),
                ConditionType::StringMatches
            );
            assert_eq!(
                FilterCondition::new_string_matches(1, "bar", false).get_condition_type(),
                ConditionType::StringMatches
            );
            assert_eq!(
                FilterCondition::new_string_matches(2, "", false).get_condition_type(),
                ConditionType::StringMatches
            );
        }

        #[test]
        fn test_get_value() {
            assert_eq!(
                FilterCondition::new_string_matches(0, "foo", true).get_value(),
                &IsarValue::String(Some("foo".to_string()))
            );
            assert_eq!(
                FilterCondition::new_string_matches(1, "bar", false).get_value(),
                &IsarValue::String(Some("bar".to_string()))
            );
            assert_eq!(
                FilterCondition::new_string_matches(2, "", false).get_value(),
                &IsarValue::String(Some("".to_string()))
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(
                FilterCondition::new_string_matches(0, "foo", true).get_values(),
                vec![IsarValue::String(Some("foo".to_string()))]
            );
            assert_eq!(
                FilterCondition::new_string_matches(1, "bar", false).get_values(),
                vec![IsarValue::String(Some("bar".to_string()))]
            );
            assert_eq!(
                FilterCondition::new_string_matches(2, "", false).get_values(),
                vec![IsarValue::String(Some("".to_string()))]
            );
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(
                FilterCondition::new_string_matches(0, "foo", true).get_case_sensitive(),
                true
            );
            assert_eq!(
                FilterCondition::new_string_matches(1, "bar", false).get_case_sensitive(),
                false
            );
            assert_eq!(
                FilterCondition::new_string_matches(2, "", false).get_case_sensitive(),
                false
            );
        }
    }

    mod true_type {
        use super::*;

        #[test]
        fn test_new_true() {
            assert_eq!(
                FilterCondition::new_true(),
                FilterCondition {
                    property_index: u32::MAX,
                    condition_type: ConditionType::True,
                    values: vec![],
                    case_sensitive: false,
                }
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(FilterCondition::new_true().get_property_index(), u32::MAX);
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_true().get_condition_type(),
                ConditionType::True
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(FilterCondition::new_true().get_values(), vec![]);
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(FilterCondition::new_true().get_case_sensitive(), false);
        }
    }

    mod false_type {
        use super::*;

        #[test]
        fn test_new_false() {
            assert_eq!(
                FilterCondition::new_false(),
                FilterCondition {
                    property_index: u32::MAX,
                    condition_type: ConditionType::False,
                    values: vec![],
                    case_sensitive: false,
                }
            );
        }

        #[test]
        fn test_get_property() {
            assert_eq!(FilterCondition::new_false().get_property_index(), u32::MAX);
        }

        #[test]
        fn test_get_condition_type() {
            assert_eq!(
                FilterCondition::new_false().get_condition_type(),
                ConditionType::False
            );
        }

        #[test]
        fn test_get_values() {
            assert_eq!(FilterCondition::new_false().get_values(), vec![]);
        }

        #[test]
        fn test_get_case_sensitive() {
            assert_eq!(FilterCondition::new_false().get_case_sensitive(), false);
        }
    }
}
