use xxhash_rust::xxh3::xxh3_64;

const PRIME32: u64 = 2654435761;
const PRIME64: u64 = 11400714785074694797;

#[test]
fn test_xxh3() {
    fn generate_test_data(len: u64) -> Vec<u8> {
        let mut byte_gen = PRIME32;

        let mut buffer = Vec::new();
        for _ in 0..len {
            buffer.push((byte_gen >> 56) as u8);
            let (b, _) = byte_gen.overflowing_mul(PRIME64);
            byte_gen = b;
        }

        buffer
    }

    let data = vec![
        (0u64, 0x2D06800538D394C2u64), /* empty string */
        (1, 0xC44BDFF4074EECDB),       /*  1 -  3 */
        (6, 0x27B56A84CD2D7325),       /*  4 -  8 */
        (12, 0xA713DAF0DFBB77E7),      /*  9 - 16 */
        (24, 0xA3FE70BF9D3510EB),      /* 17 - 32 */
        (48, 0x397DA259ECBA1F11),      /* 33 - 64 */
        (80, 0xBCDEFBBB2C47C90A),      /* 65 - 96 */
        (195, 0xCD94217EE362EC3A),     /* 129-240 */
        (403, 0xCDEB804D65C6DEA4),     /* one block, last stripe is overlapping */
        (512, 0x617E49599013CB6B),     /* one block, finishing at stripe boundary */
        (2048, 0xDD59E2C3A5F038E0),    /* 2 blocks, finishing at block boundary */
        (2240, 0x6E73A90539CF2948),    /* 3 blocks, finishing at stripe boundary */
        (2367, 0xCB37AEB9E5D361ED),    /* 3 blocks, last stripe is overlapping */
    ];
    for (len, output) in data {
        let input = generate_test_data(len);
        assert_eq!(xxh3_64(&input), output);
    }
}
