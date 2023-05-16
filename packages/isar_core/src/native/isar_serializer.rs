use std::cell::Cell;

use byteorder::{ByteOrder, LittleEndian};

use crate::{core::data_type::DataType, native::bool_to_byte};

use super::{NULL_BOOL, NULL_BYTE, NULL_DOUBLE, NULL_FLOAT, NULL_INT, NULL_LONG};

pub struct IsarSerializer {
    buffer: Cell<Vec<u8>>,
    offset: u32,
    static_size: u32,
}

impl IsarSerializer {
    pub fn new(mut buffer: Vec<u8>, offset: u32, static_size: u32) -> Self {
        let min_buffer_size = (offset + static_size + 3) as usize;
        if min_buffer_size > buffer.len() {
            buffer.resize(min_buffer_size, 0);
        }
        LittleEndian::write_u24(&mut buffer[offset as usize..], static_size);
        Self {
            buffer: Cell::new(buffer),
            offset: offset + 3,
            static_size,
        }
    }

    #[inline]
    fn write(&mut self, offset: u32, bytes: &[u8]) {
        let offset = (offset + self.offset) as usize;
        self.buffer.get_mut()[offset..offset + bytes.len()].copy_from_slice(bytes);
    }

    #[inline]
    fn write_u24(&mut self, offset: u32, value: u32) {
        LittleEndian::write_u24(
            &mut self.buffer.get_mut()[(offset + self.offset) as usize..],
            value,
        );
    }

    #[inline]
    fn assert_static_size_offset(&self, offset: u32, len: u32) {
        assert!(
            offset + len <= self.static_size,
            "Tried to write {len} byte(s) at offset {offset} into static section of {} byte(s)",
            self.static_size
        );
    }

    #[inline]
    fn write_static_checked(&mut self, offset: u32, bytes: &[u8]) {
        self.assert_static_size_offset(offset, bytes.len() as u32);
        self.write(offset, bytes);
    }

    #[inline]
    fn write_u24_static_checked(&mut self, offset: u32, value: u32) {
        self.assert_static_size_offset(offset, 3);
        self.write_u24(offset, value);
    }

    #[inline]
    pub fn write_null(&mut self, offset: u32, data_type: DataType) {
        match data_type {
            DataType::Bool => self.write_byte(offset, NULL_BOOL),
            DataType::Byte => self.write_byte(offset, NULL_BYTE),
            DataType::Int => self.write_int(offset, NULL_INT),
            DataType::Float => self.write_float(offset, NULL_FLOAT),
            DataType::Long => self.write_long(offset, NULL_LONG),
            DataType::Double => self.write_double(offset, NULL_DOUBLE),
            _ => self.write_u24_static_checked(offset, 0),
        }
    }

    #[inline]
    pub fn write_bool(&mut self, offset: u32, value: Option<bool>) {
        self.write_static_checked(offset, &[bool_to_byte(value)]);
    }

    #[inline]
    pub fn write_byte(&mut self, offset: u32, value: u8) {
        self.write_static_checked(offset, &[value]);
    }

    #[inline]
    pub fn write_int(&mut self, offset: u32, value: i32) {
        self.write_static_checked(offset, &value.to_le_bytes());
    }

    #[inline]
    pub fn write_float(&mut self, offset: u32, value: f32) {
        self.write_static_checked(offset, &value.to_le_bytes());
    }

    #[inline]
    pub fn write_long(&mut self, offset: u32, value: i64) {
        self.write_static_checked(offset, &value.to_le_bytes());
    }

    #[inline]
    pub fn write_double(&mut self, offset: u32, value: f64) {
        self.write_static_checked(offset, &value.to_le_bytes());
    }

    #[inline]
    pub fn write_dynamic(&mut self, offset: u32, value: &[u8]) {
        let buffer_len = self.buffer.get_mut().len() as u32;
        let dynamic_offset = buffer_len - self.offset;
        self.write_u24_static_checked(offset, dynamic_offset);

        self.buffer
            .get_mut()
            .resize(buffer_len as usize + value.len() + 3, 0);
        self.write_u24(dynamic_offset, value.len() as u32);
        self.write(dynamic_offset + 3, value);
    }

    pub fn begin_nested(&mut self, offset: u32, static_size: u32) -> Self {
        let nested_offset = self.buffer.get_mut().len() as u32;
        self.write_u24_static_checked(offset, nested_offset - self.offset);
        Self::new(self.buffer.take(), nested_offset, static_size)
    }

    pub fn end_nested(&mut self, writer: Self) {
        self.buffer.replace(writer.buffer.take());
    }

    pub fn finish(&self) -> Vec<u8> {
        self.buffer.take()
    }
}

#[cfg(test)]
mod tests {
    use crate::core::data_type::DataType;

    use super::super::*;
    use super::IsarSerializer;

    static LOREM: &str = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?";

    macro_rules! concat {
        ($($iter:expr),*) => {
            {
                let mut v = Vec::new();
                $(
                    for item in $iter {
                        v.push(item);
                    }
                )*
                v
            }
        }
    }

    mod single_data_type {
        use super::*;

