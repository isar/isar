mod index_key;
mod isar_deserializer;
mod isar_serializer;
mod mdbx;
mod native_collection;
mod native_cursor;
mod native_index;
mod native_insert;
pub mod native_instance;
mod native_open;
mod native_query_builder;
mod native_reader;
mod native_txn;
mod native_verify;
mod native_writer;
mod query;
mod schema_manager;

pub(crate) const FALSE_BOOL: u8 = 0;
pub(crate) const TRUE_BOOL: u8 = 1;
pub(crate) const NULL_BOOL: u8 = 255;

pub(crate) const NULL_INT: i32 = i32::MIN;
pub(crate) const NULL_LONG: i64 = i64::MIN;
pub(crate) const NULL_FLOAT: f32 = f32::NAN;
pub(crate) const NULL_DOUBLE: f64 = f64::NAN;
pub(crate) const MAX_OBJ_SIZE: u32 = 2 << 24;

pub trait BytesToId {
    fn to_id(&self) -> i64;
}

impl BytesToId for &[u8] {
    #[inline]
    fn to_id(&self) -> i64 {
        let unsigned = u64::from_le_bytes((**self).try_into().unwrap());
        let signed: i64 = unsigned as i64;
        signed ^ 1 << 63
    }
}

pub trait IdToBytes {
    fn to_id_bytes(&self) -> [u8; 8];
}

impl IdToBytes for i64 {
    #[inline]
    fn to_id_bytes(&self) -> [u8; 8] {
        let unsigned = *self as u64;
        (unsigned ^ 1 << 63).to_le_bytes()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_to_id_bytes() {
        assert_eq!(i64::MIN.to_id_bytes(), [0, 0, 0, 0, 0, 0, 0, 0]);
        assert_eq!((i64::MIN + 1).to_id_bytes(), [1, 0, 0, 0, 0, 0, 0, 0]);
        assert_eq!(
            i64::MAX.to_id_bytes(),
            [255, 255, 255, 255, 255, 255, 255, 255]
        );
        assert_eq!(
            (i64::MAX - 1).to_id_bytes(),
            [254, 255, 255, 255, 255, 255, 255, 255]
        );
    }

    #[test]
    fn test_to_id() {
        assert_eq!([0, 0, 0, 0, 0, 0, 0, 0].as_ref().to_id(), i64::MIN);
        assert_eq!([1, 0, 0, 0, 0, 0, 0, 0].as_ref().to_id(), i64::MIN + 1);
        assert_eq!(
            [254, 255, 255, 255, 255, 255, 255, 255].as_ref().to_id(),
            i64::MAX - 1
        );
        assert_eq!(
            [255, 255, 255, 255, 255, 255, 255, 255].as_ref().to_id(),
            i64::MAX
        );
    }
}
