use crate::core::data_type::DataType;
use crate::core::fast_wild_match::fast_wild_match;
use crate::core::filter::ConditionType;
use crate::core::filter_json::matches_json;
use crate::core::value::IsarValue;
use crate::native::isar_deserializer::IsarDeserializer;
use crate::native::native_collection::NativeProperty;
use enum_dispatch::enum_dispatch;
use intmap::IntMap;
use itertools::Itertools;
use paste::paste;
use regex::{Regex, RegexBuilder};
use serde_json::Value;

#[macro_export]
macro_rules! primitive_create {
    ($data_type:ident, $property:expr, $lower:expr, $upper:expr) => {
        paste! {
            {
                let filter = if $property.data_type == DataType::$data_type {
                    Filter::[<$data_type Between>]([<$data_type BetweenCond>] {
                        offset: $property.offset,
                        $lower,
                        $upper,
                    })
                } else if $property.data_type == DataType::[<$data_type List>] {
                    Filter::[<Any $data_type Between>]([<Any $data_type BetweenCond>] {
                        offset: $property.offset,
                        $lower,
                        $upper,
                    })
                } else {
                    return None;
                };
                Some(NativeFilter(filter))
            }
        }
    };
}

#[macro_export]
macro_rules! string_filter_create {
    ($name:ident, $property:expr, $value:expr, $case_sensitive:expr) => {
        paste! {
            {
                let value = $value.to_string();
                let filter = if $property.data_type == DataType::String {
                    Filter::[<String $name>]([<String $name Cond>] {
                        offset: $property.offset,
                        value,
                        $case_sensitive,
                    })
                } else if $property.data_type == DataType::StringList {
                    Filter::[<AnyString $name>]([<AnyString $name Cond>] {
                        offset: $property.offset,
                        value,
                        $case_sensitive,
                    })
                } else {
                    return None;
                };
                Some(NativeFilter(filter))
            }
        }
    };
}

#[derive(Clone, Debug)]
pub struct NativeFilter(Filter);

impl NativeFilter {
    pub fn is_null(property: &NativeProperty) -> NativeFilter {
        let filter = Filter::IsNull(IsNullCond {
            offset: property.offset,
            data_type: property.data_type,
        });
        NativeFilter(filter)
    }

    pub fn id(lower: i64, upper: i64) -> NativeFilter {
        let filter = Filter::IdBetween(IdBetweenCond { lower, upper });
        NativeFilter(filter)
    }

    pub fn bool(
        property: &NativeProperty,
        lower: Option<bool>,
        upper: Option<bool>,
    ) -> Option<NativeFilter> {
        primitive_create!(Bool, property, lower, upper)
    }

    pub fn byte(property: &NativeProperty, lower: u8, upper: u8) -> Option<NativeFilter> {
        primitive_create!(Byte, property, lower, upper)
    }

    pub fn int(property: &NativeProperty, lower: i32, upper: i32) -> Option<NativeFilter> {
        primitive_create!(Int, property, lower, upper)
    }

    pub fn long(property: &NativeProperty, lower: i64, upper: i64) -> Option<NativeFilter> {
        primitive_create!(Long, property, lower, upper)
    }

    pub fn float(property: &NativeProperty, lower: f32, upper: f32) -> Option<NativeFilter> {
        primitive_create!(Float, property, lower, upper)
    }

    pub fn double(property: &NativeProperty, lower: f64, upper: f64) -> Option<NativeFilter> {
        primitive_create!(Double, property, lower, upper)
    }

    fn string_to_bytes(str: Option<&str>, case_sensitive: bool) -> Option<Vec<u8>> {
        if case_sensitive {
            str.map(|s| s.as_bytes().to_vec())
        } else {
            str.map(|s| s.to_lowercase().as_bytes().to_vec())
        }
    }

