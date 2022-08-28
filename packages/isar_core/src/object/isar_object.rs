use crate::object::data_type::DataType;
use crate::object::object_builder::ObjectBuilder;
use byteorder::{ByteOrder, LittleEndian};
use std::{cmp::Ordering, str::from_utf8_unchecked};
use xxhash_rust::xxh3::xxh3_64_with_seed;

#[derive(Copy, Clone, Eq, PartialEq)]
pub struct IsarObject<'a> {
    bytes: &'a [u8],
    static_size: usize,
}

impl<'a> IsarObject<'a> {
    pub const NULL_BYTE: u8 = 0;
    pub const NULL_BOOL: u8 = 0;
    pub const FALSE_BOOL: u8 = 1;
    pub const TRUE_BOOL: u8 = 2;
    pub const NULL_INT: i32 = i32::MIN;
    pub const NULL_LONG: i64 = i64::MIN;
    pub const NULL_FLOAT: f32 = f32::NAN;
    pub const NULL_DOUBLE: f64 = f64::NAN;
    pub const MAX_SIZE: u32 = 2 << 24;

    pub fn from_bytes(bytes: &'a [u8]) -> Self {
        let static_size = LittleEndian::read_u16(bytes) as usize;
        IsarObject { bytes, static_size }
    }

    pub fn as_bytes(&self) -> &'a [u8] {
        self.bytes
    }

    pub fn len(&self) -> usize {
        self.bytes.len()
    }

    #[inline]
    pub(crate) fn contains_offset(&self, offset: usize) -> bool {
        self.static_size > offset
    }

    pub fn is_null(&self, offset: usize, data_type: DataType) -> bool {
        match data_type {
            DataType::Byte => false,
            DataType::Bool => self.read_bool(offset).is_none(),
            DataType::Int => self.read_int(offset) == Self::NULL_INT,
            DataType::Long => self.read_long(offset) == Self::NULL_LONG,
            DataType::Float => self.read_float(offset).is_nan(),
            DataType::Double => self.read_double(offset).is_nan(),
            _ => self.get_offset_length(offset).is_none(),
        }
    }

    #[inline]
    pub fn byte_to_bool(value: u8) -> Option<bool> {
        if value == Self::NULL_BOOL {
            None
        } else {
            Some(value == Self::TRUE_BOOL)
        }
    }

    pub fn read_byte(&self, offset: usize) -> u8 {
        if self.contains_offset(offset) {
            self.bytes[offset]
        } else {
            Self::NULL_BYTE
        }
    }

    pub fn read_bool(&self, offset: usize) -> Option<bool> {
        let value = if self.contains_offset(offset) {
            self.bytes[offset]
        } else {
            Self::NULL_BOOL
        };
        Self::byte_to_bool(value)
    }

    pub fn read_int(&self, offset: usize) -> i32 {
        if self.contains_offset(offset) {
            LittleEndian::read_i32(&self.bytes[offset..])
        } else {
            Self::NULL_INT
        }
    }

    pub fn read_float(&self, offset: usize) -> f32 {
        if self.contains_offset(offset) {
            LittleEndian::read_f32(&self.bytes[offset..])
        } else {
            Self::NULL_FLOAT
        }
    }

    pub fn read_long(&self, offset: usize) -> i64 {
        if self.contains_offset(offset) {
            LittleEndian::read_i64(&self.bytes[offset..])
        } else {
            Self::NULL_LONG
        }
    }

    pub fn read_double(&self, offset: usize) -> f64 {
        if self.contains_offset(offset) {
            LittleEndian::read_f64(&self.bytes[offset..])
        } else {
            Self::NULL_DOUBLE
        }
    }

    fn read_u24(&self, offset: usize) -> usize {
        LittleEndian::read_u24(&self.bytes[offset..]) as usize
    }

    fn get_offset_length(&self, offset: usize) -> Option<(usize, usize)> {
        if self.contains_offset(offset) {
            let length_offset = self.read_u24(offset);
            if length_offset != 0 {
                let length = self.read_u24(length_offset);
                return Some((length_offset + 3, length));
            }
        }
        None
    }

    pub fn read_length(&self, offset: usize) -> Option<usize> {
        let (_, length) = self.get_offset_length(offset)?;
        Some(length)
    }

    pub fn read_byte_list(&self, offset: usize) -> Option<&'a [u8]> {
        let (offset, length) = self.get_offset_length(offset)?;
        Some(&self.bytes[offset..offset + length])
    }

    pub fn read_string(&'a self, offset: usize) -> Option<&'a str> {
        let bytes = self.read_byte_list(offset)?;
        let str = unsafe { from_utf8_unchecked(bytes) };
        Some(str)
    }

    pub fn read_object(&'a self, offset: usize) -> Option<IsarObject> {
        let bytes = self.read_byte_list(offset)?;
        Some(IsarObject::from_bytes(bytes))
    }

    pub fn read_bool_list(&self, offset: usize) -> Option<Vec<Option<bool>>> {
        let (offset, length) = self.get_offset_length(offset)?;
        let mut list = vec![None; length];
        for i in 0..length {
            list[i] = Self::byte_to_bool(self.bytes[offset + i]);
        }
        Some(list)
    }

    pub fn read_int_list(&self, offset: usize) -> Option<Vec<i32>> {
        let (offset, length) = self.get_offset_length(offset)?;
        let mut list = vec![0; length];
        for i in 0..length {
            list[i] = LittleEndian::read_i32(&self.bytes[offset + i * 4..]);
        }
        Some(list)
    }

    pub fn read_int_or_null_list(&self, offset: usize) -> Option<Vec<Option<i32>>> {
        self.read_int_list(offset).map(|list| {
            list.into_iter()
                .map(|value| {
                    if value != Self::NULL_INT {
                        Some(value)
                    } else {
                        None
                    }
                })
                .collect()
        })
    }

    pub fn read_float_list(&self, offset: usize) -> Option<Vec<f32>> {
        let (offset, length) = self.get_offset_length(offset)?;
        let mut list = vec![0.0; length];
        for i in 0..length {
            list[i] = LittleEndian::read_f32(&self.bytes[offset + i * 4..]);
        }
        Some(list)
    }

    pub fn read_float_or_null_list(&self, offset: usize) -> Option<Vec<Option<f32>>> {
        self.read_float_list(offset).map(|list| {
            list.into_iter()
                .map(|value| if !value.is_nan() { Some(value) } else { None })
                .collect()
        })
    }

    pub fn read_long_list(&self, offset: usize) -> Option<Vec<i64>> {
        let (offset, length) = self.get_offset_length(offset)?;
        let mut list = vec![0; length];
        for i in 0..length {
            list[i] = LittleEndian::read_i64(&self.bytes[offset + i * 8..]);
        }
        Some(list)
    }

    pub fn read_long_or_null_list(&self, offset: usize) -> Option<Vec<Option<i64>>> {
        self.read_long_list(offset).map(|list| {
            list.into_iter()
                .map(|value| {
                    if value != Self::NULL_LONG {
                        Some(value)
                    } else {
                        None
                    }
                })
                .collect()
        })
    }

    pub fn read_double_list(&self, offset: usize) -> Option<Vec<f64>> {
        let (offset, length) = self.get_offset_length(offset)?;
        let mut list = vec![0.0; length];
        for i in 0..length {
            list[i] = LittleEndian::read_f64(&self.bytes[offset + i * 8..]);
        }
        Some(list)
    }

    pub fn read_double_or_null_list(&self, offset: usize) -> Option<Vec<Option<f64>>> {
        self.read_double_list(offset).map(|list| {
            list.into_iter()
                .map(|value| if !value.is_nan() { Some(value) } else { None })
                .collect()
        })
    }

    pub fn read_string_list(&self, offset: usize) -> Option<Vec<Option<&'a str>>> {
        self.read_dynamic_list(offset, |bytes| unsafe { from_utf8_unchecked(bytes) })
    }

    pub fn read_object_list(&self, offset: usize) -> Option<Vec<Option<IsarObject<'a>>>> {
        self.read_dynamic_list(offset, |bytes| IsarObject::from_bytes(bytes))
    }

    fn read_dynamic_list<T: Clone>(
        &self,
        offset: usize,
        transform: impl Fn(&'a [u8]) -> T,
    ) -> Option<Vec<Option<T>>> {
        let (offset, length) = self.get_offset_length(offset)?;

        let mut list = vec![None; length];
        let mut content_offset = offset + length * 3;
        for i in 0..length {
            let item_size = self.read_u24(offset + i * 3);
            if item_size != 0 {
                let item_size = item_size - 1;
                let bytes = &self.bytes[content_offset..content_offset + item_size];
                let value = transform(bytes);
                list[i] = Some(value);
                content_offset += item_size;
            }
        }

        Some(list)
    }

    pub fn hash_property(
        &self,
        offset: usize,
        data_type: DataType,
        case_sensitive: bool,
        seed: u64,
    ) -> u64 {
        match data_type {
            DataType::Bool | DataType::Byte => xxh3_64_with_seed(&[self.read_byte(offset)], seed),
            DataType::Int => xxh3_64_with_seed(&self.read_int(offset).to_le_bytes(), seed),
            DataType::Float => xxh3_64_with_seed(&self.read_float(offset).to_le_bytes(), seed),
            DataType::Long => xxh3_64_with_seed(&self.read_long(offset).to_le_bytes(), seed),
            DataType::Double => xxh3_64_with_seed(&self.read_double(offset).to_le_bytes(), seed),
            DataType::String => Self::hash_string(self.read_string(offset), case_sensitive, seed),
            _ => match data_type {
                DataType::StringList => {
                    Self::hash_string_list(self.read_string_list(offset), case_sensitive, seed)
                }
                _ => {
                    if let Some((offset, length)) = self.get_offset_length(offset) {
                        let element_size = data_type.get_element_type().unwrap().get_static_size();
                        xxh3_64_with_seed(&self.bytes[offset..offset + length * element_size], seed)
                    } else {
                        seed
                    }
                }
            },
        }
    }

    pub fn hash_string(value: Option<&str>, case_sensitive: bool, seed: u64) -> u64 {
        if let Some(str) = value {
            if case_sensitive {
                xxh3_64_with_seed(str.as_bytes(), seed)
            } else {
                xxh3_64_with_seed(str.to_lowercase().as_bytes(), seed)
            }
        } else {
            seed
        }
    }

    pub fn hash_list<T>(value: Option<&[T]>, seed: u64) -> u64 {
        if let Some(list) = value {
            let bytes = ObjectBuilder::get_list_bytes(list);
            xxh3_64_with_seed(bytes, seed)
        } else {
            seed
        }
    }

    pub fn hash_string_list(
        value: Option<Vec<Option<&str>>>,
        case_sensitive: bool,
        seed: u64,
    ) -> u64 {
        if let Some(str) = value {
            let mut hash = seed;
            for value in str {
                hash = Self::hash_string(value, case_sensitive, hash);
            }
            hash
        } else {
            seed
        }
    }

    pub fn compare_property(
        &self,
        other: &IsarObject,
        offset: usize,
        data_type: DataType,
    ) -> Ordering {
        match data_type {
            DataType::Bool | DataType::Byte => self.read_byte(offset).cmp(&other.read_byte(offset)),
            DataType::Int => self.read_int(offset).cmp(&other.read_int(offset)),
            DataType::Float => self.read_float(offset).total_cmp(&other.read_float(offset)),
            DataType::Long => self.read_long(offset).cmp(&other.read_long(offset)),
            DataType::Double => self
                .read_double(offset)
                .total_cmp(&other.read_double(offset)),
            DataType::String => self.read_string(offset).cmp(&other.read_string(offset)),
            _ => Ordering::Equal,
        }
    }
}

