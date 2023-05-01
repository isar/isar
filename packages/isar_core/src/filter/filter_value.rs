use std::cmp::Ordering;

#[derive(PartialEq, Clone, Debug)]
pub enum FilterValue {
    Bool(Option<bool>),
    Integer(i64),
    Real(f64),
    String(Option<String>),
}

impl FilterValue {
    pub fn is_max(&self) -> bool {
        match self {
            FilterValue::Bool(value) => *value == Some(true),
            FilterValue::Integer(value) => *value == i64::MAX,
            FilterValue::Real(value) => value.is_infinite() && value.is_sign_positive(),
            FilterValue::String(maybe_value) => match maybe_value {
                Some(value) => value == "\u{10ffff}",
                None => false,
            },
        }
    }

    pub fn get_max(&self) -> Self {
        match self {
            FilterValue::Bool(_) => FilterValue::Bool(Some(true)),
            FilterValue::Integer(_) => FilterValue::Integer(i64::MAX),
            FilterValue::Real(_) => FilterValue::Real(f64::INFINITY),
            FilterValue::String(_) => FilterValue::String(Some("\u{10ffff}".to_string())),
        }
    }

    pub fn is_null(&self) -> bool {
        match self {
            FilterValue::Bool(value) => value.is_none(),
            FilterValue::Integer(value) => *value == i64::MIN,
            FilterValue::Real(value) => value.is_nan(),
            FilterValue::String(value) => value.is_none(),
        }
    }

    pub fn get_null(&self) -> Self {
        match self {
            FilterValue::Bool(_) => FilterValue::Bool(None),
            FilterValue::Integer(_) => FilterValue::Integer(i64::MIN),
            FilterValue::Real(_) => FilterValue::Real(f64::NAN),
            FilterValue::String(_) => FilterValue::String(None),
        }
    }

    pub fn try_increment(&self) -> Option<Self> {
        match self {
            FilterValue::Bool(value) => match value {
                Some(true) => None,
                Some(false) => Some(FilterValue::Bool(Some(true))),
                None => Some(FilterValue::Bool(Some(false))),
            },
            FilterValue::Integer(value) => Some(FilterValue::Integer(value.checked_add(1)?)),
            FilterValue::Real(value) => {
                if value.is_nan() {
                    Some(FilterValue::Real(f64::NEG_INFINITY))
                } else if value.is_infinite() && value.is_sign_positive() {
                    None
                } else {
                    Some(FilterValue::Real(value.next_up()))
                }
            }
            FilterValue::String(value) => {
                if let Some(value) = value {
                    if value.is_empty() {
                        return Some(FilterValue::String(Some('\u{0}'.to_string())));
                    }
                    let mut value = value.clone();
                    let last_char = value.pop()?;
                    let new_last_char = char::from_u32((last_char as u32).checked_add(1)?)?;
                    value.push(new_last_char);
                    Some(FilterValue::String(Some(value)))
                } else {
                    Some(FilterValue::String(Some(String::new())))
                }
            }
        }
    }

    pub fn try_decrement(&self) -> Option<Self> {
        match self {
            FilterValue::Bool(value) => match value {
                Some(true) => Some(FilterValue::Bool(Some(false))),
                Some(false) => Some(FilterValue::Bool(None)),
                None => None,
            },
            FilterValue::Integer(value) => Some(FilterValue::Integer(value.checked_sub(1)?)),
            FilterValue::Real(value) => {
                if value.is_nan() {
                    None
                } else if value.is_infinite() && value.is_sign_negative() {
                    Some(FilterValue::Real(f64::NAN))
                } else {
                    Some(FilterValue::Real(value.next_down()))
                }
            }
            FilterValue::String(value) => {
                let value = value.as_ref()?;
                if value.is_empty() {
                    return Some(FilterValue::String(None));
                }
                let mut value = value.clone();
                let last_char_code = value.pop()? as u32;

                // If the last char is '\0', remove it. Otherwise, decrement it.
                if last_char_code > 0 {
                    let new_last_char = char::from_u32(last_char_code - 1)?;
                    value.push(new_last_char);
                }

                Some(FilterValue::String(Some(value)))
            }
        }
    }
}

