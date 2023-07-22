use super::query_iterator::QueryIterator;
use crate::core::data_type::DataType;
use crate::core::value::IsarValue;
use crate::native::native_collection::NativeProperty;
use crate::native::{NULL_INT, NULL_LONG};
use std::cmp::Ordering;

pub(crate) fn aggregate_sum_average<'a>(
    iterator: QueryIterator<'a>,
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
    iterator: QueryIterator<'a>,
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
