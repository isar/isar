use super::error::Result;
use super::reader::IsarReader;

pub trait IsarQuery {
    type Txn<'a>;

    type Cursor<'a>: IsarCursor
    where
        Self: 'a;

    fn cursor<'txn, 'a>(&'a self, txn: Self::Txn<'txn>) -> Result<Self::Cursor<'a>>
    where
        'txn: 'a;

    fn count(&self, txn: &Self::Txn<'_>) -> Result<u32>;

    fn delete(&self, txn: &Self::Txn<'_>) -> Result<u32>;

    /*fn export_json(
        &self,
        txn: &mut Self::Txn<'_>,
        collection: &Self::Collection,
        id_name: Option<&str>,
        primitive_null: bool,
    ) -> Result<Value>;*/
}

pub trait IsarCursor {
    type Reader<'b>: IsarReader
    where
        Self: 'b;

    fn next(&mut self) -> Result<Option<Self::Reader<'_>>>;

    fn close(self) -> Result<()>;
}