    pub fn string(
        property: &NativeProperty,
        lower: Option<&str>,
        upper: Option<&str>,
        case_sensitive: bool,
    ) -> Option<NativeFilter> {
        let lower = Self::string_to_bytes(lower, case_sensitive);
        let upper = Self::string_to_bytes(upper, case_sensitive);
        let filter = if property.data_type == DataType::String {
            Filter::StringBetween(StringBetweenCond {
                offset: property.offset,
                lower,
                upper,
                case_sensitive,
            })
        } else if property.data_type == DataType::StringList {
            Filter::AnyStringBetween(AnyStringBetweenCond {
                offset: property.offset,
                lower,
                upper,
                case_sensitive,
            })
        } else {
            return None;
        };
        Some(NativeFilter(filter))
    }

    pub fn string_ends_with(
        property: &NativeProperty,
        value: &str,
        case_sensitive: bool,
    ) -> Option<NativeFilter> {
        string_filter_create!(EndsWith, property, value, case_sensitive)
    }

    pub fn string_contains(
        property: &NativeProperty,
        value: &str,
        case_sensitive: bool,
    ) -> Option<NativeFilter> {
        string_filter_create!(Contains, property, value, case_sensitive)
    }

    pub fn string_matches(
        property: &NativeProperty,
        value: &str,
        case_sensitive: bool,
    ) -> Option<NativeFilter> {
        string_filter_create!(Matches, property, value, case_sensitive)
    }

    pub fn string_regex(
        property: &NativeProperty,
        pattern: &str,
        case_sensitive: bool,
    ) -> Option<NativeFilter> {
        let mut builder = RegexBuilder::new(pattern);
        builder.case_insensitive(!case_sensitive);
        let filter = if property.data_type == DataType::String {
            Filter::StringRegex(StringRegexCond {
                offset: property.offset,
                regex: builder.build().ok()?,
            })
        } else if property.data_type == DataType::StringList {
            Filter::AnyStringRegex(AnyStringRegexCond {
                offset: property.offset,
                regex: builder.build().ok()?,
            })
        } else {
            return None;
        };
        Some(NativeFilter(filter))
    }

    pub fn is_in(
        property: &NativeProperty,
        values: &[Option<IsarValue>],
        case_sensitive: bool,
    ) -> NativeFilter {
        let mut hashes = IntMap::new();
        for value in values {
            let hash = IsarValue::hash(value, case_sensitive, 0);
            hashes.insert(hash, ());
        }
        let filter = Filter::In(InCond {
            offset: property.offset,
            data_type: property.data_type,
            case_sensitive: false,
            hashes,
        });
        NativeFilter(filter)
    }

    pub fn embedded(property: &NativeProperty, filter: NativeFilter) -> Option<NativeFilter> {
        let filter = if property.data_type == DataType::Object {
            Filter::Embedded(EmbeddedCond {
                offset: property.offset,
                filter: Box::new(filter.0),
            })
        } else {
            return None;
        };
        Some(NativeFilter(filter))
    }

    pub fn json(
        property: &NativeProperty,
        path: Vec<String>,
        condition_type: ConditionType,
        values: Vec<Option<IsarValue>>,
        case_sensitive: bool,
    ) -> Option<NativeFilter> {
        let filter = if property.data_type == DataType::Json {
            let regex = if condition_type == ConditionType::StringRegex {
                let pattern = values.get(0)?.as_ref()?.string()?;
                Some(Regex::new(&pattern).ok()?)
            } else {
                None
            };
            Filter::Json(JsonCond {
                offset: property.offset,
                path,
                condition_type,
                values,
                case_sensitive,
                regex,
            })
        } else {
            return None;
        };
        Some(NativeFilter(filter))
    }

    pub fn and(mut filters: Vec<NativeFilter>) -> NativeFilter {
        if filters.is_empty() {
            NativeFilter::stat(true)
        } else if filters.len() == 1 {
            filters.remove(0)
        } else {
            let filters = filters.into_iter().map(|f| f.0).collect_vec();
            let filter_cond = Filter::And(AndCond { filters });
            NativeFilter(filter_cond)
        }
    }

