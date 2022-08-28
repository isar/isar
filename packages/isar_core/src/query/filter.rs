use crate::collection::IsarCollection;
use crate::cursor::IsarCursors;
use crate::error::{illegal_arg, Result};
use crate::link::IsarLink;
use crate::object::data_type::DataType;
use crate::object::isar_object::IsarObject;
use crate::object::property::Property;
use crate::query::fast_wild_match::fast_wild_match;
use enum_dispatch::enum_dispatch;
use itertools::Itertools;
use paste::paste;

#[macro_export]
macro_rules! primitive_create {
    ($data_type:ident, $property:expr, $lower:expr, $upper:expr) => {
        paste! {
            if $property.data_type == DataType::$data_type || ($property.data_type == DataType::Bool && DataType::$data_type == DataType::Byte) {
                Ok(Filter(
                    FilterCond::[<$data_type Between>]([<$data_type BetweenCond>] {
                        offset: $property.offset,
                        $lower,
                        $upper,
                    })
                ))
            } else if $property.data_type == DataType::[<$data_type List>] || ($property.data_type == DataType::BoolList && DataType::[<$data_type List>] == DataType::ByteList) {
                Ok(Filter(
                    FilterCond::[<Any $data_type Between>]([<Any $data_type BetweenCond>] {
                        offset: $property.offset,
                        $lower,
                        $upper,
                    })
                ))
            } else {
                illegal_arg("Property does not support this filter.")
            }
        }
    };
}

#[macro_export]
macro_rules! string_filter_create {
    ($name:ident, $property:expr, $value:expr, $case_sensitive:expr) => {
        paste! {
            {
                let value = if $case_sensitive {
                    $value.to_string()
                } else {
                    $value.to_lowercase()
                };
                let filter_cond = if $property.data_type == DataType::String {
                    Ok(FilterCond::[<String $name>]([<String $name Cond>] {
                        offset: $property.offset,
                        value,
                        $case_sensitive,
                    }))
                } else if $property.data_type == DataType::StringList {
                    Ok(FilterCond::[<AnyString $name>]([<AnyString $name Cond>] {
                        offset: $property.offset,
                        value,
                        $case_sensitive,
                    }))
                } else {
                    illegal_arg("Property does not support this filter.")
                }?;
                Ok(Filter(filter_cond))
            }
        }
    };
}

#[derive(Clone)]
pub struct Filter(FilterCond);

impl Filter {
    pub fn id(lower: i64, upper: i64) -> Filter {
        let filter_cond = FilterCond::IdBetween(IdBetweenCond { lower, upper });
        Filter(filter_cond)
    }

    pub fn byte(property: &Property, lower: u8, upper: u8) -> Result<Filter> {
        primitive_create!(Byte, property, lower, upper)
    }

    pub fn int(property: &Property, lower: i32, upper: i32) -> Result<Filter> {
        primitive_create!(Int, property, lower, upper)
    }

    pub fn long(property: &Property, lower: i64, upper: i64) -> Result<Filter> {
        primitive_create!(Long, property, lower, upper)
    }

    pub fn float(property: &Property, lower: f32, upper: f32) -> Result<Filter> {
        primitive_create!(Float, property, lower, upper)
    }

    pub fn double(property: &Property, lower: f64, upper: f64) -> Result<Filter> {
        primitive_create!(Double, property, lower, upper)
    }

    pub fn string_to_bytes(str: Option<&str>, case_sensitive: bool) -> Option<Vec<u8>> {
        if case_sensitive {
            str.map(|s| s.as_bytes().to_vec())
        } else {
            str.map(|s| s.to_lowercase().as_bytes().to_vec())
        }
    }

    pub fn string(
        property: &Property,
        lower: Option<&str>,
        upper: Option<&str>,
        case_sensitive: bool,
    ) -> Result<Filter> {
        Self::byte_string(
            property,
            Self::string_to_bytes(lower, case_sensitive),
            Self::string_to_bytes(upper, case_sensitive),
            case_sensitive,
        )
    }

