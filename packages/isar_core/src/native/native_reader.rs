use super::native_collection::{NativeCollection, NativeProperty};
use super::native_object::NativeObject;
use crate::core::data_type::DataType;
use crate::core::reader::IsarReader;
use serde_json::Value;
use std::borrow::Cow;

pub struct NativeReader<'a> {
    id: i64,
    object: NativeObject<'a>,
    collection: &'a NativeCollection,
    all_collections: &'a [NativeCollection],
}

impl<'a> NativeReader<'a> {
    pub fn new(
        id: i64,
        object: NativeObject<'a>,
        collection: &'a NativeCollection,
        all_collections: &'a [NativeCollection],
    ) -> Self {
        NativeReader {
            id,
            object,
            collection,
            all_collections,
        }
    }
}

impl<'a> IsarReader for NativeReader<'a> {
    type ObjectReader<'b> = NativeReader<'b> where 'a: 'b;

    type ListReader<'b> = NativeListReader<'b> where 'a: 'b;

    fn read_id(&self) -> i64 {
        self.id
    }

    fn is_null(&self, index: u32) -> bool {
        let property = &self.collection.properties[index as usize];
        self.object.is_null(property.offset, property.data_type)
    }

    fn read_byte(&self, index: u32) -> u8 {
        let property = &self.collection.properties[index as usize];
        self.object.read_byte(property.offset)
    }

    fn read_bool(&self, index: u32) -> Option<bool> {
        let property = &self.collection.properties[index as usize];
        self.object.read_bool(property.offset)
    }

    fn read_int(&self, index: u32) -> i32 {
        let property = &self.collection.properties[index as usize];
        self.object.read_int(property.offset)
    }

    fn read_float(&self, index: u32) -> f32 {
        let property = &self.collection.properties[index as usize];
        self.object.read_float(property.offset)
    }

    fn read_long(&self, index: u32) -> i64 {
        let property = &self.collection.properties[index as usize];
        self.object.read_long(property.offset)
    }

    fn read_double(&self, index: u32) -> f64 {
        let property = &self.collection.properties[index as usize];
        self.object.read_double(property.offset)
    }

    fn read_string(&self, index: u32) -> Option<&'a str> {
        let property = &self.collection.properties[index as usize];
        self.object.read_string(property.offset)
    }

    fn read_blob(&self, index: u32) -> Option<Cow<'a, [u8]>> {
        let property = &self.collection.properties[index as usize];
        self.object.read_bytes(property.offset).map(Cow::Borrowed)
    }

    fn read_json(&self, index: u32) -> Option<Cow<'a, Value>> {
        let property = &self.collection.properties[index as usize];
        let value = self.object.read_json(property.offset);
        value.map(Cow::Owned)
    }

    fn read_object(&self, index: u32) -> Option<Self::ObjectReader<'_>> {
        let property = &self.collection.properties[index as usize];
        let object = self.object.read_object(property.offset)?;

        let collection_index = property.embedded_collection_index.unwrap();
        let collection = &self.all_collections[collection_index as usize];
        Some(NativeReader {
            id: i64::MIN,
            object,
            collection,
            all_collections: self.all_collections,
        })
    }

    fn read_list(&self, index: u32) -> Option<(Self::ListReader<'_>, u32)> {
        let property = self.collection.properties[index as usize];
        let (object, length) = self.object.read_list(property.offset, property.data_type)?;
        Some((
            NativeListReader {
                object,
                property,
                all_collections: self.all_collections,
            },
            length,
        ))
    }
}

pub struct NativeListReader<'a> {
    object: NativeObject<'a>,
    property: NativeProperty,
    all_collections: &'a [NativeCollection],
}

impl<'a> IsarReader for NativeListReader<'a> {
    type ObjectReader<'b> = NativeReader<'b> where 'a: 'b;

    type ListReader<'b> = NativeListReader<'b> where 'a: 'b;

    fn read_id(&self) -> i64 {
        panic!("Cannot read id from list")
    }

    fn is_null(&self, index: u32) -> bool {
        self.object.is_null(
            index * self.property.data_type.static_size() as u32,
            self.property.data_type,
        )
    }

    fn read_byte(&self, index: u32) -> u8 {
        self.object
            .read_byte(index * DataType::Byte.static_size() as u32)
    }

    fn read_bool(&self, index: u32) -> Option<bool> {
        self.object
            .read_bool(index * DataType::Byte.static_size() as u32)
    }

    fn read_int(&self, index: u32) -> i32 {
        self.object
            .read_int(index * DataType::Int.static_size() as u32)
    }

    fn read_float(&self, index: u32) -> f32 {
        self.object
            .read_float(index * DataType::Float.static_size() as u32)
    }

    fn read_long(&self, index: u32) -> i64 {
        self.object
            .read_long(index * DataType::Long.static_size() as u32)
    }

    fn read_double(&self, index: u32) -> f64 {
        self.object
            .read_double(index * DataType::Double.static_size() as u32)
    }

    fn read_string(&self, index: u32) -> Option<&'a str> {
        self.object
            .read_string(index * DataType::String.static_size() as u32)
    }

    fn read_blob(&self, _index: u32) -> Option<Cow<'_, [u8]>> {
        panic!("Nested lists are not supported")
    }

    fn read_json(&self, index: u32) -> Option<Cow<'a, Value>> {
        let valye = self
            .object
            .read_json(index * DataType::Object.static_size() as u32);
        valye.map(Cow::Owned)
    }

    fn read_object(&self, index: u32) -> Option<Self::ObjectReader<'_>> {
        let object = self.object.read_object(index * 6)?;
        let collection_index = self.property.embedded_collection_index.unwrap();
        let collection = &self.all_collections[collection_index as usize];
        Some(NativeReader {
            id: i64::MIN,
            object,
            collection,
            all_collections: self.all_collections,
        })
    }

    fn read_list(&self, _index: u32) -> Option<(Self::ListReader<'_>, u32)> {
        panic!("Nested lists are not supported")
    }
}
