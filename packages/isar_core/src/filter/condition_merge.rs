use super::filter_condition::{ConditionType, FilterCondition};
use super::filter_group::{FilterGroup, GroupType};
use super::Filter;

impl FilterCondition {
    pub(crate) fn try_merge_and(&self, other: &Self) -> Option<Self> {
        let merged = match (self.get_condition_type(), other.get_condition_type()) {
            (ConditionType::True, _) => other.clone(),
            (_, ConditionType::True) => self.clone(),
            (ConditionType::False, _) => Self::new_false(),
            (_, ConditionType::False) => Self::new_false(),
            (ConditionType::Between, ConditionType::Between) => {
                if self.get_property() != other.get_property()
                    || self.get_case_insensitive() != other.get_case_insensitive()
                {
                    return None;
                }
                let (lower1, upper1) = self.get_lower_upper();
                let (lower2, upper2) = other.get_lower_upper();
                let new_lower = if lower1 > lower2 { lower1 } else { lower2 };
                let new_upper = if upper1 < upper2 { upper1 } else { upper2 };
                Self::new_between(
                    self.get_property(),
                    new_lower.clone(),
                    new_upper.clone(),
                    self.get_case_insensitive(),
                )
            }
            _ => {
                return None;
            }
        };
        Some(merged)
    }

    pub(crate) fn try_merge_or(&self, other: &Self) -> Option<Self> {
        let merged = match (self.get_condition_type(), other.get_condition_type()) {
            (ConditionType::True, _) => Self::new_true(),
            (_, ConditionType::True) => Self::new_true(),
            (ConditionType::False, _) => other.clone(),
            (_, ConditionType::False) => self.clone(),
            (ConditionType::Between, ConditionType::Between) => {
                if self.get_property() != other.get_property()
                    || self.get_case_insensitive() != other.get_case_insensitive()
                {
                    return None;
                }
                let (lower1, upper1) = self.get_lower_upper();
                let (lower2, upper2) = other.get_lower_upper();
                if lower1 <= lower2 && upper1 >= lower2 {
                    let upper = if upper1 > upper2 { upper1 } else { upper2 };
                    Self::new_between(
                        self.get_property(),
                        lower1.clone(),
                        upper.clone(),
                        self.get_case_insensitive(),
                    )
                } else if lower2 <= lower1 && upper2 >= lower1 {
                    let upper = if upper1 > upper2 { upper1 } else { upper2 };
                    Self::new_between(
                        self.get_property(),
                        lower2.clone(),
                        upper.clone(),
                        self.get_case_insensitive(),
                    )
                } else if &upper1.try_increment()? == lower2 {
                    Self::new_between(
                        self.get_property(),
                        lower1.clone(),
                        upper2.clone(),
                        self.get_case_insensitive(),
                    )
                } else if &upper2.try_increment()? == lower1 {
                    Self::new_between(
                        self.get_property(),
                        lower2.clone(),
                        upper1.clone(),
                        self.get_case_insensitive(),
                    )
                } else {
                    return None;
                }
            }
            _ => {
                return None;
            }
        };
        Some(merged)
    }

    pub(crate) fn try_invert(&self) -> Option<Filter> {
        let inverted = match self.get_condition_type() {
            ConditionType::Between => {
                let (lower, upper) = self.get_lower_upper();
                if lower.is_null() {
                    Self::new_greater_than(
                        self.get_property(),
                        upper.clone(),
                        self.get_case_insensitive(),
                    )
                } else if upper.is_max() {
                    Self::new_less_than(
                        self.get_property(),
                        lower.clone(),
                        self.get_case_insensitive(),
                    )
                } else {
                    let lower = Self::new_less_than(
                        self.get_property(),
                        lower.clone(),
                        self.get_case_insensitive(),
                    );
                    let upper = Self::new_greater_than(
                        self.get_property(),
                        upper.clone(),
                        self.get_case_insensitive(),
                    );
                    let group = FilterGroup::new(
                        GroupType::Or,
                        vec![Filter::Condition(lower), Filter::Condition(upper)],
                    );
                    return Some(Filter::Group(group));
                }
            }
            ConditionType::True => Self::new_false(),
            ConditionType::False => Self::new_true(),
            _ => {
                return None;
            }
        };
        Some(Filter::Condition(inverted))
    }
}

#[cfg(test)]
mod tests {
    use crate::filter::filter_value::FilterValue;

    use super::FilterCondition as C;
    use super::*;

    fn b(lower: i64, upper: i64) -> FilterCondition {
        C::new_between(
            0,
            FilterValue::Integer(lower),
            FilterValue::Integer(upper),
            false,
        )
    }

    fn t() -> FilterCondition {
        C::new_true()
    }

    fn f() -> FilterCondition {
        C::new_false()
    }

    #[test]
    fn test_try_merge_and_true_and_true() {
        assert_eq!(t().try_merge_and(&t()), Some(t()));
    }

    #[test]
    fn test_try_merge_and_true_and_false() {
        assert_eq!(t().try_merge_and(&f()), Some(f()));
    }

    #[test]
    fn test_try_merge_and_false_and_true() {
        assert_eq!(f().try_merge_and(&t()), Some(f()));
    }

