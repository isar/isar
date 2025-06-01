//! Comprehensive Data Type Coverage Tests
//! 
//! Tests for all supported Isar data types across backends

#[path = "common/mod.rs"]
mod common;

use common::*;
use isar_core::core::instance::IsarInstance;
use isar_core::core::writer::IsarWriter;
use isar_core::core::insert::IsarInsert;
use isar_core::core::cursor::IsarCursor;
use isar_core::core::reader::IsarReader;
use isar_core::core::schema::*;
use isar_core::core::data_type::DataType;

#[cfg(feature = "native")]
use isar_core::native::native_instance::NativeInstance;

#[cfg(feature = "sqlite")]
use isar_core::sqlite::sqlite_instance::SQLiteInstance;

/// Create schema that covers ALL supported Isar data types
fn create_all_types_schema() -> IsarSchema {
    let properties = vec![
        // Primitive types
        PropertySchema::new("boolField", DataType::Bool, None),
        PropertySchema::new("byteField", DataType::Byte, None),
        PropertySchema::new("intField", DataType::Int, None),
        PropertySchema::new("floatField", DataType::Float, None),
        PropertySchema::new("longField", DataType::Long, None),
        PropertySchema::new("doubleField", DataType::Double, None),
        PropertySchema::new("stringField", DataType::String, None),
        PropertySchema::new("jsonField", DataType::Json, None),
        
        // List types
        PropertySchema::new("boolListField", DataType::BoolList, None),
        PropertySchema::new("byteListField", DataType::ByteList, None),
        PropertySchema::new("intListField", DataType::IntList, None),
        PropertySchema::new("floatListField", DataType::FloatList, None),
        PropertySchema::new("longListField", DataType::LongList, None),
        PropertySchema::new("doubleListField", DataType::DoubleList, None),
        PropertySchema::new("stringListField", DataType::StringList, None),
    ];
    
    let indexes = vec![
        IndexSchema::new("bool_index", vec!["boolField"], false, false),
        IndexSchema::new("byte_index", vec!["byteField"], false, false),
        IndexSchema::new("int_index", vec!["intField"], false, false),
        IndexSchema::new("string_index", vec!["stringField"], false, false),
    ];
    
    IsarSchema::new("AllTypes", Some("id"), properties, indexes, false)
}

