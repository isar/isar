use std::str::from_utf8_unchecked;

use super::{byte_to_bool, NULL_BOOL, NULL_BYTE, NULL_DOUBLE, NULL_FLOAT, NULL_INT, NULL_LONG};
use crate::core::data_type::DataType;
use byteorder::{ByteOrder, LittleEndian};
use xxhash_rust::xxh3::xxh3_64_with_seed;

#[derive(Copy, Clone, Eq, PartialEq)]
pub struct IsarDeserializer<'a> {
    bytes: &'a [u8],
    static_size: u32,
}

impl<'a> IsarDeserializer<'a> {
    #[inline]
    pub fn from_bytes(bytes: &'a [u8]) -> Self {
        let static_size = LittleEndian::read_u24(bytes);
        Self {
            bytes: &bytes[3..],
            static_size,
        }
    }

    #[inline]
    fn contains_offset(&self, offset: u32) -> bool {
        self.static_size > offset
    }

    #[inline]
    pub fn is_null(&self, offset: u32, data_type: DataType) -> bool {
        match data_type {
            DataType::Bool => self.read_byte(offset) == NULL_BOOL,
            DataType::Byte => self.read_byte(offset) == NULL_BYTE,
            DataType::Int => self.read_int(offset) == NULL_INT,
            DataType::Float => self.read_float(offset) == NULL_FLOAT,
            DataType::Long => self.read_long(offset) == NULL_LONG,
            DataType::Double => self.read_double(offset) == NULL_DOUBLE,
            _ => self.get_offset_length(offset).is_none(),
        }
    }

    #[inline]
    pub fn read_bool(&self, offset: u32) -> Option<bool> {
        if self.contains_offset(offset) {
            byte_to_bool(self.bytes[offset as usize])
        } else {
            None
        }
    }

    #[inline]
    pub fn read_byte(&self, offset: u32) -> u8 {
        if self.contains_offset(offset) {
            self.bytes[offset as usize]
        } else {
            NULL_BYTE
        }
    }

    #[inline]
    pub fn read_int(&self, offset: u32) -> i32 {
        if self.contains_offset(offset) {
            LittleEndian::read_i32(&self.bytes[offset as usize..])
        } else {
            NULL_INT
        }
    }

    #[inline]
    pub fn read_float(&self, offset: u32) -> f32 {
        if self.contains_offset(offset) {
            LittleEndian::read_f32(&self.bytes[offset as usize..])
        } else {
            NULL_FLOAT
        }
    }

    #[inline]
    pub fn read_long(&self, offset: u32) -> i64 {
        if self.contains_offset(offset) {
            LittleEndian::read_i64(&self.bytes[offset as usize..])
        } else {
            NULL_LONG
        }
    }

    #[inline]
    pub fn read_double(&self, offset: u32) -> f64 {
        if self.contains_offset(offset) {
            LittleEndian::read_f64(&self.bytes[offset as usize..])
        } else {
            NULL_DOUBLE
        }
    }

    #[inline]
    fn get_offset(&self, offset: u32) -> Option<usize> {
        if self.contains_offset(offset) {
            let offset = LittleEndian::read_u24(&self.bytes[offset as usize..]);
            if offset > 0 {
                return Some(offset as usize);
            }
        }
        None
    }

    #[inline]
    fn get_offset_length(&self, offset: u32) -> Option<(usize, usize)> {
        let offset = self.get_offset(offset)?;
        let length = LittleEndian::read_u24(&self.bytes[offset as usize..]);
        Some((offset as usize + 3, length as usize))
    }

