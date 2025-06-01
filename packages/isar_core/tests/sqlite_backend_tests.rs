//! SQLite Backend Integration Tests
//! 
//! Tests specific to the SQLite backend implementation

#[path = "common/mod.rs"]
mod common;

use common::*;
use isar_core::core::instance::IsarInstance;

#[cfg(feature = "sqlite")]
use isar_core::sqlite::sqlite_instance::SQLiteInstance;

#[cfg(test)]
#[cfg(feature = "sqlite")]
mod tests {
    use super::*;

    /// Test CRUD operations on SQLite backend
    #[test]
    fn test_sqlite_crud_operations() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_user_schema()];
        let instance = SQLiteInstance::open_instance(
            sqlite_backend_id(0),
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
            sqlite_backend_id(1),
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
                assert!(auto_id > 0, "Auto increment should be positive");
            } // cursor dropped here
            
            instance.commit_txn(txn).expect("Failed to commit transaction");
        }
    }
} 