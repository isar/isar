use super::data_type::DataType;
use super::error::IsarError;
use super::insert::IsarInsert;
use super::instance::IsarInstance;
use super::writer::IsarWriter;
use serde::de::{Error, IgnoredAny, MapAccess, Visitor};
use serde::Deserializer;
use serde_json::value::RawValue;
use std::cell::Cell;
use std::fmt::Formatter;
use std::marker::PhantomData;

const BULK_IMPORT_COUNT: usize = 100;

pub(super) struct IsarJsonImportVisitor<'a, I: IsarInstance> {
    instance: &'a I,
    txn: Cell<Option<I::Txn>>,
    collection_index: u16,
}

impl<'a, I: IsarInstance> IsarJsonImportVisitor<'a, I> {
    pub(super) fn new(instance: &'a I, txn: I::Txn, collection_index: u16) -> Self {
        IsarJsonImportVisitor {
            instance,
            txn: Cell::new(Some(txn)),
            collection_index,
        }
    }
    fn import(&self, objects: &[&str]) -> Result<(), IsarError> {
        let txn = self.txn.take().unwrap();
        let mut insert = self
            .instance
            .insert(txn, self.collection_index, objects.len() as u32)?;

        for object in objects {
            let mut deser = serde_json::Deserializer::from_str(object);
            let visitor = IsarObjectVisitor::new(insert);
            let (id, writer) = deser
                .deserialize_map(visitor)
                .map_err(|_| IsarError::JsonError {})?;
            insert = writer;

            if let Some(id) = id {
                insert.save(id)?;
            }
        }

        self.txn.set(Some(insert.finish()?));

        Ok(())
    }
}

impl<'a, 'de, I: IsarInstance> Visitor<'de> for IsarJsonImportVisitor<'a, I> {
    type Value = (I::Txn, u32);

    fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(formatter, "a list of objects")
    }

    fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
    where
        A: serde::de::SeqAccess<'de>,
    {
        let mut count = 0;
        let mut buffer = Vec::new();
        while let Some(next) = seq.next_element::<&RawValue>()? {
            buffer.push(next.get());
            if buffer.len() >= BULK_IMPORT_COUNT {
                count += buffer.len();
                self.import(&buffer)
                    .map_err(|_| Error::custom("Failed to import objects"))?;
                buffer.clear();
            }
        }
        if !buffer.is_empty() {
            count += buffer.len();
            self.import(&buffer)
                .map_err(|_| Error::custom("Failed to import objects"))?;
        }
        let txn = self.txn.take().unwrap();
        Ok((txn, count as u32))
    }
}

struct IsarObjectVisitor<'a, W: IsarWriter<'a>> {
    writer: W,
    _marker: PhantomData<&'a ()>,
}

impl<'a, W: IsarWriter<'a>> IsarObjectVisitor<'a, W> {
    pub fn new(writer: W) -> Self {
        IsarObjectVisitor {
            writer,
            _marker: PhantomData,
        }
    }
}

#[macro_export]
macro_rules! write_list {
    ($writer:expr, $map:ident, $index:expr, $type:ty, $write:ident) => {{
        let list = $map.next_value::<Option<Vec<Option<$type>>>>()?;
        if let Some(list) = list {
            let mut list_writer = $writer
                .begin_list($index as u32, list.len() as u32)
                .unwrap();
            for (i, value) in list.iter().enumerate() {
                if let Some(value) = value {
                    list_writer.$write(i as u32, *value);
                } else {
                    list_writer.write_null(i as u32);
                }
            }
            $writer.end_list(list_writer);
        } else {
            $writer.write_null($index as u32);
        }
    }};
}

#[macro_export]
macro_rules! write_scalar {
    ($writer:expr, $map:ident, $index:expr, $type:ty, $write:ident) => {{
        let value = $map.next_value::<Option<$type>>()?;
        if let Some(value) = value {
            $writer.$write($index as u32, value);
        } else {
            $writer.write_null($index as u32);
        }
    }};
}

impl<'a, 'de: 'a, W: IsarWriter<'a>> Visitor<'de> for IsarObjectVisitor<'a, W> {
    type Value = (Option<i64>, W);

    fn expecting(&self, formatter: &mut Formatter) -> std::fmt::Result {
        write!(formatter, "a map containing object properties")
    }

