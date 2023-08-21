use super::isar_deserializer::IsarDeserializer;
use super::native_collection::{NativeCollection, NativeProperty};
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

    #[inline]
    fn get_property(&self, index: u32) -> Option<&NativeProperty> {
        self.collection.get_property(index as u16)
    }

    #[inline]
    fn get_offset(&self, index: u32, data_type: DataType) -> Option<u32> {
        let property = self.collection.get_property(index as u16)?;
        if property.data_type == data_type {
            Some(property.offset)
        } else {
            None
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
        if let Some(property) = self.get_property(index) {
            self.object.is_null(property.offset, property.data_type)
        } else {
            true
        }
    }

    #[inline]
    fn read_bool(&self, index: u32) -> Option<bool> {
        let offset = self.get_offset(index, DataType::Bool)?;
        self.object.read_bool(offset)
    }

    #[inline]
    fn read_byte(&self, index: u32) -> u8 {
        if let Some(offset) = self.get_offset(index, DataType::Byte) {
            self.object.read_byte(offset)
        } else {
            0
        }
    }

    #[inline]
    fn read_int(&self, index: u32) -> i32 {
        if let Some(offset) = self.get_offset(index, DataType::Int) {
            self.object.read_int(offset)
        } else {
            NULL_INT
        }
    }

    #[inline]
    fn read_float(&self, index: u32) -> f32 {
        if let Some(offset) = self.get_offset(index, DataType::Float) {
            self.object.read_float(offset)
        } else {
            NULL_FLOAT
        }
    }

    #[inline]
    fn read_long(&self, index: u32) -> i64 {
        if let Some(offset) = self.get_offset(index, DataType::Long) {
            self.object.read_long(offset)
        } else {
            NULL_LONG
        }
    }

    #[inline]
    fn read_double(&self, index: u32) -> f64 {
        if let Some(offset) = self.get_offset(index, DataType::Double) {
            self.object.read_double(offset)
        } else {
            NULL_DOUBLE
        }
    }

    #[inline]
    fn read_string(&self, index: u32) -> Option<&str> {
        let property = self.collection.get_property(index as u16)?;

        if property.data_type == DataType::String || property.data_type == DataType::Json {
            self.object.read_string(property.offset)
        } else {
            None
        }
    }

    #[inline]
    fn read_blob(&self, index: u32) -> Option<Cow<'_, [u8]>> {
        let offset = self.get_offset(index, DataType::ByteList)?;
        self.object.read_dynamic(offset).map(Cow::Borrowed)
    }

    fn read_object(&self, index: u32) -> Option<Self::ObjectReader<'_>> {
        let property = self.get_property(index)?;
        if property.data_type != DataType::Object {
            return None;
        }

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
        if self.data_type == DataType::Byte {
            self.list
                .read_byte(index * DataType::Byte.static_size() as u32)
        } else {
            0
        }
    }

    #[inline]
    fn read_bool(&self, index: u32) -> Option<bool> {
        if self.data_type == DataType::Bool {
            self.list
                .read_bool(index * DataType::Bool.static_size() as u32)
        } else {
            None
        }
    }

    #[inline]
    fn read_int(&self, index: u32) -> i32 {
        if self.data_type == DataType::Int {
            self.list
                .read_int(index * DataType::Int.static_size() as u32)
        } else {
            NULL_INT
        }
    }

    #[inline]
    fn read_float(&self, index: u32) -> f32 {
        if self.data_type == DataType::Float {
            self.list
                .read_float(index * DataType::Float.static_size() as u32)
        } else {
            NULL_FLOAT
        }
    }

    #[inline]
    fn read_long(&self, index: u32) -> i64 {
        if self.data_type == DataType::Long {
            self.list
                .read_long(index * DataType::Long.static_size() as u32)
        } else {
            NULL_LONG
        }
    }

    #[inline]
    fn read_double(&self, index: u32) -> f64 {
        if self.data_type == DataType::Double {
            self.list
                .read_double(index * DataType::Double.static_size() as u32)
        } else {
            NULL_DOUBLE
        }
    }

    #[inline]
    fn read_string(&self, index: u32) -> Option<&'a str> {
        if self.data_type == DataType::String {
            self.list
                .read_string(index * DataType::String.static_size() as u32)
        } else {
            None
        }
    }

    fn read_blob(&self, _index: u32) -> Option<Cow<'_, [u8]>> {
        None // nested lists are not supported
    }

    fn read_object(&self, index: u32) -> Option<Self::ObjectReader<'_>> {
        if self.data_type != DataType::Object {
            return None;
        }

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

#[cfg(test)]
mod test {
    use super::*;
    use crate::core::data_type::DataType::*;
    use crate::native::native_collection::NativeProperty;

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

