use std::{borrow::Cow, cmp::Ordering};

use crate::mdbx::Key;

pub trait BytesToId {
    fn to_id(&self) -> i64;
}

impl BytesToId for &[u8] {
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
    fn to_id_bytes(&self) -> [u8; 8] {
        let unsigned = *self as u64;
        (unsigned ^ 1 << 63).to_le_bytes()
    }
}

impl Key for i64 {
    fn as_bytes(&self) -> Cow<[u8]> {
        let bytes = self.to_id_bytes();
        Cow::Owned(bytes.to_vec())
    }

    fn cmp_bytes(&self, other: &[u8]) -> Ordering {
        let other_id = other.to_id();
        self.cmp(&other_id)
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
