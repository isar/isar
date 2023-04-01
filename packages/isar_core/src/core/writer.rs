pub trait IsarInsert<'a>: IsarWriter<'a> {
    type Txn<'txn>;

    fn next(self) -> Result<Option<Self>>;

    fn finish(self) -> Result<Self::Txn<'a>>;
}

pub trait IsarWriter<'a> {
    type ObjectWriter: IsarWriter<'a>;

    type ListWriter: IsarWriter<'a>;

    fn write_id(&mut self, id: i64);

    fn write_null(&mut self);

    fn write_byte(&mut self, value: u8);

    fn write_bool(&mut self, value: Option<bool>);

    fn write_int(&mut self, value: i32);

    fn write_float(&mut self, value: f32);

    fn write_long(&mut self, value: i64);

    fn write_double(&mut self, value: f64);

    fn write_string(&mut self, value: Option<&str>);

    fn begin_object(&mut self) -> Self::ObjectWriter;

    fn end_object(&mut self, writer: Self::ObjectWriter);

    fn begin_list(&mut self, size: usize) -> Self::ListWriter;

    fn end_list(&mut self, writer: Self::ListWriter);
}