    fn get_collection(prop_types: Vec<DataType>) -> NativeCollection {
        let mut properties = vec![];
        let mut offset = 0;
        for prop_type in prop_types {
            properties.push((
                "".to_string(),
                NativeProperty::new(prop_type, offset, Some(0)),
            ));
            offset += prop_type.static_size() as u32;
        }
        NativeCollection::new(0, "", None, properties, vec![], None)
    }

    #[test]
    fn test_reader_id_name() {
        let collection = NativeCollection::new(0, "", Some("myid"), vec![], vec![], None);
        let reader = NativeReader::new(
            0,
            IsarDeserializer::from_bytes(&[0, 0, 0]),
            &collection,
            &[],
        );
        assert_eq!(reader.id_name(), Some("myid"));
    }

    #[test]
    fn test_reader_properties() {
        let p1 = NativeProperty::new(Int, 0, None);
        let p2 = NativeProperty::new(String, 4, None);
        let collection = NativeCollection::new(
            0,
            "",
            None,
            vec![
                ("prop1".to_string(), p1.clone()),
                ("prop2".to_string(), p2.clone()),
            ],
            vec![],
            None,
        );

        let reader = NativeReader::new(
            0,
            IsarDeserializer::from_bytes(&[0, 0, 0]),
            &collection,
            &[],
        );
        let properties = reader.properties().collect::<Vec<_>>();
        assert_eq!(properties.len(), 2);
        assert_eq!(properties[0], ("prop1", Int));
        assert_eq!(properties[1], ("prop2", String));
    }

    #[test]
    fn test_reader_read_id() {
        let col: NativeCollection = get_collection(vec![]);
        let bytes = [0, 0, 0];
        let reader = NativeReader::new(55, IsarDeserializer::from_bytes(&bytes), &col, &[]);

        assert_eq!(reader.read_id(), 55);
    }

    #[test]
    fn test_reader_read_bool() {
        let col: NativeCollection = get_collection(vec![Bool, Byte, Bool, Bool]);
        let bytes = [4, 0, 0, 1, 1, 215, 0];
        let reader = NativeReader::new(0, IsarDeserializer::from_bytes(&bytes), &col, &[]);

        assert_eq!(reader.read_bool(1), Some(true));
        assert_eq!(reader.read_bool(2), None);
        assert_eq!(reader.read_bool(3), None);
        assert_eq!(reader.read_bool(4), Some(false));
        assert_eq!(reader.read_bool(5), None);

        assert_eq!(reader.is_null(1), false);
        assert_eq!(reader.is_null(3), true);
        assert_eq!(reader.is_null(4), false);
        assert_eq!(reader.is_null(5), true);
    }

    #[test]
    fn test_reader_read_byte() {
        let col: NativeCollection = get_collection(vec![Bool, Byte, Byte]);
        let bytes = [3, 0, 0, 1, 255, 0];
        let reader = NativeReader::new(0, IsarDeserializer::from_bytes(&bytes), &col, &[]);

        assert_eq!(reader.read_byte(1), 0);
        assert_eq!(reader.read_byte(2), 255);
        assert_eq!(reader.read_byte(3), 0);
        assert_eq!(reader.read_byte(4), 0);

        assert_eq!(reader.is_null(2), false);
        assert_eq!(reader.is_null(3), false);
        assert_eq!(reader.is_null(4), true);
    }

    #[test]
    fn test_reader_read_int() {
        let col: NativeCollection = get_collection(vec![Int, Byte, Int]);
        let bytes = [9, 0, 0, 44, 0, 0, 0, 1, 123, 0, 0, 0];
        let reader = NativeReader::new(0, IsarDeserializer::from_bytes(&bytes), &col, &[]);

        assert_eq!(reader.read_int(1), 44);
        assert_eq!(reader.read_int(2), NULL_INT);
        assert_eq!(reader.read_int(3), 123);
        assert_eq!(reader.read_int(4), NULL_INT);

        assert_eq!(reader.is_null(1), false);
        assert_eq!(reader.is_null(2), false);
        assert_eq!(reader.is_null(3), false);
        assert_eq!(reader.is_null(4), true);
    }

    #[test]
    fn test_reader_read_float() {
        let col: NativeCollection = get_collection(vec![Float, Byte, Float]);
        let bytes = concat!(
            [9, 0, 0],
            f32::NEG_INFINITY.to_le_bytes(),
            [1],
            123.123f32.to_le_bytes()
        );
        let reader = NativeReader::new(0, IsarDeserializer::from_bytes(&bytes), &col, &[]);

        assert_eq!(reader.read_float(1), f32::NEG_INFINITY);
        assert_eq!(reader.read_float(2).is_nan(), true);
        assert_eq!(reader.read_float(3), 123.123);
        assert_eq!(reader.read_float(4).is_nan(), true);

        assert_eq!(reader.is_null(1), false);
        assert_eq!(reader.is_null(2), false);
        assert_eq!(reader.is_null(3), false);
        assert_eq!(reader.is_null(4), true);
    }

