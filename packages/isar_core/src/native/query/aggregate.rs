use crate::core::data_type::DataType;
use crate::core::value::IsarValue;
use crate::native::isar_deserializer::IsarDeserializer;
use crate::native::native_collection::NativeProperty;
use crate::native::{NULL_INT, NULL_LONG};
use std::cmp::Ordering;

pub(crate) fn aggregate_sum_average<'a>(
    iterator: impl Iterator<Item = (i64, IsarDeserializer<'a>)>,
    property: Option<&NativeProperty>,
    aggregate_sum: bool,
) -> Option<IsarValue> {
    if let Some(property) = property {
        match property.data_type {
            DataType::Byte | DataType::Int | DataType::Long => {
                let mut sum = 0i64;
                let mut count = 0i64;
                match property.data_type {
                    DataType::Byte => {
                        for (_, reader) in iterator {
                            sum += reader.read_byte(property.offset) as i64;
                            count += 1;
                        }
                    }
                    DataType::Int => {
                        for (_, reader) in iterator {
                            let value = reader.read_int(property.offset);
                            if value != NULL_INT {
                                sum += value as i64;
                                count += 1;
                            }
                        }
                    }
                    DataType::Long => {
                        for (_, reader) in iterator {
                            let value = reader.read_long(property.offset);
                            if value != NULL_LONG {
                                sum += value;
                                count += 1;
                            }
                        }
                    }
                    _ => unreachable!(),
                }

                if aggregate_sum {
                    Some(IsarValue::Integer(sum))
                } else if count > 0 {
                    Some(IsarValue::Real(sum as f64 / count as f64))
                } else {
                    Some(IsarValue::Real(f64::NAN))
                }
            }
            DataType::Float | DataType::Double => {
                let mut sum = 0f64;
                let mut count = 0i64;
                match property.data_type {
                    DataType::Float => {
                        for (_, reader) in iterator {
                            let value = reader.read_float(property.offset);
                            if !value.is_nan() {
                                sum += value as f64;
                                count += 1;
                            }
                        }
                    }
                    DataType::Double => {
                        for (_, reader) in iterator {
                            let value = reader.read_double(property.offset);
                            if !value.is_nan() {
                                sum += value;
                                count += 1;
                            }
                        }
                    }
                    _ => unreachable!(),
                }

                if aggregate_sum {
                    Some(IsarValue::Real(sum))
                } else if count > 0 {
                    Some(IsarValue::Real(sum / count as f64))
                } else {
                    Some(IsarValue::Real(f64::NAN))
                }
            }
            _ => None,
        }
    } else {
        let mut sum = 0i64;
        let mut count = 0i64;
        for (id, _) in iterator {
            if id != NULL_LONG {
                sum += id;
                count += 1;
            }
        }
        if aggregate_sum {
            Some(IsarValue::Integer(sum))
        } else if count > 0 {
            Some(IsarValue::Real(sum as f64 / count as f64))
        } else {
            Some(IsarValue::Real(f64::NAN))
        }
    }
}