#[cfg(test)]
mod tests {
    use itertools::Itertools;

    use crate::object::data_type::DataType::*;
    use crate::object::isar_object::IsarObject;
    use crate::object::object_builder::ObjectBuilder;
    use crate::object::property::Property;

    macro_rules! builder {
        ($builder:ident, $prop:ident, $type:ident) => {
            let $prop = Property::debug($type, 2);
            let props = vec![$prop.clone()];
            let mut $builder = ObjectBuilder::new(&props, None);
        };
    }

    #[test]
    fn test_read_non_contained_property() {
        let data_types = vec![
            Bool, Byte, Int, Float, Long, Double, String, BoolList, ByteList, IntList, FloatList,
            LongList, DoubleList, StringList,
        ];
        for data_type in data_types {
            builder!(_b, p, data_type);
            let empty = vec![0, 0];
            let object = IsarObject::from_bytes(&empty);
            let should_be_null = data_type != Byte;
            assert_eq!(object.is_null(p.offset, p.data_type), should_be_null);
        }
    }

    #[test]
    fn test_read_bool() {
        builder!(b, p, Bool);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().read_bool(p.offset), None);
        assert!(b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, Bool);
        b.write_bool(p.offset, Some(true));
        assert_eq!(b.finish().read_bool(p.offset), Some(true));
        assert!(!b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, Bool);
        b.write_bool(p.offset, Some(false));
        assert_eq!(b.finish().read_bool(p.offset), Some(false));
        assert!(!b.finish().is_null(p.offset, p.data_type));
    }

    #[test]
    fn test_read_byte() {
        builder!(b, p, Byte);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().read_byte(p.offset), IsarObject::NULL_BYTE);
        assert!(!b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, Byte);
        b.write_byte(p.offset, 123);
        assert_eq!(b.finish().read_byte(p.offset), 123);
        assert!(!b.finish().is_null(p.offset, p.data_type));
    }

    #[test]
    fn test_read_int() {
        builder!(b, p, Int);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().read_int(p.offset), IsarObject::NULL_INT);
        assert!(b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, Int);
        b.write_int(p.offset, 123);
        assert_eq!(b.finish().read_int(p.offset), 123);
        assert!(!b.finish().is_null(p.offset, p.data_type));
    }

    #[test]
    fn test_read_float() {
        builder!(b, p, Float);
        b.write_null(p.offset, p.data_type);
        assert!(b.finish().read_float(p.offset).is_nan());
        assert!(b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, Float);
        b.write_float(p.offset, 123.123);
        assert!((b.finish().read_float(p.offset) - 123.123).abs() < 0.000001);
        assert!(!b.finish().is_null(p.offset, p.data_type));
    }

    #[test]
    fn test_read_long() {
        builder!(b, p, Long);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().read_long(p.offset), IsarObject::NULL_LONG);
        assert!(b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, Long);
        b.write_long(p.offset, 123123123123123123);
        assert_eq!(b.finish().read_long(p.offset), 123123123123123123);
        assert!(!b.finish().is_null(p.offset, p.data_type));
    }

    #[test]
    fn test_read_double() {
        builder!(b, p, Double);
        b.write_null(p.offset, p.data_type);
        assert!(b.finish().read_double(p.offset).is_nan());
        assert!(b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, Double);
        b.write_double(p.offset, 123123.123123123);
        assert!((b.finish().read_double(p.offset) - 123123.123123123).abs() < 0.00000001);
        assert!(!b.finish().is_null(p.offset, p.data_type));
    }

    #[test]
    fn test_read_string() {
        builder!(b, p, String);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().read_string(p.offset), None);
        assert!(b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, String);
        b.write_string(p.offset, Some("hello"));
        assert_eq!(b.finish().read_string(p.offset), Some("hello"));
        assert!(!b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, String);
        b.write_string(p.offset, Some(""));
        assert_eq!(b.finish().read_string(p.offset), Some(""));
        assert!(!b.finish().is_null(p.offset, p.data_type));
    }

    #[test]
    fn test_read_byte_list() {
        builder!(b, p, ByteList);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().read_byte_list(p.offset), None);
        assert!(b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, ByteList);
        b.write_byte_list(p.offset, Some(&[1, 2, 3]));
        assert_eq!(b.finish().read_byte_list(p.offset), Some(&[1, 2, 3][..]));
        assert!(!b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, ByteList);
        b.write_byte_list(p.offset, Some(&[]));
        assert_eq!(b.finish().read_byte_list(p.offset), Some(&[][..]));
        assert!(!b.finish().is_null(p.offset, p.data_type));
    }

    #[test]
    fn test_read_int_list() {
        builder!(b, p, IntList);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().read_int_list(p.offset), None);
        assert!(b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, IntList);
        b.write_int_list(p.offset, Some(&[1, 2, 3]));
        assert_eq!(b.finish().read_int_list(p.offset), Some(vec![1, 2, 3]));
        assert!(!b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, IntList);
        b.write_int_list(p.offset, Some(&[]));
        assert_eq!(b.finish().read_int_list(p.offset), Some(vec![]));
        assert!(!b.finish().is_null(p.offset, p.data_type));
    }

    #[test]
    fn test_read_float_list() {
        builder!(b, p, FloatList);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().read_float_list(p.offset), None);
        assert!(b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, FloatList);
        b.write_float_list(p.offset, Some(&[1.1, 2.2, 3.3]));
        assert_eq!(
            b.finish().read_float_list(p.offset),
            Some(vec![1.1, 2.2, 3.3])
        );
        assert!(!b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, FloatList);
        b.write_float_list(p.offset, Some(&[]));
        assert_eq!(b.finish().read_float_list(p.offset), Some(vec![]));
        assert!(!b.finish().is_null(p.offset, p.data_type));
    }

    #[test]
    fn test_read_long_list() {
        builder!(b, p, LongList);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().read_long_list(p.offset), None);
        assert!(b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, LongList);
        b.write_long_list(p.offset, Some(&[1, 2, 3]));
        assert_eq!(b.finish().read_long_list(p.offset), Some(vec![1, 2, 3]));
        assert!(!b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, LongList);
        b.write_long_list(p.offset, Some(&[]));
        assert_eq!(b.finish().read_long_list(p.offset), Some(vec![]));
        assert!(!b.finish().is_null(p.offset, p.data_type));
    }

    #[test]
    fn test_read_double_list() {
        builder!(b, p, DoubleList);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().read_double_list(p.offset), None);
        assert!(b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, DoubleList);
        b.write_double_list(p.offset, Some(&[1.1, 2.2, 3.3]));
        assert_eq!(
            b.finish().read_double_list(p.offset),
            Some(vec![1.1, 2.2, 3.3])
        );
        assert!(!b.finish().is_null(p.offset, p.data_type));

        builder!(b, p, DoubleList);
        b.write_double_list(p.offset, Some(&[]));
        assert_eq!(b.finish().read_double_list(p.offset), Some(vec![]));
        assert!(!b.finish().is_null(p.offset, p.data_type));
    }

    #[test]
    fn test_read_string_list() {
        builder!(b, p, StringList);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().read_string_list(p.offset), None);

        let cases = vec![
            vec![],
            vec![None],
            vec![None, None],
            vec![None, None, None],
            vec![Some("")],
            vec![Some(""), Some("")],
            vec![Some(""), Some(""), Some("")],
            vec![Some(""), None],
            vec![None, Some("")],
            vec![Some(""), None, None],
            vec![None, Some(""), None],
            vec![None, None, Some("")],
            vec![None, Some(""), Some("")],
            vec![Some(""), None, Some("")],
            vec![Some(""), Some(""), None],
            vec![Some("a")],
            vec![Some("a"), Some("ab")],
            vec![Some("a"), Some("ab"), Some("abc")],
            vec![None, Some("a")],
            vec![Some("a"), None],
            vec![None, Some("a")],
            vec![Some("a"), None, None],
            vec![None, Some("a"), None],
            vec![None, None, Some("a")],
            vec![None, Some("a"), Some("bbb")],
            vec![Some("a"), None, Some("bbb")],
            vec![Some("a"), Some("bbb"), None],
        ];

        for case1 in &cases {
            for case2 in &cases {
                for case3 in &cases {
                    let case = case1
                        .iter()
                        .chain(case2)
                        .chain(case3)
                        .cloned()
                        .collect_vec();
                    builder!(b, p, StringList);
                    b.write_string_list(p.offset, Some(&case));
                    assert_eq!(b.finish().read_string_list(p.offset), Some(case));
                }
            }
        }
    }
}
