use super::Filter;

#[derive(PartialEq, Clone, Debug)]
pub struct FilterNested {
    collection_index: usize,
    filter: Box<Filter>,
}

impl FilterNested {
    pub fn new(collection_index: usize, filter: Filter) -> Self {
        FilterNested {
            collection_index,
            filter: Box::new(filter),
        }
    }
}
