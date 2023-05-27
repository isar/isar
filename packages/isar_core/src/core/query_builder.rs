use super::filter::Filter;

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Sort {
    Asc,
    Desc,
}

pub trait IsarQueryBuilder {
    type Query;

    fn set_filter(&mut self, filter: Filter);

    fn add_sort(&mut self, property_index: u16, sort: Sort, case_sensitive: bool);

    fn add_distinct(&mut self, property_index: u16, case_sensitive: bool);

    fn build(self) -> Self::Query;
}
