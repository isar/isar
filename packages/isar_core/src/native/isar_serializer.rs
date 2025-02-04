//! # Isar Binary Format Documentation
//!
//! The Isar binary format is a compact binary serialization format designed for efficient storage and
//! retrieval of structured data. It consists of a header followed by static and dynamic sections.
//!
//! ## Format Overview
//!
//! ```text
//! +------------------------+
//! |   Static Size (3B)    |  <- Header: size of static section
//! +------------------------+ <- Base position for all offsets
//! |                       |
//! |    Static Section     |  <- Fixed-size primitive values
//! |                       |
//! +------------------------+
//! |                       |
//! |    Dynamic Section    |  <- Variable-length data
//! |                       |
//! +------------------------+
//! ```
//!
//! ## Header and Static Section
//!
//! The format begins with a 3-byte header indicating the size of the static section.
//! After the header, the static section contains:
//! - Fixed-size primitive values (bool, byte, int, float, long, double)
//! - Offsets to dynamic data (3 bytes each)
//!
//! All offsets in the format are relative to the position after the header (start of static section).
//!
//! ### Primitive Types and Their Sizes
//! - Bool: 1 byte (0 = false, 1 = true, 255 = null)
//! - Byte: 1 byte (0 = null)
//! - Int: 4 bytes (0x80000000 = null)
//! - Float: 4 bytes (NaN with specific bit pattern = null)
//! - Long: 8 bytes (0x8000000000000000 = null)
//! - Double: 8 bytes (NaN with specific bit pattern = null)
//!
//! ## Dynamic Section
//!
//! The dynamic section follows the static section and contains variable-length data:
//! - Strings (UTF-8 encoded)
//! - Lists (of any type)
//! - Objects (nested Isar objects)
//!
//! Each dynamic value is referenced by a 3-byte offset stored in the static section.
//! These offsets are relative to the position after the header.
//! The format for dynamic values is:
//!
//! ```text
//! +------------------------+
//! |    Length (3 bytes)   |  <- Length of the data
//! +------------------------+
//! |                       |
//! |         Data          |  <- Actual data bytes
//! |                       |
//! +------------------------+
//! ```
//!
//! ### Dynamic Data Types
//! - String: UTF-8 encoded bytes
//! - Lists: Length followed by contiguous elements
//! - Objects: Nested Isar format (recursive)
//!
//! ### Null Values for Dynamic Types
//! - A zero offset (0x000000) in the static section indicates null
//!
//! ## Nested Objects
//!
//! Nested objects follow the same format recursively:
//! ```text
//! +------------------------+
//! |   Static Size (3B)    |  <- Header
//! +------------------------+ <- New base position for offsets
//! |    Static Section     |
//! +------------------------+
//! |    Dynamic Section    |
//! +------------------------+
//! ```
//! Each nested object establishes a new base position for offsets after its header.
//!
//! ## Example Layout
//! ```text
//! [Static Size: 3 bytes]     <- Header
//! +------------------------+ <- Base position (offset 0)
//! [Int: 4 bytes]             <- Offset 0
//! [String offset: 3 bytes]   <- Offset 4
//! [Bool: 1 byte]             <- Offset 7
//! +------------------------+
//! [Dynamic string length: 3 bytes]
//! [String data: N bytes]
//! ```
//!
//! ## Endianness
//! All multi-byte values are stored in little-endian format.

use super::{
    FALSE_BOOL, MAX_OBJ_SIZE, NULL_BOOL, NULL_DOUBLE, NULL_FLOAT, NULL_INT, NULL_LONG, TRUE_BOOL,
};
use crate::core::data_type::DataType;
use crate::core::error::{IsarError, Result};
use crate::core::value::IsarValue;
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
        // make sure the value is not too large
        let u24_value = value & 0x00ffffff;
        LittleEndian::write_u24(&mut self.buffer.get_mut()[offset..], u24_value);
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

    pub fn update_value(
        &mut self,
        offset: u32,
        value: Option<&IsarValue>,
        data_type: DataType,
    ) -> bool {
        match (value, data_type) {
            (None, _) => self.write_null(offset, data_type),
            (Some(IsarValue::Bool(value)), DataType::Bool) => self.write_bool(offset, *value),
            (Some(IsarValue::Integer(value)), DataType::Byte) => {
                self.write_byte(offset, *value as u8)
            }
            (Some(IsarValue::Integer(value)), DataType::Int) => {
                self.write_int(offset, *value as i32)
            }
            (Some(IsarValue::Integer(value)), DataType::Long) => self.write_long(offset, *value),
            (Some(IsarValue::Real(value)), DataType::Float) => {
                self.write_float(offset, *value as f32)
            }
            (Some(IsarValue::Real(value)), DataType::Double) => self.write_double(offset, *value),
            (Some(IsarValue::String(value)), DataType::String)
            | (Some(IsarValue::String(value)), DataType::Json) => {
                self.update_dynamic(offset, value.as_bytes())
            }
            _ => return false,
        }
        true
    }

    pub fn finish(&self) -> Result<Vec<u8>> {
        let buffer = self.buffer.take();
        if buffer.len() < MAX_OBJ_SIZE {
            Ok(buffer)
        } else {
            Err(IsarError::ObjectLimitReached {})
        }
    }
}

