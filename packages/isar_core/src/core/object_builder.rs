pub trait IsarObjectBuilder<'a> {
    fn write_byte(&mut self, col: usize, value: u8);

    fn write_bool(&mut self, col: usize, value: Option<bool>);

    fn write_int(&mut self, col: usize, value: i32);

    fn write_float(&mut self, col: usize, value: f32);

    fn write_long(&mut self, col: usize, value: i64);

    fn write_double(&mut self, col: usize, value: f64);

    fn write_string(&mut self, col: usize, value: Option<&str>);
}
