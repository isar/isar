use super::{FALSE_BOOL, NULL_BOOL, NULL_DOUBLE, NULL_FLOAT, NULL_INT, NULL_LONG, TRUE_BOOL};
use crate::core::data_type::DataType;
use byteorder::{ByteOrder, LittleEndian};
use std::cell::Cell;

pub(crate) struct IsarSerializer {
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
    fn read_u24(&mut self, offset: u32) -> u32 {
        let offset = (offset + self.offset) as usize;
        LittleEndian::read_u24(&self.buffer.get_mut()[offset..]) as u32
    }

    #[inline]
    fn write_u24(&mut self, offset: u32, value: u32) {
        let offset = (offset + self.offset) as usize;
        LittleEndian::write_u24(&mut self.buffer.get_mut()[offset..], value);
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
            DataType::Byte => self.write_byte(offset, 0),
            DataType::Int => self.write_int(offset, NULL_INT),
            DataType::Float => self.write_float(offset, NULL_FLOAT),
            DataType::Long => self.write_long(offset, NULL_LONG),
            DataType::Double => self.write_double(offset, NULL_DOUBLE),
            _ => self.write_u24_static_checked(offset, 0),
        }
    }

    #[inline]
    pub fn write_bool(&mut self, offset: u32, value: bool) {
        if value {
            self.write_byte(offset, TRUE_BOOL);
        } else {
            self.write_byte(offset, FALSE_BOOL);
        }
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

    pub fn update_dynamic(&mut self, offset: u32, value: &[u8]) {
        let existing_dynamic_offset = self.read_u24(offset);
        if existing_dynamic_offset != 0 {
            let existing_dynamic_len = self.read_u24(existing_dynamic_offset);
            if existing_dynamic_len >= value.len() as u32 {
                self.write_u24(existing_dynamic_offset, value.len() as u32);
                self.write(existing_dynamic_offset + 3, value);
                return;
            }
        }

        self.write_dynamic(offset, value);
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
            assert_eq!(serializer.finish(), vec![1, 0, 0, 255]);
        }

        #[test]
        fn test_write_single_null_byte() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 1);
            serializer.write_null(0, DataType::Byte);
            assert_eq!(serializer.finish(), vec![1, 0, 0, 0]);
        }

        #[test]
        fn test_write_single_null_int() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 4);
            serializer.write_null(0, DataType::Int);
            assert_eq!(
                serializer.finish(),
                concat!([4, 0, 0], NULL_INT.to_le_bytes())
            );
        }

        #[test]
        fn test_write_single_null_float() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 4);
            serializer.write_null(0, DataType::Float);
            assert_eq!(
                serializer.finish(),
                concat!([4, 0, 0], NULL_FLOAT.to_le_bytes())
            );
        }

        #[test]
        fn test_write_single_null_long() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 8);
            serializer.write_null(0, DataType::Long);
            assert_eq!(
                serializer.finish(),
                concat!([8, 0, 0], NULL_LONG.to_le_bytes())
            );
        }

        #[test]
        fn test_write_single_null_double() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 8);
            serializer.write_null(0, DataType::Double);
            assert_eq!(
                serializer.finish(),
                concat!([8, 0, 0], NULL_DOUBLE.to_le_bytes())
            );
        }

        #[test]
        fn test_write_single_null_dynamic() {
            for dynamic_data_type in [
                DataType::String,
                DataType::Object,
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
                assert_eq!(serializer.finish(), vec![3, 0, 0, 0, 0, 0]);
            }
        }

        #[test]
        fn test_write_single_bool() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 1);
            serializer.write_bool(0, false);
            assert_eq!(serializer.finish(), vec![1, 0, 0, 0]);

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 1);
            serializer.write_bool(0, true);
            assert_eq!(serializer.finish(), vec![1, 0, 0, 1]);
        }

        #[test]
        fn test_write_single_byte() {
            for value in [0, 1, 42, 254, 255] {
                let mut serializer = IsarSerializer::new(Vec::new(), 0, 1);
                serializer.write_byte(0, value);
                assert_eq!(serializer.finish(), concat!([1, 0, 0], value.to_le_bytes()));
            }
        }

        #[test]
        fn test_write_single_int() {
            for value in [0, 1, i32::MIN, i32::MAX, i32::MAX - 1] {
                let mut serializer = IsarSerializer::new(Vec::new(), 0, 4);
                serializer.write_int(0, value);
                assert_eq!(serializer.finish(), concat!([4, 0, 0], value.to_le_bytes()));
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
                assert_eq!(serializer.finish(), concat!([4, 0, 0], value.to_le_bytes()));
            }
        }

        #[test]
        fn test_write_single_long() {
            for value in [0, -1, 1, i64::MIN, i64::MIN + 1, i64::MAX, i64::MAX - 1] {
                let mut serializer = IsarSerializer::new(Vec::new(), 0, 8);
                serializer.write_long(0, value);
                assert_eq!(serializer.finish(), concat!([8, 0, 0], value.to_le_bytes()));
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
                assert_eq!(serializer.finish(), concat!([8, 0, 0], value.to_le_bytes()));
            }
        }

        #[test]
        fn test_write_single_dynamic() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, "foo".as_bytes());
            assert_eq!(
                serializer.finish(),
                concat!([3, 0, 0], [3, 0, 0], [3, 0, 0, b'f', b'o', b'o'])
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, "".as_bytes());
            assert_eq!(
                serializer.finish(),
                concat!([3, 0, 0], [3, 0, 0], [0, 0, 0])
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, LOREM.as_bytes());
            assert_eq!(
                serializer.finish(),
                concat!(
                    [3, 0, 0],
                    [3, 0, 0],
                    LOREM.len().to_le_bytes()[0..3].iter().copied(),
                    LOREM.as_bytes().iter().copied()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[1, 2, 3, 4, 5, 6, 7, 8, 9]);
            assert_eq!(
                serializer.finish(),
                concat!([3, 0, 0], [3, 0, 0], [9, 0, 0], [1, 2, 3, 4, 5, 6, 7, 8, 9])
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &vec![0; 2000]);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [3, 0, 0],
                    [3, 0, 0],
                    2000u32.to_le_bytes()[0..3].iter().copied(),
                    vec![0; 2000]
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            let bytes = vec![5; 0xffffff];
            serializer.write_dynamic(0, &bytes);

            let finished = serializer.finish();
            let expected = concat!([3, 0, 0], [3, 0, 0], [255, 255, 255], bytes);

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
            assert_eq!(serializer.finish(), vec![2, 0, 0, 255, 255]);

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 10);
            for offset in 0..10 {
                serializer.write_null(offset, DataType::Bool);
            }
            assert_eq!(serializer.finish(), concat!([10, 0, 0], [255; 10]));
        }

        #[test]
        fn test_write_multiple_null_byte() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 2);
            serializer.write_null(0, DataType::Byte);
            serializer.write_null(1, DataType::Byte);
            assert_eq!(serializer.finish(), vec![2, 0, 0, 0, 0]);

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 10);
            for offset in 0..10 {
                serializer.write_null(offset, DataType::Byte);
            }
            assert_eq!(serializer.finish(), concat!([10, 0, 0], [0; 10]));
        }

        #[test]
        fn test_write_multiple_null_int() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 8);
            serializer.write_null(0, DataType::Int);
            serializer.write_null(4, DataType::Int);
            assert_eq!(
                serializer.finish(),
                concat!([8, 0, 0], NULL_INT.to_le_bytes(), NULL_INT.to_le_bytes())
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 40);
            for offset in 0..10 {
                serializer.write_null(offset * 4, DataType::Int);
            }
            assert_eq!(
                serializer.finish(),
                concat!(
                    [4 * 10, 0, 0],
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
                    [8, 0, 0],
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
                    [4 * 10, 0, 0],
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
                concat!([16, 0, 0], NULL_LONG.to_le_bytes(), NULL_LONG.to_le_bytes())
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 80);
            for offset in 0..10 {
                serializer.write_null(offset * 8, DataType::Long);
            }
            assert_eq!(
                serializer.finish(),
                concat!(
                    [8 * 10, 0, 0],
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
                    [16, 0, 0],
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
                    [8 * 10, 0, 0],
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
                        expected.extend(vec![0; 3]);
                    }

                    assert_eq!(serializer.finish(), expected);
                }
            }
        }

        #[test]
        fn test_write_multiple_bool() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_null(0, DataType::Bool);
            serializer.write_bool(1, false);
            serializer.write_bool(2, true);
            assert_eq!(serializer.finish(), concat!([3, 0, 0], [255, 0, 1]));

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_bool(0, false);
            serializer.write_bool(1, false);
            serializer.write_null(2, DataType::Bool);
            serializer.write_bool(3, true);
            serializer.write_bool(4, true);
            serializer.write_bool(5, false);
            assert_eq!(
                serializer.finish(),
                concat!([6, 0, 0], [0, 0, 255, 1, 1, 0])
            );
        }

        #[test]
        fn test_write_multiple_byte() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_byte(0, 0);
            serializer.write_byte(1, 10);
            serializer.write_byte(2, 42);
            assert_eq!(serializer.finish(), concat!([3, 0, 0], [0, 10, 0x2a]));

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 5);
            serializer.write_byte(0, 0);
            serializer.write_byte(1, 10);
            serializer.write_byte(2, 42);
            serializer.write_byte(3, 254);
            serializer.write_byte(4, 255);
            assert_eq!(
                serializer.finish(),
                concat!([5, 0, 0], [0, 10, 0x2a, 0xfe, 255])
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
                    [12, 0, 0],
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
                    [20, 0, 0],
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
                    [12, 0, 0],
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
                    [20, 0, 0],
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
                    [24, 0, 0],
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
                    [40, 0, 0],
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
                    [24, 0, 0],
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
                    [40, 0, 0],
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
                    [6, 0, 0],
                    [6, 0, 0],
                    [12, 0, 0],
                    [3, 0, 0, b'f', b'o', b'o'],
                    [3, 0, 0, b'b', b'a', b'r']
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[]);
            serializer.write_dynamic(3, &[]);
            assert_eq!(
                serializer.finish(),
                concat!([6, 0, 0], [6, 0, 0], [9, 0, 0], [0, 0, 0], [0, 0, 0])
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 12);
            serializer.write_dynamic(0, LOREM[..100].as_bytes());
            serializer.write_dynamic(3, LOREM[100..200].as_bytes());
            serializer.write_dynamic(6, LOREM[200..300].as_bytes());
            serializer.write_dynamic(9, LOREM[300..].as_bytes());
            assert_eq!(
                serializer.finish(),
                concat!(
                    [12, 0, 0],
                    [12, 0, 0],
                    [115, 0, 0],
                    [218, 0, 0],
                    [65, 1, 0],
                    [100, 0, 0],
                    LOREM[..100].as_bytes().iter().copied(),
                    [100, 0, 0],
                    LOREM[100..200].as_bytes().iter().copied(),
                    [100, 0, 0],
                    LOREM[200..300].as_bytes().iter().copied(),
                    [
                        ((LOREM.len() - 300) & 255) as u8,
                        (((LOREM.len() - 300) >> 8) & 255) as u8,
                        (((LOREM.len() - 300) >> 16) & 255) as u8
                    ],
                    LOREM[300..].as_bytes().iter().copied()
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 15);
            serializer.write_dynamic(0, &[1, 2, 3, 4, 5, 6, 7, 8, 9]);
            serializer.write_dynamic(3, &[0, 2, 4]);
            serializer.write_dynamic(6, &[1, 2, 3, 4, 5, 6, 7]);
            serializer.write_dynamic(9, &[1, 2, 3, 4, 5, 6, 7, 8, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
            serializer.write_dynamic(12, &[0, 255, 255, 255, 42]);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [15, 0, 0],
                    [15, 0, 0],
                    [27, 0, 0],
                    [33, 0, 0],
                    [43, 0, 0],
                    [63, 0, 0],
                    [9, 0, 0],
                    [1, 2, 3, 4, 5, 6, 7, 8, 9],
                    [3, 0, 0],
                    [0, 2, 4],
                    [7, 0, 0],
                    [1, 2, 3, 4, 5, 6, 7],
                    [17, 0, 0],
                    [1, 2, 3, 4, 5, 6, 7, 8, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                    [5, 0, 0],
                    [0, 255, 255, 255, 42]
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 9);
            serializer.write_dynamic(0, &[1; 10]);
            serializer.write_dynamic(3, &[2; 20]);
            serializer.write_dynamic(6, &[3; 30]);

            assert_eq!(
                serializer.finish(),
                concat!(
                    [9, 0, 0],
                    [9, 0, 0],
                    [22, 0, 0],
                    [45, 0, 0],
                    [10, 0, 0],
                    [1; 10],
                    [20, 0, 0],
                    [2; 20],
                    [30, 0, 0],
                    [3; 30]
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
                    [8, 0, 0],
                    NULL_BOOL.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    [0, 0, 0]
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
                    [22, 0, 0],
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
            serializer.write_bool(0, true);
            serializer.write_int(1, 123456);
            serializer.write_null(5, DataType::Bool);
            serializer.write_null(6, DataType::Float);
            serializer.write_double(10, 0.123456789);
            serializer.write_byte(18, 100);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [19, 0, 0],
                    [1],
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
                    [31, 0, 0],
                    i64::MAX.to_le_bytes(),
                    i64::MIN.to_le_bytes(),
                    0i64.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    [5],
                    0u8.to_le_bytes(),
                    0u8.to_le_bytes()
                ]
            );
        }

        #[test]
        fn test_write_any_type() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 28);
            serializer.write_int(0, 65535);
            serializer.write_bool(4, false);
            serializer.write_bool(5, true);
            serializer.write_dynamic(6, "foo bar".as_bytes());
            serializer.write_int(9, -500);
            serializer.write_dynamic(13, &[1, 10, 255]);
            serializer.write_null(16, DataType::Double);
            serializer.write_null(24, DataType::ByteList);
            serializer.write_byte(27, 42);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [28, 0, 0],
                    65535i32.to_le_bytes(),
                    [0],
                    [1],
                    [28, 0, 0],
                    (-500i32).to_le_bytes(),
                    [38, 0, 0],
                    NULL_DOUBLE.to_le_bytes(),
                    [0, 0, 0],
                    [42],
                    [7, 0, 0],
                    [b'f', b'o', b'o', b' ', b'b', b'a', b'r'],
                    [3, 0, 0],
                    [1, 10, 255]
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 18);
            serializer.write_dynamic(0, &[0x20, 10, 0, 0, 50, 255]);
            serializer.write_double(3, 5.25);
            serializer.write_dynamic(11, &[]);
            serializer.write_null(14, DataType::Int);
            assert_eq!(
                serializer.finish(),
                concat!(
                    [18, 0, 0],
                    [18, 0, 0],
                    5.25f64.to_le_bytes(),
                    [27, 0, 0],
                    NULL_INT.to_le_bytes(),
                    [6, 0, 0],
                    [0x20, 10, 0, 0, 50, 255],
                    [0, 0, 0]
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
                    [3, 0, 0],
                    [3, 0, 0],
                    [14, 0, 0],
                    NULL_INT.to_le_bytes(),
                    128i32.to_le_bytes(),
                    9.56789f32.to_le_bytes(),
                    [8],
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
            nested_serializer.write_bool(0, true);
            nested_serializer.write_bool(1, true);
            nested_serializer.write_bool(2, false);
            nested_serializer.write_bool(3, true);
            nested_serializer.write_long(4, -500);
            serializer.end_nested(nested_serializer);

            assert_eq!(
                serializer.finish(),
                concat!(
                    [14, 0, 0],
                    32i32.to_le_bytes(),
                    [14, 0, 0],
                    i32::MAX.to_le_bytes(),
                    [0x25, 0, 0],
                    concat!(
                        // First nested
                        [20, 0, 0],
                        123_456_789.987_654_33_f64.to_le_bytes(),
                        NULL_INT.to_le_bytes(),
                        1024i64.to_le_bytes()
                    ),
                    concat!(
                        // Second nested
                        [12, 0, 0],
                        [1],
                        [1],
                        [0],
                        [1],
                        (-500i64).to_le_bytes()
                    )
                )
            );

            let mut serializer = IsarSerializer::new(Vec::new(), 0, 16);
            serializer.write_dynamic(0, &[1, 2, 3, 10, 11, 12]);

            let mut nested_serializer = serializer.begin_nested(3, 11);
            nested_serializer.write_bool(0, false);
            nested_serializer.write_int(1, 42);
            nested_serializer.write_bool(5, false);
            nested_serializer.write_null(6, DataType::Byte);
            nested_serializer.write_dynamic(7, &[0, 1, 1, 0]);
            nested_serializer.write_bool(10, false);
            serializer.end_nested(nested_serializer);

            serializer.write_dynamic(6, "foo bar".as_bytes());
            serializer.write_int(9, 321);

            let mut nested_serializer = serializer.begin_nested(13, 22);
            nested_serializer.write_double(0, 8.75);
            nested_serializer.write_dynamic(8, &[10, 20, 30, 40, 50, 60]);
            nested_serializer.write_dynamic(11, &[]);
            nested_serializer.write_long(14, 0);
            serializer.end_nested(nested_serializer);

            assert_eq!(
                serializer.finish(),
                concat!(
                    [16, 0, 0],
                    [16, 0, 0], // First dynamic
                    [25, 0, 0], // First nested
                    [46, 0, 0], // Second dynamic
                    321i32.to_le_bytes(),
                    [56, 0, 0], // Second nested
                    concat!(
                        // First dynamic
                        [6, 0, 0],
                        [1, 2, 3, 10, 11, 12]
                    ),
                    concat!(
                        // First nested
                        [11, 0, 0],
                        [0],
                        42i32.to_le_bytes(),
                        [0],
                        0u8.to_le_bytes(),
                        [11, 0, 0],
                        [0],
                        [4, 0, 0],
                        [0, 1, 1, 0]
                    ),
                    concat!(
                        // Second dynamic
                        [7, 0, 0],
                        [b'f', b'o', b'o', b' ', b'b', b'a', b'r']
                    ),
                    concat!(
                        // Second nested
                        [22, 0, 0],
                        8.75f64.to_le_bytes(),
                        [22, 0, 0],
                        [31, 0, 0],
                        0i64.to_le_bytes(),
                        [6, 0, 0],
                        [10, 20, 30, 40, 50, 60],
                        [0, 0, 0]
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
            nested_serializer.write_bool(0, true);
            nested_serializer.write_null(1, DataType::Bool);

            let mut nested_nested_serializer = nested_serializer.begin_nested(2, 8);
            nested_nested_serializer.write_bool(0, false);
            nested_nested_serializer.write_dynamic(1, &[5, 5, 5, 8, 0]);
            nested_nested_serializer.write_byte(4, 5);
            nested_nested_serializer.write_dynamic(5, &[]);
            nested_serializer.end_nested(nested_nested_serializer);

            nested_serializer.write_dynamic(5, &[1, 8]);
            nested_serializer.write_null(8, DataType::Bool);
            nested_serializer.write_null(9, DataType::Float);
            serializer.end_nested(nested_serializer);

            serializer.write_int(10, 8);
            serializer.write_dynamic(14, &[]);
            serializer.write_dynamic(17, &[0, 0, 1, 255, 255, 0]);
            serializer.write_byte(20, 20);

            assert_eq!(
                serializer.finish(),
                concat!(
                    [21, 0, 0],
                    [32, 0, 0, 0],
                    [21, 0, 0], // First nested
                    [32, 0, 0], // Second nested
                    [8, 0, 0, 0],
                    [75, 0, 0], // First dynamic
                    [78, 0, 0], // Second dynamic
                    [20],
                    concat!([8, 0, 0], 1.1f64.to_le_bytes()), // First nested
                    concat!(
                        // Second nested
                        [13, 0, 0],
                        [1],
                        [255],
                        [13, 0, 0], // Nested nested
                        [35, 0, 0], // Nested dynamic
                        [255],
                        NULL_FLOAT.to_le_bytes(),
                        concat!(
                            // Nested nested
                            [8, 0, 0],
                            [0],
                            [8, 0, 0],
                            [5],
                            [16, 0, 0],
                            concat!([5, 0, 0], [5, 5, 5, 8, 0]),
                            concat!([0, 0, 0])
                        ),
                        concat!([2, 0, 0], [1, 8])
                    ),
                    concat!([0, 0, 0]),                         // First dynamic
                    concat!([6, 0, 0], [0, 0, 1, 255, 255, 0])  // Second dynamic
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
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4]);
            serializer.write_bool(3, true);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 10 into static section of 6 byte(s)"
        )]
        fn test_write_bool_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4]);
            serializer.write_dynamic(3, &[0, 0, 0]);
            serializer.write_bool(10, false);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_byte_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4]);
            serializer.write_byte(3, 1);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 10 into static section of 6 byte(s)"
        )]
        fn test_write_byte_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4]);
            serializer.write_dynamic(3, &[0, 0, 0]);
            serializer.write_byte(10, 42);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_int_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4]);
            serializer.write_int(3, 50);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 10 into static section of 6 byte(s)"
        )]
        fn test_write_int_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4]);
            serializer.write_dynamic(3, &[0, 0, 0]);
            serializer.write_int(10, -50);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_float_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4]);
            serializer.write_float(3, -12_345.679);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 10 into static section of 6 byte(s)"
        )]
        fn test_write_float_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4]);
            serializer.write_dynamic(3, &[0, 0, 0]);
            serializer.write_float(10, 5.5);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 1 into static section of 3 byte(s)"
        )]
        fn test_write_long_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            serializer.write_long(1, 128);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 20 into static section of 6 byte(s)"
        )]
        fn test_write_long_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4]);
            serializer.write_dynamic(3, &[0; 30]);
            serializer.write_long(20, 1024);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 1 into static section of 3 byte(s)"
        )]
        fn test_write_double_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            serializer.write_double(1, 10.123);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 20 into static section of 6 byte(s)"
        )]
        fn test_write_double_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4]);
            serializer.write_dynamic(3, &[0; 30]);
            serializer.write_double(20, -0.01);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_dynamic_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            serializer.write_dynamic(3, &[0]);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 4 into static section of 6 byte(s)"
        )]
        fn test_write_dynamic_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4]);
            serializer.write_dynamic(3, &[0; 30]);
            serializer.write_dynamic(4, &[1, 2, 3, 0, 5]);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 1 into static section of 3 byte(s)"
        )]
        fn test_write_nested_outside_bounds_1() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            serializer.begin_nested(1, 1);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 4 into static section of 6 byte(s)"
        )]
        fn test_write_nested_outside_bounds_2() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 6);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4]);
            serializer.write_dynamic(3, &[0; 30]);
            serializer.begin_nested(4, 5);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_null_bool_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            serializer.write_null(3, DataType::Bool);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_null_byte_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            serializer.write_null(3, DataType::Byte);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 0 into static section of 3 byte(s)"
        )]
        fn test_write_null_int_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            serializer.write_null(0, DataType::Int);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 2 into static section of 3 byte(s)"
        )]
        fn test_write_null_float_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            serializer.write_null(2, DataType::Float);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 4 into static section of 3 byte(s)"
        )]
        fn test_write_null_long_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            serializer.write_null(4, DataType::Long);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 0 into static section of 3 byte(s)"
        )]
        fn test_write_null_double_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            serializer.write_null(0, DataType::Double);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 4 into static section of 3 byte(s)"
        )]
        fn test_write_null_dynamic_outside_bounds() {
            let mut serializer = IsarSerializer::new(Vec::new(), 0, 3);
            serializer.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            serializer.write_null(4, DataType::String);
        }
    }
}
