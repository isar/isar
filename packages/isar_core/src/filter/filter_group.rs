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
        assert!(
            !(group_type == GroupType::And || group_type == GroupType::Or) || !filters.is_empty(),
            "And / Or groups must contain at least one filter"
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

// These unit tests only test the immediate functionality of the functions that are called.
// They do not test `try_merge_and` and `try_merge_or`, since they are tested on their own elsewhere.
#[cfg(test)]
mod tests {
    use super::super::Filter;
    use super::super::FilterCondition;
    use super::{FilterGroup, GroupType};

    macro_rules! and {
        ($($filters:expr),+) => {
            FilterGroup::new(GroupType::And, vec![$($filters),+])
        };
    }

    macro_rules! or {
        ($($filters:expr),+) => {
            FilterGroup::new(GroupType::Or, vec![$($filters),+])
        };
    }

    macro_rules! not {
        ($filter:expr) => {
            FilterGroup::new(GroupType::Not, vec![$filter])
        };
    }

    macro_rules! is_null {
        ($property:expr) => {
            Filter::Condition(FilterCondition::new_is_null($property))
        };
    }

    macro_rules! group {
        ($group:expr) => {
            Filter::Group($group)
        };
    }

    mod and {
        use crate::filter::filter_nested::FilterNested;

        use super::*;

        #[test]
        #[should_panic(expected = "And / Or groups must contain at least one filter")]
        fn test_new_assert() {
            FilterGroup::new(GroupType::And, vec![]);
        }

        #[test]
        fn test_get_group_type() {
            assert_eq!(and!(is_null!(0)).get_group_type(), GroupType::And);
        }

        #[test]
        fn test_get_filters() {
            assert_eq!(
                and!(is_null!(0), is_null!(1)).get_filters(),
                vec![is_null!(0), is_null!(1)]
            );
            assert_eq!(
                and!(group!(and!(is_null!(0)))).get_filters(),
                vec![group!(and!(is_null!(0)))]
            );
        }

        #[test]
        fn test_merge_conditions() {
            assert_eq!(
                and!(is_null!(0)).merge_conditions(),
                (and!(is_null!(0)), false)
            );
            assert_eq!(
                and!(is_null!(0), is_null!(0)).merge_conditions(),
                (and!(is_null!(0)), true)
            );
            assert_eq!(
                and!(is_null!(0), is_null!(0), is_null!(0)).merge_conditions(),
                (and!(is_null!(0)), true)
            );
            assert_eq!(
                and!(is_null!(0), is_null!(1), is_null!(0)).merge_conditions(),
                (and!(is_null!(0), is_null!(1)), true)
            );
            assert_eq!(
                and!(
                    is_null!(0),
                    is_null!(1),
                    is_null!(0),
                    is_null!(0),
                    is_null!(1),
                    is_null!(0),
                    is_null!(0),
                    is_null!(1),
                    is_null!(2)
                )
                .merge_conditions(),
                (and!(is_null!(2), is_null!(0), is_null!(1)), true)
            );
            assert_eq!(
                and!(
                    is_null!(0),
                    is_null!(1),
                    is_null!(0),
                    Filter::Nested(FilterNested::new(0, is_null!(0))),
                    is_null!(0),
                    is_null!(1),
                    is_null!(0),
                    is_null!(0),
                    is_null!(1),
                    is_null!(2)
                )
                .merge_conditions(),
                (
                    and!(
                        is_null!(2),
                        is_null!(0),
                        is_null!(1),
                        Filter::Nested(FilterNested::new(0, is_null!(0)))
                    ),
                    true
                )
            );
            assert_eq!(
                and!(is_null!(0), group!(and!(is_null!(1)))).merge_conditions(),
                (and!(is_null!(0), group!(and!(is_null!(1)))), false)
            );
            assert_eq!(
                and!(group!(and!(is_null!(1))), is_null!(0)).merge_conditions(),
                (and!(group!(and!(is_null!(1))), is_null!(0)), false)
            );
            assert_eq!(
                and!(
                    is_null!(0),
                    group!(and!(is_null!(1))),
                    is_null!(0),
                    group!(or!(is_null!(2), is_null!(0)))
                )
                .merge_conditions(),
                (
                    and!(
                        group!(or!(is_null!(2), is_null!(0))),
                        is_null!(0),
                        group!(and!(is_null!(1)))
                    ),
                    true
                )
            );
            assert_eq!(
                and!(
                    is_null!(0),
                    Filter::Nested(FilterNested::new(0, is_null!(0))),
                    group!(or!(is_null!(1), is_null!(2))),
                    is_null!(2)
                )
                .merge_conditions(),
                (
                    and!(
                        is_null!(0),
                        Filter::Nested(FilterNested::new(0, is_null!(0))),
                        group!(or!(is_null!(1), is_null!(2))),
                        is_null!(2)
                    ),
                    false
                )
            );
        }

        #[test]
        fn test_flatten() {
            assert_eq!(and!(is_null!(0)).flatten(), (is_null!(0), true));
            assert_eq!(
                and!(group!(and!(is_null!(0)))).flatten(),
                (group!(and!(is_null!(0))), true)
            );
            assert_eq!(
                and!(group!(and!(is_null!(0)))).flatten(),
                (group!(and!(is_null!(0))), true)
            );
            assert_eq!(
                and!(group!(and!(is_null!(0))), is_null!(1)).flatten(),
                (group!(and!(is_null!(0), is_null!(1))), true)
            );
            assert_eq!(
                and!(group!(and!(group!(and!(group!(and!(is_null!(1)))))))).flatten(),
                (group!(and!(group!(and!(group!(and!(is_null!(1))))))), true),
            );
            assert_eq!(
                and!(group!(and!(group!(and!(is_null!(1)))))).flatten(),
                (group!(and!(group!(and!(is_null!(1))))), true),
            );
            assert_eq!(
                and!(group!(and!(is_null!(1)))).flatten(),
                (group!(and!(is_null!(1))), true)
            );
            assert_eq!(and!(is_null!(1)).flatten(), (is_null!(1), true));
            assert_eq!(
                and!(group!(and!(is_null!(0), is_null!(1)))).flatten(),
                (group!(and!(is_null!(0), is_null!(1))), true)
            );
            assert_eq!(
                and!(is_null!(0), group!(and!(is_null!(1), is_null!(2)))).flatten(),
                (group!(and!(is_null!(0), is_null!(1), is_null!(2))), true),
            );
            assert_eq!(
                and!(group!(or!(is_null!(0)))).flatten(),
                (group!(or!(is_null!(0))), true)
            );
            assert_eq!(
                and!(group!(or!(is_null!(0)))).flatten(),
                (group!(or!(is_null!(0))), true)
            );
        }

        #[test]
        fn simplify() {
            assert_eq!(
                and!(is_null!(1), is_null!(2)).simplify(),
                (group!(and!(is_null!(1), is_null!(2))), false)
            );
            assert_eq!(
                and!(group!(and!(group!(and!(group!(and!(group!(and!(
                    is_null!(0)
                )))))))))
                .simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                and!(group!(and!(group!(and!(group!(and!(group!(and!(
                    is_null!(0)
                )))))))))
                .simplify(),
                (is_null!(0), true)
            );
            assert_eq!(and!(is_null!(0)).simplify(), (is_null!(0), true));
            assert_eq!(
                and!(is_null!(0), is_null!(0)).simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                and!(group!(and!(is_null!(0), is_null!(0)))).simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                and!(is_null!(0), group!(and!(is_null!(0), is_null!(0)))).simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                and!(
                    is_null!(0),
                    group!(and!(is_null!(0), is_null!(0))),
                    group!(or!(is_null!(0), is_null!(0)))
                )
                .simplify(),
                (is_null!(0), true)
            );
            assert_eq!(and!(is_null!(0)).simplify(), (is_null!(0), true));
            assert_eq!(
                and!(
                    is_null!(0),
                    group!(and!(
                        is_null!(0),
                        group!(and!(is_null!(0), group!(and!(is_null!(0)))))
                    ))
                )
                .simplify(),
                (is_null!(0), true),
            );
        }
    }

    mod or {
        use crate::filter::filter_nested::FilterNested;

        use super::*;

        #[test]
        #[should_panic(expected = "And / Or groups must contain at least one filter")]
        fn test_new_assert() {
            FilterGroup::new(GroupType::Or, vec![]);
        }

        #[test]
        fn test_get_group_type() {
            assert_eq!(or!(is_null!(0)).get_group_type(), GroupType::Or);
        }

        #[test]
        fn test_get_filters() {
            assert_eq!(
                or!(is_null!(0), is_null!(1)).get_filters(),
                vec![is_null!(0), is_null!(1)]
            );
            assert_eq!(or!(is_null!(0)).get_filters(), vec![is_null!(0)]);
        }

        #[test]
        fn test_merge_conditions() {
            assert_eq!(
                or!(is_null!(0)).merge_conditions(),
                (or!(is_null!(0)), false)
            );
            assert_eq!(
                or!(is_null!(0)).merge_conditions(),
                (or!(is_null!(0)), false)
            );
            assert_eq!(
                or!(is_null!(0), is_null!(0)).merge_conditions(),
                (or!(is_null!(0)), true)
            );
            assert_eq!(
                or!(is_null!(0), is_null!(0), is_null!(0)).merge_conditions(),
                (or!(is_null!(0)), true)
            );
            assert_eq!(
                or!(is_null!(0), is_null!(1), is_null!(0)).merge_conditions(),
                (or!(is_null!(0), is_null!(1)), true)
            );
            assert_eq!(
                or!(
                    is_null!(0),
                    is_null!(1),
                    is_null!(0),
                    is_null!(0),
                    is_null!(1),
                    is_null!(0),
                    is_null!(0),
                    is_null!(1),
                    is_null!(2)
                )
                .merge_conditions(),
                (or!(is_null!(2), is_null!(0), is_null!(1)), true)
            );
            assert_eq!(
                or!(
                    is_null!(0),
                    is_null!(1),
                    is_null!(0),
                    Filter::Nested(FilterNested::new(0, is_null!(0))),
                    is_null!(0),
                    is_null!(1),
                    is_null!(0),
                    is_null!(0),
                    is_null!(1),
                    is_null!(2)
                )
                .merge_conditions(),
                (
                    or!(
                        is_null!(2),
                        is_null!(0),
                        is_null!(1),
                        Filter::Nested(FilterNested::new(0, is_null!(0)))
                    ),
                    true
                )
            );
            assert_eq!(
                or!(group!(or!(is_null!(0)))).merge_conditions(),
                (or!(group!(or!(is_null!(0)))), false)
            );
            assert_eq!(
                or!(is_null!(0), group!(or!(is_null!(1)))).merge_conditions(),
                (or!(is_null!(0), group!(or!(is_null!(1)))), false)
            );
            assert_eq!(
                or!(group!(or!(is_null!(1))), is_null!(0)).merge_conditions(),
                (or!(group!(or!(is_null!(1))), is_null!(0)), false)
            );
            assert_eq!(
                or!(group!(and!(is_null!(0)))).merge_conditions(),
                (or!(group!(and!(is_null!(0)))), false)
            );
            assert_eq!(
                or!(is_null!(0), group!(and!(is_null!(1)))).merge_conditions(),
                (or!(is_null!(0), group!(and!(is_null!(1)))), false)
            );
            assert_eq!(
                or!(group!(and!(is_null!(1))), is_null!(0)).merge_conditions(),
                (or!(group!(and!(is_null!(1))), is_null!(0)), false)
            );
            assert_eq!(
                or!(
                    is_null!(0),
                    group!(and!(is_null!(1))),
                    is_null!(0),
                    group!(or!(is_null!(2), is_null!(0)))
                )
                .merge_conditions(),
                (
                    or!(
                        group!(or!(is_null!(2), is_null!(0))),
                        is_null!(0),
                        group!(and!(is_null!(1)))
                    ),
                    true
                )
            );
            assert_eq!(
                or!(
                    is_null!(0),
                    Filter::Nested(FilterNested::new(0, is_null!(0))),
                    group!(or!(is_null!(1), is_null!(2))),
                    is_null!(2)
                )
                .merge_conditions(),
                (
                    or!(
                        is_null!(0),
                        Filter::Nested(FilterNested::new(0, is_null!(0))),
                        group!(or!(is_null!(1), is_null!(2))),
                        is_null!(2)
                    ),
                    false
                )
            );
        }

        #[test]
        fn test_flatten() {
            assert_eq!(or!(is_null!(0)).flatten(), (is_null!(0), true));
            assert_eq!(
                or!(group!(or!(is_null!(0)))).flatten(),
                (group!(or!(is_null!(0))), true)
            );
            assert_eq!(
                or!(group!(or!(is_null!(0)))).flatten(),
                (group!(or!(is_null!(0))), true)
            );
            assert_eq!(
                or!(group!(or!(is_null!(0))), is_null!(1)).flatten(),
                (group!(or!(is_null!(0), is_null!(1))), true)
            );
            assert_eq!(
                or!(group!(or!(group!(or!(group!(or!(is_null!(1)))))))).flatten(),
                (group!(or!(group!(or!(group!(or!(is_null!(1))))))), true),
            );
            assert_eq!(
                or!(group!(or!(group!(or!(is_null!(1)))))).flatten(),
                (group!(or!(group!(or!(is_null!(1))))), true),
            );
            assert_eq!(
                or!(group!(or!(is_null!(1)))).flatten(),
                (group!(or!(is_null!(1))), true)
            );
            assert_eq!(
                or!(group!(or!(is_null!(0), is_null!(1)))).flatten(),
                (group!(or!(is_null!(0), is_null!(1))), true)
            );
            assert_eq!(
                or!(is_null!(0), group!(or!(is_null!(1), is_null!(2)))).flatten(),
                (group!(or!(is_null!(0), is_null!(1), is_null!(2))), true),
            );
            assert_eq!(
                or!(group!(and!(is_null!(0)))).flatten(),
                (group!(and!(is_null!(0))), true)
            );
            assert_eq!(
                or!(group!(and!(is_null!(0)))).flatten(),
                (group!(and!(is_null!(0))), true)
            );
        }

        #[test]
        fn simplify() {
            assert_eq!(
                or!(is_null!(1), is_null!(2)).simplify(),
                (group!(or!(is_null!(1), is_null!(2))), false)
            );
            assert_eq!(
                or!(group!(or!(group!(or!(group!(or!(group!(or!(
                    is_null!(0)
                )))))))))
                .simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                or!(group!(or!(group!(or!(group!(or!(group!(or!(
                    is_null!(0)
                )))))))))
                .simplify(),
                (is_null!(0), true)
            );
            assert_eq!(or!(is_null!(0)).simplify(), (is_null!(0), true));
            assert_eq!(
                or!(is_null!(0), is_null!(0)).simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                or!(group!(or!(is_null!(0), is_null!(0)))).simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                or!(is_null!(0), group!(or!(is_null!(0), is_null!(0)))).simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                or!(
                    is_null!(0),
                    group!(or!(is_null!(0), is_null!(0))),
                    group!(and!(is_null!(0), is_null!(0)))
                )
                .simplify(),
                (is_null!(0), true)
            );
            assert_eq!(or!(is_null!(0)).simplify(), (is_null!(0), true));
            assert_eq!(
                or!(
                    is_null!(0),
                    group!(or!(
                        is_null!(0),
                        group!(or!(is_null!(0), group!(or!(is_null!(0)))))
                    ))
                )
                .simplify(),
                (is_null!(0), true),
            );
        }
    }

    mod not {
        use super::*;

        #[test]
        #[should_panic(expected = "Not groups must contain exactly one filter")]
        fn test_new_asserts_no_empty_filters() {
            FilterGroup::new(GroupType::Not, vec![]);
        }

        #[test]
        #[should_panic(expected = "Not groups must contain exactly one filter")]
        fn test_new_asserts_no_multiple_filters() {
            FilterGroup::new(GroupType::Not, vec![is_null!(0), is_null!(1)]);
        }

        #[test]
        fn test_get_group_type() {
            assert_eq!(not!(is_null!(0)).get_group_type(), GroupType::Not);
        }

        #[test]
        fn test_get_filters() {
            assert_eq!(not!(is_null!(0)).get_filters(), vec![is_null!(0)]);
            assert_eq!(
                not!(group!(and!(is_null!(1)))).get_filters(),
                vec![group!(and!(is_null!(1)))]
            );
        }

        #[test]
        fn test_merge_conditions() {
            // Not groups can't really be merged, since they will only ever have a single filter.

            assert_eq!(
                not!(is_null!(0)).merge_conditions(),
                (not![is_null!(0)], false)
            );
            assert_eq!(
                not!(group!(and!(is_null!(1)))).merge_conditions(),
                (not!(group!(and!(is_null!(1)))), false)
            );
        }

        #[test]
        fn test_flatten() {
            assert_eq!(
                not!(is_null!(0)).flatten(),
                (group!(not!(is_null!(0))), false)
            );
            assert_eq!(
                not!(group!(not!(is_null!(0)))).flatten(),
                (is_null!(0), true)
            );
            assert_eq!(
                not!(group!(not!(group!(not!(is_null!(0)))))).flatten(),
                (group!(not!(is_null!(0))), true)
            );
        }

        #[test]
        fn simplify() {
            assert_eq!(
                not!(is_null!(0)).simplify(),
                (group!(not!(is_null!(0))), false)
            );
            assert_eq!(
                and!(group!(not!(group!(not!(group!(and!(is_null!(0)))))))).simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                not!(group!(not!(group!(not!(group!(not!(group!(and!(
                    group!(not!(is_null!(0)))
                )))))))))
                .simplify(),
                (group!(not!(is_null!(0))), true)
            );
            assert_eq!(
                not!(group!(not!(group!(not!(group!(not!(group!(not!(
                    group!(and!(group!(not!(is_null!(0)))))
                )))))))))
                .simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                not!(group!(and!(group!(not!(is_null!(0)))))).simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                not!(group!(and!(group!(not!(group!(not!(is_null!(0)))))))).simplify(),
                (group!(not!(is_null!(0))), true)
            );
            assert_eq!(
                not!(group!(and!(group!(or!(is_null!(0)))))).simplify(),
                (group!(not!(is_null!(0))), true)
            );
            assert_eq!(
                not!(group!(and!(group!(or!(group!(not!(is_null!(0)))))))).simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                not!(group!(not!(group!(or!(group!(or!(group!(not!(
                    group!(not!(is_null!(0)))
                )))))))))
                .simplify(),
                (is_null!(0), true)
            );
            assert_eq!(
                not!(group!(not!(group!(or!(group!(or!(group!(not!(
                    group!(not!(group!(and!(is_null!(1)))))
                )))))))))
                .simplify(),
                (is_null!(1), true)
            );
            assert_eq!(
                not!(group!(not!(group!(or!(group!(and!(group!(not!(
                    group!(not!(group!(or!(is_null!(0), is_null!(1)))))
                )))))))))
                .simplify(),
                (group!(or!(is_null!(0), is_null!(1))), true)
            );
        }
    }
}