#[cfg(test)]
mod tests {
    use super::super::*;
    use super::IsarSerializer;
    use crate::core::data_type::DataType;
    use crate::core::error::IsarError;

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

    #[test]
    fn test_object_limit_reached() {
        let mut s = IsarSerializer::new(Vec::new(), 0, 6);
        let large_data = vec![42u8; MAX_OBJ_SIZE - 1];
        s.write_dynamic(0, &large_data);
        s.write_dynamic(3, &[1, 2]);
        assert_eq!(s.finish(), Err(IsarError::ObjectLimitReached {}));

        let mut s = IsarSerializer::new(Vec::new(), 0, 3);
        let large_data = vec![42u8; MAX_OBJ_SIZE + 1];
        s.write_dynamic(0, &large_data);
        assert_eq!(s.finish(), Err(IsarError::ObjectLimitReached {}));
    }

    mod single_data_type {
        use super::*;

        #[test]
        fn test_write_single_null_bool() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 1);
            s.write_null(0, DataType::Bool);
            assert_eq!(s.finish().unwrap(), vec![1, 0, 0, 255]);
        }

        #[test]
        fn test_write_single_null_byte() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 1);
            s.write_null(0, DataType::Byte);
            assert_eq!(s.finish().unwrap(), vec![1, 0, 0, 0]);
        }

        #[test]
        fn test_write_single_null_int() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 4);
            s.write_null(0, DataType::Int);
            assert_eq!(
                s.finish().unwrap(),
                concat!([4, 0, 0], NULL_INT.to_le_bytes())
            );
        }

        #[test]
        fn test_write_single_null_float() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 4);
            s.write_null(0, DataType::Float);
            assert_eq!(
                s.finish().unwrap(),
                concat!([4, 0, 0], NULL_FLOAT.to_le_bytes())
            );
        }

        #[test]
        fn test_write_single_null_long() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 8);
            s.write_null(0, DataType::Long);
            assert_eq!(
                s.finish().unwrap(),
                concat!([8, 0, 0], NULL_LONG.to_le_bytes())
            );
        }

        #[test]
        fn test_write_single_null_double() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 8);
            s.write_null(0, DataType::Double);
            assert_eq!(
                s.finish().unwrap(),
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
                let mut s = IsarSerializer::new(Vec::new(), 0, 3);
                s.write_null(0, dynamic_data_type);
                assert_eq!(s.finish().unwrap(), vec![3, 0, 0, 0, 0, 0]);
            }
        }

        #[test]
        fn test_write_single_bool() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 1);
            s.write_bool(0, false);
            assert_eq!(s.finish().unwrap(), vec![1, 0, 0, 0]);

            let mut s = IsarSerializer::new(Vec::new(), 0, 1);
            s.write_bool(0, true);
            assert_eq!(s.finish().unwrap(), vec![1, 0, 0, 1]);
        }

        #[test]
        fn test_write_single_byte() {
            for value in [0, 1, 42, 254, 255] {
                let mut s = IsarSerializer::new(Vec::new(), 0, 1);
                s.write_byte(0, value);
                assert_eq!(s.finish().unwrap(), concat!([1, 0, 0], value.to_le_bytes()));
            }
        }

        #[test]
        fn test_write_single_int() {
            for value in [0, 1, i32::MIN, i32::MAX, i32::MAX - 1] {
                let mut s = IsarSerializer::new(Vec::new(), 0, 4);
                s.write_int(0, value);
                assert_eq!(s.finish().unwrap(), concat!([4, 0, 0], value.to_le_bytes()));
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
                let mut s = IsarSerializer::new(Vec::new(), 0, 4);
                s.write_float(0, value);
                assert_eq!(s.finish().unwrap(), concat!([4, 0, 0], value.to_le_bytes()));
            }
        }

        #[test]
        fn test_write_single_long() {
            for value in [0, -1, 1, i64::MIN, i64::MIN + 1, i64::MAX, i64::MAX - 1] {
                let mut s = IsarSerializer::new(Vec::new(), 0, 8);
                s.write_long(0, value);
                assert_eq!(s.finish().unwrap(), concat!([8, 0, 0], value.to_le_bytes()));
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
                let mut s = IsarSerializer::new(Vec::new(), 0, 8);
                s.write_double(0, value);
                assert_eq!(s.finish().unwrap(), concat!([8, 0, 0], value.to_le_bytes()));
            }
        }

        #[test]
        fn test_write_single_dynamic() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, "foo".as_bytes());
            assert_eq!(
                s.finish().unwrap(),
                concat!([3, 0, 0], [3, 0, 0], [3, 0, 0, b'f', b'o', b'o'])
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, "".as_bytes());
            assert_eq!(
                s.finish().unwrap(),
                concat!([3, 0, 0], [3, 0, 0], [0, 0, 0])
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, LOREM.as_bytes());
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [3, 0, 0],
                    [3, 0, 0],
                    LOREM.len().to_le_bytes()[0..3].iter().copied(),
                    LOREM.as_bytes().iter().copied()
                )
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[1, 2, 3, 4, 5, 6, 7, 8, 9]);
            assert_eq!(
                s.finish().unwrap(),
                concat!([3, 0, 0], [3, 0, 0], [9, 0, 0], [1, 2, 3, 4, 5, 6, 7, 8, 9])
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &vec![0; 2000]);
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [3, 0, 0],
                    [3, 0, 0],
                    2000u32.to_le_bytes()[0..3].iter().copied(),
                    vec![0; 2000]
                )
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            let bytes = vec![5; 0xffffff];
            s.write_dynamic(0, &bytes);

            let finished = s.finish().unwrap();
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 2);
            s.write_null(0, DataType::Bool);
            s.write_null(1, DataType::Bool);
            assert_eq!(s.finish().unwrap(), vec![2, 0, 0, 255, 255]);

            let mut s = IsarSerializer::new(Vec::new(), 0, 10);
            for offset in 0..10 {
                s.write_null(offset, DataType::Bool);
            }
            assert_eq!(s.finish().unwrap(), concat!([10, 0, 0], [255; 10]));
        }

        #[test]
        fn test_write_multiple_null_byte() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 2);
            s.write_null(0, DataType::Byte);
            s.write_null(1, DataType::Byte);
            assert_eq!(s.finish().unwrap(), vec![2, 0, 0, 0, 0]);

            let mut s = IsarSerializer::new(Vec::new(), 0, 10);
            for offset in 0..10 {
                s.write_null(offset, DataType::Byte);
            }
            assert_eq!(s.finish().unwrap(), concat!([10, 0, 0], [0; 10]));
        }

        #[test]
        fn test_write_multiple_null_int() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 8);
            s.write_null(0, DataType::Int);
            s.write_null(4, DataType::Int);
            assert_eq!(
                s.finish().unwrap(),
                concat!([8, 0, 0], NULL_INT.to_le_bytes(), NULL_INT.to_le_bytes())
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 40);
            for offset in 0..10 {
                s.write_null(offset * 4, DataType::Int);
            }
            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 8);
            s.write_null(0, DataType::Float);
            s.write_null(4, DataType::Float);
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [8, 0, 0],
                    NULL_FLOAT.to_le_bytes(),
                    NULL_FLOAT.to_le_bytes()
                )
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 40);
            for offset in 0..10 {
                s.write_null(offset * 4, DataType::Float);
            }
            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 16);
            s.write_null(0, DataType::Long);
            s.write_null(8, DataType::Long);
            assert_eq!(
                s.finish().unwrap(),
                concat!([16, 0, 0], NULL_LONG.to_le_bytes(), NULL_LONG.to_le_bytes())
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 80);
            for offset in 0..10 {
                s.write_null(offset * 8, DataType::Long);
            }
            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 16);
            s.write_null(0, DataType::Double);
            s.write_null(8, DataType::Double);
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [16, 0, 0],
                    NULL_DOUBLE.to_le_bytes(),
                    NULL_DOUBLE.to_le_bytes()
                )
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 80);
            for offset in 0..10 {
                s.write_null(offset * 8, DataType::Double);
            }
            assert_eq!(
                s.finish().unwrap(),
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
                    let mut s = IsarSerializer::new(Vec::new(), 0, count * 3);
                    let mut expected = (count * 3).to_le_bytes()[..3].to_vec();

                    for i in 0..count {
                        s.write_null(i, dynamic_data_type);
                        expected.extend(vec![0; 3]);
                    }

                    assert_eq!(s.finish().unwrap(), expected);
                }
            }
        }

        #[test]
        fn test_write_multiple_bool() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_null(0, DataType::Bool);
            s.write_bool(1, false);
            s.write_bool(2, true);
            assert_eq!(s.finish().unwrap(), concat!([3, 0, 0], [255, 0, 1]));

            let mut s = IsarSerializer::new(Vec::new(), 0, 6);
            s.write_bool(0, false);
            s.write_bool(1, false);
            s.write_null(2, DataType::Bool);
            s.write_bool(3, true);
            s.write_bool(4, true);
            s.write_bool(5, false);
            assert_eq!(
                s.finish().unwrap(),
                concat!([6, 0, 0], [0, 0, 255, 1, 1, 0])
            );
        }

        #[test]
        fn test_write_multiple_byte() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_byte(0, 0);
            s.write_byte(1, 10);
            s.write_byte(2, 42);
            assert_eq!(s.finish().unwrap(), concat!([3, 0, 0], [0, 10, 0x2a]));

            let mut s = IsarSerializer::new(Vec::new(), 0, 5);
            s.write_byte(0, 0);
            s.write_byte(1, 10);
            s.write_byte(2, 42);
            s.write_byte(3, 254);
            s.write_byte(4, 255);
            assert_eq!(
                s.finish().unwrap(),
                concat!([5, 0, 0], [0, 10, 0x2a, 0xfe, 255])
            );
        }

        #[test]
        fn test_write_multiple_int() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 12);
            s.write_int(0, 0);
            s.write_int(4, -20);
            s.write_int(8, 42);
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [12, 0, 0],
                    0i32.to_le_bytes(),
                    (-20i32).to_le_bytes(),
                    42i32.to_le_bytes()
                )
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 20);
            s.write_int(0, i32::MIN);
            s.write_int(4, -1);
            s.write_int(8, 100);
            s.write_int(12, i32::MAX - 1);
            s.write_int(16, i32::MAX);
            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 12);
            s.write_float(0, 0f32);
            s.write_float(4, -20f32);
            s.write_float(8, 42f32);
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [12, 0, 0],
                    0f32.to_le_bytes(),
                    (-20f32).to_le_bytes(),
                    42f32.to_le_bytes()
                )
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 20);
            s.write_float(0, f32::MIN);
            s.write_float(4, f32::MIN.next_up());
            s.write_float(8, -1f32);
            s.write_float(12, 100.49);
            s.write_float(16, f32::MAX);
            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 24);
            s.write_long(0, 0);
            s.write_long(8, -20);
            s.write_long(16, 42);
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [24, 0, 0],
                    0i64.to_le_bytes(),
                    (-20i64).to_le_bytes(),
                    42i64.to_le_bytes()
                )
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 40);
            s.write_long(0, i64::MIN);
            s.write_long(8, i64::MIN + 1);
            s.write_long(16, -1);
            s.write_long(24, 100);
            s.write_long(32, i64::MAX);
            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 24);
            s.write_double(0, 0.0);
            s.write_double(8, -20.0);
            s.write_double(16, 42.0);
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [24, 0, 0],
                    0f64.to_le_bytes(),
                    (-20f64).to_le_bytes(),
                    42f64.to_le_bytes()
                )
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 40);
            s.write_double(0, f64::MIN);
            s.write_double(8, f64::MIN.next_up());
            s.write_double(16, -1.0);
            s.write_double(24, 100.49);
            s.write_double(32, f64::MAX);
            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 6);
            s.write_dynamic(0, "foo".as_bytes());
            s.write_dynamic(3, "bar".as_bytes());
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [6, 0, 0],
                    [6, 0, 0],
                    [12, 0, 0],
                    [3, 0, 0, b'f', b'o', b'o'],
                    [3, 0, 0, b'b', b'a', b'r']
                )
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 6);
            s.write_dynamic(0, &[]);
            s.write_dynamic(3, &[]);
            assert_eq!(
                s.finish().unwrap(),
                concat!([6, 0, 0], [6, 0, 0], [9, 0, 0], [0, 0, 0], [0, 0, 0])
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 12);
            s.write_dynamic(0, LOREM[..100].as_bytes());
            s.write_dynamic(3, LOREM[100..200].as_bytes());
            s.write_dynamic(6, LOREM[200..300].as_bytes());
            s.write_dynamic(9, LOREM[300..].as_bytes());
            assert_eq!(
                s.finish().unwrap(),
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

            let mut s = IsarSerializer::new(Vec::new(), 0, 15);
            s.write_dynamic(0, &[1, 2, 3, 4, 5, 6, 7, 8, 9]);
            s.write_dynamic(3, &[0, 2, 4]);
            s.write_dynamic(6, &[1, 2, 3, 4, 5, 6, 7]);
            s.write_dynamic(9, &[1, 2, 3, 4, 5, 6, 7, 8, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
            s.write_dynamic(12, &[0, 255, 255, 255, 42]);
            assert_eq!(
                s.finish().unwrap(),
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

            let mut s = IsarSerializer::new(Vec::new(), 0, 9);
            s.write_dynamic(0, &[1; 10]);
            s.write_dynamic(3, &[2; 20]);
            s.write_dynamic(6, &[3; 30]);

            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 8);
            s.write_null(0, DataType::Bool);
            s.write_null(1, DataType::Int);
            s.write_null(5, DataType::String);
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [8, 0, 0],
                    NULL_BOOL.to_le_bytes(),
                    NULL_INT.to_le_bytes(),
                    [0, 0, 0]
                )
            );

            let mut s = IsarSerializer::new(Vec::new(), 0, 22);
            s.write_null(0, DataType::Bool);
            s.write_null(1, DataType::Int);
            s.write_null(5, DataType::Int);
            s.write_null(9, DataType::Float);
            s.write_null(13, DataType::Double);
            s.write_null(21, DataType::Bool);
            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 19);
            s.write_bool(0, true);
            s.write_int(1, 123456);
            s.write_null(5, DataType::Bool);
            s.write_null(6, DataType::Float);
            s.write_double(10, 0.123456789);
            s.write_byte(18, 100);
            assert_eq!(
                s.finish().unwrap(),
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

            let mut s = IsarSerializer::new(Vec::new(), 0, 31);
            s.write_long(0, i64::MAX);
            s.write_long(8, i64::MIN);
            s.write_long(16, 0);
            s.write_null(24, DataType::Int);
            s.write_byte(28, 5);
            s.write_null(29, DataType::Byte);
            s.write_null(30, DataType::Byte);
            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 28);
            s.write_int(0, 65535);
            s.write_bool(4, false);
            s.write_bool(5, true);
            s.write_dynamic(6, "foo bar".as_bytes());
            s.write_int(9, -500);
            s.write_dynamic(13, &[1, 10, 255]);
            s.write_null(16, DataType::Double);
            s.write_null(24, DataType::ByteList);
            s.write_byte(27, 42);
            assert_eq!(
                s.finish().unwrap(),
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

            let mut s = IsarSerializer::new(Vec::new(), 0, 18);
            s.write_dynamic(0, &[0x20, 10, 0, 0, 50, 255]);
            s.write_double(3, 5.25);
            s.write_dynamic(11, &[]);
            s.write_null(14, DataType::Int);
            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            let mut nested_s = s.begin_nested(0, 14);
            nested_s.write_null(0, DataType::Int);
            nested_s.write_int(4, 128);
            nested_s.write_float(8, 9.56789);
            nested_s.write_byte(12, 8);
            nested_s.write_byte(13, 250);
            s.end_nested(nested_s);

            assert_eq!(
                s.finish().unwrap(),
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

            let mut s = IsarSerializer::new(Vec::new(), 0, 14);
            s.write_int(0, 32);

            let mut nested_s = s.begin_nested(4, 20);
            nested_s.write_double(0, 123_456_789.987_654_33);
            nested_s.write_null(8, DataType::Int);
            nested_s.write_long(12, 1024);
            s.end_nested(nested_s);

            s.write_int(7, i32::MAX);

            let mut nested_s = s.begin_nested(11, 12);
            nested_s.write_bool(0, true);
            nested_s.write_bool(1, true);
            nested_s.write_bool(2, false);
            nested_s.write_bool(3, true);
            nested_s.write_long(4, -500);
            s.end_nested(nested_s);

            assert_eq!(
                s.finish().unwrap(),
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

            let mut s = IsarSerializer::new(Vec::new(), 0, 16);
            s.write_dynamic(0, &[1, 2, 3, 10, 11, 12]);

            let mut nested_s = s.begin_nested(3, 11);
            nested_s.write_bool(0, false);
            nested_s.write_int(1, 42);
            nested_s.write_bool(5, false);
            nested_s.write_null(6, DataType::Byte);
            nested_s.write_dynamic(7, &[0, 1, 1, 0]);
            nested_s.write_bool(10, false);
            s.end_nested(nested_s);

            s.write_dynamic(6, "foo bar".as_bytes());
            s.write_int(9, 321);

            let mut nested_s = s.begin_nested(13, 22);
            nested_s.write_double(0, 8.75);
            nested_s.write_dynamic(8, &[10, 20, 30, 40, 50, 60]);
            nested_s.write_dynamic(11, &[]);
            nested_s.write_long(14, 0);
            s.end_nested(nested_s);

            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 21);
            s.write_int(0, 32);

            let mut nested_s = s.begin_nested(4, 8);
            nested_s.write_double(0, 1.1);
            s.end_nested(nested_s);

            let mut nested_s = s.begin_nested(7, 13);
            nested_s.write_bool(0, true);
            nested_s.write_null(1, DataType::Bool);

            let mut nested_nested_s = nested_s.begin_nested(2, 8);
            nested_nested_s.write_bool(0, false);
            nested_nested_s.write_dynamic(1, &[5, 5, 5, 8, 0]);
            nested_nested_s.write_byte(4, 5);
            nested_nested_s.write_dynamic(5, &[]);
            nested_s.end_nested(nested_nested_s);

            nested_s.write_dynamic(5, &[1, 8]);
            nested_s.write_null(8, DataType::Bool);
            nested_s.write_null(9, DataType::Float);
            s.end_nested(nested_s);

            s.write_int(10, 8);
            s.write_dynamic(14, &[]);
            s.write_dynamic(17, &[0, 0, 1, 255, 255, 0]);
            s.write_byte(20, 20);

            assert_eq!(
                s.finish().unwrap(),
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
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4]);
            s.write_bool(3, true);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 10 into static section of 6 byte(s)"
        )]
        fn test_write_bool_outside_bounds_2() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 6);
            s.write_dynamic(0, &[0, 1, 2, 3, 4]);
            s.write_dynamic(3, &[0; 30]);
            s.write_bool(10, false);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_byte_outside_bounds_1() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4]);
            s.write_byte(3, 1);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 10 into static section of 6 byte(s)"
        )]
        fn test_write_byte_outside_bounds_2() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 6);
            s.write_dynamic(0, &[0, 1, 2, 3, 4]);
            s.write_dynamic(3, &[0; 30]);
            s.write_byte(10, 42);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_int_outside_bounds_1() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4]);
            s.write_int(3, 50);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 10 into static section of 6 byte(s)"
        )]
        fn test_write_int_outside_bounds_2() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 6);
            s.write_dynamic(0, &[0, 1, 2, 3, 4]);
            s.write_dynamic(3, &[0; 30]);
            s.write_int(10, -50);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_float_outside_bounds_1() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4]);
            s.write_float(3, -12_345.679);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 10 into static section of 6 byte(s)"
        )]
        fn test_write_float_outside_bounds_2() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 6);
            s.write_dynamic(0, &[0, 1, 2, 3, 4]);
            s.write_dynamic(3, &[0; 30]);
            s.write_float(10, 5.5);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 1 into static section of 3 byte(s)"
        )]
        fn test_write_long_outside_bounds_1() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            s.write_long(1, 128);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 20 into static section of 6 byte(s)"
        )]
        fn test_write_long_outside_bounds_2() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 6);
            s.write_dynamic(0, &[0, 1, 2, 3, 4]);
            s.write_dynamic(3, &[0; 30]);
            s.write_long(20, 1024);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 1 into static section of 3 byte(s)"
        )]
        fn test_write_double_outside_bounds_1() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            s.write_double(1, 10.123);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 20 into static section of 6 byte(s)"
        )]
        fn test_write_double_outside_bounds_2() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 6);
            s.write_dynamic(0, &[0, 1, 2, 3, 4]);
            s.write_dynamic(3, &[0; 30]);
            s.write_double(20, -0.01);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_dynamic_outside_bounds_1() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            s.write_dynamic(3, &[0]);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 4 into static section of 6 byte(s)"
        )]
        fn test_write_dynamic_outside_bounds_2() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 6);
            s.write_dynamic(0, &[0, 1, 2, 3, 4]);
            s.write_dynamic(3, &[0; 30]);
            s.write_dynamic(4, &[1, 2, 3, 0, 5]);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 1 into static section of 3 byte(s)"
        )]
        fn test_write_nested_outside_bounds_1() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            s.begin_nested(1, 1);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 4 into static section of 6 byte(s)"
        )]
        fn test_write_nested_outside_bounds_2() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 6);
            s.write_dynamic(0, &[0, 1, 2, 3, 4]);
            s.write_dynamic(3, &[0; 30]);
            s.begin_nested(4, 5);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_null_bool_outside_bounds() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            s.write_null(3, DataType::Bool);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 1 byte(s) at offset 3 into static section of 3 byte(s)"
        )]
        fn test_write_null_byte_outside_bounds() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            s.write_null(3, DataType::Byte);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 0 into static section of 3 byte(s)"
        )]
        fn test_write_null_int_outside_bounds() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            s.write_null(0, DataType::Int);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 4 byte(s) at offset 2 into static section of 3 byte(s)"
        )]
        fn test_write_null_float_outside_bounds() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            s.write_null(2, DataType::Float);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 4 into static section of 3 byte(s)"
        )]
        fn test_write_null_long_outside_bounds() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            s.write_null(4, DataType::Long);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 8 byte(s) at offset 0 into static section of 3 byte(s)"
        )]
        fn test_write_null_double_outside_bounds() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            s.write_null(0, DataType::Double);
        }

        #[test]
        #[should_panic(
            expected = "Tried to write 3 byte(s) at offset 4 into static section of 3 byte(s)"
        )]
        fn test_write_null_dynamic_outside_bounds() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[0, 1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 5]);
            s.write_null(4, DataType::String);
        }
    }

    mod update_dynamic {
        use super::*;

        #[test]
        fn test_update_dynamic_new_value() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.update_dynamic(0, "foo".as_bytes());
            assert_eq!(
                s.finish().unwrap(),
                concat!([3, 0, 0], [3, 0, 0], [3, 0, 0, b'f', b'o', b'o'])
            );
        }

        #[test]
        fn test_update_dynamic_same_size() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, "foo".as_bytes());
            s.update_dynamic(0, "bar".as_bytes());
            assert_eq!(
                s.finish().unwrap(),
                concat!([3, 0, 0], [3, 0, 0], [3, 0, 0, b'b', b'a', b'r'])
            );
        }

        #[test]
        fn test_update_dynamic_smaller_size() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, "hello".as_bytes());
            s.update_dynamic(0, "hi".as_bytes());
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [3, 0, 0],
                    [3, 0, 0],
                    [2, 0, 0, b'h', b'i', b'l', b'l', b'o']
                )
            );
        }

        #[test]
        fn test_update_dynamic_larger_size() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, "hi".as_bytes());
            s.update_dynamic(0, "hello".as_bytes());
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [3, 0, 0],
                    [8, 0, 0],
                    [2, 0, 0, b'h', b'i'],
                    [5, 0, 0, b'h', b'e', b'l', b'l', b'o']
                )
            );
        }

        #[test]
        fn test_update_dynamic_empty() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[]);
            s.update_dynamic(0, &[1, 2, 3]);
            assert_eq!(
                s.finish().unwrap(),
                concat!([3, 0, 0], [6, 0, 0], [0, 0, 0], [3, 0, 0, 1, 2, 3])
            );
        }

        #[test]
        fn test_update_dynamic_to_empty() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_dynamic(0, &[1, 2, 3]);
            s.update_dynamic(0, &[]);
            assert_eq!(
                s.finish().unwrap(),
                concat!([3, 0, 0], [3, 0, 0], [0, 0, 0, 1, 2, 3])
            );
        }

        #[test]
        fn test_update_dynamic_zero_offset() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            s.write_u24_static_checked(0, 0);
            s.update_dynamic(0, "foo".as_bytes());
            assert_eq!(
                s.finish().unwrap(),
                concat!([3, 0, 0], [3, 0, 0], [3, 0, 0, b'f', b'o', b'o'])
            );
        }
    }

    mod update_value {
        use super::*;
        use crate::core::value::IsarValue;

        #[test]
        fn test_update_bool() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            assert!(s.update_value(0, None, DataType::Bool));
            assert!(s.update_value(1, Some(&IsarValue::Bool(true)), DataType::Bool));
            assert!(s.update_value(2, Some(&IsarValue::Bool(false)), DataType::Bool));
            assert_eq!(s.finish().unwrap(), concat!([3, 0, 0], [255, 1, 0]));

            // Test invalid value type
            let mut s = IsarSerializer::new(Vec::new(), 0, 1);
            assert!(!s.update_value(0, Some(&IsarValue::Integer(42)), DataType::Bool));
            assert!(!s.update_value(0, Some(&IsarValue::Real(1.0)), DataType::Bool));
            assert!(!s.update_value(
                0,
                Some(&IsarValue::String("true".to_owned())),
                DataType::Bool
            ));
        }

        #[test]
        fn test_update_byte() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            assert!(s.update_value(0, None, DataType::Byte));
            assert!(s.update_value(1, Some(&IsarValue::Integer(42)), DataType::Byte));
            assert!(s.update_value(2, Some(&IsarValue::Integer(255)), DataType::Byte));
            assert_eq!(s.finish().unwrap(), concat!([3, 0, 0], [0, 42, 255]));

            // Test invalid value type
            let mut s = IsarSerializer::new(Vec::new(), 0, 1);
            assert!(!s.update_value(0, Some(&IsarValue::Bool(true)), DataType::Byte));
            assert!(!s.update_value(0, Some(&IsarValue::Real(1.0)), DataType::Byte));
            assert!(!s.update_value(0, Some(&IsarValue::String("42".to_owned())), DataType::Byte));
        }

        #[test]
        fn test_update_int() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 12);
            assert!(s.update_value(0, None, DataType::Int));
            assert!(s.update_value(4, Some(&IsarValue::Integer(42)), DataType::Int));
            assert!(s.update_value(8, Some(&IsarValue::Integer(-123456)), DataType::Int));
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [12, 0, 0],
                    NULL_INT.to_le_bytes(),
                    42i32.to_le_bytes(),
                    (-123456i32).to_le_bytes()
                )
            );

            // Test invalid value type
            let mut s = IsarSerializer::new(Vec::new(), 0, 4);
            assert!(!s.update_value(0, Some(&IsarValue::Bool(true)), DataType::Int));
            assert!(!s.update_value(0, Some(&IsarValue::Real(1.0)), DataType::Int));
            assert!(!s.update_value(0, Some(&IsarValue::String("42".to_owned())), DataType::Int));
        }

        #[test]
        fn test_update_float() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 12);
            assert!(s.update_value(0, None, DataType::Float));
            assert!(s.update_value(4, Some(&IsarValue::Real(3.14)), DataType::Float));
            assert!(s.update_value(8, Some(&IsarValue::Real(-123.456)), DataType::Float));
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [12, 0, 0],
                    NULL_FLOAT.to_le_bytes(),
                    3.14f32.to_le_bytes(),
                    (-123.456f32).to_le_bytes()
                )
            );

            // Test invalid value type
            let mut s = IsarSerializer::new(Vec::new(), 0, 4);
            assert!(!s.update_value(0, Some(&IsarValue::Bool(true)), DataType::Float));
            assert!(!s.update_value(0, Some(&IsarValue::Integer(42)), DataType::Float));
            assert!(!s.update_value(
                0,
                Some(&IsarValue::String("3.14".to_owned())),
                DataType::Float
            ));
        }

        #[test]
        fn test_update_long() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 24);
            assert!(s.update_value(0, None, DataType::Long));
            assert!(s.update_value(8, Some(&IsarValue::Integer(42)), DataType::Long));
            assert!(s.update_value(16, Some(&IsarValue::Integer(-123456789)), DataType::Long));
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [24, 0, 0],
                    NULL_LONG.to_le_bytes(),
                    42i64.to_le_bytes(),
                    (-123456789i64).to_le_bytes()
                )
            );

            // Test invalid value type
            let mut s = IsarSerializer::new(Vec::new(), 0, 8);
            assert!(!s.update_value(0, Some(&IsarValue::Bool(true)), DataType::Long));
            assert!(!s.update_value(0, Some(&IsarValue::Real(1.0)), DataType::Long));
            assert!(!s.update_value(0, Some(&IsarValue::String("42".to_owned())), DataType::Long));
        }

        #[test]
        fn test_update_double() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 24);
            assert!(s.update_value(0, None, DataType::Double));
            assert!(s.update_value(8, Some(&IsarValue::Real(3.14159)), DataType::Double));
            assert!(s.update_value(16, Some(&IsarValue::Real(-123.456789)), DataType::Double));
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [24, 0, 0],
                    NULL_DOUBLE.to_le_bytes(),
                    3.14159f64.to_le_bytes(),
                    (-123.456789f64).to_le_bytes()
                )
            );

            // Test invalid value type
            let mut s = IsarSerializer::new(Vec::new(), 0, 8);
            assert!(!s.update_value(0, Some(&IsarValue::Bool(true)), DataType::Double));
            assert!(!s.update_value(0, Some(&IsarValue::Integer(42)), DataType::Double));
            assert!(!s.update_value(
                0,
                Some(&IsarValue::String("3.14".to_owned())),
                DataType::Double
            ));
        }

        #[test]
        fn test_update_string() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 9);
            assert!(s.update_value(0, None, DataType::String));
            assert!(s.update_value(
                3,
                Some(&IsarValue::String("hello".to_owned())),
                DataType::String
            ));
            assert!(s.update_value(6, Some(&IsarValue::String("".to_owned())), DataType::String));
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [9, 0, 0],
                    [0, 0, 0],
                    [9, 0, 0],
                    [17, 0, 0],
                    [5, 0, 0],
                    [b'h', b'e', b'l', b'l', b'o'],
                    [0, 0, 0]
                )
            );

            // Test invalid value type
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            assert!(!s.update_value(0, Some(&IsarValue::Bool(true)), DataType::String));
            assert!(!s.update_value(0, Some(&IsarValue::Integer(42)), DataType::String));
            assert!(!s.update_value(0, Some(&IsarValue::Real(3.14)), DataType::String));
        }

        #[test]
        fn test_update_json() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 9);
            assert!(s.update_value(0, None, DataType::Json));
            assert!(s.update_value(
                3,
                Some(&IsarValue::String("{\"key\":42}".to_owned())),
                DataType::Json
            ));
            assert!(s.update_value(6, Some(&IsarValue::String("[]".to_owned())), DataType::Json));
            assert_eq!(
                s.finish().unwrap(),
                concat!(
                    [9, 0, 0],
                    [0, 0, 0],
                    [9, 0, 0],
                    [22, 0, 0],
                    [10, 0, 0],
                    [b'{', b'"', b'k', b'e', b'y', b'"', b':', b'4', b'2', b'}'],
                    [2, 0, 0],
                    [b'[', b']']
                )
            );

            // Test invalid value type
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            assert!(!s.update_value(0, Some(&IsarValue::Bool(true)), DataType::Json));
            assert!(!s.update_value(0, Some(&IsarValue::Integer(42)), DataType::Json));
            assert!(!s.update_value(0, Some(&IsarValue::Real(3.14)), DataType::Json));
        }

        #[test]
        fn test_update_list_types() {
            let list_types = [
                DataType::BoolList,
                DataType::ByteList,
                DataType::IntList,
                DataType::FloatList,
                DataType::LongList,
                DataType::DoubleList,
                DataType::StringList,
            ];

            for data_type in list_types {
                let mut s = IsarSerializer::new(Vec::new(), 0, 3);
                assert!(s.update_value(0, None, data_type));
                assert_eq!(s.finish().unwrap(), concat!([3, 0, 0], [0, 0, 0]));

                // Test invalid value types
                let mut s = IsarSerializer::new(Vec::new(), 0, 3);
                assert!(!s.update_value(0, Some(&IsarValue::Bool(true)), data_type));
                assert!(!s.update_value(0, Some(&IsarValue::Integer(42)), data_type));
                assert!(!s.update_value(0, Some(&IsarValue::Real(3.14)), data_type));
                assert!(!s.update_value(0, Some(&IsarValue::String("test".to_owned())), data_type));
            }
        }

        #[test]
        fn test_update_object() {
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            assert!(s.update_value(0, None, DataType::Object));
            assert_eq!(s.finish().unwrap(), concat!([3, 0, 0], [0, 0, 0]));

            // Test invalid value types
            let mut s = IsarSerializer::new(Vec::new(), 0, 3);
            assert!(!s.update_value(0, Some(&IsarValue::Bool(true)), DataType::Object));
            assert!(!s.update_value(0, Some(&IsarValue::Integer(42)), DataType::Object));
            assert!(!s.update_value(0, Some(&IsarValue::Real(3.14)), DataType::Object));
            assert!(!s.update_value(
                0,
                Some(&IsarValue::String("test".to_owned())),
                DataType::Object
            ));
        }
    }
}