impl PartialOrd for FilterValue {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        match (self, other) {
            (FilterValue::Bool(a), FilterValue::Bool(b)) => a.partial_cmp(b),
            (FilterValue::Integer(a), FilterValue::Integer(b)) => a.partial_cmp(b),
            (FilterValue::Real(a), FilterValue::Real(b)) => a.partial_cmp(b),
            (FilterValue::String(a), FilterValue::String(b)) => a.partial_cmp(b),
            _ => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    macro_rules! bool {
        ($value:expr) => {
            FilterValue::Bool($value)
        };
    }

    macro_rules! int {
        ($value:expr) => {
            FilterValue::Integer($value)
        };
    }

    macro_rules! real {
        ($value:expr) => {
            FilterValue::Real($value)
        };
    }

    macro_rules! string {
        ($value:expr) => {
            FilterValue::String($value)
        };
    }

    mod bool_tests {
        use super::*;

        #[test]
        fn test_is_max() {
            assert!(!bool!(None).is_max());
            assert!(!bool!(Some(false)).is_max());
            assert!(bool!(Some(true)).is_max());
        }

        #[test]
        fn test_get_max() {
            let max = bool!(Some(true));

            assert_eq!(bool!(None).get_max(), max);
            assert_eq!(bool!(Some(false)).get_max(), max);
            assert_eq!(bool!(Some(true)).get_max(), max);
        }

        #[test]
        fn test_is_null() {
            assert!(bool!(None).is_null());
            assert!(!bool!(Some(false)).is_null());
            assert!(!bool!(Some(true)).is_null());
        }

        #[test]
        fn test_get_null() {
            let null = bool!(None);

            assert_eq!(bool!(None).get_null(), null);
            assert_eq!(bool!(Some(false)).get_null(), null);
            assert_eq!(bool!(Some(true)).get_null(), null);
        }

        #[test]
        fn test_try_increment() {
            assert_eq!(bool!(None).try_increment(), Some(bool!(Some(false))));
            assert_eq!(bool!(Some(false)).try_increment(), Some(bool!(Some(true))));
            assert_eq!(bool!(Some(true)).try_increment(), None);
        }

        #[test]
        fn test_try_decrement() {
            assert_eq!(bool!(None).try_decrement(), None);
            assert_eq!(bool!(Some(false)).try_decrement(), Some(bool!(None)));
            assert_eq!(bool!(Some(true)).try_decrement(), Some(bool!(Some(false))));
        }

        #[test]
        fn test_partial_cmp() {
            for left in [None, Some(false), Some(true)] {
                for right in [None, Some(false), Some(true)] {
                    assert_eq!(
                        bool!(left).partial_cmp(&bool!(right)),
                        left.partial_cmp(&right)
                    )
                }
            }

            assert_eq!(bool!(None).partial_cmp(&int!(0)), None);
            assert_eq!(bool!(Some(false)).partial_cmp(&real!(1.0)), None);
            assert_eq!(
                bool!(Some(true)).partial_cmp(&string!(Some("foobar".to_string()))),
                None
            );
        }
    }

    mod integer_tests {
        use super::*;

        #[test]
        fn test_is_max() {
            assert!(!int!(i64::MIN).is_max());
            assert!(!int!(i64::MIN + 1).is_max());
            assert!(!int!(-1).is_max());
            assert!(!int!(0).is_max());
            assert!(!int!(1).is_max());
            assert!(!int!(42).is_max());
            assert!(!int!(i64::MAX - 1).is_max());
            assert!(int!(i64::MAX).is_max());
        }

        #[test]
        fn test_get_max() {
            let max = int!(i64::MAX);

            assert_eq!(int!(i64::MIN).get_max(), max);
            assert_eq!(int!(i64::MIN + 1).get_max(), max);
            assert_eq!(int!(-1).get_max(), max);
            assert_eq!(int!(0).get_max(), max);
            assert_eq!(int!(1).get_max(), max);
            assert_eq!(int!(42).get_max(), max);
            assert_eq!(int!(i64::MAX - 1).get_max(), max);
            assert_eq!(int!(i64::MAX).get_max(), max);
        }

