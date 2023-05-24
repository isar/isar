use super::writer::IsarWriter;
use crate::core::error::Result;

pub trait IsarInsert<'a>: IsarWriter<'a> + Sized {
    type Txn;

    fn save(&mut self, id: i64) -> Result<()>;

    fn finish(self) -> Result<Self::Txn>;
}
