use std::vec;

use super::sql::filter_sql;
use super::sqlite_collection::SQLiteCollection;
use super::sqlite_query::{QueryParam, SQLiteQuery};
use crate::core::filter::Filter;
use crate::core::query_builder::{IsarQueryBuilder, Sort};
use itertools::Itertools;

pub struct SQLiteQueryBuilder<'a> {
    all_collections: &'a [SQLiteCollection],
    collection_index: u16,
    filter: Option<Filter>,
    sort: Vec<(&'a str, Sort, bool)>,
    distinct: Vec<(&'a str, bool)>,
}

impl SQLiteQueryBuilder<'_> {
    pub(crate) fn new<'a>(
        all_collections: &'a [SQLiteCollection],
        collection_index: u16,
    ) -> SQLiteQueryBuilder<'a> {
        SQLiteQueryBuilder {
            all_collections,
            collection_index,
            filter: None,
            sort: Vec::new(),
            distinct: Vec::new(),
        }
    }
}

impl<'a> SQLiteQueryBuilder<'a> {
    fn build_query(self) -> (String, Vec<QueryParam>) {
        let mut filter_params = vec![];

        let mut sql = String::new();
        if let Some(filter) = self.filter {
            sql.push_str(" WHERE ");
            let (filter_sql, params) =
                filter_sql(self.collection_index, self.all_collections, filter);
            sql.push_str(&filter_sql);
            filter_params = params;
        }
        if !self.sort.is_empty() {
            sql.push_str(" ORDER BY ");
            sql.push_str(
                &self
                    .sort
                    .iter()
                    .map(|(prop, sort, case_sensitive)| {
                        format!(
                            "{} COLLATE {}{}",
                            prop,
                            if *case_sensitive { "NOCASE" } else { "BINARY" },
                            if *sort == Sort::Asc { "" } else { " DESC" }
                        )
                    })
                    .join(", "),
            );
        }
        if !self.distinct.is_empty() {
            sql.push_str(" GROUP BY ");
            sql.push_str(
                &self
                    .distinct
                    .iter()
                    .map(|(prop, case_sensitive)| {
                        format!(
                            "{} COLLATE {}",
                            prop,
                            if *case_sensitive { "NOCASE" } else { "BINARY" }
                        )
                    })
                    .join(", "),
            );
        }

        (sql, filter_params)
    }
}

impl<'a> IsarQueryBuilder for SQLiteQueryBuilder<'a> {
    type Query = SQLiteQuery;

    fn set_filter(&mut self, filter: Filter) {
        self.filter = Some(filter);
    }

    fn add_sort(&mut self, property_index: u16, sort: Sort, case_sensitive: bool) {
        self.sort.push((
            self.all_collections[self.collection_index as usize].get_property_name(property_index),
            sort,
            case_sensitive,
        ));
    }

    fn add_distinct(&mut self, property_index: u16, case_sensitive: bool) {
        self.distinct.push((
            self.all_collections[self.collection_index as usize].get_property_name(property_index),
            case_sensitive,
        ));
    }

