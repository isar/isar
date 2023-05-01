use itertools::Itertools;

use super::Filter;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum GroupType {
    And,
    Or,
    Not,
}

#[derive(Clone, PartialEq, Debug)]
pub struct FilterGroup {
    group_type: GroupType,
    filters: Vec<Filter>,
}

impl FilterGroup {
    pub fn new(group_type: GroupType, filters: Vec<Filter>) -> Self {
        assert!(
            group_type != GroupType::Not || filters.len() == 1,
            "Not groups must contain exactly one filter"
        );
        FilterGroup {
            group_type,
            filters,
        }
    }

    pub fn get_group_type(&self) -> GroupType {
        self.group_type
    }

    pub fn get_filters(&self) -> &[Filter] {
        &self.filters
    }

    pub(crate) fn simplify(self) -> (Filter, bool) {
        let (simplified_group, simplified) = self.simplify_nested();
        let (merged_group, merged) = simplified_group.merge_conditions();
        let (flattened_filter, flattened) = merged_group.flatten();
        (flattened_filter, simplified || merged || flattened)
    }

    fn simplify_nested(self) -> (FilterGroup, bool) {
        let mut has_changed = false;
        let filters = self
            .filters
            .into_iter()
            .map(|f| {
                let (simplified, changed) = f.simplify();
                has_changed = has_changed || changed;
                simplified
            })
            .collect_vec();

        (FilterGroup::new(self.group_type, filters), has_changed)
    }

    fn merge_conditions(self) -> (FilterGroup, bool) {
        let mut filters = self.filters;
        let mut any_merged = false;

        loop {
            let mut merged_filters = Vec::new();
            let mut merged_this_iteration = false;

            'conditions: while let Some(current_filter) = filters.pop() {
                if let Filter::Condition(c1) = current_filter {
                    for i in 0..filters.len() {
                        if let Filter::Condition(c2) = &filters[i] {
                            let merged = if self.group_type == GroupType::And {
                                c1.try_merge_and(c2)
                            } else {
                                c1.try_merge_or(c2)
                            };
                            if let Some(merged) = merged {
                                any_merged = true;
                                merged_this_iteration = true;
                                merged_filters.push(Filter::Condition(merged));
                                filters.remove(i);
                                continue 'conditions;
                            }
                        }
                    }

                    merged_filters.push(Filter::Condition(c1));
                } else {
                    merged_filters.push(current_filter);
                }
            }

            filters = merged_filters;
            if !merged_this_iteration {
                break;
            }
        }

        filters.reverse();
        let group = FilterGroup::new(self.group_type, filters);
        (group, any_merged)
    }

    pub(crate) fn flatten(self) -> (Filter, bool) {
        if self.group_type == GroupType::Not {
            if let Filter::Condition(condition) = &self.filters[0] {
                if let Some(inverted) = condition.try_invert() {
                    return (inverted, true);
                }
            }
        } else if self.filters.len() == 1 {
            // Remove unnecessary groups
            let filter = self.filters.into_iter().next().unwrap();
            return (filter, true);
        }

        let mut new_filters = Vec::new();
        let mut has_changed = false;
        for filter in self.filters.into_iter() {
            if let Filter::Group(inner_group) = filter {
                if self.group_type == GroupType::Not && inner_group.group_type == GroupType::Not {
                    // Remove nested Not groups. This is allowed since not groups can only
                    // contain one filter
                    let filter = inner_group.filters.into_iter().next().unwrap();
                    return (filter, true);
                } else if inner_group.group_type == self.group_type {
                    // Remove nested And or Or groups of the same type
                    new_filters.extend(inner_group.filters);
                    has_changed = true;
                } else {
                    new_filters.push(Filter::Group(inner_group));
                }
            } else {
                new_filters.push(filter);
            }
        }

        let group = FilterGroup::new(self.group_type, new_filters);
        (Filter::Group(group), has_changed)
    }
}

#[cfg(test)]
mod tests {
    use super::super::Filter;
    use super::super::FilterCondition;
    use super::{FilterGroup, GroupType};

    macro_rules! and {
        ($($filters:expr),*) => {
            FilterGroup::new(GroupType::And, vec![$($filters),*])
        };
    }

    macro_rules! or {
        ($($filters:expr),*) => {
            FilterGroup::new(GroupType::Or, vec![$($filters),*])
        };
    }

    macro_rules! not {
        ($filter:expr) => {
            FilterGroup::new(GroupTYpe::Not, vec![$filter])
        };
    }

    macro_rules! is_null {
        ($property:expr) => {
            Filter::Condition(FilterCondition::new_is_null($property))
        };
    }

    macro_rules! eq {
        ($property:expr, $value:expr) => {
            Filter::Condition(FilterCondition::new_equal_to($property, $value, false))
        };
    }

    macro_rules! gt {
        ($property:expr, $value:expr) => {
            Filter::Condition(FilterCondition::new_greater_than($property, $value, false))
        };
    }

    macro_rules! gte {
        ($property:expr, $value:expr) => {
            Filter::Condition(FilterCondition::new_greater_than_equal(
                $property, $value, false,
            ))
        };
    }

    mod simple_and {
        use super::*;

        #[test]
        fn test_get_group_type() {
            assert_eq!(and!().get_group_type(), GroupType::And);
        }

        #[test]
        fn test_get_filters() {
            assert_eq!(
                and!(is_null!(0), is_null!(1)).get_filters(),
                vec![is_null!(0), is_null!(1)]
            );
            assert_eq!(and!().get_filters(), vec![]);
        }

        #[test]
        fn test_merge_conditions() {
            /*assert_eq!(and!().merge_conditions(), (and!(), false));
            assert_eq!(
                and!(is_null!(0)).merge_conditions(),
                (and!(is_null!(0)), false)
            );*/
            assert_eq!(
                and!(is_null!(0), is_null!(0)).merge_conditions(),
                (and!(is_null!(0)), true)
            );
            return;
            assert_eq!(
                and!(Filter::Group(and!())).merge_conditions(),
                (and!(Filter::Group(and!())), false)
            );
        }

        #[test]
        fn test_simplify_nested() {}

        #[test]
        fn test_flatten() {}
    }
}
