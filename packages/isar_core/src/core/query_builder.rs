pub enum Sort {
    Asc,
    Desc,
}

pub trait IsarQueryBuilder {
    type Filter;
    type Query;

    fn set_filter(&mut self, filter: Self::Filter);

    fn add_sort(&mut self, property_index: usize, sort: Sort);

    fn set_offset(&mut self, offset: usize);

    fn set_limit(&mut self, limit: usize);

    fn build(self) -> Self::Query;
}