        #[test]
        fn test_is_null() {
            assert!(int!(i64::MIN).is_null());
            assert!(!int!(i64::MIN + 1).is_null());
            assert!(!int!(-1).is_null());
            assert!(!int!(0).is_null());
            assert!(!int!(1).is_null());
            assert!(!int!(42).is_null());
            assert!(!int!(i64::MAX - 1).is_null());
            assert!(!int!(i64::MAX).is_null());
        }

        #[test]
        fn test_get_null() {
            let null = int!(i64::MIN);

            assert_eq!(int!(i64::MIN).get_null(), null);
            assert_eq!(int!(i64::MIN + 1).get_null(), null);
            assert_eq!(int!(-1).get_null(), null);
            assert_eq!(int!(0).get_null(), null);
            assert_eq!(int!(1).get_null(), null);
            assert_eq!(int!(42).get_null(), null);
            assert_eq!(int!(i64::MAX - 1).get_null(), null);
            assert_eq!(int!(i64::MAX).get_null(), null);
        }

        #[test]
        fn test_try_increment() {
            assert_eq!(int!(i64::MIN).try_increment(), Some(int!(i64::MIN + 1)));
            assert_eq!(int!(i64::MIN + 1).try_increment(), Some(int!(i64::MIN + 2)));
            assert_eq!(int!(-1).try_increment(), Some(int!(0)));
            assert_eq!(int!(0).try_increment(), Some(int!(1)));
            assert_eq!(int!(1).try_increment(), Some(int!(2)));
            assert_eq!(int!(42).try_increment(), Some(int!(43)));
            assert_eq!(int!(i64::MAX - 1).try_increment(), Some(int!(i64::MAX)));
            assert_eq!(int!(i64::MAX).try_increment(), None);
        }

        #[test]
        fn test_try_decrement() {
            assert_eq!(int!(i64::MIN).try_decrement(), None);
            assert_eq!(int!(i64::MIN + 1).try_decrement(), Some(int!(i64::MIN)));
            assert_eq!(int!(-1).try_decrement(), Some(int!(-2)));
            assert_eq!(int!(0).try_decrement(), Some(int!(-1)));
            assert_eq!(int!(1).try_decrement(), Some(int!(0)));
            assert_eq!(int!(42).try_decrement(), Some(int!(41)));
            assert_eq!(int!(i64::MAX - 1).try_decrement(), Some(int!(i64::MAX - 2)));
            assert_eq!(int!(i64::MAX).try_decrement(), Some(int!(i64::MAX - 1)));
        }

        #[test]
        fn test_partial_cmp() {
            let values = [i64::MIN, i64::MIN + 1, -1, 0, 1, 42, i64::MAX - 1, i64::MAX];

            for left in values {
                for right in values {
                    assert_eq!(
                        int!(left).partial_cmp(&int!(right)),
                        left.partial_cmp(&right)
                    )
                }
            }

            assert_eq!(int!(-1).partial_cmp(&bool!(Some(true))), None);
            assert_eq!(int!(0).partial_cmp(&real!(1.0)), None);
            assert_eq!(
                int!(1).partial_cmp(&string!(Some("foobar".to_string()))),
                None
            );
        }
    }

    mod real_tests {
        use super::*;

        #[test]
        fn test_is_max() {
            assert!(!real!(-f64::NAN).is_max());
            assert!(!real!(f64::NEG_INFINITY).is_max());
            assert!(!real!(f64::MIN).is_max());
            assert!(!real!(f64::MIN.next_up()).is_max());
            assert!(!real!(f64::MIN + 1.0).is_max());
            assert!(!real!(-1.0).is_max());
            assert!(!real!(0f64.next_down()).is_max());
            assert!(!real!(0.0).is_max());
            assert!(!real!(0f64.next_up()).is_max());
            assert!(!real!(1.0).is_max());
            assert!(!real!(42.0).is_max());
            assert!(!real!(f64::MAX - 1.0).is_max());
            assert!(!real!(f64::MAX).is_max());
            assert!(real!(f64::INFINITY).is_max());
            assert!(!real!(f64::NAN).is_max());
        }

