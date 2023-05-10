use super::isar_serializer::IsarSerializer;
use super::native_collection::{NativeCollection, NativeProperty};
use super::native_insert::NativeInsert;
use crate::core::data_type::DataType;
use crate::core::writer::IsarWriter;
use serde_json::Value;

pub(crate) trait WriterImpl<'a> {
    fn next_property(&mut self) -> Option<NativeProperty>;

    fn get_collections(&self) -> &'a [NativeCollection];

    fn get_serializer(&mut self) -> &mut IsarSerializer;

    fn next_property_or_write_null(&mut self, data_type: DataType) -> Option<NativeProperty> {
        if let Some(property) = self.next_property() {
            if property.data_type == data_type {
                return Some(property);
            } else {
                self.get_serializer()
                    .write_null(property.offset, property.data_type)
            }
        }
        None
    }

    fn write_remaining_null(&mut self) {
        while let Some(property) = self.next_property() {
            self.get_serializer()
                .write_null(property.offset, property.data_type);
        }
    }
}

impl<'a, T: WriterImpl<'a>> IsarWriter<'a> for T {
    type ObjectWriter = NativeObjectWriter<'a>;

    type ListWriter = NativeListWriter<'a>;

    #[inline]
    fn write_null(&mut self) {
        if let Some(property) = self.next_property() {
            self.get_serializer()
                .write_null(property.offset, property.data_type);
        }
    }

    #[inline]
    fn write_bool(&mut self, value: Option<bool>) {
        if let Some(property) = self.next_property_or_write_null(DataType::Bool) {
            self.get_serializer().write_bool(property.offset, value);
        }
    }

    #[inline]
    fn write_byte(&mut self, value: u8) {
        if let Some(property) = self.next_property_or_write_null(DataType::Byte) {
            self.get_serializer().write_byte(property.offset, value);
        }
    }

    #[inline]
    fn write_int(&mut self, value: i32) {
        if let Some(property) = self.next_property_or_write_null(DataType::Int) {
            self.get_serializer().write_int(property.offset, value);
        }
    }

    #[inline]
    fn write_float(&mut self, value: f32) {
        if let Some(property) = self.next_property_or_write_null(DataType::Float) {
            self.get_serializer().write_float(property.offset, value);
        }
    }

    #[inline]
    fn write_long(&mut self, value: i64) {
        if let Some(property) = self.next_property_or_write_null(DataType::Long) {
            self.get_serializer().write_long(property.offset, value);
        }
    }

    #[inline]
    fn write_double(&mut self, value: f64) {
        if let Some(property) = self.next_property_or_write_null(DataType::Double) {
            self.get_serializer().write_double(property.offset, value);
        }
    }

    #[inline]
    fn write_string(&mut self, value: &str) {
        if let Some(property) = self.next_property_or_write_null(DataType::String) {
            self.get_serializer()
                .write_dynamic(property.offset, value.as_bytes());
        }
    }

    #[inline]
    fn write_json(&mut self, value: &Value) {
        if let Some(property) = self.next_property_or_write_null(DataType::Json) {
            if let Ok(bytes) = serde_json::to_vec(value) {
                self.get_serializer().write_dynamic(property.offset, &bytes);
            } else {
                self.get_serializer()
                    .write_null(property.offset, DataType::Json);
            }
        }
    }

    #[inline]
    fn write_byte_list(&mut self, value: &[u8]) {
        if let Some(property) = self.next_property_or_write_null(DataType::ByteList) {
            self.get_serializer().write_dynamic(property.offset, value);
        }
    }

    fn begin_object(&mut self) -> Option<Self::ObjectWriter> {
        let property = self.next_property_or_write_null(DataType::Object)?;

        let collection_index = property.embedded_collection_index.unwrap();
        let collections = self.get_collections();
        let collection = &collections[collection_index as usize];

        let object = self
            .get_serializer()
            .begin_nested(property.offset, collection.static_size);
        let writer = NativeObjectWriter::new(collection, collections, object);
        Some(writer)
    }

    fn end_object(&mut self, mut writer: Self::ObjectWriter) {
        writer.write_remaining_null();
        self.get_serializer().end_nested(writer.object);
    }

    fn begin_list(&mut self, length: u32) -> Option<Self::ListWriter> {
        let property = self.next_property()?;
        if !property.data_type.is_list() {
            self.get_serializer()
                .write_null(property.offset, property.data_type);
            return None;
        }

        let element_type = property.data_type.element_type().unwrap();
        let list = self
            .get_serializer()
            .begin_nested(property.offset, element_type.static_size() as u32 * length);
        let writer = NativeListWriter::new(
            element_type,
            property.embedded_collection_index,
            self.get_collections(),
            list,
            length,
        );
        Some(writer)
    }

    fn end_list(&mut self, mut writer: Self::ListWriter) {
        writer.write_remaining_null();
        self.get_serializer().end_nested(writer.list);
    }
}

impl<'a> WriterImpl<'a> for NativeInsert<'a> {
    #[inline]
    fn next_property(&mut self) -> Option<NativeProperty> {
        self.collection.get_property(self.property_index)
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
    property_index: u32,
}

impl<'a> NativeObjectWriter<'a> {
    pub fn new(
        collection: &'a NativeCollection,
        all_collections: &'a [NativeCollection],
        object: IsarSerializer,
    ) -> Self {
        Self {
            collection,
            all_collections,
            object,
            property_index: 1, // skip id
        }
    }
}

impl<'a> WriterImpl<'a> for NativeObjectWriter<'a> {
    #[inline]
    fn next_property(&mut self) -> Option<NativeProperty> {
        let property = self.collection.get_property(self.property_index)?;
        self.property_index += 1;
        Some(property)
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
    index: u32,
    length: u32,
}

impl<'a> NativeListWriter<'a> {
    pub fn new(
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
            index: 0,
            length,
        }
    }
}

impl<'a> WriterImpl<'a> for NativeListWriter<'a> {
    #[inline]
    fn next_property(&mut self) -> Option<NativeProperty> {
        if self.index >= self.length {
            return None;
        }

        let property = NativeProperty {
            data_type: self.element_type,
            offset: self.index * self.element_type.static_size() as u32,
            embedded_collection_index: self.embedded_collection_index,
        };
        self.index += 1;
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
