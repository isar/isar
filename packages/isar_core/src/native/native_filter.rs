use super::{
    native_collection::NativeProperty, native_object::NativeObject, native_reader::NativeReader,
};
use crate::core::{data_type::DataType, reader::IsarReader};
use enum_dispatch::enum_dispatch;
use paste::paste;

#[enum_dispatch]
#[derive(Clone)]
enum FilterCond {
    IdBetween(IdGreaterThanCond),
    IdLessThan(IdLessThanCond),
    IdEqualTo(IdEqualToCond),
    IdEqualToAny(IdEqualToAnyCond),

    BoolEqualTo(BoolEqualToCond),

    ByteGreaterThan(ByteGreaterThanCond),
    ByteLessThan(ByteLessThanCond),
    ByteEqualTo(ByteEqualToCond),
    ByteEqualToAny(ByteEqualToAnyCond),

    IntGreaterThan(IntGreaterThanCond),
    IntLessThan(IntLessThanCond),
    IntEqualTo(IntEqualToCond),
    IntEqualToAny(IntEqualToAnyCond),

    FloatGreaterThan(FloatGreaterThanCond),
    FloatLessThan(FloatLessThanCond),

    LongGreaterThan(LongGreaterThanCond),
    LongLessThan(LongLessThanCond),
    LongEqualTo(LongEqualToCond),
    LongEqualToAny(LongEqualToAnyCond),

    DoubleGreaterThan(DoubleGreaterThanCond),
    DoubleLessThan(DoubleLessThanCond),

    /*StringGreaterThan(StringGreaterThanCond),
    StringLessThan(StringLessThanCond),
    StringEqualTo(StringEqualToCond),
    StringStartsWith(StringStartsWithCond),
    StringEndsWith(StringEndsWithCond),
    StringContains(StringContainsCond),
    StringMatches(StringMatchesCond),

    AnyByteBetween(AnyByteBetweenCond),
    AnyIntBetween(AnyIntBetweenCond),
    AnyLongBetween(AnyLongBetweenCond),
    AnyFloatBetween(AnyFloatBetweenCond),
    AnyDoubleBetween(AnyDoubleBetweenCond),

    AnyStringBetween(AnyStringBetweenCond),
    AnyStringStartsWith(AnyStringStartsWithCond),
    AnyStringEndsWith(AnyStringEndsWithCond),
    AnyStringContains(AnyStringContainsCond),
    AnyStringMatches(AnyStringMatchesCond),

    ListLength(ListLengthCond),*/
    And(AndCond),
    Or(OrCond),
    Xor(XorCond),
    Not(NotCond),
    Static(StaticCond),
}

#[enum_dispatch(FilterCond)]
trait Condition {
    fn evaluate(&self, id: i64, object: NativeObject) -> bool;
}

#[macro_export]
macro_rules! filter_struct {
    ($name:ident, $type:ty) => {
        #[derive(Clone)]
        struct $name {
            value: $type,
            property: NativeProperty,
        }
    };
}

#[derive(Clone)]
struct IdGreaterThanCond {
    value: i64,
}

impl Condition for IdGreaterThanCond {
    fn evaluate(&self, id: i64, _object: NativeObject) -> bool {
        id > self.value
    }
}

#[derive(Clone)]
struct IdLessThanCond {
    value: i64,
}

impl Condition for IdLessThanCond {
    fn evaluate(&self, id: i64, object: NativeObject) -> bool {
        id < self.value
    }
}

#[derive(Clone)]
struct IdEqualToCond {
    value: i64,
}

impl Condition for IdEqualToCond {
    fn evaluate(&self, id: i64, object: NativeObject) -> bool {
        id == self.value
    }
}

#[derive(Clone)]
struct IdEqualToAnyCond {
    values: Vec<i64>,
}

impl Condition for IdEqualToAnyCond {
    fn evaluate(&self, id: i64, object: NativeObject) -> bool {
        for value in &self.values {
            if id == *value {
                return true;
            }
        }
        false
    }
}

#[derive(Clone)]
struct BoolEqualToCond {
    value: bool,
    offset: usize,
}

