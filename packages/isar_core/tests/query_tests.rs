//! Query Integration Tests
//! 
//! Tests for query operations, filtering, sorting, and advanced queries

#[path = "common/mod.rs"]
mod common;

use common::*;
use isar_core::core::instance::IsarInstance;
use isar_core::core::filter::*;
use isar_core::core::value::IsarValue;
use isar_core::core::instance::Aggregation;
use isar_core::core::query_builder::{IsarQueryBuilder, Sort};
use isar_core::core::cursor::IsarQueryCursor;
use isar_core::core::writer::IsarWriter;
use isar_core::core::insert::IsarInsert;
use isar_core::core::reader::IsarReader;

#[cfg(feature = "native")]
use isar_core::native::native_instance::NativeInstance;

#[cfg(feature = "sqlite")]
use isar_core::sqlite::sqlite_instance::SQLiteInstance;

/// Insert test data for query testing - simplified version for basic data only
fn insert_query_test_data<T: IsarInstance>(instance: &T, collection_index: u16) -> Vec<i64> {
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
        let _ids = insert_query_test_data(instance, 0);

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
        let _ids = insert_query_test_data(instance, 0);

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
        let _ids = insert_query_test_data(instance, 0);

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

        instance.abort_txn(txn);
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
        
        let _ids = insert_query_test_data(&instance, 0);

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
        let _native_ids = insert_query_test_data(native_instance_ref, 0);
        let _sqlite_ids = insert_query_test_data(&sqlite_instance, 0);

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

        let native_closed = NativeInstance::close(native_instance, false);
        let sqlite_closed = SQLiteInstance::close(sqlite_instance, false);
        assert!(native_closed);
        assert!(sqlite_closed);
    }
} 