use std::cell::Cell;

use super::{NULL_BOOL, NULL_BYTE, NULL_DOUBLE, NULL_FLOAT, NULL_INT, NULL_LONG};
use crate::{core::data_type::DataType, native::bool_to_byte};
use byteorder::{ByteOrder, LittleEndian};

pub struct IsarSerializer {
    buffer: Cell<Vec<u8>>,
    offset: u32,
}

impl IsarSerializer {
    pub fn new(mut buffer: Vec<u8>, offset: u32, static_size: u32) -> Self {
        let min_buffer_size = (offset + static_size) as usize;
        if min_buffer_size > buffer.len() {
            buffer.resize(min_buffer_size, 0);
        }
        LittleEndian::write_u24(&mut buffer[offset as usize + 3..], static_size);

        Self {
            buffer: Cell::new(buffer),
            offset: offset + 3,
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
    fn append(&mut self, bytes: &[u8]) {
        self.buffer.get_mut().extend_from_slice(bytes);
    }

    #[inline]
    fn append_u24(&mut self, value: u32) {
        let mut bytes = [0u8; 3];
        LittleEndian::write_u24(&mut bytes, value);
        self.append(&bytes);
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
            _ => self.write_u24(offset, 0),
        }
    }

    #[inline]
    pub fn write_bool(&mut self, offset: u32, value: Option<bool>) {
        self.write(offset, &[bool_to_byte(value)]);
    }

    #[inline]
    pub fn write_byte(&mut self, offset: u32, value: u8) {
        self.write(offset, &[value]);
    }

    #[inline]
    pub fn write_int(&mut self, offset: u32, value: i32) {
        self.write(offset, &value.to_le_bytes());
    }

    #[inline]
    pub fn write_float(&mut self, offset: u32, value: f32) {
        self.write(offset, &value.to_le_bytes());
    }

    #[inline]
    pub fn write_long(&mut self, offset: u32, value: i64) {
        self.write(offset, &value.to_le_bytes());
    }

    #[inline]
    pub fn write_double(&mut self, offset: u32, value: f64) {
        self.write(offset, &value.to_le_bytes());
    }

    #[inline]
    pub fn write_dynamic(&mut self, offset: u32, value: &[u8]) {
        let buffer_len = self.buffer.get_mut().len() as u32;
        self.write_u24(offset, buffer_len - self.offset);
        self.append_u24(value.len() as u32);
        self.append(value);
    }

    pub fn begin_nested(&mut self, offset: u32, static_size: u32) -> Self {
        let nested_offset = self.buffer.get_mut().len() as u32;
        self.write_u24(offset, nested_offset - self.offset);
        Self::new(self.buffer.take(), nested_offset, static_size)
    }

    pub fn end_nested(&mut self, writer: Self) {
        self.buffer.replace(writer.buffer.take());
    }

    pub fn finish(&self) -> Vec<u8> {
        self.buffer.take()
    }
}