        #[test]
        fn test_get_max() {
            let max = real!(f64::INFINITY);

            assert_eq!(real!(-f64::NAN).get_max(), max);
            assert_eq!(real!(f64::NEG_INFINITY).get_max(), max);
            assert_eq!(real!(f64::MIN).get_max(), max);
            assert_eq!(real!(f64::MIN.next_up()).get_max(), max);
            assert_eq!(real!(f64::MIN + 1.0).get_max(), max);
            assert_eq!(real!(-1.0).get_max(), max);
            assert_eq!(real!(0f64.next_down()).get_max(), max);
            assert_eq!(real!(0.0).get_max(), max);
            assert_eq!(real!(0f64.next_up()).get_max(), max);
            assert_eq!(real!(1.0).get_max(), max);
            assert_eq!(real!(42.0).get_max(), max);
            assert_eq!(real!(f64::MAX - 1.0).get_max(), max);
            assert_eq!(real!(f64::MAX).get_max(), max);
            assert_eq!(real!(f64::INFINITY).get_max(), max);
            assert_eq!(real!(f64::NAN).get_max(), max);
        }

        #[test]
        fn test_is_null() {
            assert!(real!(-f64::NAN).is_null());
            assert!(!real!(f64::NEG_INFINITY).is_null());
            assert!(!real!(f64::MIN).is_null());
            assert!(!real!(f64::MIN.next_up()).is_null());
            assert!(!real!(f64::MIN + 1.0).is_null());
            assert!(!real!(-1.0).is_null());
            assert!(!real!(0f64.next_down()).is_null());
            assert!(!real!(0.0).is_null());
            assert!(!real!(0f64.next_up()).is_null());
            assert!(!real!(1.0).is_null());
            assert!(!real!(42.0).is_null());
            assert!(!real!(f64::MAX - 1.0).is_null());
            assert!(!real!(f64::MAX).is_null());
            assert!(!real!(f64::INFINITY).is_null());
            assert!(real!(f64::NAN).is_null());
        }

        #[test]
        fn test_get_null() {
            for value in [
                -f64::NAN,
                f64::NEG_INFINITY,
                f64::MIN,
                f64::MIN.next_up(),
                f64::MIN + 1.0,
                -1.0,
                0f64.next_down(),
                0.0,
                0f64.next_up(),
                1.0,
                42.0,
                f64::MAX - 1.0,
                f64::MAX,
                f64::INFINITY,
                f64::NAN,
            ] {
                let null_value = match real!(value).get_null() {
                    FilterValue::Real(v) => Some(v),
                    _ => None,
                };

                assert!(null_value.is_some());
                assert!(null_value.unwrap().is_nan());
            }
        }

        #[test]
        fn test_try_increment() {
            assert_eq!(
                real!(-f64::NAN).try_increment(),
                Some(real!(f64::NEG_INFINITY))
            );
            assert_eq!(
                real!(f64::NEG_INFINITY).try_increment(),
                Some(real!(f64::NEG_INFINITY.next_up()))
            );
            assert_eq!(
                real!(f64::MIN).try_increment(),
                Some(real!(f64::MIN.next_up()))
            );
            assert_eq!(
                real!(f64::MIN.next_up()).try_increment(),
                Some(real!(f64::MIN.next_up().next_up()))
            );
            assert_eq!(
                real!(f64::MIN + 1.0).try_increment(),
                Some(real!((f64::MIN + 1.0).next_up()))
            );
            assert_eq!(real!(-1.0).try_increment(), Some(real!((-1f64).next_up())));
            assert_eq!(
                real!(0f64.next_down()).try_increment(),
                Some(real!(0f64.next_down().next_up()))
            );
            assert_eq!(real!(0.0).try_increment(), Some(real!(0f64.next_up())));
            assert_eq!(
                real!(0f64.next_up()).try_increment(),
                Some(real!(0f64.next_up().next_up()))
            );
            assert_eq!(real!(1.0).try_increment(), Some(real!(1f64.next_up())));
            assert_eq!(real!(42.0).try_increment(), Some(real!(42f64.next_up())));
            assert_eq!(
                real!(f64::MAX - 1.0).try_increment(),
                Some(real!((f64::MAX - 1.0).next_up()))
            );
            assert_eq!(real!(f64::MAX).try_increment(), Some(real!(f64::INFINITY)));
            assert_eq!(real!(f64::INFINITY).try_increment(), None);
            assert_eq!(
                real!(f64::NAN).try_increment(),
                Some(real!(f64::NEG_INFINITY))
            );
        }

