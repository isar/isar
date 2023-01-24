use super::error::Result;
use super::txn::IsarTxn;
use super::writer::IsarWriter;

pub trait IsarInsert {
    type Txn<'a>: IsarTxn;

    type Writer<'a>: IsarWriter<'a>;

    fn get_writer<'a>(&'a self, txn: &mut Self::Txn<'a>) -> Result<Self::Writer<'a>>;

    fn insert<'a>(
        &'a mut self,
        txn: &'a mut Self::Txn<'a>,
        writer: Self::Writer<'_>,
    ) -> Result<Option<Self::Writer<'a>>>;
}
