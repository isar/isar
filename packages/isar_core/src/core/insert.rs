use super::error::Result;
use super::writer::IsarWriter;

pub trait IsarInsert<'a> {
    type Writer: IsarWriter<'a>;

    type Txn<'txn>;

    fn get_writer(&'a self) -> Result<Self::Writer>;

    fn insert(&'a mut self, writer: Self::Writer) -> Result<Option<Self::Writer>>;

    fn finish(self) -> Result<Self::Txn<'a>>;
}