        #[test]
        fn test_try_decrement() {
            assert_eq!(real!(-f64::NAN).try_decrement(), None);
            let val = match real!(f64::NEG_INFINITY).try_decrement() {
                Some(FilterValue::Real(val)) => Some(val),
                _ => None,
            };
            assert!(val.is_some());
            assert!(val.unwrap().is_nan());
            assert_eq!(
                real!(f64::MIN).try_decrement(),
                Some(real!(f64::NEG_INFINITY))
            );
            assert_eq!(
                real!(f64::MIN.next_up()).try_decrement(),
                Some(real!(f64::MIN))
            );
            assert_eq!(
                real!(f64::MIN + 1.0).try_decrement(),
                Some(real!((f64::MIN + 1.0).next_down()))
            );
            assert_eq!(
                real!(-1.0).try_decrement(),
                Some(real!((-1f64).next_down()))
            );
            assert_eq!(
                real!(0f64.next_down()).try_decrement(),
                Some(real!(0f64.next_down().next_down()))
            );
            assert_eq!(real!(0.0).try_decrement(), Some(real!(0f64.next_down())));
            assert_eq!(real!(0f64.next_up()).try_decrement(), Some(real!(0f64)));
            assert_eq!(real!(1.0).try_decrement(), Some(real!(1f64.next_down())));
            assert_eq!(real!(42.0).try_decrement(), Some(real!(42f64.next_down())));
            assert_eq!(
                real!(f64::MAX - 1.0).try_decrement(),
                Some(real!((f64::MAX - 1.0).next_down()))
            );
            assert_eq!(
                real!(f64::MAX).try_decrement(),
                Some(real!(f64::MAX.next_down()))
            );
            assert_eq!(
                real!(f64::INFINITY).try_decrement(),
                Some(real!(f64::INFINITY.next_down()))
            );
            assert_eq!(real!(f64::NAN).try_decrement(), None);
        }

        #[test]
        fn test_partial_cmp() {
            let values = [
                -f64::NAN,
                f64::NEG_INFINITY,
                f64::MIN,
                f64::MIN.next_up(),
                f64::MIN + 1.0,
                -1.0,
                0f64.next_down(),
                0.0,
                0f64.next_up(),
                1.0,
                42.0,
                f64::MAX - 1.0,
                f64::MAX,
                f64::INFINITY,
                f64::NAN,
            ];

            for left in values {
                for right in values {
                    assert_eq!(
                        real!(left).partial_cmp(&real!(right)),
                        left.partial_cmp(&right)
                    );
                }
            }

            assert_eq!(real!(-1.0).partial_cmp(&bool!(None)), None);
            assert_eq!(real!(0.0).partial_cmp(&int!(0)), None);
            assert_eq!(
                real!(1.0).partial_cmp(&string!(Some("foobar".to_string()))),
                None
            );
        }
    }

    mod string_tests {
        use super::*;

        const LOREM: &str = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";

