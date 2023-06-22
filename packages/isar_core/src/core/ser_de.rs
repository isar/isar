use std::collections::HashMap;

use super::writer::IsarWriter;
use super::{data_type::DataType, reader::IsarReader};
use crate::native::{NULL_INT, NULL_LONG};
use serde::de::{MapAccess, Visitor};
use serde::ser::{SerializeMap, SerializeSeq};
use serde::{Deserialize, Serialize};
use serde_json::Value;

pub struct IsarObjectSerialize<'a, R: IsarReader> {
    id_name: Option<&'a str>,
    reader: &'a R,
}

impl<'a, R: IsarReader> IsarObjectSerialize<'a, R> {
    pub fn new(id_name: Option<&'a str>, reader: &'a R) -> Self {
        IsarObjectSerialize { id_name, reader }
    }
}

impl<'a, R: IsarReader> Serialize for IsarObjectSerialize<'a, R> {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        if let Some(properties) = self.reader.properties() {
            let mut ser = serializer.serialize_map(None)?;
            if let Some(id_name) = self.id_name {
                ser.serialize_entry(id_name, &self.reader.read_id())?;
            }

            for (index, (name, data_type)) in properties.enumerate() {
                match data_type {
                    DataType::Bool => {
                        ser.serialize_entry(name, &self.reader.read_bool(index as u32))?;
                    }
                    DataType::Byte => {
                        ser.serialize_entry(name, &self.reader.read_byte(index as u32))?;
                    }
                    DataType::Int => {
                        let value = self.reader.read_int(index as u32);
                        if value != NULL_INT {
                            ser.serialize_entry(name, &value)?;
                        }
                    }
                    DataType::Float => {
                        let value = self.reader.read_float(index as u32);
                        if !value.is_nan() {
                            ser.serialize_entry(name, &value)?;
                        }
                    }
                    DataType::Long => {
                        let value = self.reader.read_long(index as u32);
                        if value != NULL_LONG {
                            ser.serialize_entry(name, &value)?;
                        }
                    }
                    DataType::Double => {
                        let value = self.reader.read_double(index as u32);
                        if !value.is_nan() {
                            ser.serialize_entry(name, &value)?;
                        }
                    }
                    DataType::String => {
                        if let Some(value) = self.reader.read_string(index as u32) {
                            ser.serialize_entry(name, &value)?;
                        }
                    }
                    DataType::Json => {
                        let value = self.reader.read_json(index as u32);
                        let value = serde_json::from_str::<Value>(value);
                        if let Ok(value) = value {
                            if value != Value::Null {
                                ser.serialize_entry(name, &value)?;
                            }
                        }
                    }
                    DataType::Object => {
                        if let Some(object) = self.reader.read_object(index as u32) {
                            let reader = IsarObjectSerialize::new(None, &object);
                            ser.serialize_entry(name, &reader)?;
                        }
                    }
                    _ => {
                        let element_type = data_type.element_type();
                        let list = self.reader.read_list(index as u32);
                        match (element_type, list) {
                            (Some(element_type), Some((list, length))) => {
                                let reader = IsarListSerialize::new(element_type, &list, length);
                                ser.serialize_entry(name, &reader)?;
                            }
                            _ => {}
                        }
                    }
                }
            }
            ser.end()
        } else {
            serializer.serialize_none()
        }
    }
}

struct IsarListSerialize<'a, R: IsarReader> {
    element_type: DataType,
    reader: &'a R,
    length: u32,
}

impl<'a, R: IsarReader> IsarListSerialize<'a, R> {
    fn new(element_type: DataType, reader: &'a R, length: u32) -> Self {
        IsarListSerialize {
            element_type,
            reader,
            length,
        }
    }
}

impl<'a, R: IsarReader> Serialize for IsarListSerialize<'a, R> {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        let mut ser = serializer.serialize_seq(Some(self.length as usize))?;
        match self.element_type {
            DataType::Bool => {
                for i in 0..self.length {
                    ser.serialize_element(&self.reader.read_bool(i))?;
                }
            }
            DataType::Byte => {
                for i in 0..self.length {
                    ser.serialize_element(&self.reader.read_byte(i))?;
                }
            }
            DataType::Int => {
                for i in 0..self.length {
                    let value = self.reader.read_int(i);
                    if value == NULL_INT {
                        ser.serialize_element(&Value::Null)?;
                    } else {
                        ser.serialize_element(&value)?;
                    }
                }
            }
            DataType::Float => {
                for i in 0..self.length {
                    let value = self.reader.read_float(i);
                    if value.is_nan() {
                        ser.serialize_element(&Value::Null)?;
                    } else {
                        ser.serialize_element(&value)?;
                    }
                }
            }
            DataType::Long => {
                for i in 0..self.length {
                    let value = self.reader.read_long(i);
                    if value == NULL_LONG {
                        ser.serialize_element(&Value::Null)?;
                    } else {
                        ser.serialize_element(&value)?;
                    }
                }
            }
            DataType::Double => {
                for i in 0..self.length {
                    let value = self.reader.read_double(i);
                    if value.is_nan() {
                        ser.serialize_element(&Value::Null)?;
                    } else {
                        ser.serialize_element(&value)?;
                    }
                }
            }
            DataType::String => {
                for i in 0..self.length {
                    if let Some(value) = self.reader.read_string(i) {
                        ser.serialize_element(&value)?;
                    } else {
                        ser.serialize_element(&Value::Null)?;
                    }
                }
            }
            DataType::Object => {
                for i in 0..self.length {
                    if let Some(object) = self.reader.read_object(i) {
                        let reader = IsarObjectSerialize::new(None, &object);
                        ser.serialize_element(&reader)?;
                    } else {
                        ser.serialize_element(&Value::Null)?;
                    }
                }
            }
            DataType::Json => {
                for i in 0..self.length {
                    let value = self.reader.read_json(i);
                    let value = serde_json::from_str::<Value>(value);
                    if let Ok(value) = value {
                        if value != Value::Null {
                            ser.serialize_element(&value)?;
                        } else {
                            ser.serialize_element(&Value::Null)?;
                        }
                    } else {
                        ser.serialize_element(&Value::Null)?;
                    }
                }
            }
            _ => {}
        }
        ser.end()
    }
}

/*struct IsarObjectDeserialize<'a, W: IsarWriter<'a>> {
    id_name: Option<&'a str>,
    writer: &'a W,
}

impl<'a, W: IsarWriter<'a>> IsarObjectDeserialize<'a, W> {
    fn new(id_name: Option<&'a str>, writer: &'a W) -> Self {
        IsarObjectDeserialize { id_name, writer }
    }
}

impl<'a, W: IsarWriter<'a>> Deserialize<'a> for IsarObjectDeserialize<'a, W> {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'a>,
    {
       deserializer.deserialize()
        todo!()
    }
}
*/
