use std::{collections::HashMap, fs};

use intmap::IntMap;
use isar_core::object::isar_object::IsarObject;
use isar_core::object::json_encode_decode::JsonEncodeDecode;
use isar_core::object::object_builder::ObjectBuilder;
use isar_core::object::{data_type::DataType, property::Property};
use isar_core::schema::collection_schema::CollectionSchema;
use isar_core::schema::property_schema::PropertySchema;
use itertools::Itertools;
use serde::{Deserialize, Serialize};
use serde_json::{from_str, json, Value};

#[derive(PartialEq, Eq, Serialize, Deserialize, Clone)]
pub struct BinaryTest {
    pub types: Vec<DataType>,
    pub values: Vec<Value>,
    pub bytes: Vec<u8>,
}

impl BinaryTest {
    fn create(data: &[(DataType, Value)]) -> Self {
        let (types, values): (Vec<_>, Vec<_>) = data.iter().cloned().unzip();
        let properties = Self::create_properties(&types);
        let embedded_properties = IntMap::new();
        let json = Self::create_temp_json(&properties, &values);
        let mut ob = ObjectBuilder::new(&properties, None);
        JsonEncodeDecode::decode(&properties, &embedded_properties, &mut ob, &json).unwrap();
        BinaryTest {
            types,
            values,
            bytes: ob.finish().as_bytes().to_vec(),
        }
    }

    fn create_properties(types: &[DataType]) -> Vec<Property> {
        let prop_schemas = types
            .iter()
            .enumerate()
            .map(|(i, t)| PropertySchema::new(Some(format!("{}", i)), *t, None))
            .collect();
        let schema = CollectionSchema::new("col", false, prop_schemas, vec![], vec![]);
        schema.get_properties()
    }

    fn create_temp_json(properties: &[Property], values: &[Value]) -> Value {
        let map: HashMap<String, Value> = properties
            .iter()
            .zip(values.iter())
            .map(|(p, v)| (p.name.clone(), v.clone()))
            .collect();
        json!(map)
    }
}

