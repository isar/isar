use super::data_type::DataType;

pub trait IsarWriter<'a> {
    type ObjectWriter: IsarWriter<'a>;

    type ListWriter: IsarWriter<'a>;

    fn id_name(&self) -> Option<&str>;

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)>;

    fn write_null(&mut self, index: u32);

    fn write_bool(&mut self, index: u32, value: bool);

    fn write_byte(&mut self, index: u32, value: u8);

    fn write_int(&mut self, index: u32, value: i32);

    fn write_float(&mut self, index: u32, value: f32);

    fn write_long(&mut self, index: u32, value: i64);

    fn write_double(&mut self, index: u32, value: f64);

    fn write_string(&mut self, index: u32, value: &str);

    fn write_byte_list(&mut self, index: u32, value: &[u8]);

    fn begin_object(&mut self, index: u32) -> Option<Self::ObjectWriter>;

    fn end_object(&mut self, writer: Self::ObjectWriter);

    fn begin_list(&mut self, index: u32, length: u32) -> Option<Self::ListWriter>;

    fn end_list(&mut self, writer: Self::ListWriter);
}
