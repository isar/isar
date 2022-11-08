use crate::index::IsarIndex;
use crate::mdbx::Key;
use std::borrow::Cow;
use std::cmp;
use std::cmp::Ordering;
use xxhash_rust::xxh3::xxh3_64;

#[derive(Clone, Eq, PartialEq)]
pub struct IndexKey {
    bytes: Vec<u8>,
}

impl IndexKey {
    pub fn new() -> Self {
        IndexKey { bytes: vec![] }
    }

    pub fn from_bytes(bytes: Vec<u8>) -> Self {
        IndexKey { bytes }
    }

    pub fn add_byte(&mut self, value: u8) {
        self.bytes.push(value);
    }

    pub fn add_int(&mut self, value: i32) {
        let unsigned = value as u32;
        let bytes: [u8; 4] = (unsigned ^ 1 << 31).to_be_bytes();
        self.bytes.extend_from_slice(&bytes);
    }

    pub fn add_long(&mut self, value: i64) {
        let unsigned = value as u64;
        let bytes = (unsigned ^ 1 << 63).to_be_bytes().to_vec();
        self.bytes.extend_from_slice(&bytes);
    }

    pub fn add_float(&mut self, value: f32) {
        let bytes: [u8; 4] = if !value.is_nan() {
            let bits = if value.is_sign_positive() {
                value.to_bits() + 2u32.pow(31)
            } else {
                !(-value).to_bits() - 2u32.pow(31)
            };
            bits.to_be_bytes()
        } else {
            [0; 4]
        };
        self.bytes.extend_from_slice(&bytes);
    }

    pub fn add_double(&mut self, value: f64) {
        let bytes: [u8; 8] = if !value.is_nan() {
            let bits = if value.is_sign_positive() {
                value.to_bits() + 2u64.pow(63)
            } else {
                !(-value).to_bits() - 2u64.pow(63)
            };
            bits.to_be_bytes()
        } else {
            [0; 8]
        };
        self.bytes.extend_from_slice(&bytes);
    }

    pub fn add_string(&mut self, value: Option<&str>, case_sensitive: bool) {
        if let Some(value) = value {
            let value = if case_sensitive {
                value.to_string()
            } else {
                value.to_lowercase()
            };
            let bytes = value.as_bytes();
            if bytes.len() >= IsarIndex::MAX_STRING_INDEX_SIZE {
                let index_bytes = &bytes[0..IsarIndex::MAX_STRING_INDEX_SIZE];
                self.bytes.extend_from_slice(index_bytes);
                let hash = xxh3_64(bytes);
                self.bytes.extend_from_slice(&u64::to_le_bytes(hash));
            } else if bytes.is_empty() {
                self.bytes.push(1);
            } else {
                self.bytes.extend_from_slice(bytes);
            }
        } else {
            self.bytes.push(0);
        }
    }

    pub fn add_hash(&mut self, value: u64) {
        let bytes: [u8; 8] = value.to_be_bytes();
        self.bytes.extend_from_slice(&bytes);
    }

    #[allow(clippy::len_without_is_empty)]
    pub fn len(&self) -> usize {
        self.bytes.len()
    }

    pub fn truncate(&mut self, len: usize) {
        self.bytes.truncate(len);
    }

    pub fn increase(&mut self) -> bool {
        let mut increased = false;
        for i in (0..self.bytes.len()).rev() {
            if let Some(added) = self.bytes[i].checked_add(1) {
                self.bytes[i] = added;
                increased = true;
                for i2 in (i + 1)..self.bytes.len() {
                    self.bytes[i2] = 0;
                }
                break;
            }
        }
        increased
    }

    pub fn decrease(&mut self) -> bool {
        let mut decreased = false;
        for i in (0..self.bytes.len()).rev() {
            if let Some(subtracted) = self.bytes[i].checked_sub(1) {
                self.bytes[i] = subtracted;
                decreased = true;
                for i2 in (i + 1)..self.bytes.len() {
                    self.bytes[i2] = 255;
                }
                break;
            }
        }
        decreased
    }
}

impl Key for IndexKey {
    fn as_bytes(&self) -> Cow<[u8]> {
        Cow::Borrowed(&self.bytes)
    }

    fn cmp_bytes(&self, other: &[u8]) -> Ordering {
        let len = cmp::min(self.bytes.len(), other.len());
        let cmp = (&self.bytes[0..len]).cmp(&other[0..len]);
        if cmp == Ordering::Equal {
            self.bytes.len().cmp(&other.len())
        } else {
            cmp
        }
    }
}

impl PartialOrd<Self> for IndexKey {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for IndexKey {
    fn cmp(&self, other: &Self) -> Ordering {
        self.cmp_bytes(&other.bytes)
    }
}

#[cfg(test)]
mod tests {
    use crate::object::isar_object::IsarObject;

    use super::*;
    use float_next_after::NextAfter;

    #[test]
    fn test_add_byte() {
        let pairs = vec![
            (IsarObject::NULL_BYTE, vec![123, 0]),
            (123, vec![123, 123]),
            (255, vec![123, 255]),
        ];

        for (val, bytes) in pairs {
            let mut index_key = IndexKey::new();
            index_key.add_byte(123);
            index_key.add_byte(val);
            assert_eq!(&index_key.bytes, &bytes);
        }
    }

    #[test]
    fn test_add_int() {
        let pairs = vec![
            (i32::MIN, vec![123, 0, 0, 0, 0]),
            (i32::MIN + 1, vec![123, 0, 0, 0, 1]),
            (-1, vec![123, 127, 255, 255, 255]),
            (0, vec![123, 128, 0, 0, 0]),
            (1, vec![123, 128, 0, 0, 1]),
            (i32::MAX - 1, vec![123, 255, 255, 255, 254]),
            (i32::MAX, vec![123, 255, 255, 255, 255]),
        ];

        for (val, bytes) in pairs {
            let mut index_key = IndexKey::new();
            index_key.add_byte(123);
            index_key.add_int(val);
            assert_eq!(&index_key.bytes, &bytes);
        }
    }