impl Condition for BoolEqualToCond {
    fn evaluate(&self, id: i64, object: NativeObject) -> bool {
        let val = object.read_bool(self.offset);
        val == Some(self.value)
    }
}

#[macro_export]
macro_rules! primitive_gt {
    ($name:ident, $type:ty, $prop_accessor:ident) => {
        paste! {
            #[derive(Clone)]
            struct [<$name GreaterThanCond>] {
                value: $type,
                offset: usize,
            }

            impl Condition for [<$name GreaterThanCond>] {
                fn evaluate(&self, _id: i64, object: NativeObject) -> bool {
                    let val = object.$prop_accessor(self.offset);
                    val > self.value
                }
            }
        }
    };
}

#[macro_export]
macro_rules! primitive_lt {
    ($name:ident, $type:ty, $prop_accessor:ident) => {
        paste! {
            #[derive(Clone)]
            struct [<$name LessThanCond>] {
                value: $type,
                offset: usize,
            }

            impl Condition for [<$name LessThanCond>] {
                fn evaluate(&self, _id: i64, object: NativeObject) -> bool {
                    let val = object.$prop_accessor(self.offset);
                    val < self.value
                }
            }
        }
    };
}

#[macro_export]
macro_rules! primitive_eq {
    ($name:ident, $type:ty, $prop_accessor:ident) => {
        paste! {
            #[derive(Clone)]
            struct [<$name EqualToCond>] {
                value: $type,
                offset: usize,
            }

            impl Condition for [<$name EqualToCond>] {
                fn evaluate(&self, _id: i64, object: NativeObject) -> bool {
                    let val = object.$prop_accessor(self.offset);
                    val == self.value
                }
            }
        }
    };
}

#[macro_export]
macro_rules! primitive_eq_any {
    ($name:ident, $type:ty, $prop_accessor:ident) => {
        paste! {
            #[derive(Clone)]
            struct [<$name EqualToAnyCond>] {
                values: Vec<$type>,
                offset: usize,
            }

            impl Condition for [<$name EqualToAnyCond>] {
                fn evaluate(&self, _id: i64, object: NativeObject) -> bool {
                    let val = object.$prop_accessor(self.offset);
                    for value in &self.values {
                        if val == *value {
                            return true;
                        }
                    }
                    false
                }
            }
        }
    };
}

primitive_gt!(Byte, u8, read_byte);
primitive_lt!(Byte, u8, read_byte);
primitive_eq!(Byte, u8, read_byte);
primitive_eq_any!(Byte, u8, read_byte);

primitive_gt!(Int, i32, read_int);
primitive_lt!(Int, i32, read_int);
primitive_eq!(Int, i32, read_int);
primitive_eq_any!(Int, i32, read_int);

primitive_gt!(Float, f32, read_float);
primitive_lt!(Float, f32, read_float);

primitive_gt!(Long, i64, read_long);
primitive_lt!(Long, i64, read_long);
primitive_eq!(Long, i64, read_long);
primitive_eq_any!(Long, i64, read_long);

primitive_gt!(Double, f64, read_double);
primitive_lt!(Double, f64, read_double);

