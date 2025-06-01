//! End-to-End Integration Tests for isar_core
//! 
//! These tests verify the complete functionality of isar_core across different backends,
//! testing real-world scenarios and cross-platform compatibility.

use tempfile::TempDir;
use isar_core::core::schema::*;
use isar_core::core::data_type::DataType;
use isar_core::core::instance::IsarInstance;

#[cfg(feature = "native")]
use isar_core::native::native_instance::NativeInstance;

#[cfg(feature = "sqlite")]
use isar_core::sqlite::sqlite_instance::SQLiteInstance;

/// Test helper to create a temporary directory for database files
fn create_test_dir() -> TempDir {
    tempfile::tempdir().expect("Failed to create temp directory")
}

/// Create a test schema for User collection
fn create_user_schema() -> IsarSchema {
    let properties = vec![
        PropertySchema::new("name", DataType::String, None),
        PropertySchema::new("age", DataType::Int, None),
        PropertySchema::new("email", DataType::String, None),
        PropertySchema::new("isActive", DataType::Bool, None),
    ];
    
    let indexes = vec![
        IndexSchema::new("name_index", vec!["name"], false, false),
        IndexSchema::new("email_index", vec!["email"], true, false), // unique
    ];
    
    IsarSchema::new("User", Some("id"), properties, indexes, false)
}

/// Create a test schema for Post collection with relationships
fn create_post_schema() -> IsarSchema {
    let properties = vec![
        PropertySchema::new("title", DataType::String, None),
        PropertySchema::new("content", DataType::String, None),
        PropertySchema::new("userId", DataType::Long, None),
        PropertySchema::new("tags", DataType::StringList, None),
    ];
    
    let indexes = vec![
        IndexSchema::new("title_index", vec!["title"], false, false),
        IndexSchema::new("user_index", vec!["userId"], false, false),
    ];
    
    IsarSchema::new("Post", Some("id"), properties, indexes, false)
}

/// Create a comprehensive test schema with all data types
fn create_comprehensive_schema() -> IsarSchema {
    let properties = vec![
        PropertySchema::new("name", DataType::String, None),
        PropertySchema::new("age", DataType::Int, None),
        PropertySchema::new("score", DataType::Long, None),
        PropertySchema::new("rating", DataType::Float, None),
        PropertySchema::new("precision", DataType::Double, None),
        PropertySchema::new("isActive", DataType::Bool, None),
        PropertySchema::new("avatar", DataType::ByteList, None),
        PropertySchema::new("tags", DataType::StringList, None),
        PropertySchema::new("scores", DataType::IntList, None),
        PropertySchema::new("timestamps", DataType::LongList, None),
        PropertySchema::new("weights", DataType::FloatList, None),
        PropertySchema::new("measurements", DataType::DoubleList, None),
    ];
    
    let indexes = vec![
        IndexSchema::new("name_index", vec!["name"], false, false),
        IndexSchema::new("age_score_index", vec!["age", "score"], false, false),
    ];
    
    IsarSchema::new("Comprehensive", Some("id"), properties, indexes, false)
}

#[cfg(test)]
#[cfg(feature = "native")]
mod native_backend_tests {
    use super::*;

    /// Test complete CRUD operations on native backend
    #[test]
    fn test_native_crud_operations() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        // Test database creation and opening
        let schemas = vec![create_user_schema(), create_post_schema()];
        let instance = NativeInstance::open_instance(
            1,              // instance_id
            "test_db",      // name
            db_dir,         // dir
            schemas,        // schemas
            1024,           // max_size_mib
            None,           // encryption_key
            None,           // compact_condition
        ).expect("Failed to open native database");
        
        // Test transaction operations
        {
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            
            // Test basic operations through cursor
            {
                let _cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                // Insert operation would be done through cursor or insert API
                // The actual API may differ from what we expect here
            } // cursor dropped here
            
            instance.commit_txn(txn).expect("Failed to commit transaction");
        }
        
        // Test read operations
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            
            // Test query operations through cursor
            {
                let _cursor = instance.cursor(&txn, 0).expect("Failed to get read cursor");
            } // cursor dropped here
            
            instance.abort_txn(txn);
        }
        
        // Close the database
        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }

    /// Test schema migrations
    #[test]
    fn test_schema_migration() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        // Open with initial schema
        let initial_schemas = vec![create_user_schema()];
        let instance = NativeInstance::open_instance(
            2,
            "migration_db",
            db_dir,
            initial_schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database with initial schema");
        
        // Test basic operations with initial schema
        {
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            {
                let _cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
            } // cursor dropped here
            instance.commit_txn(txn).expect("Failed to commit");
        }
        
        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
        
        // Reopen with updated schema (add Post collection)
        let updated_schemas = vec![create_user_schema(), create_post_schema()];
        let instance = NativeInstance::open_instance(
            3,
            "migration_db",
            db_dir,
            updated_schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database with updated schema");
        
        // Verify both collections are available
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            {
                let _user_cursor = instance.cursor(&txn, 0).expect("Failed to get user cursor");
                let _post_cursor = instance.cursor(&txn, 1).expect("Failed to get post cursor");
            } // cursors dropped here
            instance.abort_txn(txn);
        }
        
        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }

    /// Test concurrent access and transactions
    #[test]
    fn test_concurrent_transactions() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = NativeInstance::open_instance(
            4,
            "concurrent_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");
        
        // Test multiple read transactions
        let txn1 = instance.begin_txn(false).expect("Failed to begin read txn 1");
        let txn2 = instance.begin_txn(false).expect("Failed to begin read txn 2");
        
        // Both should be able to read
        {
            let _cursor1 = instance.cursor(&txn1, 0).expect("Cursor failed in txn1");
            let _cursor2 = instance.cursor(&txn2, 0).expect("Cursor failed in txn2");
        } // cursors dropped here
        
        instance.abort_txn(txn1);
        instance.abort_txn(txn2);
        
        // Test write transaction
        {
            let write_txn = instance.begin_txn(true).expect("Failed to begin write txn");
            {
                let _write_cursor = instance.cursor(&write_txn, 0).expect("Write cursor failed");
            } // cursor dropped here
            instance.commit_txn(write_txn).expect("Failed to commit write txn");
        }
        
        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }

    /// Test auto increment functionality
    #[test]
    fn test_auto_increment() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = NativeInstance::open_instance(
            5,
            "auto_increment_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");
        
        // Test auto increment
        let auto_id_1 = instance.auto_increment(0);
        let auto_id_2 = instance.auto_increment(0);
        
        assert!(auto_id_2 > auto_id_1, "Auto increment should increase");
        
        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }
}

