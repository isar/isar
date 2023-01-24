use crate::core::writer::IsarWriter;

pub struct NativeWriter {}

impl<'a> IsarWriter<'a> for NativeWriter {
    type ObjectWriter = NativeWriter;

    type ListWriter = NativeWriter;

    fn write_id(&mut self, id: i64) {
        todo!()
    }

    fn write_null(&mut self) {
        todo!()
    }

    fn write_byte(&mut self, value: u8) {
        todo!()
    }

    fn write_bool(&mut self, value: Option<bool>) {
        todo!()
    }

    fn write_int(&mut self, value: i32) {
        todo!()
    }

    fn write_float(&mut self, value: f32) {
        todo!()
    }

    fn write_long(&mut self, value: i64) {
        todo!()
    }

    fn write_double(&mut self, value: f64) {
        todo!()
    }

    fn write_string(&mut self, value: Option<&str>) {
        todo!()
    }

    fn begin_object(&mut self) -> Self::ObjectWriter {
        todo!()
    }

    fn end_object(&mut self, writer: Self::ObjectWriter) {
        todo!()
    }

    fn begin_list(&mut self, size: usize) -> Self::ListWriter {
        todo!()
    }

    fn end_list(&mut self, writer: Self::ListWriter) {
        todo!()
    }
}
