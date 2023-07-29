use super::isar_deserializer::IsarDeserializer;
use super::native_collection::NativeCollection;
use super::{NULL_DOUBLE, NULL_FLOAT, NULL_INT, NULL_LONG};
use crate::core::data_type::DataType;
use crate::core::reader::IsarReader;
use std::borrow::Cow;
use std::iter::empty;

pub struct NativeReader<'a> {
    id: i64,
    object: IsarDeserializer<'a>,
    collection: &'a NativeCollection,
    all_collections: &'a [NativeCollection],
}

impl<'a> NativeReader<'a> {
    pub(crate) fn new(
        id: i64,
        object: IsarDeserializer<'a>,
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

    fn id_name(&self) -> Option<&str> {
        self.collection.id_name.as_deref()
    }

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> {
        self.collection
            .properties
            .iter()
            .map(|(name, property)| (name.as_str(), property.data_type))
    }

    #[inline]
    fn read_id(&self) -> i64 {
        self.id
    }

    fn is_null(&self, index: u32) -> bool {
        let property = self.collection.get_property(index as u16);
        if let Some(property) = property {
            self.object.is_null(property.offset, property.data_type)
        } else {
            true
        }
    }

    #[inline]
    fn read_bool(&self, index: u32) -> Option<bool> {
        let property = self.collection.get_property(index as u16)?;
        self.object.read_bool(property.offset)
    }

    #[inline]
    fn read_byte(&self, index: u32) -> u8 {
        if let Some(property) = self.collection.get_property(index as u16) {
            self.object.read_byte(property.offset)
        } else {
            0
        }
    }

    #[inline]
    fn read_int(&self, index: u32) -> i32 {
        if let Some(property) = self.collection.get_property(index as u16) {
            self.object.read_int(property.offset)
        } else {
            NULL_INT
        }
    }

    #[inline]
    fn read_float(&self, index: u32) -> f32 {
        if let Some(property) = self.collection.get_property(index as u16) {
            self.object.read_float(property.offset)
        } else {
            NULL_FLOAT
        }
    }

    #[inline]
    fn read_long(&self, index: u32) -> i64 {
        if let Some(property) = self.collection.get_property(index as u16) {
            self.object.read_long(property.offset)
        } else {
            NULL_LONG
        }
    }

    #[inline]
    fn read_double(&self, index: u32) -> f64 {
        if let Some(property) = self.collection.get_property(index as u16) {
            self.object.read_double(property.offset)
        } else {
            NULL_DOUBLE
        }
    }

    #[inline]
    fn read_string(&self, index: u32) -> Option<&str> {
        let property = self.collection.get_property(index as u16)?;
        self.object.read_string(property.offset)
    }

    #[inline]
    fn read_json(&self, index: u32) -> &str {
        let property = self.collection.get_property(index as u16);
        if let Some(property) = property {
            if let Some(str) = self.object.read_string(property.offset) {
                return str;
            }
        }
        "null"
    }

    #[inline]
    fn read_blob(&self, index: u32) -> Option<Cow<'_, [u8]>> {
        let property = self.collection.get_property(index as u16)?;
        self.object.read_dynamic(property.offset).map(Cow::Borrowed)
    }

    fn read_object(&self, index: u32) -> Option<Self::ObjectReader<'_>> {
        let property = self.collection.get_property(index as u16)?;
        let object = self.object.read_nested(property.offset)?;

        let collection_index = property.embedded_collection_index?;
        let collection = &self.all_collections[collection_index as usize];
        Some(NativeReader {
            id: i64::MIN,
            object,
            collection,
            all_collections: self.all_collections,
        })
    }

    fn read_list(&self, index: u32) -> Option<(Self::ListReader<'_>, u32)> {
        let property = self.collection.get_property(index as u16)?;
        let element_type = property.data_type.element_type()?;
        let (list, length) = self.object.read_list(property.offset, element_type)?;
        let reader = NativeListReader {
            list,
            data_type: element_type,
            embedded_collection_index: property.embedded_collection_index,
            all_collections: self.all_collections,
        };
        Some((reader, length))
    }
}

pub struct NativeListReader<'a> {
    list: IsarDeserializer<'a>,
    data_type: DataType,
    embedded_collection_index: Option<u16>,
    all_collections: &'a [NativeCollection],
}

impl<'a> IsarReader for NativeListReader<'a> {
    type ObjectReader<'b> = NativeReader<'b> where 'a: 'b;

    type ListReader<'b> = NativeListReader<'b> where 'a: 'b;

    fn id_name(&self) -> Option<&str> {
        None
    }

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> {
        empty()
    }

    #[inline]
    fn read_id(&self) -> i64 {
        NULL_LONG
    }

    fn is_null(&self, index: u32) -> bool {
        self.list
            .is_null(index * self.data_type.static_size() as u32, self.data_type)
    }

    #[inline]
    fn read_byte(&self, index: u32) -> u8 {
        self.list
            .read_byte(index * DataType::Byte.static_size() as u32)
    }

    #[inline]
    fn read_bool(&self, index: u32) -> Option<bool> {
        self.list
            .read_bool(index * DataType::Byte.static_size() as u32)
    }

    #[inline]
    fn read_int(&self, index: u32) -> i32 {
        self.list
            .read_int(index * DataType::Int.static_size() as u32)
    }

    #[inline]
    fn read_float(&self, index: u32) -> f32 {
        self.list
            .read_float(index * DataType::Float.static_size() as u32)
    }

    #[inline]
    fn read_long(&self, index: u32) -> i64 {
        self.list
            .read_long(index * DataType::Long.static_size() as u32)
    }

    #[inline]
    fn read_double(&self, index: u32) -> f64 {
        self.list
            .read_double(index * DataType::Double.static_size() as u32)
    }

    #[inline]
    fn read_string(&self, index: u32) -> Option<&'a str> {
        self.list
            .read_string(index * DataType::String.static_size() as u32)
    }

    fn read_json(&self, index: u32) -> &str {
        self.read_string(index).unwrap_or("null")
    }

    fn read_blob(&self, _index: u32) -> Option<Cow<'_, [u8]>> {
        None // nested lists are not supported
    }

    fn read_object(&self, index: u32) -> Option<Self::ObjectReader<'_>> {
        let object = self
            .list
            .read_nested(index * DataType::Object.static_size() as u32)?;
        let collection_index = self.embedded_collection_index?;
        let collection = &self.all_collections[collection_index as usize];
        Some(NativeReader {
            id: i64::MIN,
            object,
            collection,
            all_collections: self.all_collections,
        })
    }

    fn read_list(&self, _index: u32) -> Option<(Self::ListReader<'_>, u32)> {
        None // nested lists are not supported
    }
}
