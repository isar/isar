use crate::filter::get_property;
use crate::txn::CIsarTxn;
use isar_core::collection::IsarCollection;
use isar_core::error::Result;
use isar_core::object::data_type::DataType;
use isar_core::object::isar_object::IsarObject;
use isar_core::object::property::Property;
use isar_core::query::Query;
use isar_core::txn::IsarTxn;
use std::cmp::Ordering;

pub enum AggregationResult {
    Long(i64),
    Double(f64),
    Null,
}

#[derive(PartialEq)]
#[repr(u8)]
pub enum AggregationOp {
    Min,
    Max,
    Sum,
    Average,
    Count,
    IsEmpty,
}

impl AggregationOp {
    fn from_u8(index: u8) -> AggregationOp {
        match index {
            0 => AggregationOp::Min,
            1 => AggregationOp::Max,
            2 => AggregationOp::Sum,
            3 => AggregationOp::Average,
            4 => AggregationOp::Count,
            5 => AggregationOp::IsEmpty,
            _ => unreachable!(),
        }
    }
}

const EMPTY_PROP: &Property = &Property {
    name: String::new(),
    data_type: DataType::Bool,
    offset: 0,
    target_id: None,
};

fn aggregate(
    query: &Query,
    txn: &mut IsarTxn,
    op: AggregationOp,
    property: Option<&Property>,
) -> Result<AggregationResult> {
    let mut count = 0usize;

    let (mut long_value, mut double_value) = if op == AggregationOp::Min {
        (i64::MAX, f64::INFINITY)
    } else if op == AggregationOp::Max {
        (i64::MIN, f64::NEG_INFINITY)
    } else {
        (0, 0.0)
    };

    let min_max_cmp = if op == AggregationOp::Max {
        Ordering::Greater
    } else {
        Ordering::Less
    };

    let property = property.unwrap_or(EMPTY_PROP);

    query.find_while(txn, |_, obj| {
        match op {
            AggregationOp::Min | AggregationOp::Max => {
                if obj.is_null(property.offset, property.data_type) {
                    return true;
                }

                count += 1;
                match property.data_type {
                    DataType::Int | DataType::Long => {
                        let value = if property.data_type == DataType::Int {
                            obj.read_int(property.offset) as i64
                        } else {
                            obj.read_long(property.offset)
                        };
                        if value.cmp(&long_value) == min_max_cmp {
                            long_value = value;
                        }
                    }
                    DataType::Float | DataType::Double => {
                        let value = if property.data_type == DataType::Float {
                            obj.read_float(property.offset) as f64
                        } else {
                            obj.read_double(property.offset)
                        };
                        if value.total_cmp(&double_value) == min_max_cmp {
                            double_value = value;
                        }
                    }
                    _ => {}
                }
            }
            AggregationOp::Sum | AggregationOp::Average => {
                if obj.is_null(property.offset, property.data_type) {
                    return true;
                }

                count += 1;
                match property.data_type {
                    DataType::Int => {
                        long_value = long_value.saturating_add(obj.read_int(property.offset) as i64)
                    }
                    DataType::Long => {
                        long_value = long_value.saturating_add(obj.read_long(property.offset))
                    }
                    DataType::Float => double_value += obj.read_float(property.offset) as f64,
                    DataType::Double => double_value += obj.read_double(property.offset),
                    _ => {}
                }
            }
            AggregationOp::Count => {
                count += 1;
            }
            AggregationOp::IsEmpty => {
                count += 1;
                return false;
            }
        }
        true
    })?;

    match op {
        AggregationOp::Min | AggregationOp::Max | AggregationOp::Average => {
            if count == 0 {
                return Ok(AggregationResult::Null);
            }
        }
        _ => {}
    }

    let result = match op {
        AggregationOp::Average => match property.data_type {
            DataType::Int | DataType::Long => {
                AggregationResult::Double((long_value as f64) / (count as f64))
            }
            DataType::Float | DataType::Double => {
                AggregationResult::Double(double_value / (count as f64))
            }
            _ => AggregationResult::Null,
        },
        AggregationOp::Count => AggregationResult::Long(count as i64),
        AggregationOp::IsEmpty => AggregationResult::Long(if count > 0 { 0 } else { 1 }),
        _ => match property.data_type {
            DataType::Int | DataType::Long => AggregationResult::Long(long_value),
            DataType::Float | DataType::Double => AggregationResult::Double(double_value),
            _ => AggregationResult::Null,
        },
    };

    Ok(result)
}

pub struct AggregationResultSend(*mut *const AggregationResult);

unsafe impl Send for AggregationResultSend {}

#[no_mangle]
pub unsafe extern "C" fn isar_q_aggregate(
    collection: &'static IsarCollection,
    query: &'static Query,
    txn: &mut CIsarTxn,
    operation: u8,
    property_id: u64,
    result: *mut *const AggregationResult,
) -> i64 {
    let op = AggregationOp::from_u8(operation);
    let result = AggregationResultSend(result);
    isar_try_txn!(txn, move |txn| {
        let result = result;
        let property = if op != AggregationOp::Count {
            Some(get_property(collection, 0, property_id)?)
        } else {
            None
        };
        let aggregate_result = aggregate(query, txn, op, property)?;
        result.0.write(Box::into_raw(Box::new(aggregate_result)));
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_q_aggregate_long_result(result: &AggregationResult) -> i64 {
    match result {
        AggregationResult::Long(long) => *long,
        AggregationResult::Double(double) => *double as i64,
        AggregationResult::Null => IsarObject::NULL_LONG,
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_q_aggregate_double_result(result: &AggregationResult) -> f64 {
    match result {
        AggregationResult::Long(long) => *long as f64,
        AggregationResult::Double(double) => *double,
        AggregationResult::Null => IsarObject::NULL_DOUBLE,
    }
}
