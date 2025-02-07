use super::native_collection::{NativeCollection, NativeProperty};
use super::query::native_filter::NativeFilter;
use super::query::{NativeQuery, QueryIndex};
use crate::core::data_type::DataType;
use crate::core::filter::{ConditionType, Filter, FilterCondition};
use crate::core::query_builder::{IsarQueryBuilder, Sort};
use crate::core::value::IsarValue;

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

fn filter_to_native(
    filter: &Filter,
    collection: &NativeCollection,
    all_collections: &[NativeCollection],
) -> NativeFilter {
    match filter {
        Filter::Condition(condition) => {
            condition_to_native(condition, collection).unwrap_or(NativeFilter::stat(false))
        }
        Filter::Json(json) => {
            if let Some(property) = collection.get_property(json.property_index) {
                return NativeFilter::json(
                    property,
                    json.path.clone(),
                    json.condition_type,
                    json.values.clone(),
                    json.case_sensitive,
                );
            }
            NativeFilter::stat(false)
        }
        Filter::Embedded(embedded) => {
            if let Some(property) = collection.get_property(embedded.property_index) {
                if let Some(embedded_collection_index) = property.embedded_collection_index {
                    let embedded_collection = &all_collections[embedded_collection_index as usize];
                    let filter =
                        filter_to_native(&embedded.filter, embedded_collection, all_collections);
                    return NativeFilter::embedded(property, filter);
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
                let lower = lower_bool(lower, include_lower)?;
                let upper = upper_bool(upper, include_upper)?;
                NativeFilter::bool(property, lower, upper)
            }
            DataType::Byte | DataType::ByteList => {
                let lower = lower_byte(lower, include_lower)?;
                let upper = upper_byte(upper, include_upper)?;
                NativeFilter::byte(property, lower, upper)
            }
            DataType::Int | DataType::IntList => {
                let lower = lower_int(lower, include_lower)?;
                let upper = upper_int(upper, include_upper)?;
                NativeFilter::int(property, lower, upper)
            }
            DataType::Float | DataType::FloatList => {
                let lower = lower_real(lower, include_lower)?;
                let upper = upper_real(upper, include_upper)?;
                NativeFilter::float(property, lower as f32, upper as f32)
            }
            DataType::Long | DataType::LongList => {
                let lower = lower_long(lower, include_lower)?;
                let upper = upper_long(upper, include_upper)?;
                NativeFilter::long(property, lower, upper)
            }
            DataType::Double | DataType::DoubleList => {
                let lower = lower_real(lower, include_lower)?;
                let upper = upper_real(upper, include_upper)?;
                NativeFilter::double(property, lower, upper)
            }
            DataType::String | DataType::StringList | DataType::Json => {
                let lower = lower_string(lower, include_lower)?;
                let upper = upper_string(upper, include_upper)?;
                NativeFilter::string(property, lower.as_deref(), upper.as_deref(), case_sensitive)
            }
            DataType::Object | DataType::ObjectList => return None,
        }
    } else {
        let lower = lower_id(lower, include_lower)?;
        let upper = upper_id(upper, include_upper)?;
        NativeFilter::id(lower, upper)
    };
    Some(filter)
}

fn lower_bool(value: Option<&IsarValue>, include: bool) -> Option<Option<bool>> {
    let mut value = if let Some(value) = value {
        Some(value.bool()?)
    } else {
        None
    };
    if !include {
        value = match value {
            None => Some(false),
            Some(false) => Some(true),
            Some(true) => return None,
        }
    }
    Some(value)
}

fn upper_bool(value: Option<&IsarValue>, include: bool) -> Option<Option<bool>> {
    let mut value = if let Some(value) = value {
        Some(value.bool()?)
    } else {
        None
    };
    if !include {
        value = match value {
            Some(true) => Some(false),
            Some(false) => None,
            None => return None,
        }
    }
    Some(value)
}

fn lower_byte(value: Option<&IsarValue>, include: bool) -> Option<u8> {
    let value = if let Some(value) = value {
        value.u8()?
    } else {
        u8::MIN
    };
    if !include {
        value.checked_add(1)
    } else {
        Some(value)
    }
}

fn upper_byte(value: Option<&IsarValue>, include: bool) -> Option<u8> {
    let value = if let Some(value) = value {
        value.u8()?
    } else {
        u8::MAX
    };
    if !include {
        value.checked_sub(1)
    } else {
        Some(value)
    }
}

fn lower_int(value: Option<&IsarValue>, include: bool) -> Option<i32> {
    let value = if let Some(value) = value {
        value.i32()?
    } else {
        i32::MIN
    };
    if !include {
        value.checked_add(1)
    } else {
        Some(value)
    }
}

fn upper_int(value: Option<&IsarValue>, include: bool) -> Option<i32> {
    let value = if let Some(value) = value {
        value.i32()?
    } else {
        i32::MIN
    };
    if !include {
        value.checked_sub(1)
    } else {
        Some(value)
    }
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

fn lower_long(value: Option<&IsarValue>, include: bool) -> Option<i64> {
    let value = if let Some(value) = value {
        value.i64()?
    } else {
        i64::MIN
    };
    if !include {
        value.checked_add(1)
    } else {
        Some(value)
    }
}

fn upper_long(value: Option<&IsarValue>, include: bool) -> Option<i64> {
    let value = if let Some(value) = value {
        value.i64()?
    } else {
        i64::MIN
    };
    if !include {
        value.checked_sub(1)
    } else {
        Some(value)
    }
}

fn lower_string(value: Option<&IsarValue>, include: bool) -> Option<Option<String>> {
    let value = if let Some(value) = value {
        let mut value = value.string()?.to_string();
        if !include {
            if value.is_empty() {
                value.push('\u{0}');
            } else {
                let last_char = value.pop()?;
                let new_last_char = char::from_u32((last_char as u32).checked_add(1)?)?;
                value.push(new_last_char);
            }
        }
        Some(value)
    } else if !include {
        Some(String::new())
    } else {
        None
    };
    Some(value)
}

fn upper_string(value: Option<&IsarValue>, include: bool) -> Option<Option<String>> {
    let value = if let Some(value) = value {
        let mut value = value.string()?.to_string();
        if !include {
            if value.is_empty() {
                None
            } else {
                let last_char = value.pop()? as u32;
                if last_char > 0 {
                    value.push(char::from_u32(last_char - 1)?);
                }
                Some(value)
            }
        } else {
            Some(value)
        }
    } else if !include {
        return None; // cannot exclude
    } else {
        None
    };
    Some(value)
}

fn lower_id(value: Option<&IsarValue>, include: bool) -> Option<i64> {
    let value = if let Some(value) = value {
        value.i64()?
    } else {
        i64::MIN
    };
    if !include {
        value.checked_add(1)
    } else {
        Some(value)
    }
}

fn upper_id(value: Option<&IsarValue>, include: bool) -> Option<i64> {
    let value = if let Some(value) = value {
        value.i64()?
    } else {
        i64::MIN
    };
    if !include {
        value.checked_sub(1)
    } else {
        Some(value)
    }
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_lower_bool() {
        assert_eq!(lower_bool(None, true), Some(None));
        assert_eq!(
            lower_bool(Some(&IsarValue::Bool(false)), true),
            Some(Some(false))
        );
        assert_eq!(
            lower_bool(Some(&IsarValue::Bool(true)), true),
            Some(Some(true))
        );

        // Non-inclusive tests
        assert_eq!(lower_bool(None, false), Some(Some(false)));
        assert_eq!(
            lower_bool(Some(&IsarValue::Bool(false)), false),
            Some(Some(true))
        );
        assert_eq!(lower_bool(Some(&IsarValue::Bool(true)), false), None);
    }

    #[test]
    fn test_upper_bool() {
        assert_eq!(upper_bool(None, true), Some(None));
        assert_eq!(
            upper_bool(Some(&IsarValue::Bool(false)), true),
            Some(Some(false))
        );
        assert_eq!(
            upper_bool(Some(&IsarValue::Bool(true)), true),
            Some(Some(true))
        );

        // Non-inclusive tests
        assert_eq!(upper_bool(None, false), None);
        assert_eq!(upper_bool(Some(&IsarValue::Bool(false)), false), Some(None));
        assert_eq!(
            upper_bool(Some(&IsarValue::Bool(true)), false),
            Some(Some(false))
        );
    }

    #[test]
    fn test_lower_byte() {
        assert_eq!(lower_byte(None, true), Some(0));
        assert_eq!(lower_byte(Some(&IsarValue::Integer(5)), true), Some(5));
        assert_eq!(lower_byte(Some(&IsarValue::Integer(0)), true), Some(0));

        // Non-inclusive tests
        assert_eq!(lower_byte(Some(&IsarValue::Integer(5)), false), Some(6));
        assert_eq!(lower_byte(Some(&IsarValue::Integer(255)), false), None);
    }

    #[test]
    fn test_upper_byte() {
        assert_eq!(upper_byte(None, true), Some(255));
        assert_eq!(upper_byte(Some(&IsarValue::Integer(5)), true), Some(5));
        assert_eq!(upper_byte(Some(&IsarValue::Integer(255)), true), Some(255));

        // Non-inclusive tests
        assert_eq!(upper_byte(Some(&IsarValue::Integer(5)), false), Some(4));
        assert_eq!(upper_byte(Some(&IsarValue::Integer(0)), false), None);
    }

    #[test]
    fn test_lower_int() {
        assert_eq!(lower_int(None, true), Some(i32::MIN));
        assert_eq!(lower_int(Some(&IsarValue::Integer(5)), true), Some(5));
        assert_eq!(
            lower_int(Some(&IsarValue::Integer(i32::MIN as i64)), true),
            Some(i32::MIN)
        );

        // Non-inclusive tests
        assert_eq!(lower_int(Some(&IsarValue::Integer(5)), false), Some(6));
        assert_eq!(
            lower_int(Some(&IsarValue::Integer(i32::MAX as i64)), false),
            None
        );
    }

    #[test]
    fn test_upper_int() {
        assert_eq!(upper_int(None, true), Some(i32::MIN));
        assert_eq!(upper_int(Some(&IsarValue::Integer(5)), true), Some(5));
        assert_eq!(
            upper_int(Some(&IsarValue::Integer(i32::MAX as i64)), true),
            Some(i32::MAX)
        );

        // Non-inclusive tests
        assert_eq!(upper_int(Some(&IsarValue::Integer(5)), false), Some(4));
        assert_eq!(
            upper_int(Some(&IsarValue::Integer(i32::MIN as i64)), false),
            None
        );
    }

    #[test]
    fn test_lower_real() {
        assert!(lower_real(None, true).unwrap().is_nan());
        assert_eq!(lower_real(Some(&IsarValue::Real(5.0)), true), Some(5.0));
        assert_eq!(
            lower_real(Some(&IsarValue::Real(f64::NEG_INFINITY)), true),
            Some(f64::NEG_INFINITY)
        );

        // Non-inclusive tests
        assert_eq!(lower_real(None, false), Some(f64::NEG_INFINITY));
        assert!(lower_real(Some(&IsarValue::Real(f64::INFINITY)), false).is_none());
    }

    #[test]
    fn test_upper_real() {
        assert!(upper_real(None, true).unwrap().is_nan());
        assert_eq!(upper_real(Some(&IsarValue::Real(5.0)), true), Some(5.0));
        assert_eq!(
            upper_real(Some(&IsarValue::Real(f64::INFINITY)), true),
            Some(f64::INFINITY)
        );

        // Non-inclusive tests
        assert!(upper_real(None, false).is_none());
        assert!(upper_real(Some(&IsarValue::Real(f64::NAN)), false).is_none());
    }

    #[test]
    fn test_lower_long() {
        assert_eq!(lower_long(None, true), Some(i64::MIN));
        assert_eq!(lower_long(Some(&IsarValue::Integer(5)), true), Some(5));
        assert_eq!(
            lower_long(Some(&IsarValue::Integer(i64::MIN)), true),
            Some(i64::MIN)
        );

        // Non-inclusive tests
        assert_eq!(lower_long(Some(&IsarValue::Integer(5)), false), Some(6));
        assert_eq!(lower_long(Some(&IsarValue::Integer(i64::MAX)), false), None);
    }

    #[test]
    fn test_upper_long() {
        assert_eq!(upper_long(None, true), Some(i64::MIN));
        assert_eq!(upper_long(Some(&IsarValue::Integer(5)), true), Some(5));
        assert_eq!(
            upper_long(Some(&IsarValue::Integer(i64::MAX)), true),
            Some(i64::MAX)
        );

        // Non-inclusive tests
        assert_eq!(upper_long(Some(&IsarValue::Integer(5)), false), Some(4));
        assert_eq!(upper_long(Some(&IsarValue::Integer(i64::MIN)), false), None);
    }

    #[test]
    fn test_lower_string() {
        assert_eq!(lower_string(None, true), Some(None));
        assert_eq!(
            lower_string(Some(&IsarValue::String("test".to_string())), true),
            Some(Some("test".to_string()))
        );
        assert_eq!(
            lower_string(Some(&IsarValue::String("".to_string())), true),
            Some(Some("".to_string()))
        );

        // Non-inclusive tests
        assert_eq!(lower_string(None, false), Some(Some("".to_string())));
        assert_eq!(
            lower_string(Some(&IsarValue::String("".to_string())), false),
            Some(Some("\u{0}".to_string()))
        );
        assert_eq!(
            lower_string(Some(&IsarValue::String("testb".to_string())), false),
            Some(Some("testc".to_string()))
        );
    }

    #[test]
    fn test_upper_string() {
        assert_eq!(upper_string(None, true), Some(None));
        assert_eq!(
            upper_string(Some(&IsarValue::String("test".to_string())), true),
            Some(Some("test".to_string()))
        );
        assert_eq!(
            upper_string(Some(&IsarValue::String("".to_string())), true),
            Some(Some("".to_string()))
        );

        // Non-inclusive tests
        assert!(upper_string(None, false).is_none());
        assert_eq!(
            upper_string(Some(&IsarValue::String("".to_string())), false),
            Some(None)
        );
        assert_eq!(
            upper_string(Some(&IsarValue::String("testb".to_string())), false),
            Some(Some("testa".to_string()))
        );
    }

    #[test]
    fn test_lower_id() {
        assert_eq!(lower_id(None, true), Some(i64::MIN));
        assert_eq!(lower_id(Some(&IsarValue::Integer(5)), true), Some(5));
        assert_eq!(
            lower_id(Some(&IsarValue::Integer(i64::MIN)), true),
            Some(i64::MIN)
        );

        // Non-inclusive tests
        assert_eq!(lower_id(Some(&IsarValue::Integer(5)), false), Some(6));
        assert_eq!(lower_id(Some(&IsarValue::Integer(i64::MAX)), false), None);
    }

    #[test]
    fn test_upper_id() {
        assert_eq!(upper_id(None, true), Some(i64::MIN));
        assert_eq!(upper_id(Some(&IsarValue::Integer(5)), true), Some(5));
        assert_eq!(
            upper_id(Some(&IsarValue::Integer(i64::MAX)), true),
            Some(i64::MAX)
        );

        // Non-inclusive tests
        assert_eq!(upper_id(Some(&IsarValue::Integer(5)), false), Some(4));
        assert_eq!(upper_id(Some(&IsarValue::Integer(i64::MIN)), false), None);
    }

    #[test]
    fn test_get_max() {
        // Test with no property (id case)
        assert_eq!(get_max(None), Some(IsarValue::Integer(i64::MAX)));

        // Create test properties for each data type
        let bool_prop = NativeProperty {
            data_type: DataType::Bool,
            offset: 0,
            embedded_collection_index: None,
        };
        let byte_prop = NativeProperty {
            data_type: DataType::Byte,
            offset: 1,
            embedded_collection_index: None,
        };
        let int_prop = NativeProperty {
            data_type: DataType::Int,
            offset: 2,
            embedded_collection_index: None,
        };
        let float_prop = NativeProperty {
            data_type: DataType::Float,
            offset: 6,
            embedded_collection_index: None,
        };
        let long_prop = NativeProperty {
            data_type: DataType::Long,
            offset: 10,
            embedded_collection_index: None,
        };
        let double_prop = NativeProperty {
            data_type: DataType::Double,
            offset: 18,
            embedded_collection_index: None,
        };
        let string_prop = NativeProperty {
            data_type: DataType::String,
            offset: 26,
            embedded_collection_index: None,
        };
        let object_prop = NativeProperty {
            data_type: DataType::Object,
            offset: 34,
            embedded_collection_index: None,
        };

        // Test each data type
        assert_eq!(get_max(Some(&bool_prop)), Some(IsarValue::Bool(true)));
        assert_eq!(
            get_max(Some(&byte_prop)),
            Some(IsarValue::Integer(u8::MAX as i64))
        );
        assert_eq!(
            get_max(Some(&int_prop)),
            Some(IsarValue::Integer(i32::MAX as i64))
        );
        assert_eq!(
            get_max(Some(&float_prop)),
            Some(IsarValue::Real(f64::INFINITY))
        );
        assert_eq!(
            get_max(Some(&long_prop)),
            Some(IsarValue::Integer(i64::MAX))
        );
        assert_eq!(
            get_max(Some(&double_prop)),
            Some(IsarValue::Real(f64::INFINITY))
        );
        assert_eq!(
            get_max(Some(&string_prop)),
            Some(IsarValue::String(IsarValue::MAX_STRING.to_string()))
        );
        assert_eq!(get_max(Some(&object_prop)), None);
    }
}