        #[test]
        fn test_is_max() {
            assert!(!string!(None).is_max());
            assert!(!string!(Some("".to_string())).is_max());
            assert!(!string!(Some("\0".to_string())).is_max());
            assert!(!string!(Some("\t".to_string())).is_max());
            assert!(!string!(Some("\n".to_string())).is_max());
            assert!(!string!(Some("\r".to_string())).is_max());
            assert!(!string!(Some("\\".to_string())).is_max());
            assert!(!string!(Some("\'".to_string())).is_max());
            assert!(!string!(Some("\"".to_string())).is_max());
            assert!(!string!(Some("\u{FFFD}".to_string())).is_max());
            assert!(!string!(Some("\u{00A0}".to_string())).is_max());
            assert!(!string!(Some("\u{200B}".to_string())).is_max());
            assert!(!string!(Some("\u{FEFF}".to_string())).is_max());
            assert!(!string!(Some("a".to_string())).is_max());
            assert!(!string!(Some("A".to_string())).is_max());
            assert!(!string!(Some("Z".to_string())).is_max());
            assert!(!string!(Some("ZZZZZZZZZZZZZ".to_string())).is_max());
            assert!(!string!(Some(LOREM.to_string())).is_max());
            assert!(string!(Some("\u{10ffff}".to_string())).is_max());
        }

        #[test]
        fn test_get_max() {
            let max = string!(Some("\u{10ffff}".to_string()));

            assert_eq!(string!(None).get_max(), max);
            assert_eq!(string!(Some("".to_string())).get_max(), max);
            assert_eq!(string!(Some("\0".to_string())).get_max(), max);
            assert_eq!(string!(Some("\t".to_string())).get_max(), max);
            assert_eq!(string!(Some("\n".to_string())).get_max(), max);
            assert_eq!(string!(Some("\r".to_string())).get_max(), max);
            assert_eq!(string!(Some("\\".to_string())).get_max(), max);
            assert_eq!(string!(Some("\'".to_string())).get_max(), max);
            assert_eq!(string!(Some("\"".to_string())).get_max(), max);
            assert_eq!(string!(Some("\u{FFFD}".to_string())).get_max(), max);
            assert_eq!(string!(Some("\u{00A0}".to_string())).get_max(), max);
            assert_eq!(string!(Some("\u{200B}".to_string())).get_max(), max);
            assert_eq!(string!(Some("\u{FEFF}".to_string())).get_max(), max);
            assert_eq!(string!(Some("a".to_string())).get_max(), max);
            assert_eq!(string!(Some("A".to_string())).get_max(), max);
            assert_eq!(string!(Some("Z".to_string())).get_max(), max);
            assert_eq!(string!(Some("ZZZZZZZZZZZZZ".to_string())).get_max(), max);
            assert_eq!(string!(Some(LOREM.to_string())).get_max(), max);
            assert_eq!(string!(Some("\u{10ffff}".to_string())).get_max(), max);
        }

        #[test]
        fn test_is_null() {
            assert!(string!(None).is_null());
            assert!(!string!(Some("".to_string())).is_null());
            assert!(!string!(Some("\0".to_string())).is_null());
            assert!(!string!(Some("\t".to_string())).is_null());
            assert!(!string!(Some("\n".to_string())).is_null());
            assert!(!string!(Some("\r".to_string())).is_null());
            assert!(!string!(Some("\\".to_string())).is_null());
            assert!(!string!(Some("\'".to_string())).is_null());
            assert!(!string!(Some("\"".to_string())).is_null());
            assert!(!string!(Some("\u{FFFD}".to_string())).is_null());
            assert!(!string!(Some("\u{00A0}".to_string())).is_null());
            assert!(!string!(Some("\u{200B}".to_string())).is_null());
            assert!(!string!(Some("\u{FEFF}".to_string())).is_null());
            assert!(!string!(Some("a".to_string())).is_null());
            assert!(!string!(Some("A".to_string())).is_null());
            assert!(!string!(Some("Z".to_string())).is_null());
            assert!(!string!(Some("ZZZZZZZZZZZZZ".to_string())).is_null());
            assert!(!string!(Some(LOREM.to_string())).is_null());
            assert!(!string!(Some("\u{10ffff}".to_string())).is_null());
        }

