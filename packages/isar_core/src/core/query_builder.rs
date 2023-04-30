use crate::filter::Filter;

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Sort {
    Asc,
    Desc,
}

pub trait IsarQueryBuilder {
    type Query;

    fn set_filter(&mut self, filter: Filter);

    fn add_sort(&mut self, property_index: u16, sort: Sort);

    fn set_offset(&mut self, offset: u32);

    fn set_limit(&mut self, limit: u32);

    fn build(self) -> Self::Query;
}
