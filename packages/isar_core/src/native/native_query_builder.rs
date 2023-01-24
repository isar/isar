use super::native_filter::NativeFilter;
use super::native_query::NativeQuery;
use crate::core::query_builder::{IsarQueryBuilder, Sort};

pub struct NativeQueryBuilder {}

impl IsarQueryBuilder for NativeQueryBuilder {
    type Filter = NativeFilter;

    type Query = NativeQuery;

    fn set_filter(&mut self, filter: Self::Filter) {
        todo!()
    }

    fn add_sort(&mut self, property_index: usize, sort: Sort) {
        todo!()
    }

    fn set_offset(&mut self, offset: usize) {
        todo!()
    }

    fn set_limit(&mut self, limit: usize) {
        todo!()
    }

    fn build(self) -> Self::Query {
        todo!()
    }
}
