use super::error::{IsarError, Result};
use super::{data_type::DataType, ser::IsarObjectSerialize};
use serde::Serializer;
use std::borrow::Cow;

pub trait IsarReader {
    type ObjectReader<'b>: IsarReader
    where
        Self: 'b;

    type ListReader<'b>: IsarReader
    where
        Self: 'b;

    fn id_name(&self) -> Option<&str>;

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)>;

    fn read_id(&self) -> i64;

    fn is_null(&self, index: u32) -> bool;

    fn read_bool(&self, index: u32) -> Option<bool>;

    fn read_byte(&self, index: u32) -> u8;

    fn read_int(&self, index: u32) -> i32;

    fn read_float(&self, index: u32) -> f32;

    fn read_long(&self, index: u32) -> i64;

    fn read_double(&self, index: u32) -> f64;

    fn read_string(&self, index: u32) -> Option<&str>;

    fn read_blob(&self, index: u32) -> Option<Cow<'_, [u8]>>;

    fn read_object(&self, index: u32) -> Option<Self::ObjectReader<'_>>;

    fn read_list(&self, index: u32) -> Option<(Self::ListReader<'_>, u32)>;

    fn serialize(&self, serializer: impl Serializer) -> Result<()>
    where
        Self: Sized,
    {
        let obj = IsarObjectSerialize::new(self);
        serializer
            .serialize_some(&obj)
            .map_err(|e| IsarError::JsonError {
                message: e.to_string(),
            })?;
        Ok(())
    }
}
