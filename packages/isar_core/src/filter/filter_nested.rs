use super::Filter;

#[derive(PartialEq, Clone, Debug)]
pub struct FilterNested {
    collection_index: u16,
    filter: Box<Filter>,
}

impl FilterNested {
    pub fn new(collection_index: u16, filter: Filter) -> Self {
        FilterNested {
            collection_index,
            filter: Box::new(filter),
        }
    }
}