fn generate_binary_golden() -> Vec<BinaryTest> {
    let bool_blocks = (DataType::Bool, vec![json!(null), json!(true), json!(false)]);
    let byte_blocks = (DataType::Byte, vec![json!(0), json!(123), json!(255)]);
    let int_blocks = (
        DataType::Int,
        vec![
            json!(null),
            json!(i32::MIN + 1),
            json!(0i32),
            json!(i32::MAX),
        ],
    );
    let float_blocks = (
        DataType::Float,
        vec![
            json!(f32::MIN),
            json!(-0f32),
            json!(0f32),
            json!(core::f32::consts::PI),
            json!(f32::MAX),
        ],
    );
    let long_blocks = (
        DataType::Long,
        vec![
            json!(null),
            json!(i64::MIN + 1),
            json!(0i64),
            json!(i64::MAX),
        ],
    );
    let double_blocks = (
        DataType::Double,
        vec![
            json!(f64::MIN),
            json!(-0f64),
            json!(0f64),
            json!(core::f64::consts::PI),
            json!(f64::MAX),
        ],
    );
    let string_blocks = (
        DataType::String,
        vec![
            json!(null),
            json!(""),
            json!("a"),
            json!("רוצח עז קטנה"),
            json!("👱👱🏻👱🏼👱🏽👱🏾👱🏿👨‍❤️‍💋‍👨👩‍👩‍👧‍👦🏳️‍⚧️🇵🇷"),
            json!("Z̤͔ͧ̑̓ä͖̭̈̇lͮ̒ͫǧ̗͚̚o̙̔ͮ̇͐̇"),
        ],
    );
    let bool_list_blocks = (
        DataType::BoolList,
        vec![
            json!(null),
            json!([]),
            json!([null]),
            json!([null, null, null]),
            json!([true]),
            json!([false]),
            json!([true, null, false, null]),
        ],
    );
    let byte_list_blocks = (
        DataType::ByteList,
        vec![json!([]), json!([255]), json!([0]), json!([255, 0, 0, 255])],
    );
    let int_list_blocks = (
        DataType::IntList,
        vec![
            json!(null),
            json!([]),
            json!([null]),
            json!([null, null, null]),
            json!([12345i32]),
            json!([null, i32::MIN + 1, null, i32::MAX]),
        ],
    );
    let float_list_blocks = (
        DataType::FloatList,
        vec![
            json!(null),
            json!([]),
            json!([-0f32, 0f32]),
            json!([f32::MIN, std::f32::consts::PI, f32::MAX]),
        ],
    );
    let long_list_blocks = (
        DataType::LongList,
        vec![
            json!(null),
            json!([]),
            json!([null]),
            json!([null, null, null]),
            json!([-324234643i64]),
            json!([null, i64::MIN + 1, null, null, i64::MAX]),
        ],
    );
    let double_list_blocks = (
        DataType::DoubleList,
        vec![
            json!(null),
            json!([]),
            json!([-0f64, 0f64]),
            json!([f64::MIN, std::f64::consts::PI, f64::MAX]),
        ],
    );
    let string_list_blocks = (
        DataType::StringList,
        vec![
            json!(null),
            json!([]),
            json!([null]),
            json!([null, null]),
            json!([null, null, null]),
            json!([""]),
            json!(["", ""]),
            json!(["", "", ""]),
            json!(["", null]),
            json!([null, ""]),
            json!(["", null, null]),
            json!([null, "", null]),
            json!([null, null, ""]),
            json!([null, "", ""]),
            json!(["", null, ""]),
            json!(["", "", null]),
            json!(["a"]),
            json!(["a", "ab"]),
            json!(["a", "ab", "abc"]),
            json!([null, "a"]),
            json!(["a", null]),
            json!([null, "a"]),
            json!(["a", null, null]),
            json!([null, "a", null]),
            json!([null, null, "a"]),
            json!([null, "a", "bbb"]),
            json!(["a", null, "bbb"]),
            json!(["a", "bbb", null]),
        ],
    );

    let mut combinations = vec![];

    let static_blocks = normalize(&[
        bool_blocks,
        byte_blocks,
        int_blocks,
        float_blocks,
        long_blocks,
        double_blocks,
    ]);

    for case1 in &static_blocks {
        combinations.push(vec![case1.clone()]);
        for case2 in &static_blocks {
            combinations.push(vec![case1.clone(), case2.clone()]);
            for case3 in &static_blocks {
                combinations.push(vec![case1.clone(), case2.clone(), case3.clone()]);
            }
        }
    }

    let dynamic_blocks = normalize(&[
        string_blocks,
        bool_list_blocks,
        byte_list_blocks,
        int_list_blocks,
        float_list_blocks,
        long_list_blocks,
        double_list_blocks,
    ]);

    for case1 in &dynamic_blocks {
        combinations.push(vec![case1.clone()]);
        for case2 in &dynamic_blocks {
            combinations.push(vec![case1.clone(), case2.clone()]);
            for case3 in &dynamic_blocks {
                combinations.push(vec![case1.clone(), case2.clone(), case3.clone()]);
            }
        }
    }

    let string_list_blocks = normalize(&[string_list_blocks]);
    for case1 in &string_list_blocks {
        combinations.push(vec![case1.clone()]);
        for case2 in &string_list_blocks {
            combinations.push(vec![case1.clone(), case2.clone()]);
            for case3 in &string_list_blocks {
                combinations.push(vec![case1.clone(), case2.clone(), case3.clone()]);
            }
        }
    }

    for case1 in &static_blocks {
        for case2 in &dynamic_blocks {
            combinations.push(vec![case1.clone(), case2.clone()]);
            combinations.push(vec![case2.clone(), case1.clone()]);
        }
    }

    for case1 in &static_blocks {
        for case2 in &string_list_blocks {
            combinations.push(vec![case1.clone(), case2.clone()]);
            combinations.push(vec![case2.clone(), case1.clone()]);
        }
    }

    for case1 in &dynamic_blocks {
        for case2 in &string_list_blocks {
            combinations.push(vec![case1.clone(), case2.clone()]);
            combinations.push(vec![case2.clone(), case1.clone()]);
        }
    }

    combinations
        .into_iter()
        .map(|cases| BinaryTest::create(&cases))
        .collect()
}

fn normalize(blocks: &[(DataType, Vec<Value>)]) -> Vec<(DataType, Value)> {
    blocks
        .into_iter()
        .flat_map(|(t, blocks)| blocks.into_iter().map(move |b| (*t, b.clone())))
        .collect_vec()
}

#[allow(dead_code)]
fn overwrite_binary_golden() {
    let tests = generate_binary_golden();
    let json = json!(tests);
    fs::write("tests/binary_golden.json", json.to_string()).unwrap();
}

#[test]
fn test_binary_serialize() {
    let golden_str = fs::read_to_string("tests/binary_golden.json").unwrap();
    let golden = from_str::<Vec<BinaryTest>>(&golden_str).unwrap();
    for test in golden.iter() {
        let properties = BinaryTest::create_properties(&test.types);
        let embedded_properties = IntMap::new();
        let golden_json = BinaryTest::create_temp_json(&properties, &test.values);
        let mut ob = ObjectBuilder::new(&properties, None);
        JsonEncodeDecode::decode(&properties, &embedded_properties, &mut ob, &golden_json).unwrap();
        let bytes = ob.finish().as_bytes();
        if bytes != test.bytes {
            assert_eq!(bytes, test.bytes);
        }
    }
}

#[test]
fn test_binary_parse() {
    let golden_str = fs::read_to_string("tests/binary_golden.json").unwrap();
    let golden = from_str::<Vec<BinaryTest>>(&golden_str).unwrap();
    for test in golden.iter() {
        let properties = BinaryTest::create_properties(&test.types);
        let embedded_properties = IntMap::new();
        let golden_json = BinaryTest::create_temp_json(&properties, &test.values);
        let object = IsarObject::from_bytes(&test.bytes);
        let generated_map =
            JsonEncodeDecode::encode(&properties, &embedded_properties, object, true);
        let generated_json = json!(generated_map);
        if generated_json != golden_json {
            assert_eq!(generated_json, golden_json);
        }
    }
}
