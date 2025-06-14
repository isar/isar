use super::native_collection::{NativeCollection, NativeProperty};
use super::query::native_filter::NativeFilter;
use super::query::native_filter_from_filter::native_filter_from_filter;
use super::query::{NativeQuery, QueryIndex};
use crate::core::filter::Filter;
use crate::core::query_builder::{IsarQueryBuilder, Sort};

pub struct NativeQueryBuilder<'a> {
    instance_id: u32,
    collection: &'a NativeCollection,
    all_collections: &'a [NativeCollection],
    filter: Option<Filter>,
    // property/id, direction, case_sensitive
    sort: Vec<(Option<NativeProperty>, Sort, bool)>,
    // property, case_sensitive
    distinct: Vec<(NativeProperty, bool)>,
}

impl<'a> NativeQueryBuilder<'a> {
    pub(crate) fn new(
        instance_id: u32,
        collection: &'a NativeCollection,
        all_collections: &'a [NativeCollection],
    ) -> Self {
        Self {
            instance_id,
            collection,
            all_collections,
            filter: None,
            sort: Vec::new(),
            distinct: Vec::new(),
        }
    }
}

impl<'a> IsarQueryBuilder for NativeQueryBuilder<'a> {
    type Query = NativeQuery;

    fn set_filter(&mut self, filter: Filter) {
        self.filter = Some(filter);
    }

    fn add_sort(&mut self, property_index: u16, sort: Sort, case_sensitive: bool) {
        let property = self.collection.get_property(property_index);
        self.sort.push((property.copied(), sort, case_sensitive));
    }

    fn add_distinct(&mut self, property_index: u16, case_sensitive: bool) {
        let property = self.collection.get_property(property_index);
        if let Some(property) = property {
            self.distinct.push((*property, case_sensitive));
        }
    }

    fn build(self) -> Self::Query {
        //let sort_index_match = index_matching_sort(&self.collection.indexes, &self.sort);

        let filter = if let Some(filter) = self.filter {
            if let Some(native_filter) =
                native_filter_from_filter(&filter, self.collection, self.all_collections)
            {
                native_filter
            } else {
                // filter statically evaluated to false
                NativeFilter::stat(false)
            }
        } else {
            // no filter
            NativeFilter::stat(true)
        };

        NativeQuery::new(
            self.instance_id,
            self.collection.collection_index,
            vec![QueryIndex::Primary(i64::MIN, i64::MAX)],
            filter,
            self.sort,
            self.distinct,
        )
    }
}
