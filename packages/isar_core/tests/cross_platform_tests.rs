//! Cross-Platform Integration Tests
//! 
//! Tests to ensure consistency between different backend implementations

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
                cross_platform_id(0),
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
                cross_platform_id(1),
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

    /// Test schema compatibility across backends
    #[test]
    #[cfg(all(feature = "native", feature = "sqlite"))]
    fn test_schema_compatibility() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        // Create comprehensive schema to test all data types
        let schemas = vec![create_comprehensive_schema()];
        
        // Test with Native backend
        {
            let instance = NativeInstance::open_instance(
                cross_platform_id(2),
                "schema_compat_native",
                db_dir,
                schemas.clone(),
                1024,
                None,
                None,
            ).expect("Failed to open native database with comprehensive schema");
            
            let closed = NativeInstance::close(instance, false);
            assert!(closed);
        }
        
        // Test with SQLite backend
        {
            let sqlite_temp_dir = create_test_dir();
            let sqlite_db_dir = sqlite_temp_dir.path().to_str().unwrap();
            
            let instance = SQLiteInstance::open_instance(
                cross_platform_id(3),
                "schema_compat_sqlite",
                sqlite_db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open SQLite database with comprehensive schema");
            
            let closed = SQLiteInstance::close(instance, false);
            assert!(closed);
        }
    }

    /// Test auto-increment consistency across backends
    #[test]
    #[cfg(all(feature = "native", feature = "sqlite"))]
    fn test_auto_increment_consistency() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        let schemas = vec![create_user_schema()];
        
        // Test auto-increment behavior in Native
        let native_ids = {
            let instance = NativeInstance::open_instance(
                cross_platform_id(4),
                "auto_inc_native",
                db_dir,
                schemas.clone(),
                1024,
                None,
                None,
            ).expect("Failed to open native database");
            
            let mut ids = Vec::new();
            for _ in 0..5 {
                ids.push(instance.auto_increment(0));
            }
            
            let closed = NativeInstance::close(instance, false);
            assert!(closed);
            ids
        };
        
        // Test auto-increment behavior in SQLite
        let sqlite_ids = {
            let sqlite_temp_dir = create_test_dir();
            let sqlite_db_dir = sqlite_temp_dir.path().to_str().unwrap();
            
            let instance = SQLiteInstance::open_instance(
                cross_platform_id(5),
                "auto_inc_sqlite",
                sqlite_db_dir,
                schemas,
                1024,
                None,
                None,
            ).expect("Failed to open SQLite database");
            
            let mut ids = Vec::new();
            for _ in 0..5 {
                ids.push(instance.auto_increment(0));
            }
            
            let closed = SQLiteInstance::close(instance, false);
            assert!(closed);
            ids
        };
        
        // Both should generate sequential IDs starting from 1
        assert_eq!(native_ids.len(), 5);
        assert_eq!(sqlite_ids.len(), 5);
        
        // Check that IDs are sequential
        for i in 1..native_ids.len() {
            assert!(native_ids[i] > native_ids[i-1], "Native IDs should be sequential");
            assert!(sqlite_ids[i] > sqlite_ids[i-1], "SQLite IDs should be sequential");
        }
    }
} 