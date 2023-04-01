use super::native_collection::{data_type_static_size, NativeCollection, NativeProperty};
use super::{
    FALSE_BOOL, MAX_OBJ_SIZE, NULL_BOOL, NULL_BYTE, NULL_DOUBLE, NULL_FLOAT, NULL_INT, NULL_LONG,
    TRUE_BOOL,
};
use crate::core::data_type::DataType;
use crate::core::error::{illegal_arg, Result};
use crate::core::writer::IsarWriter;
use byteorder::{ByteOrder, LittleEndian};

pub struct NativeWriter<'a> {
    collection: &'a NativeCollection,
    all_collections: &'a Vec<NativeCollection>,
    buffer: Vec<u8>,
    property: usize,
    id: i64,
}

impl<'a> NativeWriter<'a> {
    pub fn new(
        collection: &'a NativeCollection,
        all_collections: &'a Vec<NativeCollection>,
    ) -> Self {
        let static_size = collection
            .properties
            .iter()
            .max_by_key(|p| p.offset)
            .map_or(0, |p| p.offset + data_type_static_size(p.data_type))
            as usize;

        Self {
            collection,
            all_collections,
            buffer: Vec::with_capacity(static_size),
            property: 0,
            id: 0,
        }
    }

    fn next_property(&self) -> NativeProperty {
        let property = self.collection.properties.get(self.property);
        if property.is_none() {
            panic!("Invalid property index");
        }
        *property.unwrap()
    }

    #[inline]
    fn write_at(&mut self, offset: u32, bytes: &[u8]) {
        let offset = offset as usize;
        if offset + bytes.len() > self.buffer.len() {
            self.buffer.resize(offset + bytes.len(), 0);
        }
        self.buffer[offset..offset + bytes.len()].copy_from_slice(bytes);
    }

    #[inline]
    fn write_u24(&mut self, offset: usize, value: usize) {
        if offset + 3 > self.buffer.len() {
            self.buffer.resize(offset + 3, 0);
        }
        LittleEndian::write_u24(&mut self.buffer[offset..], value as u32);
    }

    fn bool_to_byte(value: Option<bool>) -> u8 {
        if let Some(value) = value {
            if value {
                TRUE_BOOL
            } else {
                FALSE_BOOL
            }
        } else {
            NULL_BOOL
        }
    }

    pub(crate) fn finish(&self) -> Result<(i64, &[u8])> {
        if self.buffer.len() > MAX_OBJ_SIZE as usize {
            illegal_arg("Object is bigger than 16MB")?;
        }
        Ok((self.id, &self.buffer))
    }
}

impl<'a> IsarWriter<'a> for NativeWriter<'a> {
    type ObjectWriter = NativeWriter<'a>;

    type ListWriter = NativeWriter<'a>;

    fn write_id(&mut self, id: i64) {
        self.id = id;
    }

    fn write_null(&mut self) {
        let property = self.next_property();
        match property.data_type {
            DataType::Bool => self.write_bool(None),
            DataType::Byte => self.write_byte(NULL_BYTE),
            DataType::Int => self.write_int(NULL_INT),
            DataType::Float => self.write_float(NULL_FLOAT),
            DataType::Long => self.write_long(NULL_LONG),
            DataType::Double => self.write_double(NULL_DOUBLE),
            DataType::String => self.write_string(None),
            _ => todo!(),
            /*DataType::Object => self.write_object(offset, None),
            DataType::BoolList => self.write_bool_list(offset, None),
            DataType::ByteList => self.write_byte_list(offset, None),
            DataType::IntList => self.write_int_list(offset, None),
            DataType::FloatList => self.write_float_list(offset, None),
            DataType::LongList => self.write_long_list(offset, None),
            DataType::DoubleList => self.write_double_list(offset, None),
            DataType::StringList => self.write_string_list(offset, None),
            DataType::ObjectList => self.write_object_list(offset, None),*/
        }
    }

    fn write_byte(&mut self, value: u8) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Byte);
        self.write_at(property.offset, &[value]);
    }

    fn write_bool(&mut self, value: Option<bool>) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Bool);
        let value = Self::bool_to_byte(value);
        self.write_at(property.offset, &[value]);
    }

    fn write_int(&mut self, value: i32) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Int);
        self.write_at(property.offset, &value.to_le_bytes());
    }

    fn write_float(&mut self, value: f32) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Float);
        self.write_at(property.offset, &value.to_le_bytes());
    }

    fn write_long(&mut self, value: i64) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Long);
        self.write_at(property.offset, &value.to_le_bytes());
    }

    fn write_double(&mut self, value: f64) {
        let property = self.next_property();
        assert_eq!(property.data_type, DataType::Double);
        self.write_at(property.offset, &value.to_le_bytes());
    }

    fn write_string(&mut self, value: Option<&str>) {
        todo!()
    }

    fn begin_object(&mut self) -> Self::ObjectWriter {
        todo!()
    }

    fn end_object(&mut self, writer: Self::ObjectWriter) {
        todo!()
    }

    fn begin_list(&mut self, size: usize) -> Self::ListWriter {
        todo!()
    }

    fn end_list(&mut self, writer: Self::ListWriter) {
        todo!()
    }
}
