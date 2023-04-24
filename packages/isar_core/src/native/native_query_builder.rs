use super::native_query::NativeQuery;
use crate::{
    core::query_builder::{IsarQueryBuilder, Sort},
    filter::Filter,
};

pub struct NativeQueryBuilder {}

pub struct NativeFilter {}

impl IsarQueryBuilder for NativeQueryBuilder {
    type Query = NativeQuery;

    fn set_filter(&mut self, filter: Filter) {
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
