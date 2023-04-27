use crate::native::index::id_key::BytesToId;
use crate::native::native_object::NativeObject;
use crate::native::native_txn::TxnCursor;

pub struct IdsIterator<'txn> {
    ids: Vec<i64>,
    cursor: TxnCursor<'txn>,
}

impl<'txn> IdsIterator<'txn> {
    pub(crate) fn new(cursor: TxnCursor<'txn>, mut ids: Vec<i64>) -> Self {
        ids.reverse();
        IdsIterator { ids, cursor }
    }
}

impl<'txn> Iterator for IdsIterator<'txn> {
    type Item = (i64, NativeObject<'txn>);

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        while let Some(id) = self.ids.pop() {
            match self.cursor.move_to(&id) {
                Ok(Some((key, value))) => {
                    return Some((key.to_id(), NativeObject::from_bytes(value)))
                }
                Ok(None) => continue,
                Err(_) => return None,
            }
        }
        None
    }
}
