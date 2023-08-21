use std::iter::empty;

use super::isar_serializer::IsarSerializer;
use super::native_collection::NativeCollection;
use super::native_insert::NativeInsert;
use crate::core::data_type::DataType;
use crate::core::writer::IsarWriter;

pub(crate) trait WriterImpl<'a> {
    fn id_name(&self) -> Option<&str>;

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> + 'a;

    fn get_property(&self, index: u32) -> Option<(DataType, u32, Option<u16>)>;

    #[inline]
    fn get_offset(&self, index: u32, data_type: DataType) -> Option<u32> {
        if let Some((property_type, offset, _)) = self.get_property(index) {
            if property_type == data_type {
                return Some(offset);
            }
        }
        None
    }

    fn get_collections(&self) -> &'a [NativeCollection];

    fn get_serializer(&mut self) -> &mut IsarSerializer;
}

impl<'a, T: WriterImpl<'a>> IsarWriter<'a> for T {
    type ObjectWriter = NativeObjectWriter<'a>;

    type ListWriter = NativeListWriter<'a>;

    fn id_name(&self) -> Option<&str> {
        self.id_name()
    }

    #[inline]
    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> + 'a {
        self.properties()
    }

    #[inline]
    fn write_null(&mut self, index: u32) {
        if let Some((data_type, offset, _)) = self.get_property(index) {
            self.get_serializer().write_null(offset, data_type);
        }
    }

    #[inline]
    fn write_bool(&mut self, index: u32, value: bool) {
        if let Some(offset) = self.get_offset(index, DataType::Bool) {
            self.get_serializer().write_bool(offset, value);
        }
    }

    #[inline]
    fn write_byte(&mut self, index: u32, value: u8) {
        if let Some(offset) = self.get_offset(index, DataType::Byte) {
            self.get_serializer().write_byte(offset, value);
        }
    }

    #[inline]
    fn write_int(&mut self, index: u32, value: i32) {
        if let Some(offset) = self.get_offset(index, DataType::Int) {
            self.get_serializer().write_int(offset, value);
        }
    }

    #[inline]
    fn write_float(&mut self, index: u32, value: f32) {
        if let Some(offset) = self.get_offset(index, DataType::Float) {
            self.get_serializer().write_float(offset, value);
        }
    }

    #[inline]
    fn write_long(&mut self, index: u32, value: i64) {
        if let Some(offset) = self.get_offset(index, DataType::Long) {
            self.get_serializer().write_long(offset, value);
        }
    }

    #[inline]
    fn write_double(&mut self, index: u32, value: f64) {
        if let Some(offset) = self.get_offset(index, DataType::Double) {
            self.get_serializer().write_double(offset, value);
        }
    }

    #[inline]
    fn write_string(&mut self, index: u32, value: &str) {
        if let Some((data_type, index, _)) = self.get_property(index) {
            if data_type == DataType::String || data_type == DataType::Json {
                self.get_serializer().write_dynamic(index, value.as_bytes());
            }
        }
    }

    #[inline]
    fn write_byte_list(&mut self, index: u32, value: &[u8]) {
        if let Some(offset) = self.get_offset(index, DataType::ByteList) {
            self.get_serializer().write_dynamic(offset, value);
        }
    }

    fn begin_object(&mut self, index: u32) -> Option<Self::ObjectWriter> {
        let (data_type, offset, collection_index) = self.get_property(index)?;
        if data_type == DataType::Object {
            let collections = self.get_collections();
            let collection = &collections[collection_index? as usize];

            let object = self
                .get_serializer()
                .begin_nested(offset, collection.static_size);
            let writer = NativeObjectWriter::new(collection, collections, object);
            Some(writer)
        } else {
            None
        }
    }

    fn end_object(&mut self, writer: Self::ObjectWriter) {
        self.get_serializer().end_nested(writer.object);
    }

    fn begin_list(&mut self, index: u32, length: u32) -> Option<Self::ListWriter> {
        let (data_type, offset, embedded_collection_index) = self.get_property(index)?;
        if let Some(element_type) = data_type.element_type() {
            let list = self
                .get_serializer()
                .begin_nested(offset, element_type.static_size() as u32 * length);
            let writer = NativeListWriter::new(
                element_type,
                embedded_collection_index,
                self.get_collections(),
                list,
                length,
            );
            Some(writer)
        } else {
            self.write_null(index);
            None
        }
    }

    fn end_list(&mut self, writer: Self::ListWriter) {
        self.get_serializer().end_nested(writer.list);
    }
}