        #[test]
        fn test_get_null() {
            let null = string!(None);

            assert_eq!(string!(None).get_null(), null);
            assert_eq!(string!(Some("".to_string())).get_null(), null);
            assert_eq!(string!(Some("\0".to_string())).get_null(), null);
            assert_eq!(string!(Some("\t".to_string())).get_null(), null);
            assert_eq!(string!(Some("\n".to_string())).get_null(), null);
            assert_eq!(string!(Some("\r".to_string())).get_null(), null);
            assert_eq!(string!(Some("\\".to_string())).get_null(), null);
            assert_eq!(string!(Some("\'".to_string())).get_null(), null);
            assert_eq!(string!(Some("\"".to_string())).get_null(), null);
            assert_eq!(string!(Some("\u{FFFD}".to_string())).get_null(), null);
            assert_eq!(string!(Some("\u{00A0}".to_string())).get_null(), null);
            assert_eq!(string!(Some("\u{200B}".to_string())).get_null(), null);
            assert_eq!(string!(Some("\u{FEFF}".to_string())).get_null(), null);
            assert_eq!(string!(Some("a".to_string())).get_null(), null);
            assert_eq!(string!(Some("A".to_string())).get_null(), null);
            assert_eq!(string!(Some("Z".to_string())).get_null(), null);
            assert_eq!(string!(Some("ZZZZZZZZZZZZZ".to_string())).get_null(), null);
            assert_eq!(string!(Some(LOREM.to_string())).get_null(), null);
            assert_eq!(string!(Some("\u{10ffff}".to_string())).get_null(), null);
        }

        #[test]
        fn test_try_increment() {
            assert_eq!(
                string!(None).try_increment(),
                Some(string!(Some("".to_string())))
            );
            assert_eq!(
                string!(Some("".to_string())).try_increment(),
                Some(string!(Some("\0".to_string())))
            );
            assert_eq!(
                string!(Some("\0".to_string())).try_increment(),
                Some(string!(Some("\u{1}".to_string())))
            );

            assert_eq!(
                string!(Some("\t".to_string())).try_increment(),
                Some(string!(Some("\n".to_string())))
            );
            assert_eq!(
                string!(Some("\n".to_string())).try_increment(),
                Some(string!(Some("\u{B}".to_string())))
            );
            assert_eq!(
                string!(Some("\r".to_string())).try_increment(),
                Some(string!(Some("\u{E}".to_string())))
            );
            assert_eq!(
                string!(Some("\\".to_string())).try_increment(),
                Some(string!(Some("\u{5D}".to_string())))
            );
            assert_eq!(
                string!(Some("\'".to_string())).try_increment(),
                Some(string!(Some("\u{28}".to_string())))
            );
            assert_eq!(
                string!(Some("\"".to_string())).try_increment(),
                Some(string!(Some("\u{23}".to_string())))
            );
            assert_eq!(
                string!(Some("\u{FFFD}".to_string())).try_increment(),
                Some(string!(Some("\u{FFFE}".to_string())))
            );
            assert_eq!(
                string!(Some("\u{00A0}".to_string())).try_increment(),
                Some(string!(Some("\u{00A1}".to_string())))
            );
            assert_eq!(
                string!(Some("\u{FEFF}".to_string())).try_increment(),
                Some(string!(Some("\u{FF00}".to_string())))
            );
            assert_eq!(
                string!(Some("a".to_string())).try_increment(),
                Some(string!(Some("b".to_string())))
            );
            assert_eq!(
                string!(Some("A".to_string())).try_increment(),
                Some(string!(Some("B".to_string())))
            );
            assert_eq!(
                string!(Some("Z".to_string())).try_increment(),
                Some(string!(Some("[".to_string())))
            );
            assert_eq!(
                string!(Some("ZZZZZZZZZZZZZ".to_string())).try_increment(),
                Some(string!(Some("ZZZZZZZZZZZZ[".to_string())))
            );
            assert_eq!(
                string!(Some(LOREM.to_string())).try_increment(),
                Some(string!(Some(format!(
                    "{}{}",
                    &LOREM[..LOREM.len() - 1],
                    char::from_u32(LOREM.chars().last().unwrap_or('\0') as u32 + 1).unwrap()
                ))))
            );
            assert_eq!(
                string!(Some("\u{10ffff}".to_string())).try_increment(),
                None,
            );
        }