    #[inline]
    pub fn read_dynamic(&self, offset: u32) -> Option<&'a [u8]> {
        let (offset, length) = self.get_offset_length(offset)?;
        let bytes = &self.bytes[offset..offset + length];
        Some(bytes)
    }

    #[inline]
    pub fn read_string(&self, offset: u32) -> Option<&'a str> {
        let bytes = self.read_dynamic(offset)?;
        unsafe { Some(from_utf8_unchecked(bytes)) }
    }

    #[inline]
    pub fn read_nested(&self, offset: u32) -> Option<IsarDeserializer<'a>> {
        let offset = self.get_offset(offset)?;
        let object = Self::from_bytes(&self.bytes[offset..]);
        Some(object)
    }

    #[inline]
    pub fn read_list(
        &self,
        offset: u32,
        element_type: DataType,
    ) -> Option<(IsarDeserializer<'a>, u32)> {
        let nested = self.read_nested(offset)?;
        let length = nested.static_size / element_type.static_size() as u32;
        Some((nested, length))
    }

    pub fn hash_property(
        &self,
        offset: u32,
        data_type: DataType,
        case_sensitive: bool,
        mut seed: u64,
    ) -> u64 {
        match data_type {
            DataType::Byte => xxh3_64_with_seed(&[self.read_byte(offset)], seed),
            DataType::Int => xxh3_64_with_seed(&self.read_int(offset).to_le_bytes(), seed),
            DataType::Float => {
                let value = self.read_float(offset);
                if value.is_nan() {
                    xxh3_64_with_seed(&[1, 0, 128, 127], seed)
                } else {
                    xxh3_64_with_seed(&value.to_le_bytes(), seed)
                }
            }
            DataType::Long => xxh3_64_with_seed(&self.read_long(offset).to_le_bytes(), seed),
            DataType::Double => {
                let value = self.read_float(offset);
                if value.is_nan() {
                    xxh3_64_with_seed(&[0, 0, 0, 0, 0, 0, 248, 127], seed)
                } else {
                    xxh3_64_with_seed(&value.to_le_bytes(), seed)
                }
            }
            DataType::String => {
                if let Some(str) = self.read_string(offset) {
                    seed = xxh3_64_with_seed(&[1], seed);
                    if case_sensitive {
                        xxh3_64_with_seed(str.as_bytes(), seed)
                    } else {
                        xxh3_64_with_seed(str.to_lowercase().as_bytes(), seed)
                    }
                } else {
                    xxh3_64_with_seed(&[0], seed)
                }
            }
            _ => seed,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::IsarDeserializer;
    use super::{NULL_BOOL, NULL_BYTE, NULL_DOUBLE, NULL_FLOAT, NULL_INT, NULL_LONG};
    use crate::core::data_type::DataType;
    use byteorder::{ByteOrder, LittleEndian};

    static LOREM: &str = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?";

    #[test]
    fn test_is_null() {
        let bytes = &[
            NULL_BYTE,
            NULL_BOOL,
            (NULL_INT & 0xFF) as u8,
            ((NULL_INT >> 8) & 0xFF) as u8,
            ((NULL_INT >> 16) & 0xFF) as u8,
            ((NULL_INT >> 24) & 0xFF) as u8,
            (NULL_LONG & 0xFF) as u8,
            ((NULL_LONG >> 8) & 0xFF) as u8,
        ];

        let deserializer = IsarDeserializer::from_bytes(bytes);

        assert_eq!(deserializer.is_null(0, DataType::Bool), true);

        assert_eq!(deserializer.is_null(0, DataType::Byte), true);

        assert_eq!(deserializer.is_null(0, DataType::Int), true);

        assert_eq!(deserializer.is_null(0, DataType::Float), false);

        assert_eq!(deserializer.is_null(0, DataType::Long), true);

        assert_eq!(deserializer.is_null(0, DataType::Double), false);

        assert_eq!(
            deserializer.is_null(0, DataType::String),
            deserializer.get_offset_length(0).is_none()
        );
    }
    mod read_offset_assertions {
        use super::*;

        #[test]
        fn from_bytes_basic() {
            let data = vec![0, 1, 0, 1, 2, 3, 4, 5];
            let deserializer = IsarDeserializer::from_bytes(&data);

            assert_eq!(deserializer.bytes, &data[3..]);
            assert_eq!(
                deserializer.static_size,
                LittleEndian::read_u24(&data[0..3])
            );
        }

        #[test]
        #[should_panic(
            expected = "assertion failed: 1 <= nbytes && nbytes <= 8 && nbytes <= buf.len()"
        )]
        fn from_bytes_empty() {
            let data = vec![];
            let deserializer = IsarDeserializer::from_bytes(&data);

            assert_eq!(deserializer.bytes, &data[3..]);
            assert_eq!(deserializer.static_size, 0);
        }

        #[test]
        #[should_panic(
            expected = "assertion failed: 1 <= nbytes && nbytes <= 8 && nbytes <= buf.len()"
        )]
        fn from_bytes_small_input() {
            let data = vec![1];
            let deserializer = IsarDeserializer::from_bytes(&data);

            assert_eq!(deserializer.bytes, &data[3..]);
            assert_eq!(deserializer.static_size, 1);
        }

        #[test]
        fn from_bytes_large_input() {
            let data = vec![0; 10000];
            let deserializer = IsarDeserializer::from_bytes(&data);

            assert_eq!(deserializer.bytes, &data[3..]);
            assert_eq!(
                deserializer.static_size,
                LittleEndian::read_u24(&data[0..3])
            );
        }
    }

    mod single_data_type {
        use super::*;

        #[test]
        fn test_read_single_bool() {
            let bytes = [0x1, 0x0, 0x0, 0x0];
            let deserializer = IsarDeserializer::from_bytes(&bytes);
            assert_eq!(deserializer.read_bool(0), None);

            let bytes = [0x1, 0x0, 0x0, 0x1];
            let deserializer = IsarDeserializer::from_bytes(&bytes);
            assert_eq!(deserializer.read_bool(0), Some(false));

            let bytes = [0x1, 0x0, 0x0, 0x2];
            let deserializer = IsarDeserializer::from_bytes(&bytes);
            assert_eq!(deserializer.read_bool(0), Some(true));
        }
        #[test]
        fn test_read_single_byte() {
            for value in [0, 1, 42, 254, 255] {
                let bytes = [0x1, 0x0, 0x0, value];
                let deserializer = IsarDeserializer::from_bytes(&bytes);
                assert_eq!(deserializer.read_byte(0), value);
            }
        }

        #[test]
        fn test_read_single_int() {
            for value in [0, 1, i32::MIN, i32::MAX, i32::MAX - 1] {
                let bytes = [0x4, 0x0, 0x0]
                    .iter()
                    .chain(&value.to_le_bytes())
                    .cloned()
                    .collect::<Vec<u8>>();
                let deserializer = IsarDeserializer::from_bytes(&bytes);
                assert_eq!(deserializer.read_int(0), value);
            }
        }

        #[test]
        fn test_read_single_float() {
            for value in [
                0f32,
                -5f32,
                10f32,
                f32::MIN,
                f32::NEG_INFINITY,
                f32::NAN,
                f32::MAX,
                f32::INFINITY,
            ] {
                let mut bytes = vec![0x4, 0x0, 0x0];
                bytes.extend_from_slice(&value.to_le_bytes());
                let deserializer = IsarDeserializer::from_bytes(&bytes);

                let deserialized_value = deserializer.read_float(0);
                assert!(
                    deserialized_value.is_nan() && value.is_nan() || deserialized_value == value
                );
            }
        }

        #[test]
        fn test_read_single_long() {
            for value in [0, -1, 1, i64::MIN, i64::MIN + 1, i64::MAX, i64::MAX - 1] {
                let mut bytes = vec![0x8, 0x0, 0x0];
                bytes.extend_from_slice(&value.to_le_bytes());
                let deserializer = IsarDeserializer::from_bytes(&bytes);

                let deserialized_value = deserializer.read_long(0);
                assert_eq!(deserialized_value, value);
            }
        }

        #[test]
        fn test_read_single_double() {
            for value in [
                0f64,
                -1f64,
                1f64,
                f64::MIN,
                f64::MIN.next_up(),
                f64::MAX,
                f64::MAX.next_down(),
            ] {
                let mut bytes = vec![0x8, 0x0, 0x0];
                bytes.extend_from_slice(&value.to_le_bytes());
                let deserializer = IsarDeserializer::from_bytes(&bytes);

                let deserialized_value = deserializer.read_double(0);
                assert_eq!(deserialized_value, value);
            }
        }

        #[test]
        fn test_read_single_dynamic() {
            let test_cases = [
                (
                    "foo".as_bytes(),
                    vec![
                        0x3, 0x0, 0x0, 0x3, 0x0, 0x0, 0x3, 0x0, 0x0, b'f', b'o', b'o',
                    ],
                ),
                (
                    "".as_bytes(),
                    vec![0x3, 0x0, 0x0, 0x3, 0x0, 0x0, 0x0, 0x0, 0x0],
                ),
                (LOREM.as_bytes(), {
                    let mut bytes = vec![0x3, 0x0, 0x0, 0x3, 0x0, 0x0];
                    bytes.extend_from_slice(&LOREM.len().to_le_bytes()[..3]);
                    bytes.extend_from_slice(LOREM.as_bytes());
                    bytes
                }),
            ];

            for (expected, bytes) in &test_cases {
                let deserializer = IsarDeserializer::from_bytes(&bytes);
                let deserialized_value = deserializer.read_dynamic(0).unwrap();
                assert_eq!(deserialized_value, *expected);
            }
        }

        #[test]
        fn test_read_single_string() {
            let lorem = LOREM;
            let mut bytes = vec![
                0xc, 0x0, 0x0, 0xc, 0x0, 0x0, 0x73, 0x0, 0x0, 0xda, 0x0, 0x0, 0x41, 0x1, 0x0,
            ];

            bytes.extend_from_slice(&[
                (lorem.len() & 0xff) as u8,
                ((lorem.len() >> 8) & 0xff) as u8,
                ((lorem.len() >> 16) & 0xff) as u8,
            ]);
            bytes.extend_from_slice(lorem.as_bytes());

            let deserializer = IsarDeserializer::from_bytes(&bytes);

            let deserialized_value = deserializer.read_string(0).unwrap();
            assert_eq!(deserialized_value, lorem);

            let emptu_string = "";
            let mut bytes = vec![0x6, 0x0, 0x0, 0x6, 0x0, 0x0, 0x9, 0x0, 0x0];
            bytes.extend_from_slice(&[emptu_string.len() as u8, 0, 0]);
            bytes.extend_from_slice(emptu_string.as_bytes());

            let deserializer = IsarDeserializer::from_bytes(&bytes);

            let deserialized_value = deserializer.read_string(0).unwrap();
            assert_eq!(deserialized_value, emptu_string);
        }
    }
    mod multiple_identical_data_types {
        use super::*;

        #[test]
        fn test_read_multiple_bool() {
            let bytes = [0x3, 0x0, 0x0, 0x0, 0x1, 0x2];
            let deserializer = IsarDeserializer::from_bytes(&bytes);
            assert_eq!(deserializer.read_bool(0), None);
            assert_eq!(deserializer.read_bool(1), Some(false));
            assert_eq!(deserializer.read_bool(2), Some(true));

            let bytes = [0x6, 0x0, 0x0, 0x1, 0x1, 0x0, 0x2, 0x2, 0x1];
            let deserializer = IsarDeserializer::from_bytes(&bytes);
            assert_eq!(deserializer.read_bool(0), Some(false));
            assert_eq!(deserializer.read_bool(1), Some(false));
            assert_eq!(deserializer.read_bool(2), None);
            assert_eq!(deserializer.read_bool(3), Some(true));
            assert_eq!(deserializer.read_bool(4), Some(true));
            assert_eq!(deserializer.read_bool(5), Some(false));
        }
        #[test]
        fn test_read_multiple_byte() {
            let bytes = [0x3, 0x0, 0x0, 0x0, 0xa, 0x2a];
            let deserializer = IsarDeserializer::from_bytes(&bytes);
            assert_eq!(deserializer.read_byte(0), 0);
            assert_eq!(deserializer.read_byte(1), 10);
            assert_eq!(deserializer.read_byte(2), 42);

            let bytes = [0x5, 0x0, 0x0, 0x0, 0xa, 0x2a, 0xfe, 0xff];
            let deserializer = IsarDeserializer::from_bytes(&bytes);
            assert_eq!(deserializer.read_byte(0), 0);
            assert_eq!(deserializer.read_byte(1), 10);
            assert_eq!(deserializer.read_byte(2), 42);
            assert_eq!(deserializer.read_byte(3), 254);
            assert_eq!(deserializer.read_byte(4), 255);
        }
        #[test]
        fn test_read_multiple_int() {
            let bytes = [0xc, 0x0, 0x0]
                .iter()
                .chain(&0i32.to_le_bytes())
                .chain(&(-20i32).to_le_bytes())
                .chain(&42i32.to_le_bytes())
                .cloned()
                .collect::<Vec<u8>>();
            let deserializer = IsarDeserializer::from_bytes(&bytes);
            assert_eq!(deserializer.read_int(0), 0);
            assert_eq!(deserializer.read_int(4), -20);
            assert_eq!(deserializer.read_int(8), 42);

            let bytes = [0x14, 0x0, 0x0]
                .iter()
                .chain(&i32::MIN.to_le_bytes())
                .chain(&(-1i32).to_le_bytes())
                .chain(&100i32.to_le_bytes())
                .chain(&(i32::MAX - 1).to_le_bytes())
                .chain(&i32::MAX.to_le_bytes())
                .cloned()
                .collect::<Vec<u8>>();
            let deserializer = IsarDeserializer::from_bytes(&bytes);
            assert_eq!(deserializer.read_int(0), i32::MIN);
            assert_eq!(deserializer.read_int(4), -1);
            assert_eq!(deserializer.read_int(8), 100);
            assert_eq!(deserializer.read_int(12), i32::MAX - 1);
            assert_eq!(deserializer.read_int(16), i32::MAX);
        }
        #[test]
        fn test_read_multiple_float() {
            let values = [f32::MIN, f32::MIN.next_up(), -1f32, 100.49, f32::MAX];
            let mut bytes = vec![0x14, 0x0, 0x0];
            for &value in &values {
                bytes.extend_from_slice(&value.to_le_bytes());
            }

            let deserializer = IsarDeserializer::from_bytes(&bytes);

            for (i, &value) in values.iter().enumerate() {
                let offset = (i * 4) as u32;
                let deserialized_value = deserializer.read_float(offset);
                assert!(
                    deserialized_value.is_nan() && value.is_nan() || deserialized_value == value
                );
            }
        }
        #[test]
        fn test_read_multiple_long() {
            let values = [i64::MIN, i64::MIN + 1, -1i64, 100, i64::MAX];
            let mut bytes = vec![0x28, 0x0, 0x0];
            for &value in &values {
                bytes.extend_from_slice(&value.to_le_bytes());
            }

            let deserializer = IsarDeserializer::from_bytes(&bytes);

            for (i, &value) in values.iter().enumerate() {
                let offset = (i * 8) as u32;
                let deserialized_value = deserializer.read_long(offset);
                assert_eq!(deserialized_value, value);
            }
        }
        #[test]
        fn test_read_multiple_double() {
            let values = [f64::MIN, f64::MIN.next_up(), -1.0, 100.49, f64::MAX];
            let mut bytes = vec![0x28, 0x0, 0x0];
            for &value in &values {
                bytes.extend_from_slice(&value.to_le_bytes());
            }

            let deserializer = IsarDeserializer::from_bytes(&bytes);

            for (i, &value) in values.iter().enumerate() {
                let offset = (i * 8) as u32;
                let deserialized_value = deserializer.read_double(offset);
                assert_eq!(deserialized_value, value);
            }
        }
        #[test]
        fn test_read_multiple_dynamic() {
            let values = ["foo".as_bytes(), "bar".as_bytes()];
            let mut bytes = vec![0x6, 0x0, 0x0, 0x6, 0x0, 0x0, 0xc, 0x0, 0x0];
            for &value in &values {
                bytes.extend_from_slice(&[value.len() as u8, 0, 0]);
                bytes.extend_from_slice(value);
            }

            let deserializer = IsarDeserializer::from_bytes(&bytes);

            for (i, &expected) in values.iter().enumerate() {
                let offset = (i * 3) as u32;
                let deserialized_value = deserializer.read_dynamic(offset).unwrap();
                assert_eq!(deserialized_value, expected);
            }

            let chunks = [(0, 100), (100, 200), (200, 300), (300, LOREM.len())];
            let values: Vec<&[u8]> = chunks
                .iter()
                .map(|&(start, end)| LOREM[start..end].as_bytes())
                .collect();

            let mut bytes = vec![
                0xc, 0x0, 0x0, 0xc, 0x0, 0x0, 0x73, 0x0, 0x0, 0xda, 0x0, 0x0, 0x41, 0x1, 0x0,
            ];
            for &value in &values {
                bytes.extend_from_slice(&[
                    (value.len() & 0xff) as u8,
                    ((value.len() >> 8) & 0xff) as u8,
                    ((value.len() >> 16) & 0xff) as u8,
                ]);
                bytes.extend_from_slice(value);
            }

            let deserializer = IsarDeserializer::from_bytes(&bytes);
            for (i, &expected) in values.iter().enumerate() {
                let offset = (i * 3) as u32;
                let deserialized_value = deserializer.read_dynamic(offset).unwrap();
                assert_eq!(deserialized_value, expected);
            }

            let values: Vec<&[u8]> = vec![&[], &[]];

            let mut bytes = vec![0x6, 0x0, 0x0, 0x6, 0x0, 0x0, 0x9, 0x0, 0x0];
            for &value in &values {
                bytes.extend_from_slice(&[value.len() as u8, 0, 0]);
                bytes.extend_from_slice(value);
            }

            let deserializer = IsarDeserializer::from_bytes(&bytes);
            for (i, &expected) in values.iter().enumerate() {
                let offset = (i * 3) as u32;
                let deserialized_value = deserializer.read_dynamic(offset).unwrap();
                assert_eq!(deserialized_value, expected);
            }

            let values: Vec<&[u8]> = vec![&[0x1; 10], &[0x2; 20], &[0x3; 30]];

            let mut bytes = vec![0x9, 0x0, 0x0, 0x9, 0x0, 0x0, 0x16, 0x0, 0x0, 0x2d, 0x0, 0x0];
            for &value in &values {
                bytes.extend_from_slice(&[value.len() as u8, 0, 0]);
                bytes.extend_from_slice(value);
            }

            let deserializer = IsarDeserializer::from_bytes(&bytes);
            for (i, &expected) in values.iter().enumerate() {
                let offset = (i * 3) as u32;
                let deserialized_value = deserializer.read_dynamic(offset).unwrap();
                assert_eq!(deserialized_value, expected);
            }
        }
        #[test]
        fn test_read_multiple_string() {
            let values = ["foo", "bar"];

            let mut bytes = vec![0x6, 0x0, 0x0, 0x6, 0x0, 0x0, 0xc, 0x0, 0x0];

            for &value in &values {
                bytes.extend_from_slice(&[value.len() as u8, 0, 0]);
                bytes.extend_from_slice(value.as_bytes());
            }

            let deserializer = IsarDeserializer::from_bytes(&bytes);

            for (i, &expected) in values.iter().enumerate() {
                let offset = (i * 3) as u32;
                let deserialized_value = deserializer.read_string(offset).unwrap();
                assert_eq!(deserialized_value, expected);
            }

            let values = ["", ""];
            let mut bytes = vec![0x6, 0x0, 0x0, 0x6, 0x0, 0x0, 0x9, 0x0, 0x0];
            for &value in &values {
                bytes.extend_from_slice(&[value.len() as u8, 0, 0]);
                bytes.extend_from_slice(value.as_bytes());
            }

            let deserializer = IsarDeserializer::from_bytes(&bytes);

            for (i, &expected) in values.iter().enumerate() {
                let offset = (i * 3) as u32;
                let deserialized_value = deserializer.read_string(offset).unwrap();
                assert_eq!(deserialized_value, expected);
            }
        }
    }

    mod nested {
        use super::*;

        #[test]
        fn test_read_nested() {
            let null_int = NULL_INT;
            let bytes: &[u8] = &[
                0x3,
                0x0,
                0x0,
                0x3,
                0x0,
                0x0,
                0xe,
                0x0,
                0x0,
                // Null Int: 0
                null_int.to_le_bytes()[0],
                null_int.to_le_bytes()[1],
                null_int.to_le_bytes()[2],
                null_int.to_le_bytes()[3],
                // Int: 128
                128i32.to_le_bytes()[0],
                128i32.to_le_bytes()[1],
                128i32.to_le_bytes()[2],
                128i32.to_le_bytes()[3],
                // Float: 9.56789
                9.56789f32.to_le_bytes()[0],
                9.56789f32.to_le_bytes()[1],
                9.56789f32.to_le_bytes()[2],
                9.56789f32.to_le_bytes()[3],
                // Byte: 8
                0x08,
                // Byte: 250
                0xfa,
            ];

            let deserializer = IsarDeserializer::from_bytes(bytes);
            let nested_deserializer = deserializer.read_nested(0).unwrap();

            assert_eq!(nested_deserializer.read_int(0), NULL_INT);
            assert_eq!(nested_deserializer.read_int(4), 128);
            assert!((nested_deserializer.read_float(8) - 9.56789).abs() < f32::EPSILON);
            assert_eq!(nested_deserializer.read_byte(12), 8);
            assert_eq!(nested_deserializer.read_byte(13), 250);

            let null_int = NULL_INT;
            let max_int = i32::MAX;
            let bytes: &[u8] = &[
                0xe,
                0x0,
                0x0,
                // Int: 32
                32i32.to_le_bytes()[0],
                32i32.to_le_bytes()[1],
                32i32.to_le_bytes()[2],
                32i32.to_le_bytes()[3],
                // Nested start
                0xe,
                0x0,
                0x0,
                // Int: MAX
                max_int.to_le_bytes()[0],
                max_int.to_le_bytes()[1],
                max_int.to_le_bytes()[2],
                max_int.to_le_bytes()[3],
                // Nested length
                0x25,
                0x0,
                0x0,
                // Nested: First nested
                0x14,
                0x0,
                0x0,
                // Double: 123456789.98765433
                123_456_789.987_654_33_f64.to_le_bytes()[0],
                123_456_789.987_654_33_f64.to_le_bytes()[1],
                123_456_789.987_654_33_f64.to_le_bytes()[2],
                123_456_789.987_654_33_f64.to_le_bytes()[3],
                123_456_789.987_654_33_f64.to_le_bytes()[4],
                123_456_789.987_654_33_f64.to_le_bytes()[5],
                123_456_789.987_654_33_f64.to_le_bytes()[6],
                123_456_789.987_654_33_f64.to_le_bytes()[7],
                // Null Int: 0
                null_int.to_le_bytes()[0],
                null_int.to_le_bytes()[1],
                null_int.to_le_bytes()[2],
                null_int.to_le_bytes()[3],
                // Long: 1024
                1024i64.to_le_bytes()[0],
                1024i64.to_le_bytes()[1],
                1024i64.to_le_bytes()[2],
                1024i64.to_le_bytes()[3],
                1024i64.to_le_bytes()[4],
                1024i64.to_le_bytes()[5],
                1024i64.to_le_bytes()[6],
                1024i64.to_le_bytes()[7],
                // Nested: Second nested
                0xc,
                0x0,
                0x0,
                // Bool: true
                0x2,
                // Bool: true
                0x2,
                // Bool: false
                0x1,
                // Bool: true
                0x2,
                // Long: -500
                (-500i64).to_le_bytes()[0],
                (-500i64).to_le_bytes()[1],
                (-500i64).to_le_bytes()[2],
                (-500i64).to_le_bytes()[3],
                (-500i64).to_le_bytes()[4],
                (-500i64).to_le_bytes()[5],
                (-500i64).to_le_bytes()[6],
                (-500i64).to_le_bytes()[7],
            ];

            let deserializer = IsarDeserializer::from_bytes(bytes);

            assert_eq!(deserializer.read_int(0), 32);

            let first_nested_deserializer = deserializer.read_nested(4).unwrap();

            assert_eq!(
                first_nested_deserializer.read_double(0),
                123_456_789.987_654_33_f64
            );

            assert_eq!(first_nested_deserializer.read_int(8), NULL_INT);

            assert_eq!(first_nested_deserializer.read_long(12), 1024);

            let second_nested_deserializer = deserializer.read_nested(11).unwrap();

            assert_eq!(second_nested_deserializer.read_bool(0).unwrap(), true);
            assert_eq!(second_nested_deserializer.read_bool(1).unwrap(), true);
            assert_eq!(second_nested_deserializer.read_bool(2).unwrap(), false);
            assert_eq!(second_nested_deserializer.read_bool(3).unwrap(), true);

            assert_eq!(second_nested_deserializer.read_long(4), -500);
        }

        #[test]
        fn test_deeply_nested() {
            let bytes: &[u8] = &[
                0x15,
                0x0,
                0x0,
                0x20,
                0x0,
                0x0,
                0x0,
                // First nested
                0x15,
                0x0,
                0x0,
                // Second nested
                0x20,
                0x0,
                0x0,
                0x8,
                0x0,
                0x0,
                0x0,
                // First dynamic
                0x4b,
                0x0,
                0x0,
                // Second dynamic
                0x4e,
                0x0,
                0x0,
                0x14,
                // First nested
                0x8,
                0x0,
                0x0,
                1.1f64.to_le_bytes()[0],
                1.1f64.to_le_bytes()[1],
                1.1f64.to_le_bytes()[2],
                1.1f64.to_le_bytes()[3],
                1.1f64.to_le_bytes()[4],
                1.1f64.to_le_bytes()[5],
                1.1f64.to_le_bytes()[6],
                1.1f64.to_le_bytes()[7],
                // Second nested
                0xd,
                0x0,
                0x0,
                0x2,
                0x0,
                0xd,
                0x0,
                0x0,
                0x23,
                0x0,
                0x0,
                0x0,
                NULL_FLOAT.to_le_bytes()[0],
                NULL_FLOAT.to_le_bytes()[1],
                NULL_FLOAT.to_le_bytes()[2],
                NULL_FLOAT.to_le_bytes()[3],
                // Nested nested
                0x8,
                0x0,
                0x0,
                0x1,
                0x8,
                0x0,
                0x0,
                0x5,
                0x10,
                0x0,
                0x0,
                0x5,
                0x0,
                0x0,
                0x5,
                0x5,
                0x5,
                0x8,
                0x0,
                0x0,
                0x0,
                0x0,
                // Back to second nested
                0x2,
                0x0,
                0x0,
                0x1,
                0x8,
                0x0,
                0x0,
                0x0,
                0x6,
                0x0,
                0x0,
                0x0,
                0x0,
                0x1,
                0xff,
                0xff,
                0x0,
                0x8,
                0x0,
                0x0,
                0x0,
                0x0,
                0x0,
                0x0,
                0x0,
                0x0,
                0x0,
                0x0,
                0x0, // Null Float
                0x14,
            ];

            let deserializer = IsarDeserializer::from_bytes(bytes);

            assert_eq!(deserializer.read_int(0), 32);

            let first_nested_deserializer = deserializer.read_nested(4).unwrap();
            assert_eq!(first_nested_deserializer.read_double(0), 1.1);

            let second_nested_deserializer = deserializer.read_nested(7).unwrap();
            assert_eq!(second_nested_deserializer.read_bool(0).unwrap(), true);
            assert_eq!(second_nested_deserializer.read_bool(1), None);

            let nested_nested_deserializer = second_nested_deserializer.read_nested(2).unwrap();

            assert_eq!(nested_nested_deserializer.read_bool(0).unwrap(), false);
            assert_eq!(
                nested_nested_deserializer.read_dynamic(1).unwrap(),
                &[0x5, 0x5, 0x5, 0x8, 0x0]
            );
            assert_eq!(nested_nested_deserializer.read_byte(4), 5);
            assert_eq!(
                nested_nested_deserializer.read_dynamic(5).unwrap(),
                &[u8::default(); 0][..]
            );

            assert_eq!(
                second_nested_deserializer.read_dynamic(5).unwrap(),
                &[0x1, 0x8]
            );
            assert_eq!(second_nested_deserializer.read_bool(8), None);
            assert_eq!(second_nested_deserializer.read_bool(9), None);

            assert_eq!(deserializer.read_int(10), 8);
            assert_eq!(
                deserializer.read_dynamic(14).unwrap(),
                &[u8::default(); 0][..]
            );

            assert_eq!(
                deserializer.read_dynamic(17).unwrap(),
                &[0x0, 0x0, 0x1, 0xff, 0xff, 0x0]
            );
            assert_eq!(deserializer.read_byte(20), 20);
        }
    }
}
