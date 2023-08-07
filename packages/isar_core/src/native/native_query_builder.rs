use super::native_collection::{NativeCollection, NativeProperty};
use super::query::native_filter::NativeFilter;
use super::query::{NativeQuery, QueryIndex};
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
        let filter = self
            .filter
            .map(|f| filter_to_native(&f, self.collection, self.all_collections))
            .unwrap_or(NativeFilter::stat(true));

        black_box(NativeQuery::new(
            self.instance_id,
            self.collection.collection_index,
            vec![QueryIndex::Primary(i64::MIN, i64::MAX)],
            filter,
            self.sort,
            self.distinct,
        ))
    }
}

fn filter_to_native(
    filter: &Filter,
    collection: &NativeCollection,
    all_collections: &[NativeCollection],
) -> NativeFilter {
    match filter {
        Filter::Condition(condition) => {
            condition_to_native(condition, collection).unwrap_or(NativeFilter::stat(false))
        }
        Filter::Json(_) => todo!(),
        Filter::Nested(nested) => {
            if let Some(property) = collection.get_property(nested.property_index) {
                if let Some(embedded_collection_index) = property.embedded_collection_index {
                    let embedded_collection = &all_collections[embedded_collection_index as usize];
                    let filter =
                        filter_to_native(&nested.filter, embedded_collection, all_collections);
                    return NativeFilter::nested(property, filter);
                }
            }
            NativeFilter::stat(false)
        }
        Filter::And(filters) => {
            let filters = filters
                .iter()
                .map(|f| filter_to_native(f, collection, all_collections))
                .collect();
            NativeFilter::and(filters)
        }
        Filter::Or(filters) => {
            let filters = filters
                .iter()
                .map(|f| filter_to_native(f, collection, all_collections))
                .collect();
            NativeFilter::or(filters)
        }
        Filter::Not(filter) => {
            let filter = filter_to_native(filter, collection, all_collections);
            NativeFilter::not(filter)
        }
    }
}

fn condition_to_native(
    condition: &FilterCondition,
    collection: &NativeCollection,
) -> Option<NativeFilter> {
    let property = collection.get_property(condition.property_index);
    let filter = match condition.condition_type {
        ConditionType::IsNull => NativeFilter::is_null(property?),
        ConditionType::Equal => {
            let value = condition.values.get(0)?;
            native_between_filter(
                property,
                value.as_ref(),
                true,
                value.as_ref(),
                true,
                condition.case_sensitive,
            )?
        }
        ConditionType::Greater => native_between_filter(
            property,
            condition.values.get(0)?.as_ref(),
            false,
            get_max(property).as_ref(),
            true,
            condition.case_sensitive,
        )?,
        ConditionType::GreaterOrEqual => native_between_filter(
            property,
            condition.values.get(0)?.as_ref(),
            true,
            get_max(property).as_ref(),
            true,
            condition.case_sensitive,
        )?,
        ConditionType::Less => native_between_filter(
            property,
            None,
            true,
            condition.values.get(0)?.as_ref(),
            false,
            condition.case_sensitive,
        )?,
        ConditionType::LessOrEqual => native_between_filter(
            property,
            None,
            true,
            condition.values.get(0)?.as_ref(),
            true,
            condition.case_sensitive,
        )?,
        ConditionType::Between => native_between_filter(
            property,
            condition.values.get(0)?.as_ref(),
            true,
            condition.values.get(1)?.as_ref(),
            true,
            condition.case_sensitive,
        )?,
        ConditionType::StringStartsWith => {
            let lower = condition.values.get(0)?.as_ref()?.string()?;
            let upper = format!("{}{}", lower, IsarValue::MAX_STRING);
            NativeFilter::string(
                property?,
                Some(lower),
                Some(&upper),
                condition.case_sensitive,
            )
        }
        ConditionType::StringEndsWith => {
            let value = condition.values.get(0)?.as_ref()?.string()?;
            NativeFilter::string_ends_with(property?, value, condition.case_sensitive)
        }
        ConditionType::StringContains => {
            let value = condition.values.get(0)?.as_ref()?.string()?;
            NativeFilter::string_contains(property?, value, condition.case_sensitive)
        }
        ConditionType::StringMatches => {
            let value = condition.values.get(0)?.as_ref()?.string()?;
            NativeFilter::string_matches(property?, value, condition.case_sensitive)
        }
    };
    Some(filter)
}