        #[test]
        fn test_try_decrement() {
            assert_eq!(string!(None).try_decrement(), None);
            assert_eq!(
                string!(Some("".to_string())).try_decrement(),
                Some(string!(None))
            );
            assert_eq!(
                string!(Some("\0".to_string())).try_decrement(),
                Some(string!(Some("".to_string())))
            );
            assert_eq!(
                string!(Some("\t".to_string())).try_decrement(),
                Some(string!(Some("\u{8}".to_string())))
            );
            assert_eq!(
                string!(Some("\n".to_string())).try_decrement(),
                Some(string!(Some("\t".to_string())))
            );
            assert_eq!(
                string!(Some("\r".to_string())).try_decrement(),
                Some(string!(Some("\u{C}".to_string())))
            );
            assert_eq!(
                string!(Some("\\".to_string())).try_decrement(),
                Some(string!(Some("[".to_string())))
            );
            assert_eq!(
                string!(Some("\'".to_string())).try_decrement(),
                Some(string!(Some("&".to_string())))
            );
            assert_eq!(
                string!(Some("\"".to_string())).try_decrement(),
                Some(string!(Some("!".to_string())))
            );
            assert_eq!(
                string!(Some("\u{FFFD}".to_string())).try_decrement(),
                Some(string!(Some("\u{FFFC}".to_string())))
            );
            assert_eq!(
                string!(Some("\u{00A0}".to_string())).try_decrement(),
                Some(string!(Some("\u{009F}".to_string())))
            );
            assert_eq!(
                string!(Some("\u{FEFF}".to_string())).try_decrement(),
                Some(string!(Some("\u{FEFE}".to_string())))
            );
            assert_eq!(
                string!(Some("a".to_string())).try_decrement(),
                Some(string!(Some("`".to_string())))
            );
            assert_eq!(
                string!(Some("A".to_string())).try_decrement(),
                Some(string!(Some("@".to_string())))
            );
            assert_eq!(
                string!(Some("Z".to_string())).try_decrement(),
                Some(string!(Some("Y".to_string())))
            );
            assert_eq!(
                string!(Some("ZZZZZZZZZZZZZ".to_string())).try_decrement(),
                Some(string!(Some("ZZZZZZZZZZZZY".to_string())))
            );
            assert_eq!(
                string!(Some(LOREM.to_string())).try_decrement(),
                Some(string!(Some(format!(
                    "{}{}",
                    &LOREM[..LOREM.len() - 1],
                    char::from_u32(LOREM.chars().last().unwrap_or('\0') as u32 - 1).unwrap()
                ))))
            );
            assert_eq!(
                string!(Some("\u{10ffff}".to_string())).try_decrement(),
                Some(string!(Some("\u{10fffe}".to_string())))
            );
        }

        #[test]
        fn test_partial_cmp() {
            let values = [
                None,
                Some("".to_string()),
                Some("\0".to_string()),
                Some("\t".to_string()),
                Some("\n".to_string()),
                Some("\r".to_string()),
                Some("\\".to_string()),
                Some("\'".to_string()),
                Some("\"".to_string()),
                Some("\u{FFFD}".to_string()),
                Some("\u{00A0}".to_string()),
                Some("\u{200B}".to_string()),
                Some("\u{FEFF}".to_string()),
                Some("a".to_string()),
                Some("A".to_string()),
                Some("Z".to_string()),
                Some("ZZZZZZZZZZZZZ".to_string()),
                Some(LOREM.to_string()),
                Some("\u{10ffff}".to_string()),
            ];

            for left in &values {
                for right in &values {
                    assert_eq!(
                        string!(left.clone()).partial_cmp(&string!(right.clone())),
                        left.partial_cmp(right)
                    );
                }
            }

            assert_eq!(string!(None).partial_cmp(&bool!(None)), None);
            assert_eq!(string!(Some("".to_string())).partial_cmp(&int!(0)), None);
            assert_eq!(
                string!(Some(LOREM.to_string())).partial_cmp(&real!(20.0)),
                None
            );
        }
    }
}
