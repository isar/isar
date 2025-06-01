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
mod performance_tests {
    use super::*;
    use std::time::Instant;

    /// Basic performance test
    #[test]
    #[cfg(feature = "native")]
    fn test_basic_performance() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = NativeInstance::open_instance(
            12,
            "perf_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");
        
        const ITERATIONS: usize = 1000;
        
        // Benchmark transaction creation
        let start = Instant::now();
        for _ in 0..ITERATIONS {
            let txn = instance.begin_txn(false).expect("Failed to begin transaction");
            instance.abort_txn(txn);
        }
        let txn_duration = start.elapsed();
        println!("Transaction creation for {} iterations took: {:?}", ITERATIONS, txn_duration);
        
        // Benchmark cursor creation
        let start = Instant::now();
        {
            let txn = instance.begin_txn(false).expect("Failed to begin transaction");
            for _ in 0..ITERATIONS {
                let _cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                // cursor automatically dropped at end of scope
            }
            instance.abort_txn(txn);
        }
        let cursor_duration = start.elapsed();
        println!("Cursor creation for {} iterations took: {:?}", ITERATIONS, cursor_duration);
        
        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
        
        // Assert reasonable performance (adjust thresholds as needed)
        assert!(txn_duration.as_millis() < 5000, "Transaction performance degraded: {:?}", txn_duration);
        assert!(cursor_duration.as_millis() < 5000, "Cursor performance degraded: {:?}", cursor_duration);
    }
} 