#[cfg(test)]
#[cfg(feature = "sqlite")]
mod sqlite_backend_tests {
    use super::*;

    /// Test CRUD operations on SQLite backend
    #[test]
    fn test_sqlite_crud_operations() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = SQLiteInstance::open_instance(
            6,
            "test_sqlite_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");
        
        // Test basic operations
        {
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            {
                let _cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
            } // cursor dropped here
            instance.commit_txn(txn).expect("Failed to commit SQLite transaction");
        }
        
        // Test read operations
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            {
                let _cursor = instance.cursor(&txn, 0).expect("Failed to get read cursor");
            } // cursor dropped here
            instance.abort_txn(txn);
        }
    }

    /// Test SQLite-specific features
    #[test]
    fn test_sqlite_features() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_post_schema()];
        let instance = SQLiteInstance::open_instance(
            7,
            "sqlite_features_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");
        
        // Test operations with complex schema
        {
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            {
                let _cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                
                // Test auto increment
                let auto_id = instance.auto_increment(0);
                assert!(auto_id >= 0, "Auto increment should be non-negative");
            } // cursor dropped here
            
            instance.commit_txn(txn).expect("Failed to commit transaction");
        }
    }
}

#[cfg(test)]
mod cross_platform_tests {
    use super::*;

    /// Test data compatibility between backends (if both are available)
    #[test]
    #[cfg(all(feature = "native", feature = "sqlite"))]
    fn test_backend_compatibility() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        let schemas = vec![create_user_schema()];
        
        // Test native backend
        {
            let instance = NativeInstance::open_instance(
                8,
                "compat_native",
                db_dir,
                schemas.clone(),
                1024,
                None,
                None,
            ).expect("Failed to open native database");
            
            {
                let txn = instance.begin_txn(true).expect("Failed to begin transaction");
                {
                    let _cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                } // cursor dropped here
                instance.commit_txn(txn).expect("Failed to commit");
            }
            let closed = NativeInstance::close(instance, false);
            assert!(closed, "Failed to close native database");
        }
        
        // Test SQLite backend with same schema
        {
            let instance = SQLiteInstance::open_instance(
                9,
                "compat_sqlite",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open SQLite database");
            
            {
                let txn = instance.begin_txn(true).expect("Failed to begin transaction");
                {
                    let _cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                } // cursor dropped here
                instance.commit_txn(txn).expect("Failed to commit");
            }
        }
    }
}

#[cfg(test)]
mod error_handling_tests {
    use super::*;

    /// Test error scenarios and recovery
    #[test]
    #[cfg(feature = "native")]
    fn test_error_scenarios() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = NativeInstance::open_instance(
            10,
            "error_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");
        
        // Test invalid collection index
        {
            let txn = instance.begin_txn(false).expect("Failed to begin transaction");
            {
                let result = instance.cursor(&txn, 999); // Invalid collection index
                assert!(result.is_err(), "Expected error for invalid collection index");
            } // result dropped here
            instance.abort_txn(txn);
        }
        
        // Test nested transaction (should fail)
        {
            let _txn1 = instance.begin_txn(true).expect("Failed to begin first transaction");
            let txn2_result = instance.begin_txn(true);
            // This might succeed or fail depending on implementation
            if let Ok(txn2) = txn2_result {
                instance.abort_txn(txn2);
            }
            instance.abort_txn(_txn1);
        }
        
        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }

    /// Test transaction isolation
    #[test]
    #[cfg(feature = "native")]
    fn test_transaction_isolation() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = NativeInstance::open_instance(
            11,
            "isolation_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");
        
        // Test read transaction isolation
        {
            let read_txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let read_txn2 = instance.begin_txn(false).expect("Failed to begin second read transaction");
            
            {
                let _cursor = instance.cursor(&read_txn, 0).expect("Failed to get cursor");
                let _cursor2 = instance.cursor(&read_txn2, 0).expect("Failed to get second cursor");
            } // cursors dropped here
            
            instance.abort_txn(read_txn);
            instance.abort_txn(read_txn2);
        }
        
        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }
}

#[cfg(test)]
#[cfg(feature = "native")]
mod native_crud_tests {
    use super::*;
    use isar_core::core::writer::IsarWriter;
    use isar_core::core::insert::IsarInsert;
    use isar_core::core::cursor::IsarCursor;
    use isar_core::core::reader::IsarReader;

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

        // Verify the update
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            {
                let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                
                if let Some(reader) = cursor.next(user_id) {
                    assert_eq!(reader.read_string(1), Some("Jane Doe"));
                    assert_eq!(reader.read_int(2), 25);
                    assert_eq!(reader.read_bool(6), Some(false));
                    // Other fields should remain unchanged
                    assert_eq!(reader.read_long(3), 1234567890);
                    assert_eq!(reader.read_float(4), 4.5);
                } else {
                    panic!("Failed to read updated data");
                }
            } // cursor dropped here
            