impl<'a> WriterImpl<'a> for NativeInsert<'a> {
    fn id_name(&self) -> Option<&str> {
        self.collection.id_name.as_deref()
    }

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> + 'a {
        self.collection
            .properties
            .iter()
            .map(|(name, p)| (name.as_str(), p.data_type))
    }

    #[inline]
    fn get_property(&self, index: u32) -> Option<(DataType, u32, Option<u16>)> {
        let property = self.collection.get_property(index as u16)?;
        Some((
            property.data_type,
            property.offset,
            property.embedded_collection_index,
        ))
    }

    #[inline]
    fn get_collections(&self) -> &'a [NativeCollection] {
        &self.all_collections
    }

    #[inline]
    fn get_serializer(&mut self) -> &mut IsarSerializer {
        &mut self.object
    }
}

pub struct NativeObjectWriter<'a> {
    collection: &'a NativeCollection,
    all_collections: &'a [NativeCollection],
    object: IsarSerializer,
}

impl<'a> NativeObjectWriter<'a> {
    pub(crate) fn new(
        collection: &'a NativeCollection,
        all_collections: &'a [NativeCollection],
        object: IsarSerializer,
    ) -> Self {
        Self {
            collection,
            all_collections,
            object,
        }
    }
}

impl<'a> WriterImpl<'a> for NativeObjectWriter<'a> {
    fn id_name(&self) -> Option<&str> {
        None
    }

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> + 'a {
        self.collection
            .properties
            .iter()
            .map(|(name, p)| (name.as_str(), p.data_type))
    }

    #[inline]
    fn get_property(&self, index: u32) -> Option<(DataType, u32, Option<u16>)> {
        let property = self.collection.get_property(index as u16)?;
        Some((
            property.data_type,
            property.offset,
            property.embedded_collection_index,
        ))
    }

    #[inline]
    fn get_collections(&self) -> &'a [NativeCollection] {
        self.all_collections
    }

    #[inline]
    fn get_serializer(&mut self) -> &mut IsarSerializer {
        &mut self.object
    }
}

pub struct NativeListWriter<'a> {
    element_type: DataType,
    embedded_collection_index: Option<u16>,
    list: IsarSerializer,
    all_collections: &'a [NativeCollection],
    length: u32,
}

impl<'a> NativeListWriter<'a> {
    pub(crate) fn new(
        element_type: DataType,
        embedded_collection_index: Option<u16>,
        all_collections: &'a [NativeCollection],
        list: IsarSerializer,
        length: u32,
    ) -> Self {
        Self {
            element_type,
            embedded_collection_index,
            list,
            all_collections,
            length,
        }
    }
}

impl<'a> WriterImpl<'a> for NativeListWriter<'a> {
    fn id_name(&self) -> Option<&str> {
        None
    }

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> + 'a {
        empty().map(|_: ()| ("", DataType::Object)) // weird fix
    }

    #[inline]
    fn get_property(&self, index: u32) -> Option<(DataType, u32, Option<u16>)> {
        if index >= self.length {
            return None;
        }

        let property = (
            self.element_type,
            index * self.element_type.static_size() as u32,
            self.embedded_collection_index,
        );
        Some(property)
    }

    #[inline]
    fn get_collections(&self) -> &'a [NativeCollection] {
        self.all_collections
    }

    #[inline]
    fn get_serializer(&mut self) -> &mut IsarSerializer {
        &mut self.list
    }
}

