use super::error::Result;
use super::reader::IsarReader;

pub trait IsarQuery {
    type Txn;

    type Cursor<'b>: IsarCursor
    where
        Self: 'b;

    fn cursor<'c>(&'c self, txn: &'c mut Self::Txn) -> Result<Self::Cursor<'c>>;

    fn count(&self, txn: &mut Self::Txn) -> Result<u32>;

    fn delete(&self, txn: &mut Self::Txn) -> Result<u32>;

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
}