    pub fn or(mut filters: Vec<NativeFilter>) -> NativeFilter {
        if filters.is_empty() {
            NativeFilter::stat(false)
        } else if filters.len() == 1 {
            filters.remove(0)
        } else {
            let filters = filters.into_iter().map(|f| f.0).collect_vec();
            let filter_cond = Filter::Or(OrCond { filters });
            NativeFilter(filter_cond)
        }
    }

    pub fn not(filter: NativeFilter) -> NativeFilter {
        let filter_cond = Filter::Not(NotCond {
            filter: Box::new(filter.0),
        });
        NativeFilter(filter_cond)
    }

    pub fn stat(value: bool) -> NativeFilter {
        let filter_cond = Filter::Static(StaticCond { value });
        NativeFilter(filter_cond)
    }

    pub(crate) fn evaluate(&self, id: i64, object: IsarDeserializer) -> bool {
        self.0.evaluate(id, object)
    }
}

#[enum_dispatch]
#[derive(Clone, Debug)]
enum Filter {
    IsNull(IsNullCond),

    IdBetween(IdBetweenCond),
    BoolBetween(BoolBetweenCond),
    ByteBetween(ByteBetweenCond),
    IntBetween(IntBetweenCond),
    LongBetween(LongBetweenCond),
    FloatBetween(FloatBetweenCond),
    DoubleBetween(DoubleBetweenCond),

    StringBetween(StringBetweenCond),
    StringEndsWith(StringEndsWithCond),
    StringContains(StringContainsCond),
    StringMatches(StringMatchesCond),
    StringRegex(StringRegexCond),

    AnyByteBetween(AnyByteBetweenCond),
    AnyBoolBetween(AnyBoolBetweenCond),
    AnyIntBetween(AnyIntBetweenCond),
    AnyLongBetween(AnyLongBetweenCond),
    AnyFloatBetween(AnyFloatBetweenCond),
    AnyDoubleBetween(AnyDoubleBetweenCond),

    AnyStringBetween(AnyStringBetweenCond),
    AnyStringEndsWith(AnyStringEndsWithCond),
    AnyStringContains(AnyStringContainsCond),
    AnyStringMatches(AnyStringMatchesCond),
    AnyStringRegex(AnyStringRegexCond),

    In(InCond),
    Embedded(EmbeddedCond),
    Json(JsonCond),
    And(AndCond),
    Or(OrCond),
    Not(NotCond),
    Static(StaticCond),
}

#[enum_dispatch(Filter)]
trait Condition {
    fn evaluate(&self, id: i64, object: IsarDeserializer) -> bool;
}

#[derive(Clone, Debug)]
struct IsNullCond {
    offset: u32,
    data_type: DataType,
}

impl Condition for IsNullCond {
    fn evaluate(&self, _id: i64, object: IsarDeserializer) -> bool {
        object.is_null(self.offset, self.data_type)
    }
}

#[derive(Clone, Debug)]
struct IdBetweenCond {
    lower: i64,
    upper: i64,
}

impl Condition for IdBetweenCond {
    #[inline]
    fn evaluate(&self, id: i64, _object: IsarDeserializer) -> bool {
        self.lower <= id && self.upper >= id
    }
}

#[macro_export]
macro_rules! filter_between {
    ($type:ty, $data_type:ident, $prop_accessor:ident) => {
        paste! {
            #[derive(Clone, Debug)]
            struct [<$data_type BetweenCond>] {
                upper: $type,
                lower: $type,
                offset: u32,
            }


            impl Condition for [<$data_type BetweenCond>] {
                #[inline]
                fn evaluate(&self, _id: i64, object: IsarDeserializer) -> bool {
                    let val = object.$prop_accessor(self.offset);
                    let result = filter_between!(eval val, self, $data_type);
                    result
                }
            }

            #[derive(Clone, Debug)]
            struct [<Any $data_type BetweenCond>] {
                upper: $type,
                lower: $type,
                offset: u32,
            }


            impl Condition for [<Any $data_type BetweenCond>] {
                fn evaluate(&self, _id: i64, object: IsarDeserializer) -> bool {
                    if let Some((list, length)) = object.read_list(self.offset, DataType::$data_type) {
                        for i in 0..length {
                            let val = list.$prop_accessor(i * DataType::$data_type.static_size() as u32);
                            if filter_between!(eval val, self, $data_type) {
                                return true;
                            }
                        }
                    }
                    false
                }
            }
        }
    };

    (eval $val:expr, $self:ident, Float) => {
        ($self.lower <= $val || $self.lower.is_nan()) && ($self.upper >= $val || $val.is_nan())
    };

    (eval $val:expr, $self:ident, Double) => {
        ($self.lower <= $val || $self.lower.is_nan()) && ($self.upper >= $val || $val.is_nan())
    };

    (eval $val:expr, $self:ident, $data_type:ident) => {
        $self.lower <= $val && $self.upper >= $val
    };
}

