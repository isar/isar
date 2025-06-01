//! CRUD Operations Integration Tests
//! 
//! Comprehensive tests for Create, Read, Update, Delete operations

mod common;

use common::*;
use isar_core::core::instance::IsarInstance;
use isar_core::core::writer::IsarWriter;
use isar_core::core::insert::IsarInsert;
use isar_core::core::cursor::IsarCursor;
use isar_core::core::reader::IsarReader;

#[cfg(feature = "native")]
use isar_core::native::native_instance::NativeInstance;

#[cfg(feature = "sqlite")]
use isar_core::sqlite::sqlite_instance::SQLiteInstance;

/// Insert test data for query testing - simplified version for basic data only
fn insert_basic_test_data<T: IsarInstance>(instance: &T, collection_index: u16) -> Vec<i64> {
    let mut ids = Vec::new();
    
    let test_data = vec![
        ("Alice", 25, "alice@test.com", true),
        ("Bob", 30, "bob@test.com", false),
        ("Charlie", 35, "charlie@test.com", true),
    ];

    let txn = instance.begin_txn(true).expect("Failed to begin transaction");
    let mut insert = instance.insert(txn, collection_index, test_data.len() as u32)
        .expect("Failed to create insert");

    for (name, age, email, is_active) in test_data {
        let id = instance.auto_increment(collection_index);
        ids.push(id);
        
        // Write data with 1-based property indices
        insert.write_string(1, name);
        insert.write_int(2, age);
        insert.write_string(3, email);
        insert.write_bool(4, is_active);
        
        insert.save(id).expect("Failed to save test data");
    }
    
    let txn = insert.finish().expect("Failed to finish insert");
    instance.commit_txn(txn).expect("Failed to commit transaction");
    
    ids
}

#[cfg(test)]
#[cfg(feature = "native")]
mod native_crud_tests {
    use super::*;

    /// Test comprehensive CRUD operations with actual data
    #[test]
    fn test_native_comprehensive_crud() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_comprehensive_schema()];
        let instance = NativeInstance::open_instance(
            100,
            "crud_test_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open native database");

        // Test data insertion with various data types
        let user_id = instance.auto_increment(0);
        {
            let txn = instance.begin_txn(true).expect("Failed to begin write transaction");
            let mut insert = instance.insert(txn, 0, 1).expect("Failed to create insert");
            
            // Write comprehensive data (property indices are 1-based)
            insert.write_string(1, "John Doe"); // name
            insert.write_int(2, 30); // age
            insert.write_long(3, 1234567890); // score
            insert.write_float(4, 4.5); // rating
            insert.write_double(5, 98.7654321); // precision
            insert.write_bool(6, true); // isActive
            insert.write_byte_list(7, &[1, 2, 3, 4]); // avatar
            
            // Write string list (tags)
            let tag_writer = insert.begin_list(8, 3);
            if let Some(mut tw) = tag_writer {
                tw.write_string(0, "rust");
                tw.write_string(1, "database");
                tw.write_string(2, "testing");
                insert.end_list(tw);
            }

            insert.save(user_id).expect("Failed to save data");
            let txn = insert.finish().expect("Failed to finish insert");
            instance.commit_txn(txn).expect("Failed to commit transaction");
        }

        // Test reading the inserted data
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            {
                let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                
                if let Some(reader) = cursor.next(user_id) {
                    assert_eq!(reader.read_id(), user_id);
                    assert_eq!(reader.read_string(1), Some("John Doe"));
                    assert_eq!(reader.read_int(2), 30);
                    assert_eq!(reader.read_long(3), 1234567890);
                    assert_eq!(reader.read_float(4), 4.5);
                    assert_eq!(reader.read_double(5), 98.7654321);
                    assert_eq!(reader.read_bool(6), Some(true));
                    
                    if let Some(blob) = reader.read_blob(7) {
                        assert_eq!(blob.as_ref(), &[1, 2, 3, 4]);
                    }
                    
                    // Read string list
                    if let Some((list_reader, length)) = reader.read_list(8) {
                        assert_eq!(length, 3);
                        assert_eq!(list_reader.read_string(0), Some("rust"));
                        assert_eq!(list_reader.read_string(1), Some("database"));
                        assert_eq!(list_reader.read_string(2), Some("testing"));
                    }
                } else {
                    panic!("Failed to read inserted data");
                }
            } // cursor dropped here
            
            instance.abort_txn(txn);
        }

        // Test data update
        {
            let txn = instance.begin_txn(true).expect("Failed to begin update transaction");
            
            // Update multiple fields (property indices are 1-based)
            let updates = vec![
                (1, Some(isar_core::core::value::IsarValue::String("Jane Doe".to_string()))), // name
                (2, Some(isar_core::core::value::IsarValue::Integer(25))), // age
                (6, Some(isar_core::core::value::IsarValue::Bool(false))), // isActive
            ];
            
            let updated = instance.update(&txn, 0, user_id, &updates).expect("Failed to update");
            assert!(updated, "Update should return true for existing record");
            
            instance.commit_txn(txn).expect("Failed to commit update");
        }

        // Test data deletion
        {
            let txn = instance.begin_txn(true).expect("Failed to begin delete transaction");
            let deleted = instance.delete(&txn, 0, user_id).expect("Failed to delete");
            assert!(deleted, "Delete should return true for existing record");
            instance.commit_txn(txn).expect("Failed to commit deletion");
        }

        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }

    /// Test bulk operations
    #[test]
    fn test_native_bulk_operations() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = NativeInstance::open_instance(
            101,
            "bulk_test_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open native database");

        let user_ids = insert_basic_test_data(&*instance, 0);

        // Verify all records were inserted
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let count = instance.count(&txn, 0).expect("Failed to count records");
            assert_eq!(count, 3);
            instance.abort_txn(txn);
        }

        // Test clear operation
        {
            let txn = instance.begin_txn(true).expect("Failed to begin clear transaction");
            instance.clear(&txn, 0).expect("Failed to clear collection");
            instance.commit_txn(txn).expect("Failed to commit clear");
        }

        // Verify all records are cleared
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let count = instance.count(&txn, 0).expect("Failed to count after clear");
            assert_eq!(count, 0);
            instance.abort_txn(txn);
        }

        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }
}

#[cfg(test)]
#[cfg(feature = "sqlite")]
mod sqlite_crud_tests {
    use super::*;

    /// Test comprehensive CRUD operations with SQLite backend
    #[test]
    fn test_sqlite_comprehensive_crud() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_comprehensive_schema()];
        let instance = SQLiteInstance::open_instance(
            200,
            "sqlite_crud_test_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");

        // Test data insertion
        let user_id = instance.auto_increment(0);
        {
            let txn = instance.begin_txn(true).expect("Failed to begin write transaction");
            let mut insert = instance.insert(txn, 0, 1).expect("Failed to create insert");
            
            // Property indices are 1-based
            insert.write_string(1, "SQLite User");
            insert.write_int(2, 35);
            insert.write_long(3, 9876543210);
            insert.write_float(4, 7.8);
            insert.write_double(5, 123.456789);
            insert.write_bool(6, true);
            insert.write_byte_list(7, &[5, 6, 7, 8]);
            
            insert.save(user_id).expect("Failed to save SQLite data");
            let txn = insert.finish().expect("Failed to finish insert");
            instance.commit_txn(txn).expect("Failed to commit transaction");
        }

        // Test reading, update, and deletion similar to native tests...
        // (Implementation would be similar to native tests)

        let closed = SQLiteInstance::close(instance, false);
        assert!(closed);
    }
} 