    pub fn byte_string(
        property: &Property,
        lower: Option<Vec<u8>>,
        upper: Option<Vec<u8>>,
        case_sensitive: bool,
    ) -> Result<Filter> {
        let filter_cond = if property.data_type == DataType::String {
            Ok(FilterCond::StringBetween(StringBetweenCond {
                offset: property.offset,
                lower,
                upper,
                case_sensitive,
            }))
        } else if property.data_type == DataType::StringList {
            Ok(FilterCond::AnyStringBetween(AnyStringBetweenCond {
                offset: property.offset,
                lower,
                upper,
                case_sensitive,
            }))
        } else {
            illegal_arg("Property does not support this filter.")
        }?;
        Ok(Filter(filter_cond))
    }

    pub fn string_starts_with(
        property: &Property,
        value: &str,
        case_sensitive: bool,
    ) -> Result<Filter> {
        string_filter_create!(StartsWith, property, value, case_sensitive)
    }

    pub fn string_ends_with(
        property: &Property,
        value: &str,
        case_sensitive: bool,
    ) -> Result<Filter> {
        string_filter_create!(EndsWith, property, value, case_sensitive)
    }

    pub fn string_contains(
        property: &Property,
        value: &str,
        case_sensitive: bool,
    ) -> Result<Filter> {
        string_filter_create!(Contains, property, value, case_sensitive)
    }

    pub fn string_matches(
        property: &Property,
        value: &str,
        case_sensitive: bool,
    ) -> Result<Filter> {
        string_filter_create!(Matches, property, value, case_sensitive)
    }

    pub fn list_length(property: &Property, lower: usize, upper: usize) -> Result<Filter> {
        let filter_cond = if property.data_type.get_element_type().is_some() {
            Ok(FilterCond::ListLength(ListLengthCond {
                offset: property.offset,
                lower,
                upper,
            }))
        } else {
            illegal_arg("Property does not support this filter.")
        }?;
        Ok(Filter(filter_cond))
    }

    pub fn null(property: &Property) -> Filter {
        let filter_cond = FilterCond::Null(NullCond {
            offset: property.offset,
            data_type: property.data_type,
        });
        Filter(filter_cond)
    }

    pub fn and(filters: Vec<Filter>) -> Filter {
        let filters = filters.into_iter().map(|f| f.0).collect_vec();
        let filter_cond = FilterCond::And(AndCond { filters });
        Filter(filter_cond)
    }

    pub fn or(filters: Vec<Filter>) -> Filter {
        let filters = filters.into_iter().map(|f| f.0).collect_vec();
        let filter_cond = FilterCond::Or(OrCond { filters });
        Filter(filter_cond)
    }

    pub fn xor(filters: Vec<Filter>) -> Filter {
        let filters = filters.into_iter().map(|f| f.0).collect_vec();
        let filter_cond = FilterCond::Xor(XorCond { filters });
        Filter(filter_cond)
    }

    pub fn not(filter: Filter) -> Filter {
        let filter_cond = FilterCond::Not(NotCond {
            filter: Box::new(filter.0),
        });
        Filter(filter_cond)
    }

    pub fn stat(value: bool) -> Filter {
        let filter_cond = FilterCond::Static(StaticCond { value });
        Filter(filter_cond)
    }

    pub fn object(property: &Property, filter: Option<Filter>) -> Result<Filter> {
        let filter_cond = if property.data_type == DataType::Object {
            if let Some(filter) = filter {
                Ok(FilterCond::Object(ObjectCond {
                    offset: property.offset,
                    filter: Box::new(filter.0),
                }))
            } else {
                Ok(FilterCond::Null(NullCond {
                    offset: property.offset,
                    data_type: DataType::Object,
                }))
            }
        } else if property.data_type == DataType::ObjectList {
            Ok(FilterCond::AnyObject(AnyObjectCond {
                offset: property.offset,
                filter: filter.map(|f| Box::new(f.0)),
            }))
        } else {
            illegal_arg("Property does not support this filter.")
        }?;
        Ok(Filter(filter_cond))
    }