/*#[macro_export]
macro_rules! primitive_filter_between_list {
    ($name:ident, $prop_accessor:ident) => {
        impl Condition for $name {
            fn evaluate(
                &self,
                _id: i64,
                object: IsarObject,
                _: Option<&IsarCursors>,
            ) -> Result<bool> {
                let vals = object.$prop_accessor(self.offset);
                if let Some(vals) = vals {
                    for val in vals {
                        if self.lower <= val && self.upper >= val {
                            return Ok(true);
                        }
                    }
                }
                Ok(false)
            }
        }
    };
}

filter_between_struct!(AnyByteBetweenCond, Byte, u8);

impl Condition for AnyByteBetweenCond {
    fn evaluate(&self, _id: i64, object: IsarObject, _: Option<&IsarCursors>) -> Result<bool> {
        let vals = object.read_byte_list(self.offset);
        if let Some(vals) = vals {
            for val in vals {
                if self.lower <= *val && self.upper >= *val {
                    return Ok(true);
                }
            }
        }
        Ok(false)
    }
}

filter_between_struct!(AnyIntBetweenCond, Int, i32);
primitive_filter_between_list!(AnyIntBetweenCond, read_int_list);
filter_between_struct!(AnyLongBetweenCond, Long, i64);
primitive_filter_between_list!(AnyLongBetweenCond, read_long_list);

#[macro_export]
macro_rules! float_filter_between {
    ($name:ident, $prop_accessor:ident) => {
        impl Condition for $name {
            fn evaluate(&self, _id: i64, object: IsarObject, _: Option<&IsarCursors>) -> Result<bool> {
                let val = object.$prop_accessor(self.offset);
                Ok(float_filter_between!(eval val, self.lower, self.upper))
            }
        }
    };

    (eval $val:expr, $lower:expr, $upper:expr) => {{
        ($lower <= $val || $lower.is_nan()) &&
        ($upper >= $val || $val.is_nan() || ($upper.is_infinite() && $upper.is_sign_positive()))
    }};
}

filter_between_struct!(FloatBetweenCond, Float, f32);
float_filter_between!(FloatBetweenCond, read_float);
filter_between_struct!(DoubleBetweenCond, Double, f64);
float_filter_between!(DoubleBetweenCond, read_double);

#[macro_export]
macro_rules! float_filter_between_list {
    ($name:ident, $prop_accessor:ident) => {
        impl Condition for $name {
            fn evaluate(&self, _id: i64, object: IsarObject, _: Option<&IsarCursors>) -> Result<bool> {
                let vals = object.$prop_accessor(self.offset);
                if let Some(vals) = vals {
                    for val in vals {
                        if float_filter_between!(eval val, self.lower, self.upper) {
                            return Ok(true);
                        }
                    }
                }
                Ok(false)
            }
        }
    };
}

filter_between_struct!(AnyFloatBetweenCond, Float, f32);
float_filter_between_list!(AnyFloatBetweenCond, read_float_list);
filter_between_struct!(AnyDoubleBetweenCond, Double, f64);
float_filter_between_list!(AnyDoubleBetweenCond, read_double_list);

#[derive(Clone)]
struct StringBetweenCond {
    offset: usize,
    lower: Option<Vec<u8>>,
    upper: Option<Vec<u8>>,
    case_sensitive: bool,
}

#[derive(Clone)]
struct AnyStringBetweenCond {
    offset: usize,
    lower: Option<Vec<u8>>,
    upper: Option<Vec<u8>>,
    case_sensitive: bool,
}

fn string_between(
    value: Option<&str>,
    lower: Option<&[u8]>,
    upper: Option<&[u8]>,
    case_sensitive: bool,
) -> bool {
    if let Some(obj_str) = value {
        let mut matches = true;
        if case_sensitive {
            if let Some(lower) = lower {
                matches = lower <= obj_str.as_bytes();
            }
            matches &= if let Some(upper) = upper {
                upper >= obj_str.as_bytes()
            } else {
                false
            };
        } else {
            let obj_str = obj_str.to_lowercase();
            if let Some(lower) = lower {
                matches = lower <= obj_str.as_bytes();
            }
            matches &= if let Some(upper) = upper {
                upper >= obj_str.as_bytes()
            } else {
                false
            };
        }
        matches
    } else {
        lower.is_none()
    }
}

impl Condition for StringBetweenCond {
    fn evaluate(&self, _id: i64, object: IsarObject, _: Option<&IsarCursors>) -> Result<bool> {
        let value = object.read_string(self.offset);
        let result = string_between(
            value,
            self.lower.as_deref(),
            self.upper.as_deref(),
            self.case_sensitive,
        );
        Ok(result)
    }
}

impl Condition for AnyStringBetweenCond {
    fn evaluate(&self, _id: i64, object: IsarObject, _: Option<&IsarCursors>) -> Result<bool> {
        let list = object.read_string_list(self.offset);
        if let Some(list) = list {
            for value in list {
                let result = string_between(
                    value,
                    self.lower.as_deref(),
                    self.upper.as_deref(),
                    self.case_sensitive,
                );
                if result {
                    return Ok(true);
                }
            }
        }
        Ok(false)
    }
}

#[macro_export]
macro_rules! string_filter_struct {
    ($name:ident) => {
        paste! {
            #[derive(Clone)]
            struct [<$name Cond>] {
                offset: usize,
                value: String,
                case_sensitive: bool,
            }
        }
    };
}

#[macro_export]
macro_rules! string_filter {
    ($name:ident) => {
        paste! {
            string_filter_struct!($name);
            impl Condition for [<$name Cond>] {
                fn evaluate(&self, _id: i64, object: IsarObject, _: Option<&IsarCursors>) -> Result<bool> {
                    let other_str = object.read_string(self.offset);
                    let result = string_filter!(eval $name, self, other_str);
                    Ok(result)
                }
            }

            string_filter_struct!([<Any $name>]);
            impl Condition for [<Any $name Cond>] {
                fn evaluate(&self, _id: i64, object: IsarObject, _: Option<&IsarCursors>) -> Result<bool> {
                    let list = object.read_string_list(self.offset);
                    if let Some(list) = list {
                        for value in list {
                            if string_filter!(eval $name, self, value) {
                                return Ok(true);
                            }
                        }
                    }
                    Ok(false)
                }
            }
        }
    };

    (eval $name:tt, $filter:expr, $value:expr) => {
        if let Some(other_str) = $value {
            if $filter.case_sensitive {
                string_filter!($name &$filter.value, other_str)
            } else {
                let lowercase_string = other_str.to_lowercase();
                let lowercase_str = &lowercase_string;
                string_filter!($name &$filter.value, lowercase_str)
            }
        } else {
            false
        }
    };

    (StringStartsWith $filter_str:expr, $other_str:ident) => {
        $other_str.starts_with($filter_str)
    };

    (StringEndsWith $filter_str:expr, $other_str:ident) => {
        $other_str.ends_with($filter_str)
    };

    (StringContains $filter_str:expr, $other_str:ident) => {
        $other_str.contains($filter_str)
    };

    (StringMatches $filter_str:expr, $other_str:ident) => {
        fast_wild_match($other_str, $filter_str)
    };
}

string_filter!(StringStartsWith);
string_filter!(StringEndsWith);
string_filter!(StringContains);
string_filter!(StringMatches);

#[derive(Clone)]
struct ListLengthCond {
    offset: usize,
    lower: usize,
    upper: usize,
}

impl Condition for ListLengthCond {
    fn evaluate(
        &self,
        _id: i64,
        object: IsarObject,
        _cursors: Option<&IsarCursors>,
    ) -> Result<bool> {
        if let Some(len) = object.read_length(self.offset) {
            Ok(self.lower <= len && self.upper >= len)
        } else {
            Ok(false)
        }
    }
}        */