    fn visit_map<A>(mut self, mut map: A) -> Result<Self::Value, A::Error>
    where
        A: MapAccess<'de>,
    {
        let mut id = None;
        while let Some(key) = map.next_key::<String>()? {
            let prop = self
                .writer
                .properties()
                .enumerate()
                .find(|(_, (n, _))| n == &key);
            if let Some((index, (_, data_type))) = prop {
                match data_type {
                    DataType::Bool => write_scalar!(self.writer, map, index, bool, write_bool),
                    DataType::Byte => write_scalar!(self.writer, map, index, u8, write_byte),
                    DataType::Int => write_scalar!(self.writer, map, index, i32, write_int),
                    DataType::Float => write_scalar!(self.writer, map, index, f32, write_float),
                    DataType::Long => write_scalar!(self.writer, map, index, i64, write_long),
                    DataType::Double => write_scalar!(self.writer, map, index, f64, write_double),
                    DataType::String => {
                        let value = map.next_value::<Option<String>>()?;
                        if let Some(value) = value {
                            self.writer.write_string(index as u32, &value);
                        } else {
                            self.writer.write_null(index as u32);
                        }
                    }
                    DataType::Json => {
                        let value = map.next_value::<Option<&RawValue>>()?;
                        if let Some(value) = value {
                            self.writer.write_json(index as u32, value.get());
                        } else {
                            self.writer.write_null(index as u32);
                        }
                    }
                    DataType::Object => {
                        let value = map.next_value::<Option<&RawValue>>()?;
                        if let Some(value) = value {
                            let object = self.writer.begin_object(index as u32).unwrap();
                            let mut deser = serde_json::Deserializer::from_str(value.get());
                            let visitor = IsarObjectVisitor::new(object);
                            let (_, object) = deser
                                .deserialize_map(visitor)
                                .map_err(|_| Error::custom("Failed to deserialize object"))?;
                            self.writer.end_object(object);
                        } else {
                            self.writer.write_null(index as u32);
                        }
                    }
                    DataType::BoolList => write_list!(self.writer, map, index, bool, write_bool),
                    DataType::ByteList => write_list!(self.writer, map, index, u8, write_byte),
                    DataType::IntList => write_list!(self.writer, map, index, i32, write_int),
                    DataType::FloatList => write_list!(self.writer, map, index, f32, write_float),
                    DataType::LongList => write_list!(self.writer, map, index, i64, write_long),
                    DataType::DoubleList => write_list!(self.writer, map, index, f64, write_double),
                    DataType::StringList => {
                        let list = map.next_value::<Option<Vec<Option<String>>>>()?;
                        if let Some(list) = list {
                            let mut list_writer = self
                                .writer
                                .begin_list(index as u32, list.len() as u32)
                                .unwrap();
                            for (i, value) in list.iter().enumerate() {
                                if let Some(value) = value {
                                    list_writer.write_string(i as u32, value);
                                } else {
                                    list_writer.write_null(i as u32);
                                }
                            }
                            self.writer.end_list(list_writer);
                        } else {
                            self.writer.write_null(index as u32);
                        }
                    }
                    DataType::ObjectList => {
                        let list = map.next_value::<Option<Vec<Option<&RawValue>>>>()?;
                        if let Some(list) = list {
                            let mut list_writer = self
                                .writer
                                .begin_list(index as u32, list.len() as u32)
                                .unwrap();
                            for (i, value) in list.iter().enumerate() {
                                if let Some(value) = value {
                                    let object = list_writer.begin_object(i as u32).unwrap();
                                    let mut deser = serde_json::Deserializer::from_str(value.get());
                                    let visitor = IsarObjectVisitor::new(object);
                                    let (_, object) =
                                        deser.deserialize_map(visitor).map_err(|_| {
                                            Error::custom("Failed to deserialize object")
                                        })?;
                                    list_writer.end_object(object);
                                } else {
                                    list_writer.write_null(i as u32);
                                }
                            }
                            self.writer.end_list(list_writer);
                        } else {
                            self.writer.write_null(index as u32);
                        }
                    }
                }
            } else if self.writer.id_name() == Some(&key) {
                id = Some(map.next_value::<i64>()?);
            } else {
                map.next_value::<IgnoredAny>()?;
            }
        }
        Ok((id, self.writer))
    }
}