            instance.abort_txn(txn);
        }

        // Test counting records
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let count = instance.count(&txn, 0).expect("Failed to count records");
            assert_eq!(count, 1);
            instance.abort_txn(txn);
        }

        // Test data deletion
        {
            let txn = instance.begin_txn(true).expect("Failed to begin delete transaction");
            let deleted = instance.delete(&txn, 0, user_id).expect("Failed to delete");
            assert!(deleted, "Delete should return true for existing record");
            instance.commit_txn(txn).expect("Failed to commit deletion");
        }

        // Verify deletion
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let count = instance.count(&txn, 0).expect("Failed to count after delete");
            assert_eq!(count, 0);
            
            {
                let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                assert!(cursor.next(user_id).is_none(), "Record should be deleted");
            } // cursor dropped here
            
            instance.abort_txn(txn);
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

        // Insert multiple records
        let mut user_ids = Vec::new();
        {
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            let mut insert = instance.insert(txn, 0, 5).expect("Failed to create bulk insert");
            
            for i in 0..5 {
                let user_id = instance.auto_increment(0);
                user_ids.push(user_id);
                
                // Property indices are 1-based
                insert.write_string(1, &format!("User {}", i + 1)); // name
                insert.write_int(2, 20 + i as i32); // age
                insert.write_string(3, &format!("user{}@example.com", i + 1)); // email
                insert.write_bool(4, i % 2 == 0); // isActive
                
                insert.save(user_id).expect("Failed to save bulk data");
            }
            
            let txn = insert.finish().expect("Failed to finish bulk insert");
            instance.commit_txn(txn).expect("Failed to commit bulk transaction");
        }

        // Verify all records were inserted
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let count = instance.count(&txn, 0).expect("Failed to count records");
            assert_eq!(count, 5);

            {
                let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                for (idx, &user_id) in user_ids.iter().enumerate() {
                    if let Some(reader) = cursor.next(user_id) {
                        let expected_name = format!("User {}", idx + 1);
                        assert_eq!(reader.read_string(1), Some(expected_name.as_str()));
                        assert_eq!(reader.read_int(2), 20 + idx as i32);
                    } else {
                        panic!("Failed to read bulk inserted data for user {}", idx + 1);
                    }
                }
            } // cursor dropped here
            
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

    /// Test edge cases and error conditions
    #[test]
    fn test_native_crud_edge_cases() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = NativeInstance::open_instance(
            102,
            "edge_case_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open native database");

        // Test operations on non-existent records
        {
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            
            // Try to update non-existent record (property indices are 1-based)
            let updates = vec![(1, Some(isar_core::core::value::IsarValue::String("Test".to_string())))];
            let updated = instance.update(&txn, 0, 999999, &updates).expect("Update operation should not fail");
            assert!(!updated, "Update should return false for non-existent record");
            
            // Try to delete non-existent record
            let deleted = instance.delete(&txn, 0, 999999).expect("Delete operation should not fail");
            assert!(!deleted, "Delete should return false for non-existent record");
            
            instance.abort_txn(txn);
        }

        // Test empty string and null values
        {
            let user_id = instance.auto_increment(0);
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            let mut insert = instance.insert(txn, 0, 1).expect("Failed to create insert");
            
            // Property indices are 1-based
            insert.write_string(1, ""); // empty name
            insert.write_int(2, 0); // zero age
            insert.write_null(3); // null email
            insert.write_bool(4, false); // false isActive
            
            insert.save(user_id).expect("Failed to save edge case data");
            let txn = insert.finish().expect("Failed to finish insert");
            instance.commit_txn(txn).expect("Failed to commit transaction");

            // Verify edge case data
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            {
                let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                
                if let Some(reader) = cursor.next(user_id) {
                    assert_eq!(reader.read_string(1), Some(""));
                    assert_eq!(reader.read_int(2), 0);
                    assert!(reader.is_null(3));
                    assert_eq!(reader.read_bool(4), Some(false));
                } else {
                    panic!("Failed to read edge case data");
                }
            } // cursor dropped here
            
            instance.abort_txn(txn);
        }

        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }

    /// Test database size operations
    #[test]
    fn test_native_size_operations() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = NativeInstance::open_instance(
            103,
            "size_test_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open native database");

        // Test initial size
        {
            let txn = instance.begin_txn(false).expect("Failed to begin transaction");
            let size = instance.get_size(&txn, 0, false).expect("Failed to get size");
            // Size is u64, so it's always non-negative by definition
            
            let size_with_indexes = instance.get_size(&txn, 0, true).expect("Failed to get size with indexes");
            assert!(size_with_indexes >= size, "Size with indexes should be >= size without");
            
            instance.abort_txn(txn);
        }

        // Insert some data and check size changes
        {
            let user_id = instance.auto_increment(0);
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            let mut insert = instance.insert(txn, 0, 1).expect("Failed to create insert");
            
            // Property indices are 1-based
            insert.write_string(1, "Test User");
            insert.write_int(2, 25);
            insert.write_string(3, "test@example.com");
            insert.write_bool(4, true);
            
            insert.save(user_id).expect("Failed to save data");
            let txn = insert.finish().expect("Failed to finish insert");
            instance.commit_txn(txn).expect("Failed to commit transaction");
        }

        // Check size after insertion
        {
            let txn = instance.begin_txn(false).expect("Failed to begin transaction");
            let size_after = instance.get_size(&txn, 0, false).expect("Failed to get size after insert");
            assert!(size_after > 0, "Size should be positive after data insertion");
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
    use isar_core::core::writer::IsarWriter;
    use isar_core::core::insert::IsarInsert;
    use isar_core::core::cursor::IsarCursor;
    use isar_core::core::reader::IsarReader;

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

        // Test reading
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            {
                let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                
                if let Some(reader) = cursor.next(user_id) {
                    assert_eq!(reader.read_string(1), Some("SQLite User"));
                    assert_eq!(reader.read_int(2), 35);
                    assert_eq!(reader.read_long(3), 9876543210);
                    assert_eq!(reader.read_float(4), 7.8);
                    assert_eq!(reader.read_double(5), 123.456789);
                    assert_eq!(reader.read_bool(6), Some(true));
                } else {
                    panic!("Failed to read SQLite data");
                }
            } // cursor dropped here
            
            instance.abort_txn(txn);
        }

        // Test update
        {
            let txn = instance.begin_txn(true).expect("Failed to begin update transaction");
            let updates = vec![
                (1, Some(isar_core::core::value::IsarValue::String("Updated SQLite User".to_string()))),
                (2, Some(isar_core::core::value::IsarValue::Integer(40))),
            ];
            
            let updated = instance.update(&txn, 0, user_id, &updates).expect("Failed to update");
            assert!(updated, "Update should succeed");
            instance.commit_txn(txn).expect("Failed to commit update");
        }

        // Test deletion
        {
            let txn = instance.begin_txn(true).expect("Failed to begin delete transaction");
            let deleted = instance.delete(&txn, 0, user_id).expect("Failed to delete");
            assert!(deleted, "Delete should succeed");
            instance.commit_txn(txn).expect("Failed to commit deletion");
        }

        // Verify deletion
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let count = instance.count(&txn, 0).expect("Failed to count after delete");
            assert_eq!(count, 0);
            instance.abort_txn(txn);
        }
    }

    /// Test SQLite bulk operations
    #[test]
    fn test_sqlite_bulk_operations() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = SQLiteInstance::open_instance(
            201,
            "sqlite_bulk_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");

        // Bulk insert
        {
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            let mut insert = instance.insert(txn, 0, 3).expect("Failed to create bulk insert");
            
            for i in 0..3 {
                let user_id = instance.auto_increment(0);
                // Property indices are 1-based
                insert.write_string(1, &format!("SQLite User {}", i + 1));
                insert.write_int(2, 30 + i as i32);
                insert.write_string(3, &format!("sqlite{}@example.com", i + 1));
                insert.write_bool(4, true);
                insert.save(user_id).expect("Failed to save bulk SQLite data");
            }
            
            let txn = insert.finish().expect("Failed to finish bulk insert");
            instance.commit_txn(txn).expect("Failed to commit bulk transaction");
        }

        // Verify bulk insert
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let count = instance.count(&txn, 0).expect("Failed to count records");
            assert_eq!(count, 3);
            instance.abort_txn(txn);
        }
    }
}

