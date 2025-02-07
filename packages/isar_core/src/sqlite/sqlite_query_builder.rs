use std::vec;

use super::sql_filter::filter_sql;
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
            let get_property = &|collection_index, property_index| {
                self.all_collections
                    .get(collection_index as usize)?
                    .get_property(property_index)
            };
            let (filter_sql, params) = filter_sql(self.collection_index, &get_property, filter);
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
    use crate::core::filter::{ConditionType::*, Filter::*};
    use crate::core::value::IsarValue;
    use crate::sqlite::sqlite_collection::SQLiteProperty;
    use crate::sqlite::sqlite_query::JsonCondition;
    use crate::sqlite::sqlite_query::QueryParam::*;

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

    macro_rules! assert_sql {
        ($result:expr, $expected_sql:expr, $($expected_params:expr),*) => {
            let (sql, params) = $result;
            assert_eq!(sql.trim(), $expected_sql);
            assert_eq!(params, vec![$($expected_params),*]);
        };
    }

    #[test]
    fn test_build_empty() {
        let qb = SQLiteQueryBuilder::new(&[], 0);
        let sql = qb.build_query();
        assert_sql!(sql, "",);
    }

    #[test]
    fn test_build_single_sort() {
        let cols = vec![debug_col()];

        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.add_sort(0, Sort::Asc, false);
        let sql = qb.build_query();
        assert_sql!(sql, "ORDER BY _rowid_ COLLATE BINARY",);

        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.add_sort(2, Sort::Desc, true);
        let sql = qb.build_query();
        assert_sql!(sql, "ORDER BY prop2 COLLATE NOCASE DESC",);
    }

    #[test]
    fn test_build_multiple_sort() {
        let cols = vec![debug_col()];

        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.add_sort(0, Sort::Asc, false);
        qb.add_sort(1, Sort::Desc, false);
        qb.add_sort(2, Sort::Asc, true);
        let sql = qb.build_query();
        assert_sql!(
            sql,
            "ORDER BY _rowid_ COLLATE BINARY, prop1 COLLATE BINARY DESC, prop2 COLLATE NOCASE",
        );
    }

    #[test]
    fn test_build_single_distinct() {
        let cols = vec![debug_col()];

        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.add_distinct(0, false);
        let sql = qb.build_query();
        assert_sql!(sql, "GROUP BY _rowid_ COLLATE BINARY",);

        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.add_distinct(2, true);
        let sql = qb.build_query();
        assert_sql!(sql, "GROUP BY prop2 COLLATE NOCASE",);
    }

    #[test]
    fn test_build_multiple_distinct() {
        let cols = vec![debug_col()];

        let mut qb = SQLiteQueryBuilder::new(&cols, 0);
        qb.add_distinct(0, false);
        qb.add_distinct(1, false);
        qb.add_distinct(2, true);
        let sql = qb.build_query();
        assert_sql!(
            sql,
            "GROUP BY _rowid_ COLLATE BINARY, prop1 COLLATE BINARY, prop2 COLLATE NOCASE",
        );
    }

    #[test]
    fn test_filter_null() {
        let cond = Filter::new_condition(1, IsNull, vec![], false);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE prop1 IS NULL",);
    }

    #[test]
    fn test_filter_equal_value() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, Equal, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE prop1 = ?", Value(value));
    }

    #[test]
    fn test_filter_equal_value_case_insensitive() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, Equal, vec![Some(value.clone())], false);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE prop1 = ? COLLATE NOCASE", Value(value));
    }

    #[test]
    fn test_filter_equal_null() {
        let cond = Filter::new_condition(1, Equal, vec![None], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE prop1 IS NULL",);
    }

    #[test]
    fn test_filter_greater_than_value() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, Greater, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE prop1 > ?", Value(value));
    }

    #[test]
    fn test_filter_greater_than_value_case_insensitive() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, Greater, vec![Some(value.clone())], false);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE prop1 > ? COLLATE NOCASE", Value(value));
    }

    #[test]
    fn test_filter_greater_than_null() {
        let cond = Filter::new_condition(1, Greater, vec![None], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE prop1 IS NOT NULL",);
    }

    #[test]
    fn test_filter_greater_or_equal_value() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, GreaterOrEqual, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE prop1 >= ?", Value(value));
    }

    #[test]
    fn test_filter_greater_or_equal_value_case_insensitive() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, GreaterOrEqual, vec![Some(value.clone())], false);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE prop1 >= ? COLLATE NOCASE", Value(value));
    }

    #[test]
    fn test_filter_greater_or_equal_null() {
        let cond = Filter::new_condition(1, GreaterOrEqual, vec![None], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE TRUE",);
    }

    #[test]
    fn test_filter_less_than_value() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, Less, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE (prop1 < ? OR prop1 IS NULL)", Value(value));
    }

    #[test]
    fn test_filter_less_than_value_case_insensitive() {
        let value = IsarValue::String("abc".to_string());
        let cond = Filter::new_condition(1, Less, vec![Some(value.clone())], false);

        let sql = qb_filter(cond);
        assert_sql!(
            sql,
            "WHERE (prop1 < ? COLLATE NOCASE OR prop1 IS NULL)",
            Value(value)
        );
    }

    #[test]
    fn test_filter_less_than_null() {
        let cond = Filter::new_condition(1, Less, vec![None], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE FALSE",);
    }

    #[test]
    fn test_filter_less_or_equal_value() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, LessOrEqual, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE (prop1 <= ? OR prop1 IS NULL)", Value(value));
    }

    #[test]
    fn test_filter_less_or_equal_value_case_insensitive() {
        let value = IsarValue::String("abc".to_string());
        let cond = Filter::new_condition(1, LessOrEqual, vec![Some(value.clone())], false);

        let sql = qb_filter(cond);
        assert_sql!(
            sql,
            "WHERE (prop1 <= ? COLLATE NOCASE OR prop1 IS NULL)",
            Value(value)
        );
    }

    #[test]
    fn test_filter_less_or_equal_null() {
        let cond = Filter::new_condition(1, LessOrEqual, vec![None], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE prop1 IS NULL",);
    }

    #[test]
    fn test_filter_between_value() {
        let value1 = IsarValue::Integer(123);
        let value2 = IsarValue::Integer(456);
        let cond = Filter::new_condition(
            1,
            Between,
            vec![Some(value1.clone()), Some(value2.clone())],
            true,
        );

        let sql = qb_filter(cond);
        assert_sql!(
            sql,
            "WHERE prop1 BETWEEN ? AND ?",
            Value(value1),
            Value(value2)
        );
    }

    #[test]
    fn test_filter_between_lower_null() {
        let value = IsarValue::Integer(456);
        let cond = Filter::new_condition(1, Between, vec![None, Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE (prop1 <= ? OR prop1 IS NULL)", Value(value));
    }

    #[test]
    fn test_filter_between_upper_null() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, Between, vec![Some(value.clone()), None], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE prop1 >= ?", Value(value));
    }

    #[test]
    fn test_filter_between_both_null() {
        let cond = Filter::new_condition(1, Between, vec![None, None], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE prop1 IS NULL",);
    }

    #[test]
    fn test_filter_string_starts_with() {
        let value = IsarValue::String("ab%c".to_string());
        let cond = Filter::new_condition(1, StringStartsWith, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(
            sql,
            "WHERE prop1 LIKE ? ESCAPE '\\'",
            Value(IsarValue::String("ab\\%c%".to_string()))
        );
    }

    #[test]
    fn test_filter_string_starts_with_non_string() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, StringStartsWith, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE FALSE",);
    }

    #[test]
    fn test_filter_string_ends_with() {
        let value = IsarValue::String("ab%c".to_string());
        let cond = Filter::new_condition(1, StringEndsWith, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(
            sql,
            "WHERE prop1 LIKE ? ESCAPE '\\'",
            Value(IsarValue::String("%ab\\%c".to_string()))
        );
    }

    #[test]
    fn test_filter_string_ends_with_non_string() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, StringEndsWith, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE FALSE",);
    }

    #[test]
    fn test_filter_string_contains() {
        let value = IsarValue::String("ab%c".to_string());
        let cond = Filter::new_condition(1, StringContains, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(
            sql,
            "WHERE prop1 LIKE ? ESCAPE '\\'",
            Value(IsarValue::String("%ab\\%c%".to_string()))
        );
    }

    #[test]
    fn test_filter_string_contains_non_string() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, StringContains, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE FALSE",);
    }

    #[test]
    fn test_filter_string_matches() {
        let value = IsarValue::String("a?b%c*".to_string());
        let cond = Filter::new_condition(1, StringMatches, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(
            sql,
            "WHERE prop1 LIKE ? ESCAPE '\\'",
            Value(IsarValue::String("a_b\\%c%".to_string()))
        );
    }

    #[test]
    fn test_filter_string_matches_non_string() {
        let value = IsarValue::Integer(123);
        let cond = Filter::new_condition(1, StringMatches, vec![Some(value.clone())], true);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE FALSE",);
    }

    #[test]
    fn test_filter_and() {
        let cond1 = Filter::new_condition(1, IsNull, vec![], true);
        let cond2 = Filter::new_condition(2, IsNull, vec![], true);
        let cond = Filter::new_and(vec![cond1, cond2]);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE (prop1 IS NULL AND prop2 IS NULL)",);
    }

    #[test]
    fn test_filter_or() {
        let cond1 = Filter::new_condition(1, IsNull, vec![], true);
        let cond2 = Filter::new_condition(2, IsNull, vec![], true);
        let cond = Filter::new_or(vec![cond1, cond2]);

        let sql = qb_filter(cond);
        assert_sql!(sql, "WHERE (prop1 IS NULL OR prop2 IS NULL)",);
    }

    #[test]
    fn test_not() {
        let cond1 = Filter::new_condition(1, IsNull, vec![], true);
        let cond2 = Filter::new_condition(2, IsNull, vec![], true);
        let cond = Filter::new_or(vec![cond1, cond2]);

        let sql = qb_filter(Not(Box::new(cond)));
        assert_sql!(sql, "WHERE NOT (prop1 IS NULL OR prop2 IS NULL)",);
    }

    #[test]
    fn test_mixed_and_or() {
        let cond1 = Filter::new_condition(0, IsNull, vec![], true);
        let cond2 = Filter::new_condition(1, IsNull, vec![], true);
        let cond3 = Filter::new_condition(2, IsNull, vec![], true);
        let cond = Filter::new_and(vec![
            cond1.clone(),
            Filter::new_or(vec![cond1, cond2.clone(), cond3]),
            cond2,
        ]);

        let sql = qb_filter(cond);
        assert_sql!(
            sql,
            "WHERE (_rowid_ IS NULL AND (_rowid_ IS NULL OR prop1 IS NULL OR prop2 IS NULL) AND prop1 IS NULL)",
        );
    }

    #[test]
    fn test_embedded_filter_condition() {
        let cols = vec![
            SQLiteCollection::new(
                "col".to_string(),
                Some("id".to_string()),
                vec![SQLiteProperty::new("nested_obj", DataType::Object, Some(1))],
                vec![],
            ),
            SQLiteCollection::new(
                "nested_col".to_string(),
                None,
                vec![SQLiteProperty::new("prop1", DataType::Long, None)],
                vec![],
            ),
        ];
        let mut qb = SQLiteQueryBuilder::new(&cols, 0);

        let inner_cond = Filter::new_condition(1, Equal, vec![Some(IsarValue::Integer(42))], true);
        let nested = Filter::new_embedded(1, inner_cond);
        qb.set_filter(nested);
        let sql = qb.build_query();

        assert_sql!(
            sql,
            "WHERE isar_filter_json(nested_obj, ?)",
            JsonCondition(JsonCondition {
                path: vec!["prop1".to_string()],
                condition_type: Equal,
                values: vec![Some(IsarValue::Integer(42))],
                case_sensitive: true,
            })
        );
    }

    #[test]
    fn test_embedded_filter_and_or_not() {
        let cols = vec![
            SQLiteCollection::new(
                "col".to_string(),
                Some("id".to_string()),
                vec![SQLiteProperty::new("nested_obj", DataType::Object, Some(1))],
                vec![],
            ),
            SQLiteCollection::new(
                "nested_col".to_string(),
                None,
                vec![
                    SQLiteProperty::new("prop1", DataType::Long, None),
                    SQLiteProperty::new("prop2", DataType::String, None),
                ],
                vec![],
            ),
        ];
        let mut qb = SQLiteQueryBuilder::new(&cols, 0);

        let cond1 = Filter::new_condition(1, Less, vec![Some(IsarValue::Integer(12))], true);
        let cond2 = Filter::new_condition(
            2,
            Equal,
            vec![Some(IsarValue::String("22".to_string()))],
            false,
        );
        let inner_cond = Filter::new_and(vec![
            Filter::new_or(vec![Filter::new_not(cond2.clone()), cond1]),
            cond2,
        ]);
        let nested = Filter::new_embedded(1, inner_cond);
        qb.set_filter(nested);
        let sql = qb.build_query();

        assert_sql!(
            sql,
            "WHERE ((NOT isar_filter_json(nested_obj, ?) OR isar_filter_json(nested_obj, ?)) AND isar_filter_json(nested_obj, ?))",
            JsonCondition(JsonCondition {
                path: vec!["prop2".to_string()],
                condition_type: Equal,
                values: vec![Some(IsarValue::String("22".to_string()))],
                case_sensitive: false,
            }),
            JsonCondition(JsonCondition {
                path: vec!["prop1".to_string()],
                condition_type: Less,
                values: vec![Some(IsarValue::Integer(12))],
                case_sensitive: true,
            }),
            JsonCondition(JsonCondition {
                path: vec!["prop2".to_string()],
                condition_type: Equal,
                values: vec![Some(IsarValue::String("22".to_string()))],
                case_sensitive: false,
            })
        );
    }
}
