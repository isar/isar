use crate::error::{IsarError, Result};
use crate::object::data_type::DataType;
use crate::object::isar_object::IsarObject;
use crate::object::object_builder::ObjectBuilder;
use intmap::IntMap;
use itertools::Itertools;
use serde_json::{json, Map, Value};

use super::property::Property;

pub struct JsonEncodeDecode {}

impl<'a> JsonEncodeDecode {
    #[inline(never)]
    pub fn encode(
        properties: &[Property],
        embedded_properties: &IntMap<Vec<Property>>,
        object: IsarObject,
        primitive_null: bool,
    ) -> Map<String, Value> {
        let mut object_map = Map::new();

        for property in properties {
            let value = if primitive_null && object.is_null(property.offset, property.data_type) {
                Value::Null
            } else {
                match property.data_type {
                    DataType::Bool => {
                        json!(object.read_bool(property.offset))
                    }
                    DataType::Byte => {
                        json!(object.read_byte(property.offset))
                    }
                    DataType::Int => json!(object.read_int(property.offset)),
                    DataType::Float => json!(object.read_float(property.offset)),
                    DataType::Long => json!(object.read_long(property.offset)),
                    DataType::Double => json!(object.read_double(property.offset)),
                    DataType::String => json!(object.read_string(property.offset)),
                    DataType::Object => {
                        let properties = embedded_properties
                            .get(property.target_id.unwrap())
                            .unwrap();
                        Self::object_to_value(
                            properties,
                            embedded_properties,
                            object.read_object(property.offset),
                            primitive_null,
                        )
                    }
                    DataType::BoolList => json!(object.read_bool_list(property.offset).unwrap()),
                    DataType::ByteList => json!(object.read_byte_list(property.offset).unwrap()),
                    DataType::IntList => {
                        if primitive_null {
                            json!(object.read_int_or_null_list(property.offset))
                        } else {
                            json!(object.read_int_list(property.offset))
                        }
                    }
                    DataType::FloatList => {
                        if primitive_null {
                            json!(object.read_float_or_null_list(property.offset))
                        } else {
                            json!(object.read_float_list(property.offset))
                        }
                    }
                    DataType::LongList => {
                        if primitive_null {
                            json!(object.read_long_or_null_list(property.offset))
                        } else {
                            json!(object.read_long_list(property.offset))
                        }
                    }
                    DataType::DoubleList => {
                        if primitive_null {
                            json!(object.read_double_or_null_list(property.offset))
                        } else {
                            json!(object.read_double_list(property.offset))
                        }
                    }
                    DataType::StringList => json!(object.read_string_list(property.offset)),
                    DataType::ObjectList => {
                        let properties = embedded_properties
                            .get(property.target_id.unwrap())
                            .unwrap();
                        if let Some(objects) = object.read_object_list(property.offset) {
                            let encoded = objects
                                .into_iter()
                                .map(|object| {
                                    Self::object_to_value(
                                        properties,
                                        embedded_properties,
                                        object,
                                        primitive_null,
                                    )
                                })
                                .collect_vec();

                            json!(encoded)
                        } else {
                            Value::Null
                        }
                    }
                }
            };
            object_map.insert(property.name.clone(), value);
        }

        object_map
    }

    fn object_to_value(
        properties: &[Property],
        embedded_properties: &IntMap<Vec<Property>>,
        object: Option<IsarObject>,
        primitive_null: bool,
    ) -> Value {
        if let Some(object) = object {
            let encoded =
                JsonEncodeDecode::encode(properties, embedded_properties, object, primitive_null);
            json!(encoded)
        } else {
            Value::Null
        }
    }

    #[inline(never)]
    pub fn decode(
        properties: &[Property],
        embedded_properties: &IntMap<Vec<Property>>,
        ob: &mut ObjectBuilder,
        json: &Value,
    ) -> Result<()> {
        let object = json.as_object().ok_or(IsarError::InvalidJson {})?;

        for property in properties {
            if let Some(value) = object.get(&property.name) {
                match property.data_type {
                    DataType::Bool => ob.write_bool(property.offset, Self::value_to_bool(value)?),
                    DataType::Byte => ob.write_byte(property.offset, Self::value_to_byte(value)?),
                    DataType::Int => ob.write_int(property.offset, Self::value_to_int(value)?),
                    DataType::Float => {
                        ob.write_float(property.offset, Self::value_to_float(value)?)
                    }
                    DataType::Long => ob.write_long(property.offset, Self::value_to_long(value)?),
                    DataType::Double => {
                        ob.write_double(property.offset, Self::value_to_double(value)?)
                    }
                    DataType::String => {
                        ob.write_string(property.offset, Self::value_to_string(value)?)
                    }
                    DataType::Object => {
                        let builder = Self::value_to_object(
                            value,
                            embedded_properties,
                            property.target_id.unwrap(),
                        )?;
                        ob.write_object(property.offset, builder.as_ref().map(|b| b.finish()));
                    }
                    DataType::BoolList => {
                        let list = Self::value_to_array(value, Self::value_to_bool)?;
                        ob.write_bool_list(property.offset, list.as_deref());
                    }
                    DataType::ByteList => {
                        let list = Self::value_to_array(value, Self::value_to_byte)?;
                        ob.write_byte_list(property.offset, list.as_deref());
                    }
                    DataType::IntList => {
                        let list = Self::value_to_array(value, Self::value_to_int)?;
                        ob.write_int_list(property.offset, list.as_deref());
                    }
                    DataType::FloatList => {
                        let list = Self::value_to_array(value, Self::value_to_float)?;
                        ob.write_float_list(property.offset, list.as_deref());
                    }
                    DataType::LongList => {
                        let list = Self::value_to_array(value, Self::value_to_long)?;
                        ob.write_long_list(property.offset, list.as_deref());
                    }
                    DataType::DoubleList => {
                        let list = Self::value_to_array(value, Self::value_to_double)?;
                        ob.write_double_list(property.offset, list.as_deref());
                    }
                    DataType::StringList => {
                        if value.is_null() {
                            ob.write_string_list(property.offset, None);
                        } else if let Some(list) = value.as_array() {
                            let list: Result<Vec<Option<&str>>> =
                                list.iter().map(Self::value_to_string).collect();
                            ob.write_string_list(property.offset, Some(list?.as_slice()));
                        } else {
                            return Err(IsarError::InvalidJson {});
                        }
                    }
                    DataType::ObjectList => {
                        if value.is_null() {
                            ob.write_object_list(property.offset, None);
                        } else if let Some(list) = value.as_array() {
                            let list: Result<Vec<Option<ObjectBuilder>>> = list
                                .iter()
                                .map(|value| {
                                    Self::value_to_object(
                                        value,
                                        embedded_properties,
                                        property.target_id.unwrap(),
                                    )
                                })
                                .collect();
                            let list = list?;
                            let objects = list
                                .iter()
                                .map(|o| o.as_ref().map(|o| o.finish()))
                                .collect_vec();
                            ob.write_object_list(property.offset, Some(objects.as_slice()));
                        } else {
                            return Err(IsarError::InvalidJson {});
                        }
                    }
                }
            } else {
                ob.write_null(property.offset, property.data_type);
            }
        }

        Ok(())
    }

    fn value_to_bool(value: &Value) -> Result<Option<bool>> {
        if value.is_null() {
            return Ok(None);
        } else if let Some(value) = value.as_bool() {
            return Ok(Some(value));
        };
        Err(IsarError::InvalidJson {})
    }

    fn value_to_byte(value: &Value) -> Result<u8> {
        if value.is_null() {
            return Ok(IsarObject::NULL_BYTE);
        } else if let Some(value) = value.as_i64() {
            if value >= 0 && value <= u8::MAX as i64 {
                return Ok(value as u8);
            }
        }
        Err(IsarError::InvalidJson {})
    }

    fn value_to_int(value: &Value) -> Result<i32> {
        if value.is_null() {
            return Ok(IsarObject::NULL_INT);
        } else if let Some(value) = value.as_i64() {
            if value >= i32::MIN as i64 && value <= i32::MAX as i64 {
                return Ok(value as i32);
            }
        }
        Err(IsarError::InvalidJson {})
    }

    fn value_to_float(value: &Value) -> Result<f32> {
        if value.is_null() {
            return Ok(IsarObject::NULL_FLOAT);
        } else if let Some(value) = value.as_f64() {
            if value >= f32::MIN as f64 && value <= f32::MAX as f64 {
                return Ok(value as f32);
            }
        }
        Err(IsarError::InvalidJson {})
    }

    fn value_to_long(value: &Value) -> Result<i64> {
        if value.is_null() {
            Ok(IsarObject::NULL_LONG)
        } else if let Some(value) = value.as_i64() {
            Ok(value)
        } else {
            Err(IsarError::InvalidJson {})
        }
    }

    fn value_to_double(value: &Value) -> Result<f64> {
        if value.is_null() {
            Ok(IsarObject::NULL_DOUBLE)
        } else if let Some(value) = value.as_f64() {
            Ok(value)
        } else {
            Err(IsarError::InvalidJson {})
        }
    }

    fn value_to_string(value: &Value) -> Result<Option<&str>> {
        if value.is_null() {
            Ok(None)
        } else if let Some(value) = value.as_str() {
            Ok(Some(value))
        } else {
            Err(IsarError::InvalidJson {})
        }
    }

    fn value_to_object(
        value: &Value,
        embedded_properties: &IntMap<Vec<Property>>,
        target_id: u64,
    ) -> Result<Option<ObjectBuilder>> {
        if value.is_null() {
            Ok(None)
        } else {
            let properties = embedded_properties.get(target_id).unwrap();
            let mut embedded_ob = ObjectBuilder::new(properties, None);
            Self::decode(properties, embedded_properties, &mut embedded_ob, value)?;
            Ok(Some(embedded_ob))
        }
    }

    fn value_to_array<T, F>(value: &Value, convert: F) -> Result<Option<Vec<T>>>
    where
        F: Fn(&Value) -> Result<T>,
    {
        if value.is_null() {
            Ok(None)
        } else if let Some(value) = value.as_array() {
            let array: Result<Vec<T>> = value.iter().map(convert).collect();
            Ok(Some(array?))
        } else {
            Err(IsarError::InvalidJson {})
        }
    }
}
