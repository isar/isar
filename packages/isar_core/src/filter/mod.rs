use self::filter_condition::FilterCondition;
use self::filter_group::FilterGroup;
use self::filter_nested::FilterNested;

pub(crate) mod condition_merge;
pub mod filter_condition;
pub mod filter_group;
pub mod filter_nested;
pub mod filter_value;

#[derive(PartialEq, Clone, Debug)]
pub enum Filter {
    Condition(FilterCondition),
    Group(FilterGroup),
    Nested(FilterNested),
}

impl Filter {
    /// This methods optimizes the filter tree by removing unnecessary filters
    /// and conditions. It does not change the order of conditions.
    ///
    /// The following optimizations are performed:
    ///
    /// Remove redundant conditions on the same property:
    /// AND(A > 5, A > 3)                         =>  A > 5
    /// AND(A <= 7, A >= 7)                       =>  A == 7
    /// AND(BETWEEN(A, 5, 7), BETWEEN(A, 8, 10))  =>  BETWEEN(A, 5, 10)
    ///
    /// Remove nested And or Or groups of the same type:
    /// AND(AND(A > 5, B < 10), C == 7)  =>  AND(A > 5, B < 10, C == 7)
    ///
    /// Remove And and Or groups with a single condition:
    /// AND(A > 5, AND(B < 10))  =>  AND(A > 5, B < 10)
    ///
    /// Remove nested Not groups:
    /// NOT(NOT(STARTS_WITH(A, "prefix")))  =>  STARTS_WITH(A, "prefix")
    ///
    /// Try to remove Not groups by inverting the condition:
    /// NOT(A > 5)  =>  A <= 5
    ///
    /// Remove conditions that are guaranteed to be true or false:
    /// AND(A > 5, A < 3)           =>  false
    /// OR(A == 5, B == 7, B != 7)  =>  true
    pub fn optimize(self) -> Self {
        let mut filter = self;

        loop {
            let (new_filter, changed) = filter.simplify();

            if !changed {
                return new_filter;
            }
            filter = new_filter;
        }
    }

    fn simplify(self) -> (Filter, bool) {
        if let Filter::Group(group) = self {
            group.simplify()
        } else {
            (self, false)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{
        filter_condition::FilterCondition,
        filter_group::{FilterGroup, GroupType},
        filter_value::FilterValue,
        Filter,
    };

    fn gt(value: i64) -> Filter {
        Filter::Condition(FilterCondition::new_greater_than(
            0,
            FilterValue::Integer(value),
            false,
        ))
    }

    fn lt(value: i64) -> Filter {
        Filter::Condition(FilterCondition::new_less_than(
            0,
            FilterValue::Integer(value),
            false,
        ))
    }

    fn eq(value: i64) -> Filter {
        Filter::Condition(FilterCondition::new_equal_to(
            0,
            FilterValue::Integer(value),
            false,
        ))
    }

    fn between(lower: i64, upper: i64) -> Filter {
        Filter::Condition(FilterCondition::new_between(
            0,
            FilterValue::Integer(lower),
            FilterValue::Integer(upper),
            false,
        ))
    }

    macro_rules! and {
        ($($x:expr),*) => {
            {
                let mut filters = Vec::new();
                $(filters.push($x);)*
                Filter::Group(FilterGroup::new(GroupType::And, filters))
            }
        };
    }

    macro_rules! or {
        ($($x:expr),*) => {
            {
                let mut filters = Vec::new();
                $(filters.push($x);)*
                Filter::Group(FilterGroup::new(GroupType::Or, filters))
            }
        };
    }

    fn not(filter: Filter) -> Filter {
        Filter::Group(FilterGroup::new(GroupType::Not, vec![filter]))
    }

    fn t() -> Filter {
        Filter::Condition(FilterCondition::new_true())
    }

    fn f() -> Filter {
        Filter::Condition(FilterCondition::new_false())
    }

    macro_rules! opt {
        ($filter:expr, $result:expr) => {
            assert_eq!($filter.optimize(), $result);
        };
    }

    #[test]
    fn test_optimize_remove_redundant_conditions() {
        opt!(and!(gt(10), gt(20), lt(30)), between(21, 29));
        opt!(and!(gt(10), lt(10)), f());
        opt!(or!(gt(10), gt(20)), gt(10));
        opt!(or!(gt(10), gt(20), lt(30)), t());
    }

    #[test]
    fn test_optimize_remove_nested_and_or_groups() {
        opt!(
            and!(and!(gt(10), lt(30)), or!(eq(15), eq(20))),
            and!(between(11, 29), or!(eq(15), eq(20)))
        );
    }

    #[test]
    fn test_optimize_remove_nested_not_groups() {
        opt!(not(not(gt(10))), gt(10));
        opt!(not(not(not(gt(10)))), lt(11));
        opt!(not(not(not(eq(10)))), or!(lt(10), gt(10)));
    }
}