    #[test]
    fn test_reader_read_long() {
        let col: NativeCollection = get_collection(vec![Long, Byte, Long]);
        let bytes = concat!(
            [17, 0, 0],
            i64::MAX.to_le_bytes(),
            [1],
            123i64.to_le_bytes()
        );
        let reader = NativeReader::new(0, IsarDeserializer::from_bytes(&bytes), &col, &[]);

        assert_eq!(reader.read_long(1), i64::MAX);
        assert_eq!(reader.read_long(2), NULL_LONG);
        assert_eq!(reader.read_long(3), 123);
        assert_eq!(reader.read_long(4), NULL_LONG);

        assert_eq!(reader.is_null(1), false);
        assert_eq!(reader.is_null(2), false);
        assert_eq!(reader.is_null(3), false);
        assert_eq!(reader.is_null(4), true);
    }

    #[test]
    fn test_reader_read_double() {
        let col: NativeCollection = get_collection(vec![Double, Byte, Double]);
        let bytes = concat!(
            [17, 0, 0],
            f64::NEG_INFINITY.to_le_bytes(),
            [1],
            123.123f64.to_le_bytes()
        );
        let reader = NativeReader::new(0, IsarDeserializer::from_bytes(&bytes), &col, &[]);

        assert_eq!(reader.read_double(1), f64::NEG_INFINITY);
        assert_eq!(reader.read_double(2).is_nan(), true);
        assert_eq!(reader.read_double(3), 123.123);
        assert_eq!(reader.read_double(4).is_nan(), true);

        assert_eq!(reader.is_null(1), false);
        assert_eq!(reader.is_null(2), false);
        assert_eq!(reader.is_null(3), false);
        assert_eq!(reader.is_null(4), true);
    }

    #[test]
    fn test_reader_read_string() {
        let col: NativeCollection = get_collection(vec![String, Byte]);
        let bytes = [4, 0, 0, 4, 0, 0, 1, 3, 0, 0, 97, 98, 99];
        let reader = NativeReader::new(0, IsarDeserializer::from_bytes(&bytes), &col, &[]);

        assert_eq!(reader.read_string(1), Some("abc"));
        assert_eq!(reader.read_string(2), None);
        assert_eq!(reader.read_string(3), None);

        assert_eq!(reader.is_null(1), false);
        assert_eq!(reader.is_null(2), false);
        assert_eq!(reader.is_null(4), true);
    }

    #[test]
    fn test_reader_read_blob() {
        let col: NativeCollection = get_collection(vec![ByteList, Byte]);
        let bytes = [4, 0, 0, 4, 0, 0, 1, 3, 0, 0, 97, 98, 99];
        let reader = NativeReader::new(0, IsarDeserializer::from_bytes(&bytes), &col, &[]);

        assert_eq!(
            reader.read_blob(1),
            Some(Cow::Borrowed(&[97u8, 98, 99][..]))
        );
        assert_eq!(reader.read_blob(2), None);
        assert_eq!(reader.read_blob(3), None);

        assert_eq!(reader.is_null(1), false);
        assert_eq!(reader.is_null(2), false);
        assert_eq!(reader.is_null(3), true);
    }

    #[test]
    fn test_reader_read_object() {
        let col1: NativeCollection = get_collection(vec![Object, Bool, String]);
        let col2: NativeCollection = get_collection(vec![Bool, String, Int]);
        let bytes = concat!(
            [7, 0, 0, 7, 0, 0, 1, 20, 0, 0],
            [4, 0, 0, 1, 4, 0, 0, 3, 0, 0, 97, 98, 99],
            [1, 0, 0, 100]
        );
        let cols = [col2];
        let reader = NativeReader::new(0, IsarDeserializer::from_bytes(&bytes), &col1, &cols);

        let nested = reader.read_object(1).unwrap();
        assert_eq!(nested.read_bool(1), Some(true));
        assert_eq!(nested.read_string(2), Some("abc"));
        assert_eq!(nested.read_int(3), NULL_INT);

        assert_eq!(reader.read_bool(2), Some(true));
        assert_eq!(reader.read_string(3), Some("d"));
    }

    /*#[test]
    fn test_reader_read_list() {
        let col: NativeCollection = get_collection(vec![IntList, Byte, String]);
        let bytes = concat!(
            [7, 0, 0, 7, 0, 0, 55, 20, 0, 0],
            [6, 0, 0, 7, 0, 0, 13, 0, 0, 3, 0, 0, 97, 98, 99, 2, 0, 0, 100, 101],
            [1, 0, 0, 102]
        );
        let reader = NativeReader::new(0, IsarDeserializer::from_bytes(&bytes), &col1, &cols);

        let (list, len) = reader.read_list(1).unwrap();
        assert_eq!(nested.read_bool(1), Some(true));
        assert_eq!(nested.read_string(2), Some("abc"));
        assert_eq!(nested.read_int(3), NULL_INT);

        assert_eq!(reader.read_bool(2), Some(true));
        assert_eq!(reader.read_string(3), Some("d"));
    }*/
}
