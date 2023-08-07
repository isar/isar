use xxhash_rust::xxh3::xxh3_64;

#[derive(Clone, Eq, PartialEq)]
pub struct IndexKey {
    bytes: Vec<u8>,
    contains_null: bool,
}

impl IndexKey {
    pub(crate) const MAX_INDEX_SIZE: usize = 1024;

    pub fn min() -> Self {
        IndexKey {
            bytes: vec![],
            contains_null: false,
        }
    }

    pub fn max() -> Self {
        let mut key = IndexKey {
            bytes: vec![],
            contains_null: false,
        };
        key.add_long(i64::MAX);
        key
    }

    pub fn with_buffer(mut buffer: Vec<u8>) -> Self {
        buffer.clear();
        IndexKey {
            bytes: buffer,
            contains_null: false,
        }
    }

    pub fn add_bool(&mut self, value: Option<bool>) {
        if let Some(value) = value {
            self.bytes.push(if value { 2 } else { 1 });
        } else {
            self.bytes.push(0);
            self.contains_null = true;
        }
    }

    pub fn add_byte(&mut self, value: u8) {
        self.bytes.push(value);
    }

    pub fn add_int(&mut self, value: i32) {
        let unsigned = value as u32;
        let bytes: [u8; 4] = (unsigned ^ 1 << 31).to_be_bytes();
        self.bytes.extend_from_slice(&bytes);
        self.contains_null |= value == i32::MIN;
    }

