use std::marker::PhantomData;

use super::native_reader::NativeReader;
use super::native_txn::NativeTxn;
use crate::core::error::Result;
use crate::core::query::{IsarCursor, IsarQuery};

pub struct NativeQuery {}

impl IsarQuery for NativeQuery {
    type Txn<'a> = NativeTxn<'a>;

    type Cursor<'b> = NativeCursor
    where
        Self: 'b;

    fn cursor<'txn, 'a>(&'a self, txn: Self::Txn<'txn>) -> Result<Self::Cursor<'a>>
    where
        'txn: 'a,
    {
        todo!()
    }

    fn count(&self, txn: &Self::Txn<'_>) -> Result<u32> {
        todo!()
    }

    fn delete(&self, txn: &Self::Txn<'_>) -> Result<u32> {
        todo!()
    }
}

pub struct NativeCursor {}

impl IsarCursor for NativeCursor {
    type Reader<'b> = NativeReader<'b>
    where
        Self: 'b;

    fn next(&mut self) -> Result<Option<Self::Reader<'_>>> {
        todo!()
    }

    fn close(self) -> Result<()> {
        todo!()
    }
}