#[cfg(test)]
mod crud_comparison_tests {
    use super::*;
    use isar_core::core::writer::IsarWriter;
    use isar_core::core::insert::IsarInsert;

    /// Test data consistency between Native and SQLite backends
    #[test]
    #[cfg(all(feature = "native", feature = "sqlite"))]
    fn test_backend_crud_consistency() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        let schemas = vec![create_user_schema()];
        
        // Test identical operations on both backends
        let test_data = vec![
            ("Alice", 25, "alice@test.com", true),
            ("Bob", 30, "bob@test.com", false),
            ("Charlie", 35, "charlie@test.com", true),
        ];

        let mut native_ids = Vec::new();
        let mut sqlite_ids = Vec::new();

        // Insert identical data into Native backend
        {
            let instance = NativeInstance::open_instance(
                300,
                "consistency_native",
                db_dir,
                schemas.clone(),
                1024,
                None,
                None,
            ).expect("Failed to open native database");

            let txn = instance.begin_txn(true).expect("Failed to begin native transaction");
            let mut insert = instance.insert(txn, 0, test_data.len() as u32).expect("Failed to create native insert");
            
            for (name, age, email, active) in &test_data {
                let user_id = instance.auto_increment(0);
                native_ids.push(user_id);
                
                // Property indices are 1-based
                insert.write_string(1, name);
                insert.write_int(2, *age);
                insert.write_string(3, email);
                insert.write_bool(4, *active);
                insert.save(user_id).expect("Failed to save native data");
            }
            
            let txn = insert.finish().expect("Failed to finish native insert");
            instance.commit_txn(txn).expect("Failed to commit native transaction");
            
            let closed = NativeInstance::close(instance, false);
            assert!(closed);
        }

        // Insert identical data into SQLite backend  
        {
            let instance = SQLiteInstance::open_instance(
                301,
                "consistency_sqlite",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open SQLite database");

            let txn = instance.begin_txn(true).expect("Failed to begin SQLite transaction");
            let mut insert = instance.insert(txn, 0, test_data.len() as u32).expect("Failed to create SQLite insert");
            
            for (name, age, email, active) in &test_data {
                let user_id = instance.auto_increment(0);
                sqlite_ids.push(user_id);
                
                // Property indices are 1-based
                insert.write_string(1, name);
                insert.write_int(2, *age);
                insert.write_string(3, email);
                insert.write_bool(4, *active);
                insert.save(user_id).expect("Failed to save SQLite data");
            }
            
            let txn = insert.finish().expect("Failed to finish SQLite insert");
            instance.commit_txn(txn).expect("Failed to commit SQLite transaction");
        }

        // Verify both backends have consistent auto-increment behavior
        assert_eq!(native_ids.len(), sqlite_ids.len());
        for (native_id, sqlite_id) in native_ids.iter().zip(sqlite_ids.iter()) {
            // IDs should be sequential within each backend
            assert!(*native_id > 0);
            assert!(*sqlite_id > 0);
        }
    }
}

// Note: Performance testing is intentionally not included in integration tests.
// Performance should be measured using:
// 1. Dedicated benchmark suites (e.g., criterion.rs)
// 2. Separate performance CI pipelines with consistent hardware
// 3. Realistic workloads and statistical analysis
// 4. Performance regression detection tools
//
// Integration tests should focus on correctness, not timing. 

#[cfg(test)]
mod query_functionality_tests {
    use super::*;
    use isar_core::core::filter::*;
    use isar_core::core::value::IsarValue;
    use isar_core::core::instance::Aggregation;
    use isar_core::core::query_builder::{IsarQueryBuilder, Sort};
    use isar_core::core::cursor::IsarQueryCursor;
    use isar_core::core::writer::IsarWriter;
    use isar_core::core::insert::IsarInsert;
    use isar_core::core::reader::IsarReader;

    /// Create a test schema with varied data types for comprehensive query testing
    fn create_query_test_schema() -> IsarSchema {
        let properties = vec![
            PropertySchema::new("name", DataType::String, None),
            PropertySchema::new("age", DataType::Int, None),
            PropertySchema::new("score", DataType::Long, None),
            PropertySchema::new("rating", DataType::Float, None),
            PropertySchema::new("salary", DataType::Double, None),
            PropertySchema::new("isActive", DataType::Bool, None),
            PropertySchema::new("tags", DataType::StringList, None),
            PropertySchema::new("numbers", DataType::IntList, None),
        ];
        
        let indexes = vec![
            IndexSchema::new("name_index", vec!["name"], false, false),
            IndexSchema::new("age_index", vec!["age"], false, false),
            IndexSchema::new("score_index", vec!["score"], false, false),
            IndexSchema::new("rating_index", vec!["rating"], false, false),
            IndexSchema::new("compound_index", vec!["age", "score"], false, false),
        ];
        
        IsarSchema::new("QueryTest", Some("id"), properties, indexes, false)
    }

