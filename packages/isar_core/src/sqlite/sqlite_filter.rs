use super::sqlite_query_builder::SQLiteQueryBuilder;
use crate::core::filter::{IsarFilterBuilder, IsarValue};
use itertools::Itertools;

pub struct SQLiteFilter {
    pub(crate) sql: String,
}

fn value_to_sql(value: IsarValue) -> String {
    match value {
        IsarValue::Bool(b) => b.to_string(),
        IsarValue::Integer(i) => i.to_string(),
        IsarValue::Real(r) => r.to_string(),
        IsarValue::String(s) => format!("'{}'", s),
    }
}

fn get_prop_name<'a>(qb: &'a SQLiteQueryBuilder, property_index: usize) -> &'a str {
    if property_index == 0 {
        "_rowid_"
    } else {
        &qb.collection.properties[property_index - 1].name
    }
}

impl<'a> IsarFilterBuilder for SQLiteQueryBuilder<'a> {
    type Filter = SQLiteFilter;

    fn null(&self, property_index: usize) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        SQLiteFilter {
            sql: format!("{} IS NULL", prop),
        }
    }

    fn not_null(&self, property_index: usize) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        SQLiteFilter {
            sql: format!("{} IS NOT NULL", prop),
        }
    }

    fn gt(&self, property_index: usize, value: IsarValue) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        SQLiteFilter {
            sql: format!("{} > {}", prop, value_to_sql(value)),
        }
    }

    fn gte(&self, property_index: usize, value: IsarValue) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        SQLiteFilter {
            sql: format!("{} >= {}", prop, value_to_sql(value)),
        }
    }

    fn lt(&self, property_index: usize, value: IsarValue) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        SQLiteFilter {
            sql: format!("{} < {}", prop, value_to_sql(value)),
        }
    }

    fn lte(&self, property_index: usize, value: IsarValue) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        SQLiteFilter {
            sql: format!("{} <= {}", prop, value_to_sql(value)),
        }
    }

    fn eq(&self, property_index: usize, value: IsarValue) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        SQLiteFilter {
            sql: format!("{} = {}", prop, value_to_sql(value)),
        }
    }

    fn neq(&self, property_index: usize, value: IsarValue) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        SQLiteFilter {
            sql: format!("{} != {}", prop, value_to_sql(value)),
        }
    }

    fn between(&self, property_index: usize, lower: IsarValue, upper: IsarValue) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        SQLiteFilter {
            sql: format!(
                "{} BETWEEN {} AND {}",
                prop,
                value_to_sql(lower),
                value_to_sql(upper)
            ),
        }
    }

    fn in_list(&self, property_index: usize, values: Vec<IsarValue>) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        let sql = values.into_iter().map(|v| value_to_sql(v)).join(", ");
        SQLiteFilter {
            sql: format!("{} IN ({})", prop, sql),
        }
    }

    fn starts_with(&self, property_index: usize, value: &str) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        SQLiteFilter {
            sql: format!("{} LIKE '{}%'", prop, value),
        }
    }

    fn ends_with(&self, property_index: usize, value: &str) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        SQLiteFilter {
            sql: format!("{} LIKE '%{}'", prop, value),
        }
    }

    fn contains(&self, property_index: usize, value: &str) -> Self::Filter {
        let prop = get_prop_name(self, property_index);
        SQLiteFilter {
            sql: format!("{} LIKE '%{}%'", prop, value),
        }
    }

    fn and(filters: Vec<Self::Filter>) -> Self::Filter {
        let sql = filters.into_iter().map(|filter| filter.sql).join(" AND ");
        SQLiteFilter {
            sql: format!("({})", sql),
        }
    }

    fn or(filters: Vec<Self::Filter>) -> Self::Filter {
        let sql = filters.into_iter().map(|filter| filter.sql).join(" OR ");
        SQLiteFilter {
            sql: format!("({})", sql),
        }
    }

    fn not(filter: Self::Filter) -> Self::Filter {
        SQLiteFilter {
            sql: format!("NOT {}", filter.sql),
        }
    }
}