        #[test]
        fn test_write_single_null_bool() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 1);
            serializer.write_null(0, DataType::Bool);
            assert_eq!(serializer.finish(), vec![0x1, 0x0, 0x0, 0x0]);
        }

        #[test]
        fn test_write_single_null_byte() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 1);
            serializer.write_null(0, DataType::Byte);
            assert_eq!(serializer.finish(), vec![0x1, 0x0, 0x0, 0x0]);
        }

        #[test]
        fn test_write_single_null_int() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 4);
            serializer.write_null(0, DataType::Int);
            assert_eq!(
                serializer.finish(),
                concat!([0x4, 0x0, 0x0], NULL_INT.to_le_bytes())
            );
        }

        #[test]
        fn test_write_single_null_float() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 4);
            serializer.write_null(0, DataType::Float);
            assert_eq!(
                serializer.finish(),
                concat!([0x4, 0x0, 0x0], NULL_FLOAT.to_le_bytes())
            );
        }

        #[test]
        fn test_write_single_null_long() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 8);
            serializer.write_null(0, DataType::Long);
            assert_eq!(
                serializer.finish(),
                concat!([0x8, 0x0, 0x0], NULL_LONG.to_le_bytes())
            );
        }

        #[test]
        fn test_write_single_null_double() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 8);
            serializer.write_null(0, DataType::Double);
            assert_eq!(
                serializer.finish(),
                concat!([0x8, 0x0, 0x0], NULL_DOUBLE.to_le_bytes())
            );
        }

        #[test]
        fn test_write_single_null_dynamic() {
            for dynamic_data_type in [
                DataType::String,
                DataType::Object,
                DataType::Json,
                DataType::BoolList,
                DataType::ByteList,
                DataType::IntList,
                DataType::FloatList,
                DataType::LongList,
                DataType::DoubleList,
                DataType::StringList,
                DataType::ObjectList,
            ] {
                let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
                serializer.write_null(0, dynamic_data_type);
                assert_eq!(
                    serializer.finish(),
                    concat!([0x3, 0x0, 0x0], [0x0, 0x0, 0x0])
                );
            }
        }

        #[test]
        fn test_write_single_bool() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 1);
            serializer.write_bool(0, None);
            assert_eq!(serializer.finish(), concat!([0x1, 0x0, 0x0], [0x0]));

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 1);
            serializer.write_bool(0, Some(false));
            assert_eq!(serializer.finish(), concat!([0x1, 0x0, 0x0], [0x1]));

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 1);
            serializer.write_bool(0, Some(true));
            assert_eq!(serializer.finish(), concat!([0x1, 0x0, 0x0], [0x2]));
        }

        #[test]
        fn test_write_single_byte() {
            for value in [0, 1, 42, 254, 255] {
                let mut serializer = IsarSerializer::new(Vec::new(), 0, 1);
                serializer.write_byte(0, value);
                assert_eq!(
                    serializer.finish(),
                    concat!([0x1, 0x0, 0x0], value.to_le_bytes())
                );
            }
        }

        #[test]
        fn test_write_single_int() {
            for value in [0, 1, i32::MIN, i32::MAX, i32::MAX - 1] {
                let mut serializer = IsarSerializer::new(Vec::new(), 0, 4);
                serializer.write_int(0, value);
                assert_eq!(
                    serializer.finish(),
                    concat!([0x4, 0x0, 0x0], value.to_le_bytes())
                );
            }
        }

        #[test]
        fn test_write_single_float() {
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
                let mut serializer = IsarSerializer::new(Vec::new(), 0, 4);
                serializer.write_float(0, value);
                assert_eq!(
                    serializer.finish(),
                    concat!([0x4, 0x0, 0x0], value.to_le_bytes())
                );
            }
        }

        #[test]
        fn test_write_single_long() {
            for value in [0, -1, 1, i64::MIN, i64::MIN + 1, i64::MAX, i64::MAX - 1] {
                let mut serializer = IsarSerializer::new(Vec::new(), 0, 8);
                serializer.write_long(0, value);
                assert_eq!(
                    serializer.finish(),
                    concat!([0x8, 0x0, 0x0], value.to_le_bytes())
                );
            }
        }

        #[test]
        fn test_write_single_double() {
            for value in [
                0f64,
                -1f64,
                1f64,
                f64::MIN,
                f64::MIN.next_up(),
                f64::MAX,
                f64::MAX.next_down(),
            ] {
                let mut serializer = IsarSerializer::new(Vec::new(), 0, 8);
                serializer.write_double(0, value);
                assert_eq!(
                    serializer.finish(),
                    concat!([0x8, 0x0, 0x0], value.to_le_bytes())
                );
            }
        }

        #[test]
        fn test_write_single_dynamic() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, "foo".as_bytes());
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x3, 0x0, 0x0],
                    [0x3, 0x0, 0x0],
                    [0x3, 0x0, 0x0, b'f', b'o', b'o']
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, "".as_bytes());
            assert_eq!(
                serializer.finish(),
                concat!([0x3, 0x0, 0x0], [0x3, 0x0, 0x0], [0x0, 0x0, 0x0])
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, LOREM.as_bytes());
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x3, 0x0, 0x0],
                    [0x3, 0x0, 0x0],
                    LOREM.len().to_le_bytes()[0..3].iter().copied(),
                    LOREM.as_bytes().iter().copied()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9]);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x3, 0x0, 0x0],
                    [0x3, 0x0, 0x0],
                    [0x9, 0x0, 0x0],
                    [0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9]
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &vec![0x0; 2000]);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x3, 0x0, 0x0],
                    [0x3, 0x0, 0x0],
                    2000u32.to_le_bytes()[0..3].iter().copied(),
                    vec![0x0; 2000]
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            let bytes = vec![0x5; 0xffffff];
            serializer.write_dynamic(0, &bytes);

            let finished = serializer.finish();
            let expected = concat!([0x3, 0x0, 0x0], [0x3, 0x0, 0x0], [0xff, 0xff, 0xff], bytes);

            assert_eq!(finished.len(), expected.len());
            assert!(finished.iter().zip(expected.iter()).all(|(a, b)| a == b));
        }
    }

    mod multiple_identical_data_types {
        use std::vec;

        use super::*;

        #[test]
        fn test_write_multiple_null_bool() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 2);
            serializer.write_null(0, DataType::Bool);
            serializer.write_null(1, DataType::Bool);
            assert_eq!(serializer.finish(), vec![0x2, 0x0, 0x0, 0x0, 0x0]);

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 10);
            for offset in 0..10 {
                serializer.write_null(offset, DataType::Bool);
            }
            assert_eq!(serializer.finish(), concat!([0xa, 0x0, 0x0], [0x0; 10]));
        }

        #[test]
        fn test_write_multiple_null_byte() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 2);
            serializer.write_null(0, DataType::Byte);
            serializer.write_null(1, DataType::Byte);
            assert_eq!(serializer.finish(), vec![0x2, 0x0, 0x0, 0x0, 0x0]);

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 10);
            for offset in 0..10 {
                serializer.write_null(offset, DataType::Byte);
            }
            assert_eq!(serializer.finish(), concat!([0xa, 0x0, 0x0], [0x0; 10]));
        }

        #[test]
        fn test_write_multiple_null_int() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 8);
            serializer.write_null(0, DataType::Int);
            serializer.write_null(4, DataType::Int);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x8, 0x0, 0x0],
                    NULL_INT.to_le_bytes(),
                    NULL_INT.to_le_bytes()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 40);
            for offset in 0..10 {
                serializer.write_null(offset * 4, DataType::Int);
            }
            assert_eq!(
                serializer.finish(),
                concat!(
                    [4 * 10, 0x0, 0x0],
                    NULL_INT.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    NULL_INT.to_le_bytes()
                )
            );
        }

        #[test]
        fn test_write_multiple_null_float() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 8);
            serializer.write_null(0, DataType::Float);
            serializer.write_null(4, DataType::Float);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x8, 0x0, 0x0],
                    NULL_FLOAT.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 40);
            for offset in 0..10 {
                serializer.write_null(offset * 4, DataType::Float);
            }
            assert_eq!(
                serializer.finish(),
                concat!(
                    [4 * 10, 0x0, 0x0],
                    NULL_FLOAT.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes()
                )
            );
        }

        #[test]
        fn test_write_multiple_null_long() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 16);
            serializer.write_null(0, DataType::Long);
            serializer.write_null(8, DataType::Long);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x10, 0x0, 0x0],
                    NULL_LONG.to_le_bytes(),
                    NULL_LONG.to_le_bytes()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 80);
            for offset in 0..10 {
                serializer.write_null(offset * 8, DataType::Long);
            }
            assert_eq!(
                serializer.finish(),
                concat!(
                    [8 * 10, 0x0, 0x0],
                    NULL_LONG.to_le_bytes(),
                    NULL_LONG.to_le_bytes(),
                    NULL_LONG.to_le_bytes(),
                    NULL_LONG.to_le_bytes(),
                    NULL_LONG.to_le_bytes(),
                    NULL_LONG.to_le_bytes(),
                    NULL_LONG.to_le_bytes(),
                    NULL_LONG.to_le_bytes(),
                    NULL_LONG.to_le_bytes(),
                    NULL_LONG.to_le_bytes()
                )
            );
        }

        #[test]
        fn test_write_multiple_null_double() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 16);
            serializer.write_null(0, DataType::Double);
            serializer.write_null(8, DataType::Double);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x10, 0x0, 0x0],
                    NULL_DOUBLE.to_le_bytes(),
                    NULL_DOUBLE.to_le_bytes()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 80);
            for offset in 0..10 {
                serializer.write_null(offset * 8, DataType::Double);
            }
            assert_eq!(
                serializer.finish(),
                concat!(
                    [8 * 10, 0x0, 0x0],
                    NULL_DOUBLE.to_le_bytes(),
                    NULL_DOUBLE.to_le_bytes(),
                    NULL_DOUBLE.to_le_bytes(),
                    NULL_DOUBLE.to_le_bytes(),
                    NULL_DOUBLE.to_le_bytes(),
                    NULL_DOUBLE.to_le_bytes(),
                    NULL_DOUBLE.to_le_bytes(),
                    NULL_DOUBLE.to_le_bytes(),
                    NULL_DOUBLE.to_le_bytes(),
                    NULL_DOUBLE.to_le_bytes()
                )
            );
        }

        #[test]
        fn test_write_multiple_null_dynamic() {
            for dynamic_data_type in [
                DataType::String,
                DataType::Object,
                DataType::Json,
                DataType::BoolList,
                DataType::ByteList,
                DataType::IntList,
                DataType::FloatList,
                DataType::LongList,
                DataType::DoubleList,
                DataType::StringList,
                DataType::ObjectList,
            ] {
                for count in [2, 10, 100] {
                    let mut serializer = IsarSerializer::new(Vec::new(), 0, count * 3);
                    let mut expected = (count * 3).to_le_bytes()[..3].to_vec();

                    for i in 0..count {
                        serializer.write_null(i, dynamic_data_type);
                        expected.extend(vec![0x0; 3]);
                    }

                    assert_eq!(serializer.finish(), expected);
                }
            }
        }

        #[test]
        fn test_write_multiple_bool() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_bool(0, None);
            serializer.write_bool(1, Some(false));
            serializer.write_bool(2, Some(true));
            assert_eq!(
                serializer.finish(),
                concat!([0x3, 0x0, 0x0], [0x0, 0x1, 0x2])
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_bool(0, Some(false));
            serializer.write_bool(1, Some(false));
            serializer.write_bool(2, None);
            serializer.write_bool(3, Some(true));
            serializer.write_bool(4, Some(true));
            serializer.write_bool(5, Some(false));
            assert_eq!(
                serializer.finish(),
                concat!([0x6, 0x0, 0x0], [0x1, 0x1, 0x0, 0x2, 0x2, 0x1])
            );
        }

        #[test]
        fn test_write_multiple_byte() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_byte(0, 0);
            serializer.write_byte(1, 10);
            serializer.write_byte(2, 42);
            assert_eq!(
                serializer.finish(),
                concat!([0x3, 0x0, 0x0], [0x0, 0xa, 0x2a])
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 5);
            serializer.write_byte(0, 0);
            serializer.write_byte(1, 10);
            serializer.write_byte(2, 42);
            serializer.write_byte(3, 254);
            serializer.write_byte(4, 255);
            assert_eq!(
                serializer.finish(),
                concat!([0x5, 0x0, 0x0], [0, 0xa, 0x2a, 0xfe, 0xff])
            );
        }

        #[test]
        fn test_write_multiple_int() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 12);
            serializer.write_int(0, 0);
            serializer.write_int(4, -20);
            serializer.write_int(8, 42);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0xc, 0x0, 0x0],
                    0i32.to_le_bytes(),
                    (-20i32).to_le_bytes(),
                    42i32.to_le_bytes()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 20);
            serializer.write_int(0, i32::MIN);
            serializer.write_int(4, -1);
            serializer.write_int(8, 100);
            serializer.write_int(12, i32::MAX - 1);
            serializer.write_int(16, i32::MAX);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x14, 0x0, 0x0],
                    i32::MIN.to_le_bytes(),
                    (-1i32).to_le_bytes(),
                    100i32.to_le_bytes(),
                    (i32::MAX - 1).to_le_bytes(),
                    i32::MAX.to_le_bytes()
                )
            );
        }

        #[test]
        fn test_write_multiple_float() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 12);
            serializer.write_float(0, 0f32);
            serializer.write_float(4, -20f32);
            serializer.write_float(8, 42f32);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0xc, 0x0, 0x0],
                    0f32.to_le_bytes(),
                    (-20f32).to_le_bytes(),
                    42f32.to_le_bytes()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 20);
            serializer.write_float(0, f32::MIN);
            serializer.write_float(4, f32::MIN.next_up());
            serializer.write_float(8, -1f32);
            serializer.write_float(12, 100.49);
            serializer.write_float(16, f32::MAX);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x14, 0x0, 0x0],
                    f32::MIN.to_le_bytes(),
                    f32::MIN.next_up().to_le_bytes(),
                    (-1f32).to_le_bytes(),
                    100.49f32.to_le_bytes(),
                    f32::MAX.to_le_bytes()
                )
            );
        }

        #[test]
        fn test_write_multiple_long() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 24);
            serializer.write_long(0, 0);
            serializer.write_long(8, -20);
            serializer.write_long(16, 42);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x18, 0x0, 0x0],
                    0i64.to_le_bytes(),
                    (-20i64).to_le_bytes(),
                    42i64.to_le_bytes()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 40);
            serializer.write_long(0, i64::MIN);
            serializer.write_long(8, i64::MIN + 1);
            serializer.write_long(16, -1);
            serializer.write_long(24, 100);
            serializer.write_long(32, i64::MAX);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x28, 0x0, 0x0],
                    i64::MIN.to_le_bytes(),
                    (i64::MIN + 1).to_le_bytes(),
                    (-1i64).to_le_bytes(),
                    100i64.to_le_bytes(),
                    i64::MAX.to_le_bytes()
                )
            );
        }

        #[test]
        fn test_write_multiple_double() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 24);
            serializer.write_double(0, 0.0);
            serializer.write_double(8, -20.0);
            serializer.write_double(16, 42.0);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x18, 0x0, 0x0],
                    0f64.to_le_bytes(),
                    (-20f64).to_le_bytes(),
                    42f64.to_le_bytes()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 40);
            serializer.write_double(0, f64::MIN);
            serializer.write_double(8, f64::MIN.next_up());
            serializer.write_double(16, -1.0);
            serializer.write_double(24, 100.49);
            serializer.write_double(32, f64::MAX);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x28, 0x0, 0x0],
                    f64::MIN.to_le_bytes(),
                    f64::MIN.next_up().to_le_bytes(),
                    (-1.0f64).to_le_bytes(),
                    100.49f64.to_le_bytes(),
                    f64::MAX.to_le_bytes()
                )
            );
        }

        #[test]
        fn test_write_multiple_dynamic() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, "foo".as_bytes());
            serializer.write_dynamic(3, "bar".as_bytes());
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x6, 0x0, 0x0],
                    [0x6, 0x0, 0x0],
                    [0xc, 0x0, 0x0],
                    [0x3, 0x0, 0x0, b'f', b'o', b'o'],
                    [0x3, 0x0, 0x0, b'b', b'a', b'r']
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[]);
            serializer.write_dynamic(3, &[]);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x6, 0x0, 0x0],
                    [0x6, 0x0, 0x0],
                    [0x9, 0x0, 0x0],
                    [0x0, 0x0, 0x0],
                    [0x0, 0x0, 0x0]
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 12);
            serializer.write_dynamic(0, LOREM[..100].as_bytes());
            serializer.write_dynamic(3, LOREM[100..200].as_bytes());
            serializer.write_dynamic(6, LOREM[200..300].as_bytes());
            serializer.write_dynamic(9, LOREM[300..].as_bytes());
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0xc, 0x0, 0x0],
                    [0xc, 0x0, 0x0],
                    [0x73, 0x0, 0x0],
                    [0xda, 0x0, 0x0],
                    [0x41, 0x1, 0x0],
                    [0x64, 0x0, 0x0],
                    LOREM[..100].as_bytes().iter().copied(),
                    [0x64, 0x0, 0x0],
                    LOREM[100..200].as_bytes().iter().copied(),
                    [0x64, 0x0, 0x0],
                    LOREM[200..300].as_bytes().iter().copied(),
                    [
                        ((LOREM.len() - 300) & 0xff) as u8,
                        (((LOREM.len() - 300) >> 8) & 0xff) as u8,
                        (((LOREM.len() - 300) >> 16) & 0xff) as u8
                    ],
                    LOREM[300..].as_bytes().iter().copied()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 15);
            serializer.write_dynamic(0, &[0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9]);
            serializer.write_dynamic(3, &[0x0, 0x2, 0x4]);
            serializer.write_dynamic(6, &[0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7]);
            serializer.write_dynamic(
                9,
                &[
                    0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0x8, 0x7, 0x6, 0x5, 0x4, 0x3, 0x2,
                    0x1,
                ],
            );
            serializer.write_dynamic(12, &[0x0, 0xff, 0xff, 0xff, 0x42]);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0xf, 0x0, 0x0],
                    [0xf, 0x0, 0x0],
                    [0x1b, 0x0, 0x0],
                    [0x21, 0x0, 0x0],
                    [0x2b, 0x0, 0x0],
                    [0x3f, 0x0, 0x0],
                    [0x9, 0x0, 0x0],
                    [0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9],
                    [0x3, 0x0, 0x0],
                    [0x0, 0x2, 0x4],
                    [0x7, 0x0, 0x0],
                    [0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7],
                    [0x11, 0x0, 0x0],
                    [
                        0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0x8, 0x7, 0x6, 0x5, 0x4, 0x3,
                        0x2, 0x1,
                    ],
                    [0x5, 0x0, 0x0],
                    [0x0, 0xff, 0xff, 0xff, 0x42]
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 9);
            serializer.write_dynamic(0, &[0x1; 10]);
            serializer.write_dynamic(3, &[0x2; 20]);
            serializer.write_dynamic(6, &[0x3; 30]);

            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x9, 0x0, 0x0],
                    [0x9, 0x0, 0x0],
                    [0x16, 0x0, 0x0],
                    [0x02d, 0x0, 0x0],
                    [0xa, 0x0, 0x0],
                    [0x1; 10],
                    [0x14, 0x0, 0x0],
                    [0x2; 20],
                    [0x1e, 0x0, 0x0],
                    [0x3; 30]
                )
            );
        }
    }

    mod multiple_properties {
        use super::*;

        #[test]
        fn test_write_null() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 8);
            serializer.write_null(0, DataType::Bool);
            serializer.write_null(1, DataType::Int);
            serializer.write_null(5, DataType::String);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x8, 0x0, 0x0],
                    NULL_BOOL.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    [0x0, 0x0, 0x0]
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 22);
            serializer.write_null(0, DataType::Bool);
            serializer.write_null(1, DataType::Int);
            serializer.write_null(5, DataType::Int);
            serializer.write_null(9, DataType::Float);
            serializer.write_null(13, DataType::Double);
            serializer.write_null(21, DataType::Bool);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x16, 0x0, 0x0],
                    NULL_BOOL.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes(),
                    NULL_DOUBLE.to_le_bytes(),
                    NULL_BOOL.to_le_bytes()
                )
            );
        }

        #[test]
        fn test_write_primitives() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 19);
            serializer.write_bool(0, Some(true));
            serializer.write_int(1, 123456);
            serializer.write_null(5, DataType::Bool);
            serializer.write_null(6, DataType::Float);
            serializer.write_double(10, 0.123456789);
            serializer.write_byte(18, 100);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x13, 0x0, 0x0],
                    [0x2],
                    123456i32.to_le_bytes(),
                    NULL_BOOL.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes(),
                    0.123456789f64.to_le_bytes(),
                    100u8.to_le_bytes()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 31);
            serializer.write_long(0, i64::MAX);
            serializer.write_long(8, i64::MIN);
            serializer.write_long(16, 0);
            serializer.write_null(24, DataType::Int);
            serializer.write_byte(28, 5);
            serializer.write_null(29, DataType::Byte);
            serializer.write_null(30, DataType::Byte);
            assert_eq!(
                serializer.finish(),
                concat![
                    [0x1f, 0x0, 0x0],
                    i64::MAX.to_le_bytes(),
                    i64::MIN.to_le_bytes(),
                    0i64.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    [0x5],
                    NULL_BYTE.to_le_bytes(),
                    NULL_BYTE.to_le_bytes()
                ]
            );
        }

        #[test]
        fn test_write_any_type() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 31);
            serializer.write_int(0, 65535);
            serializer.write_bool(4, Some(false));
            serializer.write_bool(5, Some(true));
            serializer.write_dynamic(6, "foo bar".as_bytes());
            serializer.write_int(9, -500);
            serializer.write_dynamic(13, &[0x1, 0x10, 0xff]);
            serializer.write_null(16, DataType::Double);
            serializer.write_null(24, DataType::Json);
            serializer.write_null(27, DataType::ByteList);
            serializer.write_byte(30, 42);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x1f, 0x0, 0x0],
                    65535i32.to_le_bytes(),
                    [0x1],
                    [0x2],
                    [0x1f, 0x0, 0x0],
                    (-500i32).to_le_bytes(),
                    [0x29, 0x0, 0x0],
                    NULL_DOUBLE.to_le_bytes(),
                    [0x0, 0x0, 0x0],
                    [0x0, 0x0, 0x0],
                    42u8.to_le_bytes(),
                    [0x7, 0x0, 0x0],
                    [b'f', b'o', b'o', b' ', b'b', b'a', b'r'],
                    [0x3, 0x0, 0x0],
                    [0x1, 0x10, 0xff]
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 21);
            serializer.write_dynamic(0, &[0x20, 0x10, 0x0, 0x0, 0x50, 0xff]);
            serializer.write_double(3, 5.25);
            serializer.write_dynamic(11, &[]);
            serializer.write_null(14, DataType::Json);
            serializer.write_null(17, DataType::Int);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x15, 0x0, 0x0],
                    [0x15, 0x0, 0x0],
                    5.25f64.to_le_bytes(),
                    [0x1e, 0x0, 0x0],
                    [0x0, 0x0, 0x0],
                    NULL_INT.to_le_bytes(),
                    [0x6, 0x0, 0x0],
                    [0x20, 0x10, 0x0, 0x0, 0x50, 0xff],
                    [0x0, 0x0, 0x0]
                )
            );
        }
    }

    mod nested {
        use super::*;

        #[test]
        fn test_nested_write_primitive() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            let mut nested_serializer = serializer.begin_nested(0, 14);
            nested_serializer.write_null(0, DataType::Int);
            nested_serializer.write_int(4, 128);
            nested_serializer.write_float(8, 9.56789);
            nested_serializer.write_byte(12, 8);
            nested_serializer.write_byte(13, 250);
            serializer.end_nested(nested_serializer);

            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x3, 0x0, 0x0],
                    [0x3, 0x0, 0x0],
                    [0xe, 0x0, 0x0],
                    NULL_INT.to_le_bytes(),
                    128i32.to_le_bytes(),
                    9.56789f32.to_le_bytes(),
                    [0x8],
                    [0xfa]
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 14);
            serializer.write_int(0, 32);

            let mut nested_serializer = serializer.begin_nested(4, 20);
            nested_serializer.write_double(0, 123_456_789.987_654_33);
            nested_serializer.write_null(8, DataType::Int);
            nested_serializer.write_long(12, 1024);
            serializer.end_nested(nested_serializer);

            serializer.write_int(7, i32::MAX);

            let mut nested_serializer = serializer.begin_nested(11, 12);
            nested_serializer.write_bool(0, Some(true));
            nested_serializer.write_bool(1, Some(true));
            nested_serializer.write_bool(2, Some(false));
            nested_serializer.write_bool(3, Some(true));
            nested_serializer.write_long(4, -500);
            serializer.end_nested(nested_serializer);

            assert_eq!(
                serializer.finish(),
                concat!(
                    [0xe, 0x0, 0x0],
                    32i32.to_le_bytes(),
                    [0xe, 0x0, 0x0],
                    i32::MAX.to_le_bytes(),
                    [0x25, 0x0, 0x0],
                    concat!(
                        // First nested
                        [0x14, 0x0, 0x0],
                        123_456_789.987_654_33_f64.to_le_bytes(),
                        NULL_INT.to_le_bytes(),
                        1024i64.to_le_bytes()
                    ),
                    concat!(
                        // Second nested
                        [0xc, 0x0, 0x0],
                        [0x2],
                        [0x2],
                        [0x1],
                        [0x2],
                        (-500i64).to_le_bytes()
                    )
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 16);
            serializer.write_dynamic(0, &[0x1, 0x2, 0x3, 0x10, 0x11, 0x12]);

            let mut nested_serializer = serializer.begin_nested(3, 11);
            nested_serializer.write_bool(0, Some(false));
            nested_serializer.write_int(1, 42);
            nested_serializer.write_bool(5, Some(false));
            nested_serializer.write_null(6, DataType::Byte);
            nested_serializer.write_dynamic(7, &[0x0, 0x1, 0x1, 0x0]);
            nested_serializer.write_bool(10, Some(false));
            serializer.end_nested(nested_serializer);

            serializer.write_dynamic(6, "foo bar".as_bytes());
            serializer.write_int(9, 321);

            let mut nested_serializer = serializer.begin_nested(13, 22);
            nested_serializer.write_double(0, 8.75);
            nested_serializer.write_dynamic(8, &[0x10, 0x20, 0x30, 0x40, 0x50, 0x60]);
            nested_serializer.write_dynamic(11, &[]);
            nested_serializer.write_long(14, 0);
            serializer.end_nested(nested_serializer);

            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x10, 0x0, 0x0],
                    [0x10, 0x0, 0x0], // First dynamic
                    [0x19, 0x0, 0x0], // First nested
                    [0x2e, 0x0, 0x0], // Second dynamic
                    321i32.to_le_bytes(),
                    [0x38, 0x0, 0x0], // Second nested
                    concat!(
                        // First dynamic
                        [0x6, 0x0, 0x0],
                        [0x1, 0x2, 0x3, 0x10, 0x11, 0x12]
                    ),
                    concat!(
                        // First nested
                        [0xb, 0x0, 0x0],
                        [0x1],
                        42i32.to_le_bytes(),
                        [0x1],
                        NULL_BYTE.to_le_bytes(),
                        [0xb, 0x0, 0x0],
                        [0x1],
                        [0x4, 0x0, 0x0],
                        [0x0, 0x1, 0x1, 0x0]
                    ),
                    concat!(
                        // Second dynamic
                        [0x7, 0x0, 0x0],
                        [b'f', b'o', b'o', b' ', b'b', b'a', b'r']
                    ),
                    concat!(
                        // Second nested
                        [0x16, 0x0, 0x0],
                        8.75f64.to_le_bytes(),
                        [0x16, 0x0, 0x0],
                        [0x1f, 0x0, 0x0],
                        0i64.to_le_bytes(),
                        [0x6, 0x0, 0x0],
                        [0x10, 0x20, 0x30, 0x40, 0x50, 0x60],
                        [0x0, 0x0, 0x0]
                    )
                )
            );
        }

        #[test]
        fn test_deeply_nested() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 21);
            serializer.write_int(0, 32);

            let mut nested_serializer = serializer.begin_nested(4, 8);
            nested_serializer.write_double(0, 1.1);
            serializer.end_nested(nested_serializer);

            let mut nested_serializer = serializer.begin_nested(7, 13);
            nested_serializer.write_bool(0, Some(true));
            nested_serializer.write_null(1, DataType::Bool);

            let mut nested_nested_serializer = nested_serializer.begin_nested(2, 8);
            nested_nested_serializer.write_bool(0, Some(false));
            nested_nested_serializer.write_dynamic(1, &[0x5, 0x5, 0x5, 0x8, 0x0]);
            nested_nested_serializer.write_byte(4, 5);
            nested_nested_serializer.write_dynamic(5, &[]);
            nested_serializer.end_nested(nested_nested_serializer);

            nested_serializer.write_dynamic(5, &[0x1, 0x8]);
            nested_serializer.write_null(8, DataType::Bool);
            nested_serializer.write_null(9, DataType::Float);
            serializer.end_nested(nested_serializer);

            serializer.write_int(10, 8);
            serializer.write_dynamic(14, &[]);
            serializer.write_dynamic(17, &[0x0, 0x0, 0x1, 0xff, 0xff, 0x0]);
            serializer.write_byte(20, 20);

            assert_eq!(
                serializer.finish(),
                concat!(
                    [0x15, 0x0, 0x0],
                    [0x20, 0x0, 0x0, 0x0],
                    [0x15, 0x0, 0x0], // First nested
                    [0x20, 0x0, 0x0], // Second nested
                    [0x8, 0x0, 0x0, 0x0],
                    [0x4b, 0x0, 0x0], // First dynamic
                    [0x4e, 0x0, 0x0], // Second dynamic
                    [0x14],
                    concat!([0x8, 0x0, 0x0], 1.1f64.to_le_bytes()), // First nested
                    concat!(
                        // Second nested
                        [0xd, 0x0, 0x0],
                        [0x2],
                        [0x0],
                        [0xd, 0x0, 0x0],  // Nested nested
                        [0x23, 0x0, 0x0], // Nested dynamic
                        [0x0],
                        NULL_FLOAT.to_le_bytes(),
                        concat!(
                            // Nested nested
                            [0x8, 0x0, 0x0],
                            [0x1],
                            [0x8, 0x0, 0x0],
                            [0x5],
                            [0x10, 0x0, 0x0],
                            concat!([0x5, 0x0, 0x0], [0x5, 0x5, 0x5, 0x8, 0x0]),
                            concat!([0x0, 0x0, 0x0])
                        ),
                        concat!([0x2, 0x0, 0x0], [0x1, 0x8])
                    ),
                    concat!([0x0, 0x0, 0x0]), // First dynamic
                    concat!([0x6, 0x0, 0x0], [0x0, 0x0, 0x1, 0xff, 0xff, 0x0])  // Second dynamic
                )
            );
        }
    }

    mod static_write_offset_assertions {
        use super::*;

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_bool_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0x0, 0x1, 0x2, 0x3, 0x4]);
            serializer.write_bool(3, Some(true));
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 10 into static section of 6 byte(s)"
        )]
        fn test_write_bool_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0x0, 0x1, 0x2, 0x3, 0x4]);
            serializer.write_dynamic(3, &[0x0, 0x0, 0x0]);
            serializer.write_bool(10, Some(false));
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_byte_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0x0, 0x1, 0x2, 0x3, 0x4]);
            serializer.write_byte(3, 1);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 10 into static section of 6 byte(s)"
        )]
        fn test_write_byte_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0x0, 0x1, 0x2, 0x3, 0x4]);
            serializer.write_dynamic(3, &[0x0, 0x0, 0x0]);
            serializer.write_byte(10, 42);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_int_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0x0, 0x1, 0x2, 0x3, 0x4]);
            serializer.write_int(3, 50);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 10 into static section of 6 byte(s)"
        )]
        fn test_write_int_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0x0, 0x1, 0x2, 0x3, 0x4]);
            serializer.write_dynamic(3, &[0x0, 0x0, 0x0]);
            serializer.write_int(10, -50);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_float_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0x0, 0x1, 0x2, 0x3, 0x4]);
            serializer.write_float(3, -12_345.679);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 10 into static section of 6 byte(s)"
        )]
        fn test_write_float_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0x0, 0x1, 0x2, 0x3, 0x4]);
            serializer.write_dynamic(3, &[0x0, 0x0, 0x0]);
            serializer.write_float(10, 5.5);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 1 into static section of 3 byte(s)"
        )]
        fn test_write_long_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(
                0,
                &[0x0, 0x1, 0x2, 0x3, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5, 0x5, 0x5],
            );
            serializer.write_long(1, 128);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 20 into static section of 6 byte(s)"
        )]
        fn test_write_long_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0x0, 0x1, 0x2, 0x3, 0x4]);
            serializer.write_dynamic(3, &[0x0; 30]);
            serializer.write_long(20, 1024);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 1 into static section of 3 byte(s)"
        )]
        fn test_write_double_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(
                0,
                &[0x0, 0x1, 0x2, 0x3, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5, 0x5, 0x5],
            );
            serializer.write_double(1, 10.123);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 20 into static section of 6 byte(s)"
        )]
        fn test_write_double_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0x0, 0x1, 0x2, 0x3, 0x4]);
            serializer.write_dynamic(3, &[0x0; 30]);
            serializer.write_double(20, -0.01);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_dynamic_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(
                0,
                &[0x0, 0x1, 0x2, 0x3, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5, 0x5, 0x5],
            );
            serializer.write_dynamic(3, &[0x0]);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 4 into static section of 6 byte(s)"
        )]
        fn test_write_dynamic_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0x0, 0x1, 0x2, 0x3, 0x4]);
            serializer.write_dynamic(3, &[0x0; 30]);
            serializer.write_dynamic(4, &[0x1, 0x2, 0x3, 0x0, 0x5]);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 1 into static section of 3 byte(s)"
        )]
        fn test_write_nested_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(
                0,
                &[0x0, 0x1, 0x2, 0x3, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5, 0x5, 0x5],
            );
            serializer.begin_nested(1, 1);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 4 into static section of 6 byte(s)"
        )]
        fn test_write_nested_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0x0, 0x1, 0x2, 0x3, 0x4]);
            serializer.write_dynamic(3, &[0x0; 30]);
            serializer.begin_nested(4, 5);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_null_bool_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(
                0,
                &[0x0, 0x1, 0x2, 0x3, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5, 0x5, 0x5],
            );
            serializer.write_null(3, DataType::Bool);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_null_byte_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(
                0,
                &[0x0, 0x1, 0x2, 0x3, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5, 0x5, 0x5],
            );
            serializer.write_null(3, DataType::Byte);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 0 into static section of 3 byte(s)"
        )]
        fn test_write_null_int_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(
                0,
                &[0x0, 0x1, 0x2, 0x3, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5, 0x5, 0x5],
            );
            serializer.write_null(0, DataType::Int);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 2 into static section of 3 byte(s)"
        )]
        fn test_write_null_float_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(
                0,
                &[0x0, 0x1, 0x2, 0x3, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5, 0x5, 0x5],
            );
            serializer.write_null(2, DataType::Float);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 4 into static section of 3 byte(s)"
        )]
        fn test_write_null_long_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(
                0,
                &[0x0, 0x1, 0x2, 0x3, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5, 0x5, 0x5],
            );
            serializer.write_null(4, DataType::Long);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 0 into static section of 3 byte(s)"
        )]
        fn test_write_null_double_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(
                0,
                &[0x0, 0x1, 0x2, 0x3, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5, 0x5, 0x5],
            );
            serializer.write_null(0, DataType::Double);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 4 into static section of 3 byte(s)"
        )]
        fn test_write_null_dynamic_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(
                0,
                &[0x0, 0x1, 0x2, 0x3, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5, 0x5, 0x5],
            );
            serializer.write_null(4, DataType::Json);
        }
    }
}
