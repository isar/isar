use super::QueryIndex;
use crate::native::isar_deserializer::IsarDeserializer;
use crate::native::mdbx::cursor_iterator::CursorIterator;
use crate::native::native_collection::NativeCollection;
use crate::native::native_txn::{NativeTxn, TxnCursor};
use crate::native::BytesToId;

pub(crate) struct IndexIterator<'a> {
    txn: &'a NativeTxn,
    collection: &'a NativeCollection,
    // Either a primary or secondary index iterator. If primary_cursor is None, then iterator is a
    // primary index iterator.
    iterator: Option<CursorIterator<'a, TxnCursor<'a>>>,
    primary_cursor: Option<TxnCursor<'a>>,
    indexes: Vec<QueryIndex>,
}

impl<'a> IndexIterator<'a> {
    pub fn new(
        txn: &'a NativeTxn,
        collection: &'a NativeCollection,
        indexes: &[QueryIndex],
    ) -> Self {
        let mut indexes = indexes.to_vec();
        indexes.reverse();
        if let Some((iterator, primary_cursor)) =
            Self::next_iterator(txn, collection, None, &mut indexes)
        {
            Self {
                txn,
                collection,
                iterator: Some(iterator),
                primary_cursor,
                indexes,
            }
        } else {
            Self {
                txn,
                collection,
                iterator: None,
                primary_cursor: None,
                indexes,
            }
        }
    }

    fn next_iterator<'b>(
        txn: &'b NativeTxn,
        collection: &'b NativeCollection,
        primary_cursor: Option<TxnCursor<'b>>,
        indexes: &mut Vec<QueryIndex>,
    ) -> Option<(CursorIterator<'b, TxnCursor<'b>>, Option<TxnCursor<'b>>)> {
        let next_index = indexes.pop();
        if let Some(QueryIndex::Primary(start, end)) = next_index {
            let cursor = if let Some(primary_cursor) = primary_cursor {
                primary_cursor
            } else {
                collection.get_cursor(txn).ok()?
            };
            let iterator = cursor.iter_between_ids(start, end, false, false).ok()?;
            Some((iterator, None))
        } else if let Some(QueryIndex::Secondary(start, end)) = next_index {
            todo!()
        } else {
            None
        }
    }
}

impl<'a> Iterator for IndexIterator<'a> {
    type Item = (i64, IsarDeserializer<'a>);

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        let next = self.iterator.as_mut()?.next();
        if let Some((key, value)) = next {
            if let Some(primary_cursor) = &mut self.primary_cursor {
                let (id, object) = primary_cursor.move_to(value).ok()??;
                return Some((id.to_id(), IsarDeserializer::from_bytes(object)));
            } else {
                return Some((key.to_id(), IsarDeserializer::from_bytes(value)));
            }
        } else {
            let primary_cursor = if let Some(primary_cursor) = self.primary_cursor.take() {
                Some(primary_cursor)
            } else {
                self.iterator.take().map(|i| i.close())
            };
            let (iterator, primary_cursor) =
                Self::next_iterator(self.txn, self.collection, primary_cursor, &mut self.indexes)?;
            self.iterator = Some(iterator);
            self.primary_cursor = primary_cursor;
            self.next()
        }
    }
}