fn native_between_filter(
    property: Option<&NativeProperty>,
    lower: Option<&IsarValue>,
    include_lower: bool,
    upper: Option<&IsarValue>,
    include_upper: bool,
    case_sensitive: bool,
) -> Option<NativeFilter> {
    let filter = if let Some(property) = property {
        match property.data_type {
            DataType::Bool | DataType::BoolList => {
                let mut lower = if let Some(lower) = lower {
                    Some(lower.bool()?)
                } else {
                    None
                };
                if !include_lower {
                    lower = match lower {
                        None => Some(false),
                        Some(false) => Some(true),
                        Some(true) => return None,
                    }
                }
                let mut upper = if let Some(upper) = upper {
                    Some(upper.bool()?)
                } else {
                    None
                };
                if !include_upper {
                    upper = match upper {
                        Some(true) => Some(false),
                        Some(false) => None,
                        None => return None,
                    }
                }
                NativeFilter::bool(property, lower, upper)
            }
            DataType::Byte | DataType::ByteList => {
                let mut lower = if let Some(lower) = lower {
                    lower.u8()?
                } else {
                    u8::MIN
                };
                if !include_lower {
                    lower = lower.checked_add(1)?;
                }
                let mut upper = if let Some(upper) = upper {
                    upper.u8()?
                } else {
                    u8::MAX
                };
                if !include_upper {
                    upper = upper.checked_sub(1)?;
                }
                NativeFilter::byte(property, lower, upper)
            }
            DataType::Int | DataType::IntList => {
                let mut lower = if let Some(lower) = lower {
                    lower.i32()?
                } else {
                    i32::MIN
                };
                if !include_lower {
                    lower = lower.checked_add(1)?;
                }
                let mut upper = if let Some(upper) = upper {
                    upper.i32()?
                } else {
                    i32::MIN
                };
                if !include_upper {
                    upper = upper.checked_sub(1)?;
                }
                NativeFilter::int(property, lower, upper)
            }
            DataType::Float | DataType::FloatList => {
                let lower = lower_real(lower, include_lower)?;
                let upper = upper_real(upper, include_upper)?;
                NativeFilter::float(property, lower as f32, upper as f32)
            }
            DataType::Long | DataType::LongList => {
                let mut lower = if let Some(lower) = lower {
                    lower.i64()?
                } else {
                    i64::MIN
                };
                if !include_lower {
                    lower = lower.checked_add(1)?;
                }
                let mut upper = if let Some(upper) = upper {
                    upper.i64()?
                } else {
                    i64::MIN
                };
                if !include_upper {
                    upper = upper.checked_sub(1)?;
                }
                NativeFilter::long(property, lower, upper)
            }
            DataType::Double | DataType::DoubleList => {
                let lower = lower_real(lower, include_lower)?;
                let upper = upper_real(upper, include_upper)?;
                NativeFilter::double(property, lower, upper)
            }
            DataType::String | DataType::StringList | DataType::Json => {
                let lower = if let Some(lower) = lower {
                    let mut lower = lower.string()?.to_string();
                    if !include_lower {
                        if lower.is_empty() {
                            lower.push('\u{0}');
                        } else {
                            let last_char = lower.pop()?;
                            let new_last_char = char::from_u32((last_char as u32).checked_add(1)?)?;
                            lower.push(new_last_char);
                        }
                    }
                    Some(lower)
                } else if !include_lower {
                    Some(String::new())
                } else {
                    None
                };

                let upper = if let Some(upper) = upper {
                    let mut upper = upper.string()?.to_string();
                    if !include_upper {
                        if upper.is_empty() {
                            None
                        } else {
                            let last_char = upper.pop()? as u32;
                            if last_char > 0 {
                                upper.push(char::from_u32(last_char - 1)?);
                            }
                            Some(upper)
                        }
                    } else {
                        Some(upper)
                    }
                } else if !include_upper {
                    return None; // cannot exclude
                } else {
                    None
                };

                NativeFilter::string(property, lower.as_deref(), upper.as_deref(), case_sensitive)
            }
            DataType::Object | DataType::ObjectList => return None,
        }
    } else {
        let mut lower = if let Some(lower) = lower {
            lower.i64()?
        } else {
            i64::MIN
        };
        if !include_lower {
            lower = lower.checked_add(1)?;
        }
        let mut upper = if let Some(upper) = upper {
            upper.i64()?
        } else {
            i64::MIN
        };
        if !include_upper {
            upper = upper.checked_sub(1)?;
        }
        NativeFilter::id(lower, upper)
    };
    Some(filter)
}

fn lower_real(value: Option<&IsarValue>, include: bool) -> Option<f64> {
    let mut value = if let Some(value) = value {
        value.real()?
    } else {
        f64::NAN
    };
    if !include {
        if value.is_nan() {
            value = f64::NEG_INFINITY
        } else if value == f64::INFINITY {
            return None;
        } else {
            value = (value as f32).next_up() as f64;
        }
    }

    Some(value)
}

fn upper_real(value: Option<&IsarValue>, include: bool) -> Option<f64> {
    let mut value = if let Some(value) = value {
        value.real()?
    } else {
        f64::NAN
    };
    if !include {
        if value.is_nan() {
            return None;
        } else if value == f64::NEG_INFINITY {
            value = f64::NAN;
        } else {
            value = (value as f32).next_up() as f64;
        }
    }

    Some(value)
}

fn get_max(property: Option<&NativeProperty>) -> Option<IsarValue> {
    let value = if let Some(property) = property {
        match property.data_type {
            DataType::Bool | DataType::BoolList => IsarValue::Bool(true),
            DataType::Byte | DataType::ByteList => IsarValue::Integer(u8::MAX as i64),
            DataType::Int | DataType::IntList => IsarValue::Integer(i32::MAX as i64),
            DataType::Float | DataType::FloatList => IsarValue::Real(f64::INFINITY),
            DataType::Long | DataType::LongList => IsarValue::Integer(i64::MAX),
            DataType::Double | DataType::DoubleList => IsarValue::Real(f64::INFINITY),
            DataType::String | DataType::StringList | DataType::Json => {
                IsarValue::String(IsarValue::MAX_STRING.to_string())
            }
            DataType::Object | DataType::ObjectList => return None,
        }
    } else {
        IsarValue::Integer(i64::MAX)
    };
    Some(value)
}
