use super::error::Result;
use super::writer::IsarWriter;

pub trait IsarInsert<'txn> {
    type Writer: IsarWriter<'txn>;

    fn get_writer(&self) -> Result<Self::Writer>;

    fn insert(&mut self, writer: Self::Writer) -> Result<Option<Self::Writer>>;
}
