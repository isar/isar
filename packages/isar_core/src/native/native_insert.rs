use super::native_writer::NativeWriter;
use crate::core::error::Result;
use crate::core::insert::IsarInsert;

pub struct NativeInsert {}

impl<'a> IsarInsert<'a> for NativeInsert {
    type Txn<'a>;

    type Writer<'a>;

    fn get_writer<'a>(&'a self, txn: &mut Self::Txn<'a>) -> Result<Self::Writer<'a>> {
        todo!()
    }

    fn insert<'a>(
        &'a mut self,
        txn: &'a mut Self::Txn<'a>,
        writer: Self::Writer<'_>,
    ) -> Result<Option<Self::Writer<'a>>> {
        todo!()
    }
}
