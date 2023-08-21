use super::{data_type::DataType, reader::IsarReader};
use serde::ser::{SerializeMap, SerializeSeq};
use serde::Serialize;
use serde_json::Value;

pub(super) struct IsarObjectSerialize<'a, R: IsarReader> {
    reader: &'a R,
}

impl<'a, R: IsarReader> IsarObjectSerialize<'a, R> {
    pub fn new(reader: &'a R) -> Self {
        IsarObjectSerialize { reader }
    }
}

impl<'a, R: IsarReader> Serialize for IsarObjectSerialize<'a, R> {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        let mut ser = serializer.serialize_map(None)?;

        let id_name = self.reader.id_name();
        let mut id_serialized = false;

        for (mut index, (name, data_type)) in self.reader.properties().enumerate() {
            index += 1;
            if Some(name) == id_name {
                id_serialized = true;
            }

            match data_type {
                DataType::Bool => {
                    ser.serialize_entry(name, &self.reader.read_bool(index as u32))?;
                }
                DataType::Byte => {
                    ser.serialize_entry(name, &self.reader.read_byte(index as u32))?;
                }
                DataType::Int => {
                    let value = self.reader.read_int(index as u32);
                    if value != i32::MIN {
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
                    if value != i64::MIN {
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
                    if let Some(value) = self.reader.read_string(index as u32) {
                        let value = serde_json::from_str::<Value>(value);
                        if let Ok(value) = value {
                            if value != Value::Null {
                                ser.serialize_entry(name, &value)?;
                            }
                        }
                    }
                }
                DataType::Object => {
                    if let Some(object) = self.reader.read_object(index as u32) {
                        let reader = IsarObjectSerialize::new(&object);
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

        if !id_serialized {
            if let Some(id_name) = self.reader.id_name() {
                ser.serialize_entry(id_name, &self.reader.read_id())?;
            }
        }

        ser.end()
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
                    if value == i32::MIN {
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
                    if value == i64::MIN {
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
            DataType::String | DataType::Json => {
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
                        let reader = IsarObjectSerialize::new(&object);
                        ser.serialize_element(&reader)?;
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