    #[test]
    fn test_try_merge_and_false_and_false() {
        assert_eq!(f().try_merge_and(&f()), Some(f()));
    }

    #[test]
    fn test_try_merge_and_between_and_true() {
        assert_eq!(b(1, 5).try_merge_and(&t()), Some(b(1, 5)));
    }

    #[test]
    fn test_try_merge_and_between_and_false() {
        assert_eq!(b(1, 5).try_merge_and(&f()), Some(f()));
    }

    #[test]
    fn test_try_merge_and_non_intersecting_ranges() {
        assert_eq!(b(1, 5).try_merge_and(&b(6, 10)), Some(f()));
    }

    #[test]
    fn test_try_merge_and_intersecting_ranges() {
        assert_eq!(b(1, 5).try_merge_and(&b(3, 7)), Some(b(3, 5)));
        assert_eq!(b(3, 7).try_merge_and(&b(1, 5)), Some(b(3, 5)));
        assert_eq!(b(1, 10).try_merge_and(&b(5, 7)), Some(b(5, 7)));
        assert_eq!(b(5, 7).try_merge_and(&b(1, 10)), Some(b(5, 7)));
    }

    #[test]
    fn test_try_merge_and_overlapping_ranges() {
        assert_eq!(b(1, 7).try_merge_and(&b(3, 5)), Some(b(3, 5)));
        assert_eq!(b(3, 5).try_merge_and(&b(1, 7)), Some(b(3, 5)));
        assert_eq!(b(1, 10).try_merge_and(&b(3, 7)), Some(b(3, 7)));
        assert_eq!(b(3, 7).try_merge_and(&b(1, 10)), Some(b(3, 7)));
    }

    #[test]
    fn test_try_merge_and_identical_ranges() {
        assert_eq!(b(1, 5).try_merge_and(&b(1, 5)), Some(b(1, 5)));
    }

    #[test]
    fn test_try_merge_and_different_properties() {
        let b1 = C::new_between(0, FilterValue::Integer(1), FilterValue::Integer(5), false);
        let b2 = C::new_between(1, FilterValue::Integer(1), FilterValue::Integer(5), false);
        assert_eq!(b1.try_merge_and(&b2), None);
    }

    #[test]
    fn test_try_merge_and_different_case_sensitivity() {
        let b1 = C::new_between(0, FilterValue::Integer(1), FilterValue::Integer(5), false);
        let b2 = C::new_between(0, FilterValue::Integer(1), FilterValue::Integer(5), true);
        assert_eq!(b1.try_merge_and(&b2), None);
    }

    #[test]
    fn test_try_merge_or_true_and_true() {
        assert_eq!(t().try_merge_or(&t()), Some(t()));
    }

    #[test]
    fn test_try_merge_or_true_and_false() {
        assert_eq!(t().try_merge_or(&f()), Some(t()));
    }

    #[test]
    fn test_try_merge_or_false_and_true() {
        assert_eq!(f().try_merge_or(&t()), Some(t()));
    }

    #[test]
    fn test_try_merge_or_false_and_false() {
        assert_eq!(f().try_merge_or(&f()), Some(f()));
    }

    #[test]
    fn test_try_merge_or_between_and_true() {
        assert_eq!(b(1, 5).try_merge_or(&t()), Some(t()));
    }

    #[test]
    fn test_try_merge_or_between_and_false() {
        assert_eq!(b(1, 5).try_merge_or(&f()), Some(b(1, 5)));
    }

    #[test]
    fn test_try_merge_or_non_intersecting_ranges() {
        assert_eq!(b(1, 5).try_merge_or(&b(6, 10)), None);
    }

    #[test]
    fn test_try_merge_or_intersecting_ranges() {
        assert_eq!(b(1, 5).try_merge_or(&b(3, 7)), Some(b(1, 7)));
        assert_eq!(b(3, 7).try_merge_or(&b(1, 5)), Some(b(1, 7)));
        assert_eq!(b(1, 10).try_merge_or(&b(5, 7)), Some(b(1, 10)));
        assert_eq!(b(5, 7).try_merge_or(&b(1, 10)), Some(b(1, 10)));
    }

    #[test]
    fn test_try_merge_or_overlapping_ranges() {
        assert_eq!(b(1, 7).try_merge_or(&b(3, 5)), Some(b(1, 7)));
        assert_eq!(b(3, 5).try_merge_or(&b(1, 7)), Some(b(1, 7)));
        assert_eq!(b(1, 10).try_merge_or(&b(3, 7)), Some(b(1, 10)));
        assert_eq!(b(3, 7).try_merge_or(&b(1, 10)), Some(b(1, 10)));
    }

    #[test]
    fn test_try_merge_or_adjacent_ranges() {
        assert_eq!(b(1, 5).try_merge_or(&b(6, 7)), Some(b(1, 7)));
        assert_eq!(b(6, 7).try_merge_or(&b(1, 5)), Some(b(1, 7)));
    }

    #[test]
    fn test_try_merge_or_identical_ranges() {
        assert_eq!(b(1, 5).try_merge_or(&b(1, 5)), Some(b(1, 5)));
    }
}