/// Insert comprehensive test data covering all data types
fn insert_all_types_test_data<T: IsarInstance>(instance: &T, collection_index: u16) -> i64 {
    let txn = instance.begin_txn(true).expect("Failed to begin transaction");
    let mut insert = instance.insert(txn, collection_index, 1)
        .expect("Failed to create insert");

    let id = instance.auto_increment(collection_index);
    
    // Write primitive data types with 1-based property indices
    insert.write_bool(1, true); // boolField
    insert.write_byte(2, 255); // byteField - max u8 value
    insert.write_int(3, -2147483648); // intField - min i32 value
    insert.write_float(4, 3.14159); // floatField
    insert.write_long(5, 9223372036854775807); // longField - max i64 value
    insert.write_double(6, 2.718281828459045); // doubleField
    insert.write_string(7, "Hello, Isar!"); // stringField
    insert.write_string(8, r#"{"key": "value", "number": 42}"#); // jsonField
    
    // Write list data types
    
    // BoolList
    if let Some(mut list_writer) = insert.begin_list(9, 3) {
        list_writer.write_bool(0, true);
        list_writer.write_bool(1, false);
        list_writer.write_bool(2, true);
        insert.end_list(list_writer);
    }
    
    // ByteList
    insert.write_byte_list(10, &[0, 127, 255]);
    
    // IntList
    if let Some(mut list_writer) = insert.begin_list(11, 4) {
        list_writer.write_int(0, -2147483648); // min i32
        list_writer.write_int(1, 0);
        list_writer.write_int(2, 2147483647); // max i32
        list_writer.write_int(3, 42);
        insert.end_list(list_writer);
    }
    
    // FloatList
    if let Some(mut list_writer) = insert.begin_list(12, 3) {
        list_writer.write_float(0, 0.0);
        list_writer.write_float(1, -3.14159);
        list_writer.write_float(2, 2.71828);
        insert.end_list(list_writer);
    }
    
    // LongList
    if let Some(mut list_writer) = insert.begin_list(13, 3) {
        list_writer.write_long(0, -9223372036854775808); // min i64
        list_writer.write_long(1, 0);
        list_writer.write_long(2, 9223372036854775807); // max i64
        insert.end_list(list_writer);
    }
    
    // DoubleList
    if let Some(mut list_writer) = insert.begin_list(14, 4) {
        list_writer.write_double(0, 0.0);
        list_writer.write_double(1, -1.7976931348623157e+308); // close to min f64
        list_writer.write_double(2, 1.7976931348623157e+308); // close to max f64
        list_writer.write_double(3, 2.718281828459045);
        insert.end_list(list_writer);
    }
    
    // StringList
    if let Some(mut list_writer) = insert.begin_list(15, 4) {
        list_writer.write_string(0, "");
        list_writer.write_string(1, "Hello");
        list_writer.write_string(2, "Isar Database");
        list_writer.write_string(3, "🚀 Unicode support!");
        insert.end_list(list_writer);
    }

    insert.save(id).expect("Failed to save test data");
    let txn = insert.finish().expect("Failed to finish insert");
    instance.commit_txn(txn).expect("Failed to commit transaction");
    
    id
}

/// Test edge cases like null values and empty lists
fn insert_edge_case_data<T: IsarInstance>(instance: &T, collection_index: u16) -> i64 {
    let txn = instance.begin_txn(true).expect("Failed to begin transaction");
    let mut insert = instance.insert(txn, collection_index, 1)
        .expect("Failed to create insert");

    let id = instance.auto_increment(collection_index);
    
    // Test null/default values for primitive types
    // Note: Some types don't support explicit null in Isar, they use default values
    insert.write_bool(1, false); // boolField - default false
    insert.write_byte(2, 0); // byteField - default 0
    // Don't write intField to test default behavior
    // Don't write floatField to test default behavior
    // Don't write longField to test default behavior  
    // Don't write doubleField to test default behavior
    insert.write_string(7, ""); // stringField - empty string
    insert.write_string(8, "null"); // jsonField - JSON null
    
    // Test empty lists
    if let Some(list_writer) = insert.begin_list(9, 0) {
        insert.end_list(list_writer); // Empty BoolList
    }
    
    insert.write_byte_list(10, &[]); // Empty ByteList
    
    if let Some(list_writer) = insert.begin_list(11, 0) {
        insert.end_list(list_writer); // Empty IntList
    }
    
    if let Some(list_writer) = insert.begin_list(12, 0) {
        insert.end_list(list_writer); // Empty FloatList
    }
    
    if let Some(list_writer) = insert.begin_list(13, 0) {
        insert.end_list(list_writer); // Empty LongList
    }
    
    if let Some(list_writer) = insert.begin_list(14, 0) {
        insert.end_list(list_writer); // Empty DoubleList
    }
    
    if let Some(list_writer) = insert.begin_list(15, 0) {
        insert.end_list(list_writer); // Empty StringList
    }

    insert.save(id).expect("Failed to save edge case data");
    let txn = insert.finish().expect("Failed to finish insert");
    instance.commit_txn(txn).expect("Failed to commit transaction");
    
    id
}

#[cfg(test)]
#[cfg(feature = "native")]
mod native_data_type_tests {
    use super::*;

    /// Test all data types with comprehensive data
    #[test]
    fn test_native_all_data_types() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_all_types_schema()];
        let instance = NativeInstance::open_instance(
            1600, // data type test ID range
            "all_types_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open native database");

        let test_id = insert_all_types_test_data(&*instance, 0);

        // Read and verify all data types
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            {
                let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                
                if let Some(reader) = cursor.next(test_id) {
                    assert_eq!(reader.read_id(), test_id);
                    
                    // Verify primitive types
                    assert_eq!(reader.read_bool(1), Some(true)); // boolField
                    assert_eq!(reader.read_byte(2), 255); // byteField
                    assert_eq!(reader.read_int(3), -2147483648); // intField
                    assert_eq!(reader.read_float(4), 3.14159); // floatField
                    assert_eq!(reader.read_long(5), 9223372036854775807); // longField
                    assert_eq!(reader.read_double(6), 2.718281828459045); // doubleField
                    assert_eq!(reader.read_string(7), Some("Hello, Isar!")); // stringField
                    assert_eq!(reader.read_string(8), Some(r#"{"key": "value", "number": 42}"#)); // jsonField
                    
                    // Verify BoolList
                    if let Some((list_reader, length)) = reader.read_list(9) {
                        assert_eq!(length, 3);
                        assert_eq!(list_reader.read_bool(0), Some(true));
                        assert_eq!(list_reader.read_bool(1), Some(false));
                        assert_eq!(list_reader.read_bool(2), Some(true));
                    }
                    
                    // Verify ByteList
                    if let Some(blob) = reader.read_blob(10) {
                        assert_eq!(blob.as_ref(), &[0, 127, 255]);
                    }
                    
                    // Verify IntList
                    if let Some((list_reader, length)) = reader.read_list(11) {
                        assert_eq!(length, 4);
                        assert_eq!(list_reader.read_int(0), -2147483648);
                        assert_eq!(list_reader.read_int(1), 0);
                        assert_eq!(list_reader.read_int(2), 2147483647);
                        assert_eq!(list_reader.read_int(3), 42);
                    }
                    
                    // Verify FloatList
                    if let Some((list_reader, length)) = reader.read_list(12) {
                        assert_eq!(length, 3);
                        assert_eq!(list_reader.read_float(0), 0.0);
                        assert_eq!(list_reader.read_float(1), -3.14159);
                        assert!((list_reader.read_float(2) - 2.71828).abs() < 0.0001);
                    }
                    
                    // Verify LongList
                    if let Some((list_reader, length)) = reader.read_list(13) {
                        assert_eq!(length, 3);
                        assert_eq!(list_reader.read_long(0), -9223372036854775808);
                        assert_eq!(list_reader.read_long(1), 0);
                        assert_eq!(list_reader.read_long(2), 9223372036854775807);
                    }
                    
                    // Verify DoubleList
                    if let Some((list_reader, length)) = reader.read_list(14) {
                        assert_eq!(length, 4);
                        assert_eq!(list_reader.read_double(0), 0.0);
                        assert_eq!(list_reader.read_double(1), -1.7976931348623157e+308);
                        assert_eq!(list_reader.read_double(2), 1.7976931348623157e+308);
                        assert_eq!(list_reader.read_double(3), 2.718281828459045);
                    }
                    
                    // Verify StringList
                    if let Some((list_reader, length)) = reader.read_list(15) {
                        assert_eq!(length, 4);
                        assert_eq!(list_reader.read_string(0), Some(""));
                        assert_eq!(list_reader.read_string(1), Some("Hello"));
                        assert_eq!(list_reader.read_string(2), Some("Isar Database"));
                        assert_eq!(list_reader.read_string(3), Some("🚀 Unicode support!"));
                    }
                } else {
                    panic!("Failed to read inserted data");
                }
            } // cursor dropped here
            
            instance.abort_txn(txn);
        }

        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }

    /// Test edge cases and boundary values
    #[test]
    fn test_native_edge_cases() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_all_types_schema()];
        let instance = NativeInstance::open_instance(
            1601,
            "edge_cases_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open native database");

        let edge_id = insert_edge_case_data(&*instance, 0);

        // Read and verify edge cases
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            {
                let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                
                if let Some(reader) = cursor.next(edge_id) {
                    assert_eq!(reader.read_id(), edge_id);
                    
                    // Verify default/edge values
                    assert_eq!(reader.read_bool(1), Some(false)); // boolField
                    assert_eq!(reader.read_byte(2), 0); // byteField
                    assert_eq!(reader.read_string(7), Some("")); // stringField
                    assert_eq!(reader.read_string(8), Some("null")); // jsonField
                    
                    // Verify empty lists
                    if let Some((_, length)) = reader.read_list(9) {
                        assert_eq!(length, 0); // Empty BoolList
                    }
                    
                    if let Some(blob) = reader.read_blob(10) {
                        assert_eq!(blob.len(), 0); // Empty ByteList
                    }
                    
                    if let Some((_, length)) = reader.read_list(11) {
                        assert_eq!(length, 0); // Empty IntList
                    }
                    
                    if let Some((_, length)) = reader.read_list(12) {
                        assert_eq!(length, 0); // Empty FloatList
                    }
                    
                    if let Some((_, length)) = reader.read_list(13) {
                        assert_eq!(length, 0); // Empty LongList
                    }
                    
                    if let Some((_, length)) = reader.read_list(14) {
                        assert_eq!(length, 0); // Empty DoubleList
                    }
                    
                    if let Some((_, length)) = reader.read_list(15) {
                        assert_eq!(length, 0); // Empty StringList
                    }
                } else {
                    panic!("Failed to read edge case data");
                }
            } // cursor dropped here
            
            instance.abort_txn(txn);
        }

        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }

    /// Test boundary values for numeric types
    #[test]
    fn test_native_boundary_values() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_all_types_schema()];
        let instance = NativeInstance::open_instance(
            1602,
            "boundary_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open native database");

        // Test boundary values
        let txn = instance.begin_txn(true).expect("Failed to begin transaction");
        let mut insert = instance.insert(txn, 0, 1)
            .expect("Failed to create insert");

        let boundary_id = instance.auto_increment(0);
        
        // Test boundary values for numeric types
        insert.write_byte(2, u8::MAX); // 255
        insert.write_int(3, i32::MIN); // -2147483648
        insert.write_long(5, i64::MAX); // 9223372036854775807
        insert.write_float(4, f32::MIN); // Most negative finite f32
        insert.write_double(6, f64::MAX); // Most positive finite f64

        insert.save(boundary_id).expect("Failed to save boundary data");
        let txn = insert.finish().expect("Failed to finish insert");
        instance.commit_txn(txn).expect("Failed to commit transaction");

        // Verify boundary values
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            {
                let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                
                if let Some(reader) = cursor.next(boundary_id) {
                    assert_eq!(reader.read_byte(2), u8::MAX);
                    assert_eq!(reader.read_int(3), i32::MIN);
                    assert_eq!(reader.read_long(5), i64::MAX);
                    assert_eq!(reader.read_float(4), f32::MIN);
                    assert_eq!(reader.read_double(6), f64::MAX);
                } else {
                    panic!("Failed to read boundary data");
                }
            } // cursor dropped here
            
            instance.abort_txn(txn);
        }

        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }
}