filter_between!(Option<bool>, Bool, read_bool);
filter_between!(u8, Byte, read_byte);
filter_between!(i32, Int, read_int);
filter_between!(i64, Long, read_long);
filter_between!(f32, Float, read_float);
filter_between!(f64, Double, read_double);

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

#[derive(Clone, Debug)]
struct StringBetweenCond {
    upper: Option<Vec<u8>>,
    lower: Option<Vec<u8>>,
    offset: u32,
    case_sensitive: bool,
}

impl Condition for StringBetweenCond {
    #[inline]
    fn evaluate(&self, _id: i64, object: IsarDeserializer) -> bool {
        let value = object.read_string(self.offset);
        string_between(
            value,
            self.lower.as_deref(),
            self.upper.as_deref(),
            self.case_sensitive,
        )
    }
}

#[derive(Clone, Debug)]
struct AnyStringBetweenCond {
    upper: Option<Vec<u8>>,
    lower: Option<Vec<u8>>,
    offset: u32,
    case_sensitive: bool,
}

impl Condition for AnyStringBetweenCond {
    fn evaluate(&self, _id: i64, object: IsarDeserializer) -> bool {
        if let Some((list, length)) = object.read_list(self.offset, DataType::String) {
            for i in 0..length {
                let value = list.read_string(i * DataType::String.static_size() as u32);
                let result = string_between(
                    value,
                    self.lower.as_deref(),
                    self.upper.as_deref(),
                    self.case_sensitive,
                );
                if result {
                    return true;
                }
            }
        }
        false
    }
}

