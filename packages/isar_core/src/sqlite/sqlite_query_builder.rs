use super::sqlite_collection::SQLiteCollection;
use super::sqlite_filter::SQLiteFilter;
use super::sqlite_query::SQLiteQuery;
use crate::core::query_builder::{IsarQueryBuilder, Sort};
use itertools::Itertools;

pub struct SQLiteQueryBuilder<'a> {
    pub(crate) collection: &'a SQLiteCollection,
    pub(crate) all_collections: &'a Vec<SQLiteCollection>,
    filter: Option<SQLiteFilter>,
    sort: Vec<(&'a str, Sort)>,
    offset: Option<usize>,
    limit: Option<usize>,
}

impl SQLiteQueryBuilder<'_> {
    pub fn new<'a>(
        collection: &'a SQLiteCollection,
        all_collections: &'a Vec<SQLiteCollection>,
    ) -> SQLiteQueryBuilder<'a> {
        SQLiteQueryBuilder {
            collection,
            all_collections,
            filter: None,
            sort: Vec::new(),
            offset: None,
            limit: None,
        }
    }
}

impl<'a> IsarQueryBuilder for SQLiteQueryBuilder<'a> {
    type Filter = SQLiteFilter;

    type Query = SQLiteQuery<'a>;

    fn set_filter(&mut self, filter: Self::Filter) {
        self.filter = Some(filter);
    }

    fn add_sort(&mut self, property_index: usize, sort: Sort) {
        let prop = if property_index == 0 {
            "_rowid_"
        } else {
            &self.collection.properties[property_index - 1].name
        };
        self.sort.push((prop, sort));
    }

    fn set_offset(&mut self, offset: usize) {
        self.offset = Some(offset);
    }

    fn set_limit(&mut self, limit: usize) {
        self.limit = Some(limit);
    }

    fn build(self) -> Self::Query {
        let mut sql = String::new();
        sql.push_str("FROM ");
        sql.push_str(&self.collection.name);
        if let Some(filter) = self.filter {
            sql.push_str(" WHERE ");
            sql.push_str(&filter.sql);
        }
        if !self.sort.is_empty() {
            sql.push_str(" ORDER BY ");
            sql.push_str(
                &self
                    .sort
                    .iter()
                    .map(|(prop, sort)| match sort {
                        Sort::Asc => format!("{} ASC", prop),
                        Sort::Desc => format!("{} DESC", prop),
                    })
                    .join(","),
            );
        }
        if let Some(offset) = self.offset {
            sql.push_str(" OFFSET ");
            sql.push_str(&offset.to_string());
        }
        if let Some(limit) = self.limit {
            sql.push_str(" LIMIT ");
            sql.push_str(&limit.to_string());
        }

        SQLiteQuery::new(sql, self.collection, self.all_collections)
    }
}