#[derive(Clone)]
struct AndCond {
    filters: Vec<FilterCond>,
}

impl Condition for AndCond {
    fn evaluate(&self, id: i64, object: NativeObject) -> bool {
        for filter in &self.filters {
            if !filter.evaluate(id, object) {
                return false;
            }
        }
        true
    }
}

#[derive(Clone)]
struct OrCond {
    filters: Vec<FilterCond>,
}

impl Condition for OrCond {
    fn evaluate(&self, id: i64, object: NativeObject) -> bool {
        for filter in &self.filters {
            if filter.evaluate(id, object) {
                return true;
            }
        }
        false
    }
}

#[derive(Clone)]
struct XorCond {
    filters: Vec<FilterCond>,
}

impl Condition for XorCond {
    fn evaluate(&self, id: i64, object: NativeObject) -> bool {
        let mut any = false;
        for filter in &self.filters {
            if filter.evaluate(id, object) {
                if any {
                    return false;
                } else {
                    any = true;
                }
            }
        }
        any
    }
}

#[derive(Clone)]
struct NotCond {
    filter: Box<FilterCond>,
}

impl Condition for NotCond {
    fn evaluate(&self, id: i64, object: NativeObject) -> bool {
        !self.filter.evaluate(id, object)
    }
}

#[derive(Clone)]
struct StaticCond {
    value: bool,
}

impl Condition for StaticCond {
    fn evaluate(&self, _id: i64, _object: NativeObject) -> bool {
        self.value
    }
}
