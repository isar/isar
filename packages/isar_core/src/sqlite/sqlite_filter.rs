use crate::filter::{filter_value::IsarValue, Filter};

use super::{sqlite_collection::SQLiteCollection, sqlite_query_builder::SQLiteQueryBuilder};
use intmap::IntMap;
use itertools::Itertools;

pub struct SQLiteFilter {
    sql: String,
    embedded_filters: IntMap<Filter>,
}

/*impl SQLiteFilter {
    pub fn from_filter(filter: Filter) -> Option<SQLiteFilter> {
        if let Some(filter) = &qb.filter {
            let mut sql = String::new();
            sql.push_str("WHERE ");
            sql.push_str(&filter_to_sql(qb, filter));
            Some(SQLiteFilter { sql })
        } else {
            None
        }
    }

    fn filter_to_sql(
        collection_index: usize,
        filter: &Filter,
        all_collections: &IntMap<SQLiteCollection>,
    ) -> String {
    }
}*/

fn value_to_sql(value: IsarValue) -> String {
    match value {
        IsarValue::Bool(b) => {
            if let Some(b) = b {
                if b {
                    "TRUE".to_string()
                } else {
                    "FALSE".to_string()
                }
            } else {
                "NULL".to_string()
            }
        }
        IsarValue::Integer(i) => i.to_string(),
        IsarValue::Real(r) => {
            if r.is_nan() {
                "NULL".to_string()
            } else if r.is_infinite() {
                if r.is_sign_positive() {
                    "9e999".to_string()
                } else {
                    "-9e999".to_string()
                }
            } else {
                r.to_string()
            }
        }
        IsarValue::String(s) => {
            if let Some(s) = s {
                let mut escaped = s.replace("'", "''");
                escaped.insert(0, '\'');
                escaped.push('\'');
                escaped
            } else {
                "NULL".to_string()
            }
        }
    }
}

fn get_prop_name<'a>(qb: &'a SQLiteQueryBuilder, property_index: usize) -> &'a str {
    if property_index == 0 {
        "_rowid_"
    } else {
        &qb.collection.properties[property_index - 1].name
    }
}

fn collate(case_insensitive: bool) -> &'static str {
    if case_insensitive {
        " COLLATE NOCASE"
    } else {
        ""
    }
}

macro_rules! filter {
    ($($arg:tt)*) => {{
        SQLiteFilter { sql: format!($($arg)*) }
    }};
}

/*impl<'a> IsarFilterBuilder for SQLiteQueryBuilder<'a> {
    type Filter = SQLiteFilter;

    fn gt(
        &self,
        collection_index: usize,
        property_index: usize,
        value: IsarValue,
        case_insensitive: bool,
    ) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        if let IsarValue::Null = value {
            filter!("{} IS NOT NULL", prop)
        } else {
            filter!(
                "{} > {} {}",
                prop,
                value_to_sql(value),
                collate(case_insensitive)
            )
        }
    }

    fn lt(
        &self,
        collection_index: usize,
        property_index: usize,
        value: IsarValue,
        case_insensitive: bool,
    ) -> Self::Filter {
        if let IsarValue::Null = value {
            filter!("FALSE")
        } else {
            let prop = get_prop_name(self, property_index);
            filter!(
                "{} < {} {}",
                prop,
                value_to_sql(value),
                collate(case_insensitive)
            )
        }
    }

    fn eq(
        &self,
        collection_index: usize,
        property_index: usize,
        value: IsarValue,
        case_insensitive: bool,
    ) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        filter!(
            "{} IS {} {}",
            prop,
            value_to_sql(value),
            collate(case_insensitive)
        )
    }

    /*fn in_list(
        &self,
        collection_index: usize,
        property_index: usize,
        values: Vec<IsarValue>,
        case_insensitive: bool,
    ) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        let sql = values.into_iter().map(|v| value_to_sql(v)).join(", ");
        filter!("{} IN {} ({})", prop, collate(case_insensitive), sql)
    }*/

    fn starts_with(
        &self,
        collection_index: usize,
        property_index: usize,
        value: &str,
        case_insensitive: bool,
    ) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        filter!("{} GLOB '{}*'", prop, value)
    }

    fn ends_with(
        &self,
        collection_index: usize,
        property_index: usize,
        value: &str,
        case_insensitive: bool,
    ) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        filter!("{} LIKE '%{}'", prop, value)
    }

    fn contains(
        &self,
        collection_index: usize,
        property_index: usize,
        value: &str,
        case_insensitive: bool,
    ) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        filter!("{} LIKE '%{}%'", prop, value)
    }

    fn matches(
        &self,
        collection_index: usize,
        property_index: usize,
        value: &str,
        case_insensitive: bool,
    ) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        filter!("{} LIKE '{}'", prop, value)
    }

    fn and(filters: Vec<Self::Filter>) -> Self::Filter {
        let sql = filters.into_iter().map(|filter| filter.sql).join(" AND ");
        filter!("({})", sql)
    }

    fn or(filters: Vec<Self::Filter>) -> Self::Filter {
        let sql = filters.into_iter().map(|filter| filter.sql).join(" OR ");
        filter!("({})", sql)
    }

    fn xor(filters: Vec<Self::Filter>) -> Self::Filter {
        filter!("FALSE")
    }

    fn not(filter: Self::Filter) -> Self::Filter {
        filter!("NOT ({})", filter.sql)
    }
}
*/
