use super::reader::IsarReader;

pub trait IsarCursor {
    type Reader<'a>: IsarReader
    where
        Self: 'a;

    fn next(&mut self, id: i64) -> Option<Self::Reader<'_>>;
}

pub trait IsarQueryCursor {
    type Reader<'a>: IsarReader
    where
        Self: 'a;

    fn next(&mut self) -> Option<Self::Reader<'_>>;
}
