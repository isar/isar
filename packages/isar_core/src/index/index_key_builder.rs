use crate::error::Result;
use crate::index::index_key::IndexKey;
use crate::index::IndexProperty;
use crate::object::data_type::DataType;
use crate::object::isar_object::IsarObject;
use crate::schema::index_schema::IndexType;

pub(crate) struct IndexKeyBuilder<'a> {
    properties: &'a [IndexProperty],
}

impl<'a> IndexKeyBuilder<'a> {
    pub fn new(properties: &'a [IndexProperty]) -> Self {
        Self { properties }
    }

    pub fn create_keys(
        &self,
        object: IsarObject,
        mut callback: impl FnMut(&IndexKey) -> Result<bool>,
    ) -> Result<bool> {
        let first = self.properties.first().unwrap();
        if !first.is_multi_entry() {
            let key = self.create_primitive_key(object);
            callback(&key)?;
            Ok(true)
        } else {
            assert_eq!(self.properties.len(), 1);
            Self::create_list_keys(first, object, &mut callback)
        }
    }

    pub fn create_primitive_key(&self, object: IsarObject) -> IndexKey {
        let mut key = IndexKey::new();
        for index_property in self.properties {
            let property = &index_property.property;

            if index_property.index_type == IndexType::Hash {
                let hash = object.hash_property(
                    property.offset,
                    property.data_type,
                    index_property.case_sensitive,
                    0,
                );
                key.add_hash(hash);
            } else {
                match property.data_type {
                    DataType::Bool | DataType::Byte => {
                        assert_eq!(IsarObject::NULL_BOOL, IsarObject::NULL_BYTE);
                        key.add_byte(object.read_byte(property.offset))
                    }
                    DataType::Int => key.add_int(object.read_int(property.offset)),
                    DataType::Float => key.add_float(object.read_float(property.offset)),
                    DataType::Long => key.add_long(object.read_long(property.offset)),
                    DataType::Double => key.add_double(object.read_double(property.offset)),
                    DataType::String => key.add_string(
                        object.read_string(property.offset),
                        index_property.case_sensitive,
                    ),
                    _ => unreachable!(),
                }
            }
        }
        key
    }

    fn create_list_keys(
        index_property: &IndexProperty,
        object: IsarObject,
        mut callback: impl FnMut(&IndexKey) -> Result<bool>,
    ) -> Result<bool> {
        let mut key = IndexKey::new();
        let property = &index_property.property;
        if object.is_null(property.offset, property.data_type) {
            return Ok(true);
        }
        match property.data_type {
            DataType::BoolList | DataType::ByteList => {
                for value in object.read_byte_list(property.offset).unwrap() {
                    key.truncate(0);
                    key.add_byte(*value);
                    if !callback(&key)? {
                        return Ok(false);
                    }
                }
            }
            DataType::IntList => {
                for value in object.read_int_list(property.offset).unwrap() {
                    key.truncate(0);
                    key.add_int(value);
                    if !callback(&key)? {
                        return Ok(false);
                    }
                }
            }
            DataType::LongList => {
                for value in object.read_long_list(property.offset).unwrap() {
                    key.truncate(0);
                    key.add_long(value);
                    if !callback(&key)? {
                        return Ok(false);
                    }
                }
            }
            DataType::FloatList => {
                for value in object.read_float_list(property.offset).unwrap() {
                    key.truncate(0);
                    key.add_float(value);
                    if !callback(&key)? {
                        return Ok(false);
                    }
                }
            }
            DataType::DoubleList => {
                for value in object.read_double_list(property.offset).unwrap() {
                    key.truncate(0);
                    key.add_double(value);
                    if !callback(&key)? {
                        return Ok(false);
                    }
                }
            }
            DataType::StringList => {
                for value in object.read_string_list(property.offset).unwrap() {
                    key.truncate(0);
                    if index_property.index_type == IndexType::HashElements {
                        let hash = IsarObject::hash_string(value, index_property.case_sensitive, 0);
                        key.add_hash(hash);
                    } else {
                        key.add_string(value, index_property.case_sensitive);
                    }
                    if !callback(&key)? {
                        return Ok(false);
                    }
                }
            }
            _ => unreachable!(),
        }
        Ok(true)
    }
}

#[cfg(test)]
mod tests {}