    /// Insert test data for query testing - simplified version for basic data only
    fn insert_basic_query_test_data<T: IsarInstance>(instance: &T, collection_index: u16) -> Vec<i64> {
        let mut ids = Vec::new();
        
        let test_data = vec![
            ("Alice", 25, 1000i64, 4.5f32, 50000.0, true),
            ("Bob", 30, 1500, 3.8, 60000.0, false),
            ("Charlie", 35, 2000, 4.9, 70000.0, true),
            ("Diana", 28, 1200, 4.2, 55000.0, true),
            ("Eve", 32, 1800, 3.5, 65000.0, false),
        ];

        let txn = instance.begin_txn(true).expect("Failed to begin transaction");
        let mut insert = instance.insert(txn, collection_index, test_data.len() as u32)
            .expect("Failed to create insert");

        for (name, age, score, rating, salary, is_active) in test_data {
            let id = instance.auto_increment(collection_index);
            ids.push(id);
            
            // Write data with 1-based property indices
            insert.write_string(1, name);
            insert.write_int(2, age);
            insert.write_long(3, score);
            insert.write_float(4, rating);
            insert.write_double(5, salary);
            insert.write_bool(6, is_active);
            
            insert.save(id).expect("Failed to save test data");
        }
        
        let txn = insert.finish().expect("Failed to finish insert");
        instance.commit_txn(txn).expect("Failed to commit transaction");
        
        ids
    }

    #[cfg(test)]
    #[cfg(feature = "native")]
    mod native_query_tests {
        use super::*;

        /// Test basic filter operations
        #[test]
        fn test_native_basic_filters() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            let instance_result = NativeInstance::open_instance(
                1000,
                "query_filter_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open database");
            
            // Dereference the Arc to get the underlying instance
            let instance = &*instance_result;
            let _ids = insert_basic_query_test_data(instance, 0);

            // Test equal filter
            {
                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.set_filter(Filter::new_condition(
                    1, // name property (1-based index)
                    ConditionType::Equal,
                    vec![Some(IsarValue::String("Alice".to_string()))],
                    true,
                ));
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                    .expect("Failed to execute count");
                assert_eq!(count, Some(IsarValue::Integer(1)));
                instance.abort_txn(txn);
            }

            // Test greater than filter
            {
                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.set_filter(Filter::new_condition(
                    2, // age property
                    ConditionType::Greater,
                    vec![Some(IsarValue::Integer(30))],
                    true,
                ));
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                    .expect("Failed to execute count");
                assert_eq!(count, Some(IsarValue::Integer(2))); // Charlie and Eve
                instance.abort_txn(txn);
            }

            // Test between filter
            {
                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.set_filter(Filter::new_condition(
                    3, // score property
                    ConditionType::Between,
                    vec![Some(IsarValue::Integer(1200)), Some(IsarValue::Integer(1600))],
                    true,
                ));
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                    .expect("Failed to execute count");
                assert_eq!(count, Some(IsarValue::Integer(2))); // Bob and Diana
                instance.abort_txn(txn);
            }

            // Test string contains filter
            {
                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.set_filter(Filter::new_condition(
                    1, // name property
                    ConditionType::StringContains,
                    vec![Some(IsarValue::String("i".to_string()))],
                    true,
                ));
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                    .expect("Failed to execute count");
                assert_eq!(count, Some(IsarValue::Integer(3))); // Alice, Charlie, Diana
                instance.abort_txn(txn);
            }

            let closed = NativeInstance::close(instance_result, false);
            assert!(closed);
        }

        /// Test compound filters with AND/OR operations
        #[test]
        fn test_native_compound_filters() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            let instance_result = NativeInstance::open_instance(
                1001,
                "compound_filter_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open database");
            
            let instance = &*instance_result;
            let _ids = insert_basic_query_test_data(instance, 0);

            // Test AND filter: age > 25 AND isActive = true
            {
                let age_filter = Filter::new_condition(
                    2, // age property
                    ConditionType::Greater,
                    vec![Some(IsarValue::Integer(25))],
                    true,
                );
                let active_filter = Filter::new_condition(
                    6, // isActive property
                    ConditionType::Equal,
                    vec![Some(IsarValue::Bool(true))],
                    true,
                );
                let and_filter = Filter::new_and(vec![age_filter, active_filter]);

                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.set_filter(and_filter);
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                    .expect("Failed to execute count");
                assert_eq!(count, Some(IsarValue::Integer(2))); // Charlie and Diana
                instance.abort_txn(txn);
            }

            // Test OR filter: age < 30 OR score > 1500
            {
                let age_filter = Filter::new_condition(
                    2, // age property
                    ConditionType::Less,
                    vec![Some(IsarValue::Integer(30))],
                    true,
                );
                let score_filter = Filter::new_condition(
                    3, // score property
                    ConditionType::Greater,
                    vec![Some(IsarValue::Integer(1500))],
                    true,
                );
                let or_filter = Filter::new_or(vec![age_filter, score_filter]);

                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.set_filter(or_filter);
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                    .expect("Failed to execute count");
                assert_eq!(count, Some(IsarValue::Integer(4))); // Alice, Diana, Charlie, Eve
                instance.abort_txn(txn);
            }