    pub fn link(collection: &IsarCollection, link_id: u64, filter: Filter) -> Result<Filter> {
        let link = collection.get_link_backlink(link_id)?.clone();
        let filter_cond = FilterCond::AnyLink(AnyLinkCond {
            link,
            filter: Box::new(filter.0),
        });
        Ok(Filter(filter_cond))
    }

    pub fn link_length(
        collection: &IsarCollection,
        link_id: u64,
        lower: usize,
        upper: usize,
    ) -> Result<Filter> {
        let link = collection.get_link_backlink(link_id)?.clone();
        let filter_cond = FilterCond::LinkLength(LinkLengthCond { link, lower, upper });
        Ok(Filter(filter_cond))
    }

    pub(crate) fn evaluate(
        &self,
        id: i64,
        object: IsarObject,
        cursors: Option<&IsarCursors>,
    ) -> Result<bool> {
        self.0.evaluate(id, object, cursors)
    }
}

#[enum_dispatch]
#[derive(Clone)]
enum FilterCond {
    IdBetween(IdBetweenCond),
    ByteBetween(ByteBetweenCond),
    IntBetween(IntBetweenCond),
    LongBetween(LongBetweenCond),
    FloatBetween(FloatBetweenCond),
    DoubleBetween(DoubleBetweenCond),

    StringBetween(StringBetweenCond),
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

    ListLength(ListLengthCond),

    Null(NullCond),
    And(AndCond),
    Or(OrCond),
    Xor(XorCond),
    Not(NotCond),
    Static(StaticCond),

    Object(ObjectCond),
    AnyObject(AnyObjectCond),

    AnyLink(AnyLinkCond),
    LinkLength(LinkLengthCond),
}

#[enum_dispatch(FilterCond)]
trait Condition {
    fn evaluate(&self, id: i64, object: IsarObject, cursors: Option<&IsarCursors>) -> Result<bool>;
}

#[derive(Clone)]
struct IdBetweenCond {
    lower: i64,
    upper: i64,
}

impl Condition for IdBetweenCond {
    fn evaluate(&self, id: i64, _object: IsarObject, _: Option<&IsarCursors>) -> Result<bool> {
        Ok(self.lower <= id && self.upper >= id)
    }
}

#[macro_export]
macro_rules! filter_between_struct {
    ($name:ident, $data_type:ident, $type:ty) => {
        #[derive(Clone)]
        struct $name {
            upper: $type,
            lower: $type,
            offset: usize,
        }
    };
}

#[macro_export]
macro_rules! primitive_filter_between {
    ($name:ident, $prop_accessor:ident) => {
        impl Condition for $name {
            fn evaluate(
                &self,
                _id: i64,
                object: IsarObject,
                _: Option<&IsarCursors>,
            ) -> Result<bool> {
                let val = object.$prop_accessor(self.offset);
                Ok(self.lower <= val && self.upper >= val)
            }
        }
    };
}

filter_between_struct!(ByteBetweenCond, Byte, u8);
primitive_filter_between!(ByteBetweenCond, read_byte);
filter_between_struct!(IntBetweenCond, Int, i32);
primitive_filter_between!(IntBetweenCond, read_int);
filter_between_struct!(LongBetweenCond, Long, i64);
primitive_filter_between!(LongBetweenCond, read_long);

#[macro_export]
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
}

#[derive(Clone)]
struct NullCond {
    offset: usize,
    data_type: DataType,
}

impl Condition for NullCond {
    fn evaluate(
        &self,
        _id: i64,
        object: IsarObject,
        _cursors: Option<&IsarCursors>,
    ) -> Result<bool> {
        Ok(object.is_null(self.offset, self.data_type))
    }
}

#[derive(Clone)]
struct AndCond {
    filters: Vec<FilterCond>,
}

impl Condition for AndCond {
    fn evaluate(&self, id: i64, object: IsarObject, cursors: Option<&IsarCursors>) -> Result<bool> {
        for filter in &self.filters {
            if !filter.evaluate(id, object, cursors)? {
                return Ok(false);
            }
        }
        Ok(true)
    }
}