    #[test]
    fn test_add_long() {
        let pairs = vec![
            (i64::MIN, vec![123, 0, 0, 0, 0, 0, 0, 0, 0]),
            (i64::MIN + 1, vec![123, 0, 0, 0, 0, 0, 0, 0, 1]),
            (-1, vec![123, 127, 255, 255, 255, 255, 255, 255, 255]),
            (0, vec![123, 128, 0, 0, 0, 0, 0, 0, 0]),
            (1, vec![123, 128, 0, 0, 0, 0, 0, 0, 1]),
            (
                i64::MAX - 1,
                vec![123, 255, 255, 255, 255, 255, 255, 255, 254],
            ),
            (i64::MAX, vec![123, 255, 255, 255, 255, 255, 255, 255, 255]),
        ];

        for (val, bytes) in pairs {
            let mut index_key = IndexKey::new();
            index_key.add_byte(123);
            index_key.add_long(val);
            assert_eq!(&index_key.bytes, &bytes);
        }
    }

    #[test]
    fn test_add_float() {
        let pairs = vec![
            (f32::NAN, vec![123, 0, 0, 0, 0]),
            (f32::NEG_INFINITY, vec![123, 0, 127, 255, 255]),
            (f32::MIN, vec![123, 0, 128, 0, 0]),
            (f32::MIN.next_after(f32::MAX), vec![123, 0, 128, 0, 1]),
            ((-0.0).next_after(f32::MIN), vec![123, 127, 255, 255, 254]),
            (-0.0, vec![123, 127, 255, 255, 255]),
            (0.0, vec![123, 128, 0, 0, 0]),
            (0.0.next_after(f32::MAX), vec![123, 128, 0, 0, 1]),
            (f32::MAX.next_after(f32::MIN), vec![123, 255, 127, 255, 254]),
            (f32::MAX, vec![123, 255, 127, 255, 255]),
            (f32::INFINITY, vec![123, 255, 128, 0, 0]),
        ];

        for (val, bytes) in pairs {
            let mut index_key = IndexKey::new();
            index_key.add_byte(123);
            index_key.add_float(val);
            assert_eq!(&index_key.bytes, &bytes);
        }
    }

    #[test]
    fn test_add_double() {
        let pairs = vec![
            (f64::NAN, vec![123, 0, 0, 0, 0, 0, 0, 0, 0]),
            (
                f64::NEG_INFINITY,
                vec![123, 0, 15, 255, 255, 255, 255, 255, 255],
            ),
            (f64::MIN, vec![123, 0, 16, 0, 0, 0, 0, 0, 0]),
            (
                f64::MIN.next_after(f64::MAX),
                vec![123, 0, 16, 0, 0, 0, 0, 0, 1],
            ),
            (
                (-0.0).next_after(f64::MIN),
                vec![123, 127, 255, 255, 255, 255, 255, 255, 254],
            ),
            (-0.0, vec![123, 127, 255, 255, 255, 255, 255, 255, 255]),
            (0.0, vec![123, 128, 0, 0, 0, 0, 0, 0, 0]),
            (
                0.0.next_after(f64::MAX),
                vec![123, 128, 0, 0, 0, 0, 0, 0, 1],
            ),
            (
                f64::MAX.next_after(f64::MIN),
                vec![123, 255, 239, 255, 255, 255, 255, 255, 254],
            ),
            (f64::MAX, vec![123, 255, 239, 255, 255, 255, 255, 255, 255]),
            (f64::INFINITY, vec![123, 255, 240, 0, 0, 0, 0, 0, 0]),
        ];

        for (val, bytes) in pairs {
            let mut index_key = IndexKey::new();
            index_key.add_byte(123);
            index_key.add_double(val);
            assert_eq!(&index_key.bytes, &bytes);
        }
    }

    #[test]
    fn test_add_string() {
        let long_str = (0..850).map(|_| "aB").collect::<String>();
        let long_str_lc = long_str.to_lowercase();

        let mut long_str_bytes = vec![123];
        long_str_bytes.extend_from_slice(long_str.as_bytes());

        let mut long_str_lc_bytes = vec![123];
        long_str_lc_bytes.extend_from_slice(long_str_lc.as_bytes());

        let mut hello_bytes = vec![123];
        hello_bytes.extend_from_slice(b"hELLO");

        let mut hello_bytes_lc = vec![123];
        hello_bytes_lc.extend_from_slice(b"hello");

        let pairs: Vec<(Option<&str>, Vec<u8>, Vec<u8>)> = vec![
            (None, vec![123, 0], vec![123, 0]),
            (Some(""), vec![123, 1], vec![123, 1]),
            (
                Some("hello"),
                hello_bytes_lc.clone(),
                hello_bytes_lc.clone(),
            ),
            (Some("hELLO"), hello_bytes.clone(), hello_bytes_lc.clone()),
            //(Some(&long_str), long_str_bytes, long_str_lc_bytes),
        ];

        for (str, bytes, bytes_lc) in pairs {
            let mut index_key = IndexKey::new();
            index_key.add_byte(123);
            index_key.add_string(str, true);
            assert_eq!(index_key.bytes, bytes);

            let mut index_key = IndexKey::new();
            index_key.add_byte(123);
            index_key.add_string(str, false);
            assert_eq!(index_key.bytes, bytes_lc);
        }
    }
}