    pub fn add_long(&mut self, value: i64) {
        let unsigned = value as u64;
        let bytes = (unsigned ^ 1 << 63).to_be_bytes().to_vec();
        self.bytes.extend_from_slice(&bytes);
        self.contains_null |= value == i64::MIN;
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
            self.contains_null = true;
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
            self.contains_null = true;
            [0; 8]
        };
        self.bytes.extend_from_slice(&bytes);
    }

    pub fn add_string(&mut self, value: Option<&str>) {
        if let Some(value) = value {
            if value.is_empty() {
                self.bytes.push(1);
            } else {
                self.bytes.extend_from_slice(value.as_bytes());
            }
        } else {
            self.contains_null = true;
            self.bytes.push(0);
        }
    }

    pub fn finish(mut self) -> (Vec<u8>, bool) {
        if self.bytes.len() > IndexKey::MAX_INDEX_SIZE {
            let hash = xxh3_64(&self.bytes);
            self.bytes.truncate(IndexKey::MAX_INDEX_SIZE - 8);
            self.bytes.extend_from_slice(&hash.to_be_bytes());
        }
        (self.bytes, self.contains_null)
    }

    pub fn hash(&self) -> u64 {
        xxh3_64(&self.bytes)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use float_next_after::NextAfter;

    #[test]
    fn test_min() {
        let index_key = IndexKey::min();
        assert_eq!(index_key.finish(), (Vec::<u8>::new(), false));
    }

    #[test]
    fn test_max() {
        let index_key = IndexKey::max();
        assert_eq!(
            index_key.finish(),
            (vec![255, 255, 255, 255, 255, 255, 255, 255], false)
        );
    }

    #[test]
    fn test_with_buffer() {
        let bytes = vec![1, 2, 3];
        let index_key = IndexKey::with_buffer(bytes);
        assert_eq!(index_key.finish(), (Vec::<u8>::new(), false));
    }

    #[test]
    fn test_add_bool() {
        let pairs = vec![
            (None, vec![0], true),
            (Some(false), vec![1], false),
            (Some(true), vec![2], false),
        ];

        for (val, bytes, contains_null) in pairs {
            let mut index_key = IndexKey::min();
            index_key.add_bool(val);
            assert_eq!(index_key.finish(), (bytes, contains_null));
        }
    }

    #[test]
    fn test_add_byte() {
        let pairs = vec![
            (0, vec![123, 0]),
            (1, vec![123, 1]),
            (123, vec![123, 123]),
            (255, vec![123, 255]),
        ];

        for (val, bytes) in pairs {
            let mut index_key = IndexKey::min();
            index_key.add_byte(123);
            index_key.add_byte(val);
            assert_eq!(index_key.finish(), (bytes, false));
        }
    }

    #[test]
    fn test_add_int() {
        let pairs = vec![
            (i32::MIN, vec![123, 0, 0, 0, 0], true),
            (i32::MIN + 1, vec![123, 0, 0, 0, 1], false),
            (-1, vec![123, 127, 255, 255, 255], false),
            (0, vec![123, 128, 0, 0, 0], false),
            (1, vec![123, 128, 0, 0, 1], false),
            (i32::MAX - 1, vec![123, 255, 255, 255, 254], false),
            (i32::MAX, vec![123, 255, 255, 255, 255], false),
        ];

        for (val, bytes, contains_null) in pairs {
            let mut index_key = IndexKey::min();
            index_key.add_byte(123);
            index_key.add_int(val);
            assert_eq!(index_key.finish(), (bytes, contains_null));
        }
    }

    #[test]
    fn test_add_long() {
        let pairs = vec![
            (i64::MIN, vec![123, 0, 0, 0, 0, 0, 0, 0, 0], true),
            (i64::MIN + 1, vec![123, 0, 0, 0, 0, 0, 0, 0, 1], false),
            (-1, vec![123, 127, 255, 255, 255, 255, 255, 255, 255], false),
            (0, vec![123, 128, 0, 0, 0, 0, 0, 0, 0], false),
            (1, vec![123, 128, 0, 0, 0, 0, 0, 0, 1], false),
            (
                i64::MAX - 1,
                vec![123, 255, 255, 255, 255, 255, 255, 255, 254],
                false,
            ),
            (
                i64::MAX,
                vec![123, 255, 255, 255, 255, 255, 255, 255, 255],
                false,
            ),
        ];

        for (val, bytes, contains_null) in pairs {
            let mut index_key = IndexKey::min();
            index_key.add_byte(123);
            index_key.add_long(val);
            assert_eq!(index_key.finish(), (bytes, contains_null));
        }
    }

    #[test]
    fn test_add_float() {
        let pairs = vec![
            (f32::NAN, vec![123, 0, 0, 0, 0], true),
            (f32::NEG_INFINITY, vec![123, 0, 127, 255, 255], false),
            (f32::MIN, vec![123, 0, 128, 0, 0], false),
            (
                f32::MIN.next_after(f32::MAX),
                vec![123, 0, 128, 0, 1],
                false,
            ),
            (
                (-0.0).next_after(f32::MIN),
                vec![123, 127, 255, 255, 254],
                false,
            ),
            (-0.0, vec![123, 127, 255, 255, 255], false),
            (0.0, vec![123, 128, 0, 0, 0], false),
            (0.0.next_after(f32::MAX), vec![123, 128, 0, 0, 1], false),
            (
                f32::MAX.next_after(f32::MIN),
                vec![123, 255, 127, 255, 254],
                false,
            ),
            (f32::MAX, vec![123, 255, 127, 255, 255], false),
            (f32::INFINITY, vec![123, 255, 128, 0, 0], false),
        ];

        for (val, bytes, contains_null) in pairs {
            let mut index_key = IndexKey::min();
            index_key.add_byte(123);
            index_key.add_float(val);
            assert_eq!(index_key.finish(), (bytes, contains_null));
        }
    }

    #[test]
    fn test_add_double() {
        let pairs = vec![
            (f64::NAN, vec![123, 0, 0, 0, 0, 0, 0, 0, 0], true),
            (
                f64::NEG_INFINITY,
                vec![123, 0, 15, 255, 255, 255, 255, 255, 255],
                false,
            ),
            (f64::MIN, vec![123, 0, 16, 0, 0, 0, 0, 0, 0], false),
            (
                f64::MIN.next_after(f64::MAX),
                vec![123, 0, 16, 0, 0, 0, 0, 0, 1],
                false,
            ),
            (
                (-0.0).next_after(f64::MIN),
                vec![123, 127, 255, 255, 255, 255, 255, 255, 254],
                false,
            ),
            (
                -0.0,
                vec![123, 127, 255, 255, 255, 255, 255, 255, 255],
                false,
            ),
            (0.0, vec![123, 128, 0, 0, 0, 0, 0, 0, 0], false),
            (
                0.0.next_after(f64::MAX),
                vec![123, 128, 0, 0, 0, 0, 0, 0, 1],
                false,
            ),
            (
                f64::MAX.next_after(f64::MIN),
                vec![123, 255, 239, 255, 255, 255, 255, 255, 254],
                false,
            ),
            (
                f64::MAX,
                vec![123, 255, 239, 255, 255, 255, 255, 255, 255],
                false,
            ),
            (f64::INFINITY, vec![123, 255, 240, 0, 0, 0, 0, 0, 0], false),
        ];

        for (val, bytes, contains_null) in pairs {
            let mut index_key = IndexKey::min();
            index_key.add_byte(123);
            index_key.add_double(val);
            assert_eq!(index_key.finish(), (bytes, contains_null));
        }
    }

    #[test]
    fn test_add_string() {
        let pairs = vec![
            (None, vec![123, 0], true),
            (Some(""), vec![123, 1], false),
            (Some("a"), vec![123, 97], false),
            (Some("abc"), vec![123, 97, 98, 99], false),
            (Some("abcde"), vec![123, 97, 98, 99, 100, 101], false),
        ];

        for (val, bytes, contains_null) in pairs {
            let mut index_key = IndexKey::min();
            index_key.add_byte(123);
            index_key.add_string(val);
            assert_eq!(index_key.finish(), (bytes, contains_null));
        }
    }

    #[test]
    fn test_finish() {
        let long_str: String = (0..1030).map(|_| "I").collect::<String>();
        let mut bytes = vec![];
        bytes.extend_from_slice(&long_str.as_bytes()[..1016]);
        bytes.extend_from_slice(&xxh3_64(long_str.as_bytes()).to_be_bytes());

        let mut index_key = IndexKey::min();
        index_key.add_string(Some(&long_str));
        assert_eq!(index_key.finish(), (bytes, false));
    }

    #[test]
    fn test_hash() {
        let mut index_key = IndexKey::min();
        index_key.add_byte(123);
        index_key.add_string(Some("123"));

        let bytes = vec![123, 49, 50, 51];
        assert_eq!(index_key.hash(), xxh3_64(&bytes));
    }
}
