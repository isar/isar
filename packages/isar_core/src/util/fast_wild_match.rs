const ASTERISK: u8 = 42;
const QUESTION_MARK: u8 = 63;

pub(crate) fn fast_wild_match(tame: &str, wild: &str) -> bool {
    let wild = wild.as_bytes();
    let tame = tame.as_bytes();
    let mut i_wild = 0;
    let mut i_tame = 0;
    let mut i_last = 0;
    let mut i_star = 0;

    while tame.get(i_tame).is_some() {
        match wild.get(i_wild) {
            Some(&QUESTION_MARK) => {
                i_tame += 1;
                i_wild += 1;
                continue;
            }
            Some(&ASTERISK) => {
                loop {
                    i_wild += 1;
                    if wild.get(i_wild) != Some(&ASTERISK) {
                        break;
                    }
                }
                if wild.get(i_wild).is_none() {
                    return true;
                }
                i_star = i_wild;
            }
            _ => {
                if tame.get(i_tame) == wild.get(i_wild) {
                    i_tame += 1;
                    i_wild += 1;
                    continue;
                }
                if i_star == 0 {
                    return false;
                }
                i_wild = i_star;
                i_tame = i_last + 1;
            }
        }

        while tame.get(i_tame) != wild.get(i_wild) && wild.get(i_wild) != Some(&QUESTION_MARK) {
            i_tame += 1;
            if tame.get(i_tame).is_none() {
                return false;
            }
        }
        i_last = i_tame;
        i_tame += 1;
        i_wild += 1;
    }
    while wild.get(i_wild) == Some(&ASTERISK) {
        i_wild += 1;
    }
    wild.get(i_wild).is_none()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_wild() {
        let wild_cases = vec![
            ("Hi", "Hi*", true),
            ("abc", "ab*d", false),
            ("abcccd", "*ccd", true),
            ("mississipissippi", "*issip*ss*", true),
            ("xxxx*zzzzzzzzy*f", "xxxx*zzy*fffff", false),
            ("xxxx*zzzzzzzzy*f", "xxx*zzy*f", true),
            ("xxxxzzzzzzzzyf", "xxxx*zzy*fffff", false),
            ("xxxxzzzzzzzzyf", "xxxx*zzy*f", true),
            ("xyxyxyzyxyz", "xy*z*xyz", true),
            ("mississippi", "*sip*", true),
            ("xyxyxyxyz", "xy*xyz", true),
            ("mississippi", "mi*sip*", true),
            ("ababac", "*abac*", true),
            ("ababac", "*abac*", true),
            ("aaazz", "a*zz*", true),
            ("a12b12", "*12*23", false),
            ("a12b12", "a12b", false),
            ("a12b12", "*12*12*", true),
            ("caaab", "*a?b", true),
            ("*", "*", true),
            ("a*abab", "a*b", true),
            ("a*r", "a*", true),
            ("a*ar", "a*aar", false),
            ("XYXYXYZYXYz", "XY*Z*XYz", true),
            ("missisSIPpi", "*SIP*", true),
            ("mississipPI", "*issip*PI", true),
            ("xyxyxyxyz", "xy*xyz", true),
            ("miSsissippi", "mi*sip*", true),
            ("miSsissippi", "mi*Sip*", false),
            ("abAbac", "*Abac*", true),
            ("abAbac", "*Abac*", true),
            ("aAazz", "a*zz*", true),
            ("A12b12", "*12*23", false),
            ("a12B12", "*12*12*", true),
            ("oWn", "*oWn*", true),
            ("bLah", "bLah", true),
            ("bLah", "bLaH", false),
            ("a", "*?", true),
            ("ab", "*?", true),
            ("abc", "*?", true),
            ("a", "??", false),
            ("ab", "?*?", true),
            ("ab", "*?*?*", true),
            ("abc", "?**?*?", true),
            ("abc", "?**?*&?", false),
            ("abcd", "?b*??", true),
            ("abcd", "?a*??", false),
            ("abcd", "?**?c?", true),
            ("abcd", "?**?d?", false),
            ("abcde", "?*b*?*d*?", true),
            ("bLah", "bL?h", true),
            ("bLaaa", "bLa?", false),
            ("bLah", "bLa?", true),
            ("bLaH", "?Lah", false),
            ("bLaH", "?LaH", true),
            ("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab", "a*a*a*a*a*a*aa*aaa*a*a*b", true),
            ("abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab", "*a*b*ba*ca*a*aa*aaa*fa*ga*b*", true),
            ("abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab", "*a*b*ba*ca*a*x*aaa*fa*ga*b*", false),
            ("abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab", "*a*b*ba*ca*aaaa*fa*ga*gggg*b*", false),
            ("abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab", "*a*b*ba*ca*aaaa*fa*ga*ggg*b*", true),
            ("aaabbaabbaab", "*aabbaa*a*", true),
            ("a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*", "a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*", true),
            ("aaaaaaaaaaaaaaaaa", "*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*", true),
            ("aaaaaaaaaaaaaaaa", "*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*", false),
            ("abc*abcd*abcde*abcdef*abcdefg*abcdefgh*abcdefghi*abcdefghij*abcdefghijk*abcdefghijkl*abcdefghijklm*abcdefghijklmn", "abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*", false),
            ("abc*abcd*abcde*abcdef*abcdefg*abcdefgh*abcdefghi*abcdefghij*abcdefghijk*abcdefghijkl*abcdefghijklm*abcdefghijklmn", "abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*", true),
            ("abc*abcd*abcd*abc*abcd", "abc*abc*abc*abc*abc", false),
            ("abc*abcd*abcd*abc*abcd*abcd*abc*abcd*abc*abc*abcd", "abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abcd", true),
            ("abc", "********a********b********c********", true),
            ("********a********b********c********", "abc", false),
            ("abc", "********a********b********b********", false),
            ("*abc*", "***a*b*c***", true),
            ("", "?", false),
            ("", "*?", false),
            ("", "", true),
            ("", "*", true),
            ("a", "", false),
        ];

        for (tame, wild, result) in wild_cases {
            assert_eq!(fast_wild_match(tame, wild), result);
        }
    }

    #[test]
    fn test_tame() {
        let tame_cases = vec![
            ("abc", "abd", false),
            ("abcccd", "abcccd", true),
            ("mississipissippi", "mississipissippi", true),
            ("xxxxzzzzzzzzyf", "xxxxzzzzzzzzyfffff", false),
            ("xxxxzzzzzzzzyf", "xxxxzzzzzzzzyf", true),
            ("xxxxzzzzzzzzyf", "xxxxzzy.fffff", false),
            ("xxxxzzzzzzzzyf", "xxxxzzzzzzzzyf", true),
            ("xyxyxyzyxyz", "xyxyxyzyxyz", true),
            ("mississippi", "mississippi", true),
            ("xyxyxyxyz", "xyxyxyxyz", true),
            ("m ississippi", "m ississippi", true),
            ("ababac", "ababac?", false),
            ("dababac", "ababac", false),
            ("aaazz", "aaazz", true),
            ("a12b12", "1212", false),
            ("a12b12", "a12b", false),
            ("a12b12", "a12b12", true),
            ("n", "n", true),
            ("aabab", "aabab", true),
            ("ar", "ar", true),
            ("aar", "aaar", false),
            ("XYXYXYZYXYz", "XYXYXYZYXYz", true),
            ("missisSIPpi", "missisSIPpi", true),
            ("mississipPI", "mississipPI", true),
            ("xyxyxyxyz", "xyxyxyxyz", true),
            ("miSsissippi", "miSsissippi", true),
            ("miSsissippi", "miSsisSippi", false),
            ("abAbac", "abAbac", true),
            ("abAbac", "abAbac", true),
            ("aAazz", "aAazz", true),
            ("A12b12", "A12b123", false),
            ("a12B12", "a12B12", true),
            ("oWn", "oWn", true),
            ("bLah", "bLah", true),
            ("bLah", "bLaH", false),
            ("a", "a", true),
            ("ab", "a?", true),
            ("abc", "ab?", true),
            ("a", "??", false),
            ("ab", "??", true),
            ("abc", "???", true),
            ("abcd", "????", true),
            ("abc", "????", false),
            ("abcd", "?b??", true),
            ("abcd", "?a??", false),
            ("abcd", "??c?", true),
            ("abcd", "??d?", false),
            ("abcde", "?b?d*?", true),
            (
                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab",
                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab",
                true,
            ),
            (
                "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
                "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
                true,
            ),
            (
                "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
                "abababababababababababababababababababaacacacacacacacadaeafagahaiajaxalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
                false,
            ),
            (
                "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
                "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaggggagaaaaaaaab",
                false,
            ),
            (
                "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
                "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
                true,
            ),
            ("aaabbaabbaab", "aaabbaabbaab", true),
            ("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", true,
            ),
            ("aaaaaaaaaaaaaaaaa", "aaaaaaaaaaaaaaaaa", true),
            ("aaaaaaaaaaaaaaaa", "aaaaaaaaaaaaaaaaa", false),
            (
                "abcabcdabcdeabcdefabcdefgabcdefghabcdefghiabcdefghijabcdefghijkabcdefghijklabcdefghijklmabcdefghijklmn",
                "abcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabc",
                false,
            ),
            (
                "abcabcdabcdeabcdefabcdefgabcdefghabcdefghiabcdefghijabcdefghijkabcdefghijklabcdefghijklmabcdefghijklmn",
                "abcabcdabcdeabcdefabcdefgabcdefghabcdefghiabcdefghijabcdefghijkabcdefghijklabcdefghijklmabcdefghijklmn",
                true,
            ),
            ("abcabcdabcdabcabcd", "abcabc?abcabcabc", false),
            (
                "abcabcdabcdabcabcdabcdabcabcdabcabcabcd",
                "abcabc?abc?abcabc?abc?abc?bc?abc?bc?bcd",
                true,
            ),
            ("?abc?", "?abc?", true),
        ];

        for (tame, wild, result) in tame_cases {
            assert_eq!(fast_wild_match(tame, wild), result);
        }
    }

    #[test]
    fn test_empty() {
        let empty_cases = vec![
            ("", "abd", false),
            ("", "abcccd", false),
            ("", "mississipissippi", false),
            ("", "xxxxzzzzzzzzyfffff", false),
            ("", "xxxxzzzzzzzzyf", false),
            ("", "xxxxzzy.fffff", false),
            ("", "xxxxzzzzzzzzyf", false),
            ("", "xyxyxyzyxyz", false),
            ("", "mississippi", false),
            ("", "xyxyxyxyz", false),
            ("", "m ississippi", false),
            ("", "ababac*", false),
            ("", "ababac", false),
            ("", "aaazz", false),
            ("", "1212", false),
            ("", "a12b", false),
            ("", "a12b12", false),
            // A mix of cases
            ("", "n", false),
            ("", "aabab", false),
            ("", "ar", false),
            ("", "aaar", false),
            ("", "XYXYXYZYXYz", false),
            ("", "missisSIPpi", false),
            ("", "mississipPI", false),
            ("", "xyxyxyxyz", false),
            ("", "miSsissippi", false),
            ("", "miSsisSippi", false),
            ("", "abAbac", false),
            ("", "abAbac", false),
            ("", "aAazz", false),
            ("", "A12b123", false),
            ("", "a12B12", false),
            ("", "oWn", false),
            ("", "bLah", false),
            ("", "bLaH", false),
            ("", "", true),
            ("abc", "", false),
            ("abcccd", "", false),
            ("mississipissippi", "", false),
            ("xxxxzzzzzzzzyf", "", false),
            ("xxxxzzzzzzzzyf", "", false),
            ("xxxxzzzzzzzzyf", "", false),
            ("xxxxzzzzzzzzyf", "", false),
            ("xyxyxyzyxyz", "", false),
            ("mississippi", "", false),
            ("xyxyxyxyz", "", false),
            ("m ississippi", "", false),
            ("ababac", "", false),
            ("dababac", "", false),
            ("aaazz", "", false),
            ("a12b12", "", false),
            ("a12b12", "", false),
            ("a12b12", "", false),
            ("n", "", false),
            ("aabab", "", false),
            ("ar", "", false),
            ("aar", "", false),
            ("XYXYXYZYXYz", "", false),
            ("missisSIPpi", "", false),
            ("mississipPI", "", false),
            ("xyxyxyxyz", "", false),
            ("miSsissippi", "", false),
            ("miSsissippi", "", false),
            ("abAbac", "", false),
            ("abAbac", "", false),
            ("aAazz", "", false),
            ("A12b12", "", false),
            ("a12B12", "", false),
            ("oWn", "", false),
            ("bLah", "", false),
            ("bLah", "", false),
        ];

        for (tame, wild, result) in empty_cases {
            assert_eq!(fast_wild_match(tame, wild), result);
        }
    }
}
