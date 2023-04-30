use super::writer::IsarWriter;
use crate::core::error::Result;

pub trait IsarInsert<'a>: IsarWriter<'a> + Sized {
    type Txn;

    fn save(self, id: Option<i64>) -> Result<Self>;

    fn finish(self) -> Result<Self::Txn>;
}