/*#[cfg(test)]
mod tests {
    use super::*;

    macro_rules! builder {
        ($var:ident, $prop:ident, $type:ident) => {
            let $prop = NativeProperty::debug($type, 3);
            let props = vec![NativeProperty::debug(Byte, 2), $prop.clone()];
            let mut $var = ObjectBuilder::new(&props, None);
            $var.write_byte(2, 255);
        };
    }

    fn offset_size(value: usize) -> [u8; 3] {
        let mut bytes = [0; 3];
        bytes[2] = (value >> 16) as u8;
        bytes[1] = (value >> 8) as u8;
        bytes[0] = value as u8;
        bytes
    }

    #[test]
    pub fn test_write_null() {
        builder!(b, p, Bool);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, 0]);

        builder!(b, p, Byte);
        b.write_null(p.offset, p.data_type);
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, 0]);

        builder!(b, p, Int);
        b.write_null(p.offset, p.data_type);
        let mut bytes = vec![7, 0, 255];
        bytes.extend_from_slice(&IsarObject::NULL_INT.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, Float);
        b.write_null(p.offset, p.data_type);
        let mut bytes = vec![7, 0, 255];
        bytes.extend_from_slice(&IsarObject::NULL_FLOAT.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, Long);
        b.write_null(p.offset, p.data_type);
        let mut bytes = vec![11, 0, 255];
        bytes.extend_from_slice(&IsarObject::NULL_LONG.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, Double);
        b.write_null(p.offset, p.data_type);
        let mut bytes = vec![11, 0, 255];
        bytes.extend_from_slice(&IsarObject::NULL_DOUBLE.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        let list_types = vec![
            String, Object, ByteList, IntList, FloatList, LongList, DoubleList, StringList,
            ObjectList,
        ];

        for list_type in list_types {
            builder!(b, p, list_type);
            b.write_null(p.offset, p.data_type);
            let bytes = vec![6, 0, 255, 0, 0, 0];
            assert_eq!(b.finish().as_bytes(), &bytes);
        }
    }

    #[test]
    pub fn test_write_bool() {
        builder!(b, p, Bool);
        b.write_bool(p.offset, Some(true));
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, IsarObject::TRUE_BOOL]);

        builder!(b, p, Bool);
        b.write_bool(p.offset, Some(false));
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, IsarObject::FALSE_BOOL]);

        builder!(b, p, Bool);
        b.write_bool(p.offset, None);
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, IsarObject::NULL_BOOL]);
    }

    #[test]
    pub fn test_write_byte() {
        builder!(b, p, Byte);
        b.write_byte(p.offset, 0);
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, 0]);

        builder!(b, p, Byte);
        b.write_byte(p.offset, 123);
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, 123]);

        builder!(b, p, Byte);
        b.write_byte(p.offset, 255);
        assert_eq!(b.finish().as_bytes(), &[4, 0, 255, 255]);
    }

    #[test]
    pub fn test_write_int() {
        builder!(b, p, Int);
        b.write_int(p.offset, 123);
        assert_eq!(b.finish().as_bytes(), &[7, 0, 255, 123, 0, 0, 0])
    }

    #[test]
    pub fn test_write_float() {
        builder!(b, p, Float);
        b.write_float(p.offset, 123.123);
        let mut bytes = vec![7, 0, 255];
        bytes.extend_from_slice(&123.123f32.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, Float);
        b.write_float(p.offset, f32::NAN);
        let mut bytes = vec![7, 0, 255];
        bytes.extend_from_slice(&f32::NAN.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_long() {
        builder!(b, p, Long);
        b.write_long(p.offset, 123123);
        let mut bytes = vec![11, 0, 255];
        bytes.extend_from_slice(&123123i64.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes)
    }

    #[test]
    pub fn test_write_double() {
        builder!(b, p, Double);
        b.write_double(p.offset, 123.123);
        let mut bytes = vec![11, 0, 255];
        bytes.extend_from_slice(&123.123f64.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, Double);
        b.write_double(p.offset, f64::NAN);
        let mut bytes = vec![11, 0, 255];
        bytes.extend_from_slice(&f64::NAN.to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_string() {
        builder!(b, p, String);
        b.write_string(p.offset, Some("hello"));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(5));
        bytes.extend_from_slice(b"hello");
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, String);
        b.write_string(p.offset, Some(""));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, String);
        b.write_string(p.offset, None);
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_object() {
        builder!(b, p, Object);
        let object = IsarObject::from_bytes(&[3, 0, 111]);
        b.write_object(p.offset, Some(object));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(3));
        bytes.extend_from_slice(&[3, 0, 111]);
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_multiple_static_types() {
        let props = vec![
            Property::debug(DataType::Long, 2),
            Property::debug(DataType::Byte, 10),
            Property::debug(DataType::Int, 11),
            Property::debug(DataType::Float, 15),
            Property::debug(DataType::Long, 19),
            Property::debug(DataType::Double, 27),
        ];
        let mut b = ObjectBuilder::new(&props, None);

        b.write_long(props.get(0).unwrap().offset, 1);
        b.write_byte(props.get(1).unwrap().offset, u8::MAX);
        b.write_int(props.get(2).unwrap().offset, i32::MAX);
        b.write_float(props.get(3).unwrap().offset, std::f32::consts::E);
        b.write_long(props.get(4).unwrap().offset, i64::MIN);
        b.write_double(props.get(5).unwrap().offset, std::f64::consts::PI);

        let mut bytes = vec![35, 0, 1, 0, 0, 0, 0, 0, 0, 0];
        bytes.push(u8::MAX);
        bytes.extend_from_slice(&i32::MAX.to_le_bytes());
        bytes.extend_from_slice(&std::f32::consts::E.to_le_bytes());
        bytes.extend_from_slice(&i64::MIN.to_le_bytes());
        bytes.extend_from_slice(&std::f64::consts::PI.to_le_bytes());

        assert_eq!(b.finish().as_bytes(), bytes);
    }

    #[test]
    pub fn test_write_byte_list() {
        builder!(b, p, ByteList);
        b.write_byte_list(p.offset, Some(&[1, 2, 3]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(3));
        bytes.extend_from_slice(&[1, 2, 3]);
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, ByteList);
        b.write_byte_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_int_list() {
        builder!(b, p, IntList);
        b.write_int_list(p.offset, Some(&[1, -10]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(2));
        bytes.extend_from_slice(&1i32.to_le_bytes());
        bytes.extend_from_slice(&(-10i32).to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, IntList);
        b.write_int_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_float_list() {
        builder!(b, p, FloatList);
        b.write_float_list(p.offset, Some(&[1.1, -10.10]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(2));
        bytes.extend_from_slice(&1.1f32.to_le_bytes());
        bytes.extend_from_slice(&(-10.10f32).to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, FloatList);
        b.write_float_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_long_list() {
        builder!(b, p, LongList);
        b.write_long_list(p.offset, Some(&[1, -10]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(2));
        bytes.extend_from_slice(&1i64.to_le_bytes());
        bytes.extend_from_slice(&(-10i64).to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, LongList);
        b.write_long_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_double_list() {
        builder!(b, p, DoubleList);
        b.write_double_list(p.offset, Some(&[1.1, -10.10]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(2));
        bytes.extend_from_slice(&1.1f64.to_le_bytes());
        bytes.extend_from_slice(&(-10.10f64).to_le_bytes());
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, DoubleList);
        b.write_double_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_string_list() {
        builder!(b, p, StringList);
        b.write_string_list(p.offset, Some(&[Some("abc"), None, Some(""), Some("de")]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(4));
        bytes.extend_from_slice(&offset_size(4));
        bytes.extend_from_slice(&offset_size(0));
        bytes.extend_from_slice(&offset_size(1));
        bytes.extend_from_slice(&offset_size(3));
        bytes.extend_from_slice(b"abcde");
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, StringList);
        b.write_string_list(p.offset, Some(&[None]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(1));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, StringList);
        b.write_string_list(p.offset, Some(&[Some("")]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(1));
        bytes.extend_from_slice(&offset_size(1));
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, StringList);
        b.write_string_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }

    #[test]
    pub fn test_write_object_list() {
        builder!(b, p, ObjectList);
        let object1 = IsarObject::from_bytes(&[2, 0]);
        let object2 = IsarObject::from_bytes(&[3, 0, 123]);
        b.write_object_list(p.offset, Some(&[Some(object1), None, Some(object2)]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(3));
        bytes.extend_from_slice(&offset_size(3));
        bytes.extend_from_slice(&offset_size(0));
        bytes.extend_from_slice(&offset_size(4));
        bytes.extend_from_slice(&[2, 0, 3, 0, 123]);
        assert_eq!(b.finish().as_bytes(), &bytes);

        builder!(b, p, ObjectList);
        b.write_object_list(p.offset, Some(&[]));
        let mut bytes = vec![6, 0, 255];
        bytes.extend_from_slice(&offset_size(6));
        bytes.extend_from_slice(&offset_size(0));
        assert_eq!(b.finish().as_bytes(), &bytes);
    }
}
*/