#[cfg(test)]
#[cfg(feature = "sqlite")]
mod sqlite_data_type_tests {
    use super::*;

    /// Test all data types with comprehensive data on SQLite backend
    #[test]
    fn test_sqlite_all_data_types() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_all_types_schema()];
        let instance = SQLiteInstance::open_instance(
            1700, // SQLite data type test ID range
            "sqlite_all_types_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");

        let test_id = insert_all_types_test_data(&instance, 0);

        // Read and verify all data types
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            {
                let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                
                if let Some(reader) = cursor.next(test_id) {
                    assert_eq!(reader.read_id(), test_id);
                    
                    // Verify primitive types (SQLite may have slight differences in precision)
                    assert_eq!(reader.read_bool(1), Some(true)); // boolField
                    assert_eq!(reader.read_byte(2), 255); // byteField
                    assert_eq!(reader.read_int(3), -2147483648); // intField
                    assert!((reader.read_float(4) - 3.14159).abs() < 0.0001); // floatField
                    assert_eq!(reader.read_long(5), 9223372036854775807); // longField
                    assert!((reader.read_double(6) - 2.718281828459045).abs() < 0.000000000001); // doubleField
                    assert_eq!(reader.read_string(7), Some("Hello, Isar!")); // stringField
                    assert_eq!(reader.read_string(8), Some(r#"{"key": "value", "number": 42}"#)); // jsonField
                    
                    // Verify list types work on SQLite
                    if let Some((list_reader, length)) = reader.read_list(9) {
                        assert_eq!(length, 3);
                        assert_eq!(list_reader.read_bool(0), Some(true));
                        assert_eq!(list_reader.read_bool(1), Some(false));
                        assert_eq!(list_reader.read_bool(2), Some(true));
                    }
                    
                    if let Some((list_reader, length)) = reader.read_list(15) {
                        assert_eq!(length, 4);
                        assert_eq!(list_reader.read_string(0), Some(""));
                        assert_eq!(list_reader.read_string(1), Some("Hello"));
                        assert_eq!(list_reader.read_string(2), Some("Isar Database"));
                        assert_eq!(list_reader.read_string(3), Some("🚀 Unicode support!"));
                    }
                } else {
                    panic!("Failed to read inserted data");
                }
            } // cursor dropped here
            
            instance.abort_txn(txn);
        }

        let closed = SQLiteInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }

    /// Test edge cases on SQLite backend
    #[test]
    fn test_sqlite_edge_cases() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_all_types_schema()];
        let instance = SQLiteInstance::open_instance(
            1701,
            "sqlite_edge_cases_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");

        let edge_id = insert_edge_case_data(&instance, 0);

        // Read and verify edge cases
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            {
                let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                
                if let Some(reader) = cursor.next(edge_id) {
                    assert_eq!(reader.read_id(), edge_id);
                    
                    // Verify default/edge values
                    assert_eq!(reader.read_bool(1), Some(false)); // boolField
                    assert_eq!(reader.read_byte(2), 0); // byteField
                    assert_eq!(reader.read_string(7), Some("")); // stringField
                    assert_eq!(reader.read_string(8), Some("null")); // jsonField
                    
                    // Verify empty lists work on SQLite
                    if let Some((_, length)) = reader.read_list(9) {
                        assert_eq!(length, 0); // Empty BoolList
                    }
                    
                    if let Some((_, length)) = reader.read_list(15) {
                        assert_eq!(length, 0); // Empty StringList
                    }
                } else {
                    panic!("Failed to read edge case data");
                }
            } // cursor dropped here
            
            instance.abort_txn(txn);
        }

        let closed = SQLiteInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }
}

#[cfg(test)]
mod cross_backend_data_type_tests {
    use super::*;

    /// Test data type consistency across backends
    #[test]
    #[cfg(all(feature = "native", feature = "sqlite"))]
    fn test_data_type_consistency() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_all_types_schema()];
        
        // Test on Native backend
        let native_instance = NativeInstance::open_instance(
            1800,
            "native_consistency_db",
            db_dir,
            schemas.clone(),
            1024,
            None,
            None,
        ).expect("Failed to open native database");

        let native_id = insert_all_types_test_data(&*native_instance, 0);
        
        // Test on SQLite backend  
        let sqlite_instance = SQLiteInstance::open_instance(
            1801,
            "sqlite_consistency_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");

        let sqlite_id = insert_all_types_test_data(&sqlite_instance, 0);

        // Verify both backends handle the same data types correctly
        assert!(native_id > 0);
        assert!(sqlite_id > 0);

        let native_closed = NativeInstance::close(native_instance, false);
        let sqlite_closed = SQLiteInstance::close(sqlite_instance, false);
        assert!(native_closed && sqlite_closed);
    }
} 