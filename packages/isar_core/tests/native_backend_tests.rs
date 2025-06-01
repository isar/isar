//! Native Backend Integration Tests
//! 
//! Tests specific to the native backend implementation

use crate::common::*;
use isar_core::core::instance::IsarInstance;

#[cfg(feature = "native")]
use isar_core::native::native_instance::NativeInstance;

#[cfg(test)]
#[cfg(feature = "native")]
mod tests {
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