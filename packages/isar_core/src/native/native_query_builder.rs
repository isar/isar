use super::native_collection::{NativeCollection, NativeProperty};
use super::native_filter::NativeFilter;
use super::query::{Query, QueryIndex};
use crate::core::data_type::DataType;
use crate::core::filter::{ConditionType, Filter, FilterCondition};
use crate::core::query_builder::{IsarQueryBuilder, Sort};
use crate::core::value::IsarValue;
use std::hint::black_box;

pub struct NativeQueryBuilder<'a> {
    instance_id: u32,
    collection: &'a NativeCollection,
    all_collections: &'a [NativeCollection],
    filter: Option<Filter>,
    sort: Vec<(Option<NativeProperty>, Sort, bool)>,
    distinct: Vec<(NativeProperty, bool)>,
}

impl<'a> NativeQueryBuilder<'a> {
    pub fn new(
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
    type Query = Query;

    fn set_filter(&mut self, filter: Filter) {
        self.filter = Some(filter);
    }

    fn add_sort(&mut self, property_index: u16, sort: Sort, case_sensitive: bool) {
        let property = self.collection.get_property(property_index as u32);
        self.sort.push((property.copied(), sort, case_sensitive));
    }

    fn add_distinct(&mut self, property_index: u16, case_sensitive: bool) {
        let property = self.collection.get_property(property_index as u32);
        if let Some(property) = property {
            self.distinct.push((*property, case_sensitive));
        }
    }

    fn build(self) -> Self::Query {
        let filter = self
            .filter
            .map(|f| f.to_native_filter(self.collection, self.all_collections))
            .unwrap_or(NativeFilter::stat(true));
        black_box(Query::new(
            self.instance_id,
            self.collection.collection_index,
            vec![QueryIndex::Primary(i64::MIN, i64::MAX)],
            filter,
            self.sort,
            self.distinct,
        ))
    }
}

impl Filter {
    fn to_native_filter(
        &self,
        collection: &NativeCollection,
        all_collections: &[NativeCollection],
    ) -> NativeFilter {
        match self {
            Filter::Condition(condition) => condition
                .to_native_filter(collection)
                .unwrap_or(NativeFilter::stat(false)),
            Filter::Nested(_) => todo!(),
            Filter::And(filters) => {
                let filters = filters
                    .iter()
                    .map(|f| f.to_native_filter(collection, all_collections))
                    .collect();
                NativeFilter::and(filters)
            }
            Filter::Or(filters) => {
                let filters = filters
                    .iter()
                    .map(|f| f.to_native_filter(collection, all_collections))
                    .collect();
                NativeFilter::or(filters)
            }
            Filter::Not(filter) => {
                let filter = filter.to_native_filter(collection, all_collections);
                NativeFilter::not(filter)
            }
        }
    }
}

impl FilterCondition {
    fn to_native_filter(&self, collection: &NativeCollection) -> Option<NativeFilter> {
        let property = collection.get_property(self.property_index);
        let filter = match self.condition_type {
            ConditionType::IsNull => NativeFilter::is_null(property?),
            ConditionType::ListIsEmpty => NativeFilter::list_is_empty(property?),
            ConditionType::Equal => {
                let value = self.values.get(0)?;
                Self::native_between_filter(property, value, value, self.case_sensitive)?
            }
            ConditionType::Greater => {
                let value = self.values.get(0)?;
                Self::native_between_filter(
                    property,
                    &value.try_increment()?,
                    &value.get_max(),
                    self.case_sensitive,
                )?
            }
            ConditionType::GreaterOrEqual => {
                let value = self.values.get(0)?;
                Self::native_between_filter(property, value, &value.get_max(), self.case_sensitive)?
            }
            ConditionType::Less => {
                let value = self.values.get(0)?;
                Self::native_between_filter(
                    property,
                    &value.get_null(),
                    &value.try_decrement()?,
                    self.case_sensitive,
                )?
            }
            ConditionType::LessOrEqual => {
                let value = self.values.get(0)?;
                Self::native_between_filter(
                    property,
                    &value.get_null(),
                    value,
                    self.case_sensitive,
                )?
            }
            ConditionType::Between => {
                let lower = self.values.get(0)?;
                let upper = self.values.get(1)?;
                Self::native_between_filter(property, lower, upper, self.case_sensitive)?
            }
            ConditionType::StringStartsWith => {
                let lower = self.values.get(0)?.string()??;
                let upper = format!("{}{}", lower, IsarValue::MAX_STRING);
                NativeFilter::string(property?, Some(lower), Some(&upper), self.case_sensitive)
            }
            ConditionType::StringEndsWith => {
                let value = self.values.get(0)?.string()??;
                NativeFilter::string_ends_with(property?, value, self.case_sensitive)
            }
            ConditionType::StringContains => {
                let value = self.values.get(0)?.string()??;
                NativeFilter::string_contains(property?, value, self.case_sensitive)
            }
            ConditionType::StringMatches => {
                let value = self.values.get(0)?.string()??;
                NativeFilter::string_matches(property?, value, self.case_sensitive)
            }
        };
        Some(filter)
    }

    fn native_between_filter(
        property: Option<&NativeProperty>,
        lower: &IsarValue,
        upper: &IsarValue,
        case_sensitive: bool,
    ) -> Option<NativeFilter> {
        let filter = if let Some(property) = property {
            match property.data_type {
                DataType::Bool | DataType::BoolList => {
                    NativeFilter::bool(property, lower.bool()?, upper.bool()?)
                }
                DataType::Byte | DataType::ByteList => {
                    let lower = Self::adjust_int(lower.integer()?, u8::MIN as i64, u8::MAX as i64);
                    let upper = Self::adjust_int(upper.integer()?, u8::MIN as i64, u8::MAX as i64);
                    NativeFilter::byte(property, lower.try_into().ok()?, upper.try_into().ok()?)
                }
                DataType::Int | DataType::IntList => {
                    let lower =
                        Self::adjust_int(lower.integer()?, i32::MIN as i64, i32::MAX as i64);
                    let upper =
                        Self::adjust_int(upper.integer()?, i32::MIN as i64, i32::MAX as i64);
                    NativeFilter::int(property, lower.try_into().ok()?, upper.try_into().ok()?)
                }
                DataType::Float | DataType::FloatList => {
                    NativeFilter::float(property, lower.real()? as f32, upper.real()? as f32)
                }
                DataType::Long | DataType::LongList => {
                    NativeFilter::long(property, lower.integer()?, upper.integer()?)
                }
                DataType::Double | DataType::DoubleList => {
                    NativeFilter::double(property, lower.real()?, upper.real()?)
                }
                DataType::String | DataType::StringList => {
                    NativeFilter::string(property, lower.string()?, upper.string()?, case_sensitive)
                }
                DataType::Object | DataType::ObjectList => return None,
            }
        } else {
            NativeFilter::id(lower.integer()?, upper.integer()?)
        };
        Some(filter)
    }

    fn adjust_int(value: i64, min: i64, max: i64) -> i64 {
        if value == i64::MIN {
            min
        } else if value == i64::MIN + 1 {
            min + 1
        } else if value == i64::MAX {
            max
        } else if value == i64::MAX - 1 {
            max - 1
        } else {
            value
        }
    }
}