pub(crate) fn aggregate_min_max<'a>(
    iterator: impl Iterator<Item = (i64, IsarDeserializer<'a>)>,
    property: Option<&NativeProperty>,
    aggregate_min: bool,
) -> Option<IsarValue> {
    let min_max_cmp = if aggregate_min {
        Ordering::Less
    } else {
        Ordering::Greater
    };

    if let Some(property) = property {
        match property.data_type {
            DataType::Byte => {
                let mut min_max = if aggregate_min { 255u8 } else { 0u8 };
                let mut has_value = false;
                for (_, reader) in iterator {
                    let value = reader.read_byte(property.offset);
                    if value.cmp(&min_max) == min_max_cmp {
                        min_max = value;
                        has_value = true;
                    }
                }
                if has_value {
                    Some(IsarValue::Integer(min_max as i64))
                } else {
                    None
                }
            }
            DataType::Int => {
                let mut min_max = if aggregate_min { i32::MAX } else { i32::MIN };
                let mut has_value = false;
                for (_, reader) in iterator {
                    let value = reader.read_int(property.offset);
                    if value != NULL_INT && value.cmp(&min_max) == min_max_cmp {
                        min_max = value;
                        has_value = true;
                    }
                }
                if has_value {
                    Some(IsarValue::Integer(min_max as i64))
                } else {
                    None
                }
            }
            DataType::Float => {
                let mut min_max = if aggregate_min {
                    f32::INFINITY
                } else {
                    f32::NEG_INFINITY
                };
                let mut has_value = false;
                for (_, reader) in iterator {
                    let value = reader.read_float(property.offset);
                    if value.partial_cmp(&min_max) == Some(min_max_cmp) {
                        min_max = value;
                        has_value = true;
                    }
                }
                if has_value {
                    Some(IsarValue::Real(min_max as f64))
                } else {
                    None
                }
            }
            DataType::Long => {
                let mut min_max = if aggregate_min { i64::MAX } else { i64::MIN };
                let mut has_value = false;
                for (_, reader) in iterator {
                    let value = reader.read_long(property.offset);
                    if value != NULL_LONG && value.cmp(&min_max) == min_max_cmp {
                        min_max = value;
                        has_value = true;
                    }
                }
                if has_value {
                    Some(IsarValue::Integer(min_max))
                } else {
                    None
                }
            }
            DataType::Double => {
                let mut min_max = if aggregate_min {
                    f64::INFINITY
                } else {
                    f64::NEG_INFINITY
                };
                let mut has_value = false;
                for (_, reader) in iterator {
                    let value = reader.read_double(property.offset);
                    if value.partial_cmp(&min_max) == Some(min_max_cmp) {
                        min_max = value;
                        has_value = true;
                    }
                }
                if has_value {
                    Some(IsarValue::Real(min_max))
                } else {
                    None
                }
            }
            DataType::String => {
                let mut min_max = if aggregate_min {
                    "\u{10FFFF}".to_string()
                } else {
                    String::new()
                };
                let mut has_value = false;
                for (_, reader) in iterator {
                    let value = reader.read_string(property.offset);
                    if let Some(value) = value {
                        if value.cmp(&min_max) == min_max_cmp {
                            min_max = value.to_string();
                            has_value = true;
                        }
                    }
                }
                if has_value {
                    Some(IsarValue::String(min_max))
                } else {
                    None
                }
            }
            _ => None,
        }
    } else {
        let mut min_max = if aggregate_min { i64::MAX } else { i64::MIN };
        let mut has_value = false;
        for (id, _) in iterator {
            if id != NULL_LONG && id.cmp(&min_max) == min_max_cmp {
                min_max = id;
                has_value = true;
            }
        }
        if has_value {
            Some(IsarValue::Integer(min_max))
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::native::isar_serializer::IsarSerializer;

    fn create_deserializer(
        static_size: u32,
        write_fn: impl FnOnce(&mut IsarSerializer),
    ) -> IsarDeserializer<'static> {
        let mut serializer = IsarSerializer::new(Vec::new(), 0, static_size);
        write_fn(&mut serializer);
        let bytes = serializer.finish().unwrap().leak();
        IsarDeserializer::from_bytes(bytes)
    }

    fn create_property(data_type: DataType) -> NativeProperty {
        NativeProperty {
            data_type,
            offset: 0,
            embedded_collection_index: None,
        }
    }

    #[test]
    fn test_aggregate_sum_average_byte() {
        let property = create_property(DataType::Byte);

        // Test sum
        let deserializer = create_deserializer(1, |s| s.write_byte(0, 5));
        let iterator = vec![(0, deserializer)];
        assert_eq!(
            aggregate_sum_average(iterator.into_iter(), Some(&property), true),
            Some(IsarValue::Integer(5))
        );

        // Test average
        let deserializer1 = create_deserializer(1, |s| s.write_byte(0, 10));
        let deserializer2 = create_deserializer(1, |s| s.write_byte(0, 20));
        let iterator = vec![(0, deserializer1), (0, deserializer2)];
        assert_eq!(
            aggregate_sum_average(iterator.into_iter(), Some(&property), false),
            Some(IsarValue::Real(15.0))
        );
    }

    #[test]
    fn test_aggregate_sum_average_int() {
        let property = create_property(DataType::Int);

        // Test sum with nulls
        let deserializer1 = create_deserializer(4, |s| s.write_int(0, 100));
        let deserializer2 = create_deserializer(4, |s| s.write_null(0, DataType::Int));
        let deserializer3 = create_deserializer(4, |s| s.write_int(0, 50));
        let iterator = vec![(0, deserializer1), (0, deserializer2), (0, deserializer3)];
        assert_eq!(
            aggregate_sum_average(iterator.into_iter(), Some(&property), true),
            Some(IsarValue::Integer(150))
        );

        // Test average with nulls
        let deserializer1 = create_deserializer(4, |s| s.write_int(0, -10));
        let deserializer2 = create_deserializer(4, |s| s.write_null(0, DataType::Int));
        let deserializer3 = create_deserializer(4, |s| s.write_int(0, 20));
        let iterator = vec![(0, deserializer1), (0, deserializer2), (0, deserializer3)];
        assert_eq!(
            aggregate_sum_average(iterator.into_iter(), Some(&property), false),
            Some(IsarValue::Real(5.0))
        );
    }

    #[test]
    fn test_aggregate_sum_average_float() {
        let property = create_property(DataType::Float);

        // Test sum with NaN
        let deserializer1 = create_deserializer(4, |s| s.write_float(0, 1.5));
        let deserializer2 = create_deserializer(4, |s| s.write_float(0, f32::NAN));
        let deserializer3 = create_deserializer(4, |s| s.write_float(0, 2.5));
        let iterator = vec![(0, deserializer1), (0, deserializer2), (0, deserializer3)];
        assert_eq!(
            aggregate_sum_average(iterator.into_iter(), Some(&property), true),
            Some(IsarValue::Real(4.0))
        );

        // Test average with empty iterator
        let iterator = Vec::<(i64, IsarDeserializer)>::new();
        let result = aggregate_sum_average(iterator.into_iter(), Some(&property), false);
        assert!(result.unwrap().real().unwrap().is_nan());
    }

    #[test]
    fn test_aggregate_min_max_int() {
        let property = create_property(DataType::Int);

        // Test min with nulls
        let deserializer1 = create_deserializer(4, |s| s.write_int(0, 100));
        let deserializer2 = create_deserializer(4, |s| s.write_null(0, DataType::Int));
        let deserializer3 = create_deserializer(4, |s| s.write_int(0, 50));
        let iterator = vec![(0, deserializer1), (0, deserializer2), (0, deserializer3)];
        assert_eq!(
            aggregate_min_max(iterator.into_iter(), Some(&property), true),
            Some(IsarValue::Integer(50))
        );

        // Test max with nulls
        let deserializer1 = create_deserializer(4, |s| s.write_int(0, -10));
        let deserializer2 = create_deserializer(4, |s| s.write_null(0, DataType::Int));
        let deserializer3 = create_deserializer(4, |s| s.write_int(0, 20));
        let iterator = vec![(0, deserializer1), (0, deserializer2), (0, deserializer3)];
        assert_eq!(
            aggregate_min_max(iterator.into_iter(), Some(&property), false),
            Some(IsarValue::Integer(20))
        );
    }

    #[test]
    fn test_aggregate_min_max_string() {
        let property = create_property(DataType::String);

        // Test min with nulls
        let deserializer1 = create_deserializer(3, |s| s.write_dynamic(0, b"banana"));
        let deserializer2 = create_deserializer(3, |s| s.write_null(0, DataType::String));
        let deserializer3 = create_deserializer(3, |s| s.write_dynamic(0, b"apple"));
        let iterator = vec![(0, deserializer1), (0, deserializer2), (0, deserializer3)];
        assert_eq!(
            aggregate_min_max(iterator.into_iter(), Some(&property), true),
            Some(IsarValue::String("apple".to_string()))
        );

        // Test max with nulls
        let deserializer1 = create_deserializer(3, |s| s.write_dynamic(0, b"cat"));
        let deserializer2 = create_deserializer(3, |s| s.write_null(0, DataType::String));
        let deserializer3 = create_deserializer(3, |s| s.write_dynamic(0, b"dog"));
        let iterator = vec![(0, deserializer1), (0, deserializer2), (0, deserializer3)];
        assert_eq!(
            aggregate_min_max(iterator.into_iter(), Some(&property), false),
            Some(IsarValue::String("dog".to_string()))
        );
    }

    #[test]
    fn test_aggregate_min_max_empty() {
        let property = create_property(DataType::Int);

        // Test empty iterator
        let iterator = Vec::<(i64, IsarDeserializer)>::new();
        assert_eq!(
            aggregate_min_max(iterator.into_iter(), Some(&property), true),
            None
        );
    }

    #[test]
    fn test_aggregate_id() {
        // Test sum of IDs
        let iterator = vec![
            (1, IsarDeserializer::from_bytes(&[0, 0, 0])),
            (2, IsarDeserializer::from_bytes(&[0, 0, 0])),
        ];
        assert_eq!(
            aggregate_sum_average(iterator.into_iter(), None, true),
            Some(IsarValue::Integer(3))
        );

        // Test average of IDs
        let iterator = vec![
            (10, IsarDeserializer::from_bytes(&[0, 0, 0])),
            (20, IsarDeserializer::from_bytes(&[0, 0, 0])),
        ];
        assert_eq!(
            aggregate_sum_average(iterator.into_iter(), None, false),
            Some(IsarValue::Real(15.0))
        );

        // Test min of IDs
        let iterator = vec![
            (100, IsarDeserializer::from_bytes(&[0, 0, 0])),
            (50, IsarDeserializer::from_bytes(&[0, 0, 0])),
        ];
        assert_eq!(
            aggregate_min_max(iterator.into_iter(), None, true),
            Some(IsarValue::Integer(50))
        );

        // Test max of IDs
        let iterator = vec![
            (100, IsarDeserializer::from_bytes(&[0, 0, 0])),
            (50, IsarDeserializer::from_bytes(&[0, 0, 0])),
        ];
        assert_eq!(
            aggregate_min_max(iterator.into_iter(), None, false),
            Some(IsarValue::Integer(100))
        );
    }
}
