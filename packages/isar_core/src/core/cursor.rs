use super::reader::IsarReader;

pub trait IsarCursor {
    type Reader<'a>: IsarReader
    where
        Self: 'a;

    fn next(&mut self) -> Option<Self::Reader<'_>>;
}
