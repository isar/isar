use crate::filter::Filter;

pub enum Sort {
    Asc,
    Desc,
}

pub trait IsarQueryBuilder {
    type Query;

    fn set_filter(&mut self, filter: Filter);

    fn add_sort(&mut self, property_index: usize, sort: Sort);

    fn set_offset(&mut self, offset: usize);

    fn set_limit(&mut self, limit: usize);

    fn build(self) -> Self::Query;
}