#[macro_export]
macro_rules! string_filter_struct {
    ($name:ident) => {
        paste! {
            #[derive(Clone, Debug)]
            struct [<$name Cond>] {
                offset: u32,
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
                fn evaluate(&self, _id: i64, object: IsarDeserializer) -> bool {
                    let other_str = object.read_string(self.offset);
                    string_filter!(eval $name, self, other_str)
                }
            }

            string_filter_struct!([<Any $name>]);
            impl Condition for [<Any $name Cond>] {
                fn evaluate(&self, _id: i64, object: IsarDeserializer) -> bool {
                    if let Some((list, length)) = object.read_list(self.offset, DataType::String) {
                        for i in 0..length {
                            let value = list.read_string(i * DataType::String.static_size() as u32);
                            if string_filter!(eval $name, self, value) {
                                return true;
                            }
                        }
                    }
                    false
                }
            }
        }
    };

    (eval $name:tt, $filter:expr, $value:expr) => {
        if let Some(other_str) = $value {
            if $filter.case_sensitive {
                string_filter!($name & $filter.value, other_str)
            } else {
                let lowercase_string = other_str.to_lowercase();
                let lowercase_str = &lowercase_string;
                string_filter!($name & $filter.value, lowercase_str)
            }
        } else {
            false
        }
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

string_filter!(StringEndsWith);
string_filter!(StringContains);
string_filter!(StringMatches);

#[derive(Clone, Debug)]
struct StringRegexCond {
    offset: u32,
    regex: Regex,
}

impl Condition for StringRegexCond {
    fn evaluate(&self, _id: i64, object: IsarDeserializer) -> bool {
        let value = object.read_string(self.offset);
        if let Some(value) = value {
            self.regex.is_match(value)
        } else {
            false
        }
    }
}

#[derive(Clone, Debug)]
struct AnyStringRegexCond {
    offset: u32,
    regex: Regex,
}

impl Condition for AnyStringRegexCond {
    fn evaluate(&self, _id: i64, object: IsarDeserializer) -> bool {
        if let Some((list, length)) = object.read_list(self.offset, DataType::String) {
            for i in 0..length {
                let value = list.read_string(i * DataType::String.static_size() as u32);
                if let Some(value) = value {
                    if self.regex.is_match(value) {
                        return true;
                    }
                }
            }
        }
        false
    }
}

#[derive(Clone, Debug)]
struct InCond {
    offset: u32,
    data_type: DataType,
    case_sensitive: bool,
    hashes: IntMap<u64, ()>,
}

impl Condition for InCond {
    fn evaluate(&self, _id: i64, object: IsarDeserializer) -> bool {
        if let Some(element_type) = self.data_type.element_type() {
            let list = object.read_list(self.offset, self.data_type);
            if let Some((list, length)) = list {
                for i in 0..length {
                    let hash = list.hash_property(
                        i * element_type.static_size() as u32,
                        element_type,
                        self.case_sensitive,
                        0,
                    );
                    if self.hashes.contains_key(hash) {
                        return true;
                    }
                }
            }
            false
        } else {
            let hash = object.hash_property(self.offset, self.data_type, self.case_sensitive, 0);
            self.hashes.contains_key(hash)
        }
    }
}

#[derive(Clone, Debug)]
struct EmbeddedCond {
    offset: u32,
    filter: Box<Filter>,
}

impl Condition for EmbeddedCond {
    fn evaluate(&self, _id: i64, object: IsarDeserializer) -> bool {
        if let Some(object) = object.read_nested(self.offset) {
            self.filter.evaluate(i64::MIN, object)
        } else {
            false
        }
    }
}

#[derive(Clone, Debug)]
struct JsonCond {
    offset: u32,
    path: Vec<String>,
    condition_type: ConditionType,
    values: Vec<Option<IsarValue>>,
    regex: Option<Regex>,
    case_sensitive: bool,
}

impl Condition for JsonCond {
    fn evaluate(&self, _id: i64, object: IsarDeserializer) -> bool {
        if let Some(string) = object.read_string(self.offset) {
            let json = serde_json::from_str::<Value>(string);
            if let Ok(json) = json {
                matches_json(
                    &json,
                    self.condition_type,
                    &self.path,
                    &self.values,
                    self.regex.as_ref(),
                    self.case_sensitive,
                )
            } else {
                false
            }
        } else {
            false
        }
    }
}

#[derive(Clone, Debug)]
struct AndCond {
    filters: Vec<Filter>,
}

impl Condition for AndCond {
    #[inline]
    fn evaluate(&self, id: i64, object: IsarDeserializer) -> bool {
        for filter in &self.filters {
            if !filter.evaluate(id, object) {
                return false;
            }
        }
        true
    }
}

#[derive(Clone, Debug)]
struct OrCond {
    filters: Vec<Filter>,
}

impl Condition for OrCond {
    #[inline]
    fn evaluate(&self, id: i64, object: IsarDeserializer) -> bool {
        for filter in &self.filters {
            if filter.evaluate(id, object) {
                return true;
            }
        }
        false
    }
}

#[derive(Clone, Debug)]
struct NotCond {
    filter: Box<Filter>,
}

impl Condition for NotCond {
    #[inline]
    fn evaluate(&self, id: i64, object: IsarDeserializer) -> bool {
        !self.filter.evaluate(id, object)
    }
}

#[derive(Clone, Debug)]
struct StaticCond {
    value: bool,
}

impl Condition for StaticCond {
    fn evaluate(&self, _id: i64, _: IsarDeserializer) -> bool {
        self.value
    }
}
