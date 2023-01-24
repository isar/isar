use std::marker::PhantomData;

use super::native_reader::NativeReader;
use super::native_txn::NativeTxn;
use crate::core::error::Result;
use crate::core::query::{IsarCursor, IsarQuery};

pub struct NativeQuery {}

impl IsarQuery for NativeQuery {
    type Txn = NativeTxn;

    type Cursor<'b> = NativeCursor
    where
        Self: 'b;

    fn cursor<'c>(&'c self, txn: &'c mut Self::Txn) -> Result<Self::Cursor<'c>> {
        todo!()
    }

    fn count(&self, txn: &mut Self::Txn) -> Result<u32> {
        todo!()
    }

    fn delete(&self, txn: &mut Self::Txn) -> Result<u32> {
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
}
