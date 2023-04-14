use serde::de::{MapAccess, SeqAccess, Visitor};
use serde_json::de::SliceRead;
use serde_json::ser::{CompactFormatter, Formatter};
use serde_json::Deserializer;
use std::{collections::BTreeMap, io::Write};

pub enum IsarAny {
    Bool(bool),
    Integer(i64),
    Real(f64),
    String(String),
    Array(Vec<IsarAny>),
    Object(BTreeMap<String, IsarAny>),
}

impl IsarAny {
    pub fn to_json<W: Write>(&self, writer: &mut W) {
        match self {
            IsarAny::Bool(value) => CompactFormatter.write_bool(writer, *value),
            IsarAny::Integer(value) => CompactFormatter.write_i64(writer, *value),
            IsarAny::Real(value) => CompactFormatter.write_f64(writer, *value),
            IsarAny::String(value) => CompactFormatter.write_string_fragment(writer, value),
            IsarAny::Array(value) => {
                CompactFormatter.begin_array(writer);
                for (i, value) in value.iter().enumerate() {
                    CompactFormatter.begin_array_value(writer, i == 0);
                    value.to_json(writer);
                }
                CompactFormatter.end_array(writer)
            }
            IsarAny::Object(value) => {
                CompactFormatter.begin_object(writer);
                for (i, (key, value)) in value.iter().enumerate() {
                    CompactFormatter.begin_object_key(writer, i == 0);
                    CompactFormatter.write_string_fragment(writer, key);
                    CompactFormatter.end_object_key(writer);
                    CompactFormatter.begin_object_value(writer);
                    value.to_json(writer);
                    CompactFormatter.end_object_value(writer);
                }
                CompactFormatter.end_object(writer)
            }
        };
    }

    pub fn from_json(value: &[u8]) -> Option<IsarAny> {
        let mut deser = Deserializer::new(SliceRead::new(value));
        let val = serde::de::Deserializer::deserialize_any(&mut deser, ValueVisitor);
        val.ok()
    }
}

struct ValueVisitor;

impl<'de> Visitor<'de> for ValueVisitor {
    type Value = IsarAny;

    #[inline]
    fn visit_bool<E>(self, value: bool) -> Result<IsarAny, E> {
        Ok(IsarAny::Bool(value))
    }

    #[inline]
    fn visit_i64<E>(self, value: i64) -> Result<IsarAny, E> {
        Ok(IsarAny::Integer(value))
    }

    #[inline]
    fn visit_f64<E>(self, value: f64) -> Result<IsarAny, E> {
        Ok(IsarAny::Real(value))
    }

    #[inline]
    fn visit_str<E>(self, value: &str) -> Result<IsarAny, E>
    where
        E: serde::de::Error,
    {
        self.visit_string(String::from(value))
    }

    #[inline]
    fn visit_string<E>(self, value: String) -> Result<IsarAny, E> {
        Ok(IsarAny::String(value))
    }

    #[inline]
    fn visit_seq<V>(self, mut visitor: V) -> Result<IsarAny, V::Error>
    where
        V: SeqAccess<'de>,
    {
        let mut vec = Vec::new();
        while let Some(elem) = visitor.next_element()? {
            vec.push(elem);
        }
        Ok(IsarAny::Array(vec))
    }

    fn visit_map<V>(self, mut visitor: V) -> Result<IsarAny, V::Error>
    where
        V: MapAccess<'de>,
    {
        let map = BTreeMap::new();
        while let Some((key, val)) = visitor.next_entry()? {
            map.insert(key, val);
        }
        Ok(IsarAny::Object(map))
    }

    fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
        todo!()
    }
}