#[derive(Clone)]
struct OrCond {
    filters: Vec<FilterCond>,
}

impl Condition for OrCond {
    fn evaluate(&self, id: i64, object: IsarObject, cursors: Option<&IsarCursors>) -> Result<bool> {
        for filter in &self.filters {
            if filter.evaluate(id, object, cursors)? {
                return Ok(true);
            }
        }
        Ok(false)
    }
}

#[derive(Clone)]
struct XorCond {
    filters: Vec<FilterCond>,
}

impl Condition for XorCond {
    fn evaluate(&self, id: i64, object: IsarObject, cursors: Option<&IsarCursors>) -> Result<bool> {
        let mut any = false;
        for filter in &self.filters {
            if filter.evaluate(id, object, cursors)? {
                if any {
                    return Ok(false);
                } else {
                    any = true;
                }
            }
        }
        Ok(any)
    }
}

#[derive(Clone)]
struct NotCond {
    filter: Box<FilterCond>,
}

impl Condition for NotCond {
    fn evaluate(&self, id: i64, object: IsarObject, cursors: Option<&IsarCursors>) -> Result<bool> {
        Ok(!self.filter.evaluate(id, object, cursors)?)
    }
}

#[derive(Clone)]
struct StaticCond {
    value: bool,
}

impl Condition for StaticCond {
    fn evaluate(&self, _id: i64, _: IsarObject, _: Option<&IsarCursors>) -> Result<bool> {
        Ok(self.value)
    }
}

#[derive(Clone)]
struct ObjectCond {
    offset: usize,
    filter: Box<FilterCond>,
}

impl Condition for ObjectCond {
    fn evaluate(
        &self,
        _id: i64,
        object: IsarObject,
        _cursors: Option<&IsarCursors>,
    ) -> Result<bool> {
        if let Some(object) = object.read_object(self.offset) {
            self.filter.evaluate(i64::MIN, object, None)
        } else {
            Ok(false)
        }
    }
}

#[derive(Clone)]
struct AnyObjectCond {
    offset: usize,
    filter: Option<Box<FilterCond>>,
}

impl Condition for AnyObjectCond {
    fn evaluate(
        &self,
        _id: i64,
        object: IsarObject,
        _cursors: Option<&IsarCursors>,
    ) -> Result<bool> {
        if let Some(list) = object.read_object_list(self.offset) {
            if let Some(filter) = &self.filter {
                for object in list {
                    if let Some(object) = object {
                        let result = filter.evaluate(0, object, None)?;
                        if result {
                            return Ok(true);
                        }
                    }
                }
            } else {
                for object in list {
                    if object.is_none() {
                        return Ok(true);
                    }
                }
            }
        }
        Ok(false)
    }
}

#[derive(Clone)]
struct AnyLinkCond {
    link: IsarLink,
    filter: Box<FilterCond>,
}

impl Condition for AnyLinkCond {
    fn evaluate(
        &self,
        id: i64,
        _object: IsarObject,
        cursors: Option<&IsarCursors>,
    ) -> Result<bool> {
        if let Some(cursors) = cursors {
            self.link
                .iter(cursors, id, |id, object| {
                    self.filter
                        .evaluate(id, object, Some(cursors))
                        .map(|matches| !matches)
                })
                .map(|none_matches| !none_matches)
        } else {
            Ok(true)
        }
    }
}

#[derive(Clone)]
struct LinkLengthCond {
    link: IsarLink,
    lower: usize,
    upper: usize,
}

impl Condition for LinkLengthCond {
    fn evaluate(
        &self,
        id: i64,
        _object: IsarObject,
        cursors: Option<&IsarCursors>,
    ) -> Result<bool> {
        if let Some(cursors) = cursors {
            let mut length = 0;
            self.link.iter_ids(cursors, id, |_, _| {
                length += 1;
                Ok(true)
            })?;

            Ok(self.lower <= length && self.upper >= length)
        } else {
            Ok(true)
        }
    }
}
