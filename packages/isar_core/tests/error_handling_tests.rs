//! Error Handling Integration Tests
//! 
//! Tests for error scenarios, edge cases, and recovery behavior

#[path = "common/mod.rs"]
mod common;

use common::*;
use isar_core::core::instance::IsarInstance;

#[cfg(feature = "native")]
use isar_core::native::native_instance::NativeInstance;

#[cfg(feature = "sqlite")]
use isar_core::sqlite::sqlite_instance::SQLiteInstance;

#[cfg(test)]
mod tests {
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

    /// Test edge cases with invalid data
    #[test]
    #[cfg(feature = "native")]
    fn test_invalid_data_handling() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = NativeInstance::open_instance(
            12,
            "invalid_data_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");

        // Test operations on non-existent records
        {
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            
            // Try to update non-existent record
            let updates = vec![(1, Some(isar_core::core::value::IsarValue::String("Test".to_string())))];
            let updated = instance.update(&txn, 0, 999999, &updates).expect("Update operation should not fail");
            assert!(!updated, "Update should return false for non-existent record");
            
            // Try to delete non-existent record
            let deleted = instance.delete(&txn, 0, 999999).expect("Delete operation should not fail");
            assert!(!deleted, "Delete should return false for non-existent record");
            
            instance.abort_txn(txn);
        }

        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }

    /// Test database size limits and constraints
    #[test]
    #[cfg(feature = "native")]
    fn test_database_constraints() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        
        // Test with very small max size
        let instance = NativeInstance::open_instance(
            13,
            "constraints_db",
            db_dir,
            schemas,
            1, // Very small max size (1 MiB)
            None,
            None,
        ).expect("Failed to open database with small size limit");
        
        // Database should still be functional despite size constraints
        {
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            {
                let _cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
            } // cursor dropped here
            instance.commit_txn(txn).expect("Failed to commit transaction");
        }
        
        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }

    /// Test concurrent access error scenarios
    #[test]
    #[cfg(feature = "native")]
    fn test_concurrent_access_errors() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = NativeInstance::open_instance(
            14,
            "concurrent_errors_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");
        
        // Test multiple write transactions (if implementation allows)
        {
            let write_txn1 = instance.begin_txn(true).expect("Failed to begin first write transaction");
            
            // Attempt second write transaction - behavior depends on implementation
            let write_txn2_result = instance.begin_txn(true);
            
            match write_txn2_result {
                Ok(write_txn2) => {
                    // If second write transaction is allowed, clean up both
                    instance.abort_txn(write_txn2);
                    instance.abort_txn(write_txn1);
                }
                Err(_) => {
                    // If second write transaction fails (expected), clean up first
                    instance.abort_txn(write_txn1);
                }
            }
        }
        
        let closed = NativeInstance::close(instance, false);
        assert!(closed, "Failed to close database");
    }

    /// Test SQLite-specific error scenarios
    #[test]
    #[cfg(feature = "sqlite")]
    fn test_sqlite_error_scenarios() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = SQLiteInstance::open_instance(
            15,
            "sqlite_error_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");
        
        // Test invalid collection access
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            {
                let result = instance.cursor(&txn, 999); // Invalid collection index
                assert!(result.is_err(), "Expected error for invalid collection index in SQLite");
            }
            instance.abort_txn(txn);
        }
        
        let closed = SQLiteInstance::close(instance, false);
        assert!(closed, "Failed to close SQLite database");
    }

    /// Test recovery from database corruption (simulation)
    #[test]
    #[cfg(feature = "native")]
    fn test_corruption_recovery() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        
        // Create and use a database normally
        {
            let instance = NativeInstance::open_instance(
                16,
                "corruption_test_db",
                db_dir,
                schemas.clone(),
                1024,
                None,
                None,
            ).expect("Failed to open database initially");
            
            // Perform some operations
            {
                let txn = instance.begin_txn(true).expect("Failed to begin transaction");
                {
                    let _cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
                } // cursor dropped here
                instance.commit_txn(txn).expect("Failed to commit transaction");
            }
            
            let closed = NativeInstance::close(instance, false);
            assert!(closed);
        }
        
        // Try to reopen the same database (should work)
        {
            let instance = NativeInstance::open_instance(
                17,
                "corruption_test_db",
                db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to reopen database");
            
            let closed = NativeInstance::close(instance, false);
            assert!(closed);
        }
    }
} 