    fn build(self) -> Self::Query {
        let collection_index = self.collection_index;
        let has_sort_distinct = !self.sort.is_empty() || !self.distinct.is_empty();
        let (sql, filter_params) = self.build_query();
        SQLiteQuery::new(collection_index, sql, has_sort_distinct, filter_params)
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use crate::core::data_type::DataType;
    use crate::core::filter::{ConditionType::*, Filter::*, FilterCondition};
    use crate::core::value::IsarValue;
    use crate::sqlite::sqlite_collection::SQLiteProperty;

    fn debug_col() -> SQLiteCollection {
        SQLiteCollection::new(
            "col".to_string(),
            Some("id".to_string()),
            vec![
                SQLiteProperty::new("prop1", DataType::Long, None),
                SQLiteProperty::new("prop2", DataType::String, None),
            ],
            vec![],
        )
    }

    fn qb_filter(filter: Filter) -> (String, Vec<QueryParam>) {
        let cols = vec![debug_col()];
        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.set_filter(filter);
        qb.build_query()
    }

    #[test]
    fn test_build_empty() {
        let qb = SQLiteQueryBuilder::new(&[], 0);
        let (sql, params) = qb.build_query();
        assert_eq!(sql, "");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_build_single_sort() {
        let cols = vec![debug_col()];

        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.add_sort(0, Sort::Asc, false);
        let (sql, params) = qb.build_query();
        assert_eq!(sql.trim(), "ORDER BY _rowid_ COLLATE BINARY");
        assert_eq!(params.is_empty(), true);

        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.add_sort(2, Sort::Desc, true);
        let (sql, params) = qb.build_query();
        assert_eq!(sql.trim(), "ORDER BY prop2 COLLATE NOCASE DESC");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_build_multiple_sort() {
        let cols = vec![debug_col()];

        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.add_sort(0, Sort::Asc, false);
        qb.add_sort(1, Sort::Desc, false);
        qb.add_sort(2, Sort::Asc, true);
        let (sql, params) = qb.build_query();
        assert_eq!(
            sql.trim(),
            "ORDER BY _rowid_ COLLATE BINARY, prop1 COLLATE BINARY DESC, prop2 COLLATE NOCASE"
        );
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_build_single_distinct() {
        let cols = vec![debug_col()];

        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.add_distinct(0, false);
        let (sql, params) = qb.build_query();
        assert_eq!(sql.trim(), "GROUP BY _rowid_ COLLATE BINARY");
        assert_eq!(params.is_empty(), true);

        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.add_distinct(2, true);
        let (sql, params) = qb.build_query();
        assert_eq!(sql.trim(), "GROUP BY prop2 COLLATE NOCASE");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_build_multiple_distinct() {
        let cols = vec![debug_col()];

        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.add_distinct(0, false);
        qb.add_distinct(1, false);
        qb.add_distinct(2, true);
        let (sql, params) = qb.build_query();
        assert_eq!(
            sql.trim(),
            "GROUP BY _rowid_ COLLATE BINARY, prop1 COLLATE BINARY, prop2 COLLATE NOCASE"
        );
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_null() {
        let cond = FilterCondition::new(1, IsNull, vec![], false);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 IS NULL");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_equal_value() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, Equal, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 = ?");
        assert_eq!(params, vec![QueryParam::Value(value)]);
    }

    #[test]
    fn test_filter_equal_value_case_insensitive() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, Equal, vec![Some(value.clone())], false);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 = ? COLLATE NOCASE");
        assert_eq!(params, vec![QueryParam::Value(value)]);
    }

    #[test]
    fn test_filter_equal_null() {
        let cond = FilterCondition::new(1, Equal, vec![None], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 IS NULL");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_greater_than_value() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, Greater, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 > ?");
        assert_eq!(params, vec![QueryParam::Value(value)]);
    }

    #[test]
    fn test_filter_greater_than_value_case_insensitive() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, Greater, vec![Some(value.clone())], false);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 > ? COLLATE NOCASE");
        assert_eq!(params, vec![QueryParam::Value(value)]);
    }

    #[test]
    fn test_filter_greater_than_null() {
        let cond = FilterCondition::new(1, Greater, vec![None], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 IS NOT NULL");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_greater_or_equal_value() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, GreaterOrEqual, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 >= ?");
        assert_eq!(params, vec![QueryParam::Value(value)]);
    }

    #[test]
    fn test_filter_greater_or_equal_value_case_insensitive() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, GreaterOrEqual, vec![Some(value.clone())], false);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 >= ? COLLATE NOCASE");
        assert_eq!(params, vec![QueryParam::Value(value)]);
    }

    #[test]
    fn test_filter_greater_or_equal_null() {
        let cond = FilterCondition::new(1, GreaterOrEqual, vec![None], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE TRUE");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_less_than_value() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, Less, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 < ? OR prop1 IS NULL");
        assert_eq!(params, vec![QueryParam::Value(value)]);
    }

    #[test]
    fn test_filter_less_than_value_case_insensitive() {
        let value = IsarValue::String("abc".to_string());
        let cond = FilterCondition::new(1, Less, vec![Some(value.clone())], false);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(
            sql.trim(),
            "WHERE prop1 < ? COLLATE NOCASE OR prop1 IS NULL"
        );
        assert_eq!(params, vec![QueryParam::Value(value)]);
    }

    #[test]
    fn test_filter_less_than_null() {
        let cond = FilterCondition::new(1, Less, vec![None], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE FALSE");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_less_or_equal_value() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, LessOrEqual, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 <= ? OR prop1 IS NULL");
        assert_eq!(params, vec![QueryParam::Value(value)]);
    }

    #[test]
    fn test_filter_less_or_equal_value_case_insensitive() {
        let value = IsarValue::String("abc".to_string());
        let cond = FilterCondition::new(1, LessOrEqual, vec![Some(value.clone())], false);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(
            sql.trim(),
            "WHERE prop1 <= ? COLLATE NOCASE OR prop1 IS NULL"
        );
        assert_eq!(params, vec![QueryParam::Value(value)]);
    }

    #[test]
    fn test_filter_less_or_equal_null() {
        let cond = FilterCondition::new(1, LessOrEqual, vec![None], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 IS NULL");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_between_value() {
        let value1 = IsarValue::Integer(123);
        let value2 = IsarValue::Integer(456);
        let cond = FilterCondition::new(
            1,
            Between,
            vec![Some(value1.clone()), Some(value2.clone())],
            true,
        );

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 BETWEEN ? AND ?");
        assert_eq!(
            params,
            vec![QueryParam::Value(value1), QueryParam::Value(value2)]
        );
    }

    #[test]
    fn test_filter_between_lower_null() {
        let value = IsarValue::Integer(456);
        let cond = FilterCondition::new(1, Between, vec![None, Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 <= ? OR prop1 IS NULL");
        assert_eq!(params, vec![QueryParam::Value(value)]);
    }

    #[test]
    fn test_filter_between_upper_null() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, Between, vec![Some(value.clone()), None], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 >= ?");
        assert_eq!(params, vec![QueryParam::Value(value)]);
    }

    #[test]
    fn test_filter_between_both_null() {
        let cond = FilterCondition::new(1, Between, vec![None, None], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 IS NULL");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_string_starts_with() {
        let value = IsarValue::String("ab%c".to_string());
        let cond = FilterCondition::new(1, StringStartsWith, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 LIKE ? ESCAPE '\\'");
        assert_eq!(
            params,
            vec![QueryParam::Value(IsarValue::String("ab\\%c%".to_string()))]
        );
    }

    #[test]
    fn test_filter_string_starts_with_non_string() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, StringStartsWith, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE FALSE");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_string_ends_with() {
        let value = IsarValue::String("ab%c".to_string());
        let cond = FilterCondition::new(1, StringEndsWith, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 LIKE ? ESCAPE '\\'");
        assert_eq!(
            params,
            vec![QueryParam::Value(IsarValue::String("%ab\\%c".to_string()))]
        );
    }

    #[test]
    fn test_filter_string_ends_with_non_string() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, StringEndsWith, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE FALSE");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_string_contains() {
        let value = IsarValue::String("ab%c".to_string());
        let cond = FilterCondition::new(1, StringContains, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 LIKE ? ESCAPE '\\'");
        assert_eq!(
            params,
            vec![QueryParam::Value(IsarValue::String("%ab\\%c%".to_string()))]
        );
    }

    #[test]
    fn test_filter_string_contains_non_string() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, StringContains, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE FALSE");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_string_matches() {
        let value = IsarValue::String("a?b%c*".to_string());
        let cond = FilterCondition::new(1, StringMatches, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE prop1 LIKE ? ESCAPE '\\'");
        assert_eq!(
            params,
            vec![QueryParam::Value(IsarValue::String("a_b\\%c%".to_string()))]
        );
    }

    #[test]
    fn test_filter_string_matches_non_string() {
        let value = IsarValue::Integer(123);
        let cond = FilterCondition::new(1, StringMatches, vec![Some(value.clone())], true);

        let (sql, params) = qb_filter(Condition(cond));
        assert_eq!(sql.trim(), "WHERE FALSE");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_and() {
        let cond1 = FilterCondition::new(1, IsNull, vec![], true);
        let cond2 = FilterCondition::new(2, IsNull, vec![], true);
        let cond = And(vec![Condition(cond1), Condition(cond2)]);

        let (sql, params) = qb_filter(cond);
        assert_eq!(sql.trim(), "WHERE (prop1 IS NULL AND prop2 IS NULL)");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_filter_or() {
        let cond1 = FilterCondition::new(1, IsNull, vec![], true);
        let cond2 = FilterCondition::new(2, IsNull, vec![], true);
        let cond = Or(vec![Condition(cond1), Condition(cond2)]);

        let (sql, params) = qb_filter(cond);
        assert_eq!(sql.trim(), "WHERE (prop1 IS NULL OR prop2 IS NULL)");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_not() {
        let cond1 = FilterCondition::new(1, IsNull, vec![], true);
        let cond2 = FilterCondition::new(2, IsNull, vec![], true);
        let cond = Or(vec![Condition(cond1), Condition(cond2)]);

        let (sql, params) = qb_filter(Not(Box::new(cond)));
        assert_eq!(sql.trim(), "WHERE NOT ((prop1 IS NULL OR prop2 IS NULL))");
        assert_eq!(params.is_empty(), true);
    }

    #[test]
    fn test_mixed_and_or() {
        let cond1 = FilterCondition::new(0, IsNull, vec![], true);
        let cond2 = FilterCondition::new(1, IsNull, vec![], true);
        let cond3 = FilterCondition::new(2, IsNull, vec![], true);
        let cond = And(vec![
            Condition(cond1.clone()),
            Or(vec![
                Condition(cond1),
                Condition(cond2.clone()),
                Condition(cond3),
            ]),
            Condition(cond2),
        ]);

        let (sql, params) = qb_filter(cond);
        assert_eq!(
            sql.trim(),
            "WHERE (_rowid_ IS NULL AND (_rowid_ IS NULL OR prop1 IS NULL OR prop2 IS NULL) AND prop1 IS NULL)"
        );
        assert_eq!(params.is_empty(), true);
    }
}