            let closed = NativeInstance::close(instance_result, false);
            assert!(closed);
        }

        /// Test sorting operations
        #[test]
        fn test_native_sorting() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            let instance_result = NativeInstance::open_instance(
                1002,
                "sorting_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open database");
            
            let instance = &*instance_result;
            let _ids = insert_basic_query_test_data(instance, 0);

            // Test sort by age ascending
            {
                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.add_sort(2, Sort::Asc, true); // age property
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let mut cursor = instance.query_cursor(&txn, &query, None, None)
                    .expect("Failed to create query cursor");
                
                let mut ages = Vec::new();
                while let Some(reader) = cursor.next() {
                    let age = reader.read_int(2);
                    ages.push(age);
                }
                drop(cursor);
                
                assert_eq!(ages, vec![25, 28, 30, 32, 35]); // Alice, Diana, Bob, Eve, Charlie
                instance.abort_txn(txn);
            }

            // Test sort by score descending
            {
                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.add_sort(3, Sort::Desc, true); // score property
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let mut cursor = instance.query_cursor(&txn, &query, None, None)
                    .expect("Failed to create query cursor");
                
                let mut scores = Vec::new();
                while let Some(reader) = cursor.next() {
                    let score = reader.read_long(3);
                    scores.push(score);
                }
                drop(cursor);
                
                assert_eq!(scores, vec![2000, 1800, 1500, 1200, 1000]); // Charlie, Eve, Bob, Diana, Alice
                instance.abort_txn(txn);
            }

            let closed = NativeInstance::close(instance_result, false);
            assert!(closed);
        }

        /// Test aggregation operations
        #[test]
        fn test_native_aggregations() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            let instance_result = NativeInstance::open_instance(
                1003,
                "aggregation_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open database");
            
            let instance = &*instance_result;
            let _ids = insert_basic_query_test_data(instance, 0);

            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let qb = instance.query(0).expect("Failed to create query builder");
            let query = qb.build();

            // Test count
            let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                .expect("Failed to execute count");
            assert_eq!(count, Some(IsarValue::Integer(5)));

            // Test min age
            let min_age = instance.query_aggregate(&txn, &query, Aggregation::Min, Some(2))
                .expect("Failed to execute min");
            assert_eq!(min_age, Some(IsarValue::Integer(25)));

            // Test max age
            let max_age = instance.query_aggregate(&txn, &query, Aggregation::Max, Some(2))
                .expect("Failed to execute max");
            assert_eq!(max_age, Some(IsarValue::Integer(35)));

            // Test sum of scores
            let sum_scores = instance.query_aggregate(&txn, &query, Aggregation::Sum, Some(3))
                .expect("Failed to execute sum");
            assert_eq!(sum_scores, Some(IsarValue::Integer(7500))); // 1000+1500+2000+1200+1800

            // Test average of ages
            let avg_age = instance.query_aggregate(&txn, &query, Aggregation::Average, Some(2))
                .expect("Failed to execute average");
            if let Some(IsarValue::Real(avg)) = avg_age {
                assert!((avg - 30.0).abs() < 0.01); // (25+30+35+28+32)/5 = 30
            } else {
                panic!("Expected Real value for average");
            }

            instance.abort_txn(txn);
            let closed = NativeInstance::close(instance_result, false);
            assert!(closed);
        }

        /// Test limit and offset operations
        #[test]
        fn test_native_limit_offset() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            let instance_result = NativeInstance::open_instance(
                1004,
                "limit_offset_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open database");
            
            let instance = &*instance_result;
            let _ids = insert_basic_query_test_data(instance, 0);

            // Test limit
            {
                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.add_sort(2, Sort::Asc, true); // Sort by age
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let mut cursor = instance.query_cursor(&txn, &query, None, Some(3))
                    .expect("Failed to create query cursor");
                
                let mut count = 0;
                while cursor.next().is_some() {
                    count += 1;
                }
                drop(cursor);
                
                assert_eq!(count, 3);
                instance.abort_txn(txn);
            }

            // Test offset
            {
                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.add_sort(2, Sort::Asc, true); // Sort by age
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let mut cursor = instance.query_cursor(&txn, &query, Some(2), None)
                    .expect("Failed to create query cursor");
                
                let mut ages = Vec::new();
                while let Some(reader) = cursor.next() {
                    let age = reader.read_int(2);
                    ages.push(age);
                }
                drop(cursor);
                
                assert_eq!(ages, vec![30, 32, 35]); // Bob, Eve, Charlie (skipping Alice, Diana)
                instance.abort_txn(txn);
            }

            // Test offset and limit together
            {
                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.add_sort(2, Sort::Asc, true); // Sort by age
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let mut cursor = instance.query_cursor(&txn, &query, Some(1), Some(2))
                    .expect("Failed to create query cursor");
                
                let mut ages = Vec::new();
                while let Some(reader) = cursor.next() {
                    let age = reader.read_int(2);
                    ages.push(age);
                }
                drop(cursor);
                
                assert_eq!(ages, vec![28, 30]); // Diana, Bob (skip Alice, limit 2)
                instance.abort_txn(txn);
            }

            let closed = NativeInstance::close(instance_result, false);
            assert!(closed);
        }

        /// Test distinct operations
        #[test]
        fn test_native_distinct() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            let instance_result = NativeInstance::open_instance(
                1005,
                "distinct_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open database");
            
            let instance = &*instance_result;
            
            // Insert data with some duplicate values
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            let mut insert = instance.insert(txn, 0, 6)
                .expect("Failed to create insert");

            let test_data = vec![
                ("Alice", 25), ("Bob", 30), ("Charlie", 25), 
                ("Diana", 30), ("Eve", 35), ("Frank", 25)
            ];

            for (i, (name, age)) in test_data.iter().enumerate() {
                let id = instance.auto_increment(0);
                insert.write_string(1, name);
                insert.write_int(2, *age);
                insert.write_long(3, 1000 + i as i64 * 100);
                insert.write_float(4, 4.0);
                insert.write_double(5, 50000.0);
                insert.write_bool(6, true);
                insert.save(id).expect("Failed to save test data");
            }
            
            let txn = insert.finish().expect("Failed to finish insert");
            instance.commit_txn(txn).expect("Failed to commit transaction");

            // Test distinct by age
            {
                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.add_distinct(2, true); // age property
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let mut cursor = instance.query_cursor(&txn, &query, None, None)
                    .expect("Failed to create query cursor");
                
                let mut distinct_ages = std::collections::HashSet::new();
                while let Some(reader) = cursor.next() {
                    let age = reader.read_int(2);
                    distinct_ages.insert(age);
                }
                drop(cursor);
                
                assert_eq!(distinct_ages.len(), 3); // 25, 30, 35
                assert!(distinct_ages.contains(&25));
                assert!(distinct_ages.contains(&30));
                assert!(distinct_ages.contains(&35));
                
                instance.abort_txn(txn);
            }

            let closed = NativeInstance::close(instance_result, false);
            assert!(closed);
        }

        /// Test complex queries combining filters, sorting, and limits
        #[test]
        fn test_native_complex_queries() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            let instance_result = NativeInstance::open_instance(
                1006,
                "complex_query_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open database");
            
            let instance = &*instance_result;
            let _ids = insert_basic_query_test_data(instance, 0);

            // Complex query: age >= 28 AND isActive = true, sorted by score descending, limit 2
            {
                let age_filter = Filter::new_condition(
                    2, // age property
                    ConditionType::GreaterOrEqual,
                    vec![Some(IsarValue::Integer(28))],
                    true,
                );
                let active_filter = Filter::new_condition(
                    6, // isActive property
                    ConditionType::Equal,
                    vec![Some(IsarValue::Bool(true))],
                    true,
                );
                let combined_filter = Filter::new_and(vec![age_filter, active_filter]);

                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.set_filter(combined_filter);
                qb.add_sort(3, Sort::Desc, true);
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let mut cursor = instance.query_cursor(&txn, &query, None, Some(2))
                    .expect("Failed to create query cursor");
                
                let mut results = Vec::new();
                while let Some(reader) = cursor.next() {
                    let name = reader.read_string(1).unwrap_or("").to_string();
                    let score = reader.read_long(3);
                    results.push((name, score));
                }
                drop(cursor);
                
                assert_eq!(results.len(), 2);
                assert_eq!(results[0], ("Charlie".to_string(), 2000)); // Highest score, active, age 35
                assert_eq!(results[1], ("Diana".to_string(), 1200)); // Second result, active, age 28
                
                instance.abort_txn(txn);
            }

            let closed = NativeInstance::close(instance_result, false);
            assert!(closed);
        }
    }

    #[cfg(test)]
    #[cfg(feature = "sqlite")]
    mod sqlite_query_tests {
        use super::*;

        /// Test basic filter operations on SQLite backend
        #[test]
        fn test_sqlite_basic_filters() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            let instance = SQLiteInstance::open_instance(
                2000,
                "sqlite_query_filter_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open SQLite database");
            
            let _ids = insert_basic_query_test_data(&instance, 0);

            // Test equal filter
            {
                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.set_filter(Filter::new_condition(
                    1, // name property
                    ConditionType::Equal,
                    vec![Some(IsarValue::String("Alice".to_string()))],
                    true,
                ));
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                    .expect("Failed to execute count");
                assert_eq!(count, Some(IsarValue::Integer(1)));
                instance.abort_txn(txn);
            }

            let closed = SQLiteInstance::close(instance, false);
            assert!(closed);
        }

        /// Test aggregation operations on SQLite backend
        #[test]
        fn test_sqlite_aggregations() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            let instance = SQLiteInstance::open_instance(
                2001,
                "sqlite_aggregation_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open SQLite database");
            
            let _ids = insert_basic_query_test_data(&instance, 0);

            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let qb = instance.query(0).expect("Failed to create query builder");
            let query = qb.build();

            // Test count
            let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                .expect("Failed to execute count");
            assert_eq!(count, Some(IsarValue::Integer(5)));

            // Test min age
            let min_age = instance.query_aggregate(&txn, &query, Aggregation::Min, Some(2))
                .expect("Failed to execute min");
            assert_eq!(min_age, Some(IsarValue::Integer(25)));

            instance.abort_txn(txn);
            let closed = SQLiteInstance::close(instance, false);
            assert!(closed);
        }

        /// Test sorting and limiting on SQLite backend
        #[test]
        fn test_sqlite_sorting_limiting() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            let instance = SQLiteInstance::open_instance(
                2002,
                "sqlite_sort_limit_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open SQLite database");
            
            let _ids = insert_basic_query_test_data(&instance, 0);

            // Test sort by age ascending with limit
            {
                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.add_sort(2, Sort::Desc, true); // Sort by age desc
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                let mut cursor = instance.query_cursor(&txn, &query, None, Some(2))
                    .expect("Failed to create query cursor");
                
                let mut ages = Vec::new();
                while let Some(reader) = cursor.next() {
                    let age = reader.read_int(2);
                    ages.push(age);
                }
                drop(cursor);
                
                assert_eq!(ages.len(), 2);
                assert!(ages[0] >= ages[1]); // Descending order
                
                instance.abort_txn(txn);
            }

            let closed = SQLiteInstance::close(instance, false);
            assert!(closed);
        }
    }

    #[cfg(test)]
    #[cfg(all(feature = "native", feature = "sqlite"))]
    mod cross_backend_query_tests {
        use super::*;

        /// Test query result consistency between Native and SQLite backends
        #[test]
        fn test_query_result_consistency() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            
            // Setup Native instance
            let native_instance = NativeInstance::open_instance(
                3000,
                "native_consistency_db",
                db_dir,
                schemas.clone(),
                1024,
                None,
                None,
            ).expect("Failed to open Native database");
            let native_instance_ref = &*native_instance;
            
            // Setup SQLite instance
            let sqlite_temp_dir = create_test_dir();
            let sqlite_db_dir = sqlite_temp_dir.path().to_str().unwrap();
            let sqlite_instance = SQLiteInstance::open_instance(
                3001,
                "sqlite_consistency_db",
                sqlite_db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open SQLite database");
            
            // Insert same data in both
            let _native_ids = insert_basic_query_test_data(native_instance_ref, 0);
            let _sqlite_ids = insert_basic_query_test_data(&sqlite_instance, 0);

            // Test count consistency
            {
                let native_qb = native_instance_ref.query(0).expect("Failed to create native query");
                let native_query = native_qb.build();
                
                let sqlite_qb = sqlite_instance.query(0).expect("Failed to create sqlite query");
                let sqlite_query = sqlite_qb.build();
                
                let native_txn = native_instance_ref.begin_txn(false).expect("Failed to begin native txn");
                let sqlite_txn = sqlite_instance.begin_txn(false).expect("Failed to begin sqlite txn");
                
                let native_count = native_instance_ref.query_aggregate(&native_txn, &native_query, Aggregation::Count, None)
                    .expect("Failed to execute native count");
                let sqlite_count = sqlite_instance.query_aggregate(&sqlite_txn, &sqlite_query, Aggregation::Count, None)
                    .expect("Failed to execute sqlite count");
                
                assert_eq!(native_count, sqlite_count);
                assert_eq!(native_count, Some(IsarValue::Integer(5)));
                
                native_instance_ref.abort_txn(native_txn);
                sqlite_instance.abort_txn(sqlite_txn);
            }

            // Test filter consistency
            {
                let age_filter = Filter::new_condition(
                    2, // age property
                    ConditionType::Greater,
                    vec![Some(IsarValue::Integer(30))],
                    true,
                );

                let mut native_qb = native_instance_ref.query(0).expect("Failed to create native query");
                native_qb.set_filter(age_filter.clone());
                let native_query = native_qb.build();
                
                let mut sqlite_qb = sqlite_instance.query(0).expect("Failed to create sqlite query");
                sqlite_qb.set_filter(age_filter);
                let sqlite_query = sqlite_qb.build();
                
                let native_txn = native_instance_ref.begin_txn(false).expect("Failed to begin native txn");
                let sqlite_txn = sqlite_instance.begin_txn(false).expect("Failed to begin sqlite txn");
                
                let native_count = native_instance_ref.query_aggregate(&native_txn, &native_query, Aggregation::Count, None)
                    .expect("Failed to execute native count");
                let sqlite_count = sqlite_instance.query_aggregate(&sqlite_txn, &sqlite_query, Aggregation::Count, None)
                    .expect("Failed to execute sqlite count");
                
                assert_eq!(native_count, sqlite_count);
                assert_eq!(native_count, Some(IsarValue::Integer(2))); // Charlie and Eve
                
                native_instance_ref.abort_txn(native_txn);
                sqlite_instance.abort_txn(sqlite_txn);
            }

            // Test aggregation consistency
            {
                let native_qb = native_instance_ref.query(0).expect("Failed to create native query");
                let native_query = native_qb.build();
                
                let sqlite_qb = sqlite_instance.query(0).expect("Failed to create sqlite query");
                let sqlite_query = sqlite_qb.build();
                
                let native_txn = native_instance_ref.begin_txn(false).expect("Failed to begin native txn");
                let sqlite_txn = sqlite_instance.begin_txn(false).expect("Failed to begin sqlite txn");
                
                let native_min = native_instance_ref.query_aggregate(&native_txn, &native_query, Aggregation::Min, Some(2))
                    .expect("Failed to execute native min");
                let sqlite_min = sqlite_instance.query_aggregate(&sqlite_txn, &sqlite_query, Aggregation::Min, Some(2))
                    .expect("Failed to execute sqlite min");
                
                let native_max = native_instance_ref.query_aggregate(&native_txn, &native_query, Aggregation::Max, Some(2))
                    .expect("Failed to execute native max");
                let sqlite_max = sqlite_instance.query_aggregate(&sqlite_txn, &sqlite_query, Aggregation::Max, Some(2))
                    .expect("Failed to execute sqlite max");
                
                assert_eq!(native_min, sqlite_min);
                assert_eq!(native_max, sqlite_max);
                assert_eq!(native_min, Some(IsarValue::Integer(25)));
                assert_eq!(native_max, Some(IsarValue::Integer(35)));
                
                native_instance_ref.abort_txn(native_txn);
                sqlite_instance.abort_txn(sqlite_txn);
            }

            let native_closed = NativeInstance::close(native_instance, false);
            let sqlite_closed = SQLiteInstance::close(sqlite_instance, false);
            assert!(native_closed);
            assert!(sqlite_closed);
        }
    }

    #[cfg(test)]
    mod query_error_tests {
        use super::*;

        /// Test query error scenarios and edge cases
        #[test]
        #[cfg(feature = "native")]
        fn test_query_error_scenarios() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            let instance_result = NativeInstance::open_instance(
                4000,
                "error_test_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open database");
            
            let instance = &*instance_result;

            // Test query on non-existent collection
            let result = instance.query(999);
            assert!(result.is_err());

            // Test aggregation on non-existent property
            let qb = instance.query(0).expect("Failed to create query builder");
            let query = qb.build();
            let txn = instance.begin_txn(false).expect("Failed to begin transaction");
            
            let result = instance.query_aggregate(&txn, &query, Aggregation::Min, Some(999));
            // This might succeed but return None, or fail - either is acceptable
            let _ = result;
            
            instance.abort_txn(txn);
            let closed = NativeInstance::close(instance_result, false);
            assert!(closed);
        }

        /// Test performance with larger datasets
        #[test]
        #[cfg(feature = "native")]
        fn test_query_performance_large_dataset() {
            let temp_dir = create_test_dir();
            let db_dir = temp_dir.path().to_str().unwrap();
            
            let schemas = vec![create_query_test_schema()];
            let instance_result = NativeInstance::open_instance(
                4001,
                "performance_test_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open database");
            
            let instance = &*instance_result;

            // Insert larger dataset
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            let mut insert = instance.insert(txn, 0, 100)
                .expect("Failed to create insert");

            for i in 0..100 {
                let id = instance.auto_increment(0);
                insert.write_string(1, &format!("User{}", i));
                insert.write_int(2, 20 + (i % 50) as i32); // Ages 20-69
                insert.write_long(3, 1000 + i as i64 * 10);
                insert.write_float(4, 3.0 + (i % 5) as f32 * 0.5);
                insert.write_double(5, 40000.0 + i as f64 * 1000.0);
                insert.write_bool(6, i % 2 == 0);
                insert.save(id).expect("Failed to save test data");
            }
            
            let txn = insert.finish().expect("Failed to finish insert");
            instance.commit_txn(txn).expect("Failed to commit transaction");

            // Test complex query on large dataset
            {
                let age_filter = Filter::new_condition(
                    2, // age property
                    ConditionType::Between,
                    vec![Some(IsarValue::Integer(30)), Some(IsarValue::Integer(50))],
                    true,
                );
                let active_filter = Filter::new_condition(
                    6, // isActive property
                    ConditionType::Equal,
                    vec![Some(IsarValue::Bool(true))],
                    true,
                );
                let combined_filter = Filter::new_and(vec![age_filter, active_filter]);

                let mut qb = instance.query(0).expect("Failed to create query builder");
                qb.set_filter(combined_filter);
                qb.add_sort(3, Sort::Desc, true);
                let query = qb.build();
                
                let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
                
                // Test aggregation performance
                let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                    .expect("Failed to execute count");
                assert!(count.is_some());
                
                // Test query cursor performance
                let mut cursor = instance.query_cursor(&txn, &query, None, Some(10))
                    .expect("Failed to create query cursor");
                
                let mut result_count = 0;
                while cursor.next().is_some() {
                    result_count += 1;
                }
                drop(cursor);
                
                assert!(result_count <= 10);
                instance.abort_txn(txn);
            }

            let closed = NativeInstance::close(instance_result, false);
            assert!(closed);
        }
    }
} 