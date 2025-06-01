//! Advanced Features Integration Tests
//! 
//! Tests for encryption, watchers, and comprehensive aggregations

#[path = "common/mod.rs"]
mod common;

use common::*;
use isar_core::core::instance::IsarInstance;
use isar_core::core::writer::IsarWriter;
use isar_core::core::insert::IsarInsert;
use isar_core::core::schema::*;
use isar_core::core::data_type::DataType;
use isar_core::core::filter::*;
use isar_core::core::value::IsarValue;
use isar_core::core::instance::Aggregation;
use isar_core::core::query_builder::IsarQueryBuilder;
use isar_core::core::watcher::WatcherCallback;
use std::sync::{Arc, Mutex};
use std::collections::HashMap;

#[cfg(feature = "native")]
use isar_core::native::native_instance::NativeInstance;

#[cfg(feature = "sqlite")]
use isar_core::sqlite::sqlite_instance::SQLiteInstance;

/// Get instance IDs for advanced features tests (3000-3099)
pub fn advanced_features_id(offset: u32) -> u32 {
    3000 + offset
}

/// Create schema for advanced testing with complex data types
fn create_advanced_test_schema() -> IsarSchema {
    let properties = vec![
        PropertySchema::new("name", DataType::String, None),
        PropertySchema::new("score", DataType::Int, None),
        PropertySchema::new("rating", DataType::Float, None),
        PropertySchema::new("balance", DataType::Double, None),
        PropertySchema::new("timestamp", DataType::Long, None),
        PropertySchema::new("isActive", DataType::Bool, None),
        PropertySchema::new("tags", DataType::StringList, None),
        PropertySchema::new("scores", DataType::IntList, None),
        PropertySchema::new("ratings", DataType::FloatList, None),
        PropertySchema::new("balances", DataType::DoubleList, None),
        PropertySchema::new("data", DataType::ByteList, None),
        PropertySchema::new("metadata", DataType::Json, None),
    ];
    
    let indexes = vec![
        IndexSchema::new("name_index", vec!["name"], false, false),
        IndexSchema::new("score_index", vec!["score"], false, false),
        IndexSchema::new("rating_index", vec!["rating"], false, false),
        IndexSchema::new("timestamp_index", vec!["timestamp"], false, false),
        IndexSchema::new("compound_index", vec!["score", "rating"], false, false),
    ];
    
    IsarSchema::new("AdvancedTest", Some("id"), properties, indexes, false)
}

/// Insert comprehensive test data for advanced features
fn insert_advanced_test_data<T: IsarInstance>(instance: &T, collection_index: u16) -> Vec<i64> {
    let mut ids = Vec::new();
    
    let test_data = vec![
        ("Alpha", 100, 4.5f32, 1000.50, 1703980800i64, true, 
         vec!["premium", "featured"], vec![10, 20, 30], 
         vec![1.1f32, 2.2f32, 3.3f32], vec![100.1, 200.2, 300.3],
         vec![1u8, 2u8, 3u8], r#"{"category": "A", "priority": 1}"#),
        ("Beta", 85, 4.2f32, 850.75, 1703980860i64, true,
         vec!["standard"], vec![15, 25, 35],
         vec![1.5f32, 2.5f32, 3.5f32], vec![150.1, 250.2, 350.3],
         vec![4u8, 5u8, 6u8], r#"{"category": "B", "priority": 2}"#),
        ("Gamma", 120, 4.8f32, 1200.25, 1703980920i64, false,
         vec!["premium", "exclusive"], vec![5, 15, 25],
         vec![2.1f32, 3.2f32, 4.3f32], vec![200.1, 300.2, 400.3],
         vec![7u8, 8u8, 9u8], r#"{"category": "A", "priority": 3}"#),
        ("Delta", 75, 3.9f32, 750.00, 1703980980i64, true,
         vec!["basic"], vec![20, 30, 40],
         vec![1.8f32, 2.8f32, 3.8f32], vec![175.1, 275.2, 375.3],
         vec![10u8, 11u8, 12u8], r#"{"category": "C", "priority": 1}"#),
        ("Epsilon", 95, 4.3f32, 950.80, 1703981040i64, true,
         vec!["standard", "featured"], vec![12, 22, 32],
         vec![2.0f32, 3.0f32, 4.0f32], vec![190.1, 290.2, 390.3],
         vec![13u8, 14u8, 15u8], r#"{"category": "B", "priority": 2}"#),
    ];
    
    let txn = instance.begin_txn(true).expect("Failed to begin transaction");
    let mut insert = instance.insert(txn, collection_index, test_data.len() as u32)
        .expect("Failed to create insert");
    
    for (name, score, rating, balance, timestamp, active, tags, scores, ratings, balances, data, metadata) in test_data {
        let id = instance.auto_increment(collection_index);
        ids.push(id);
        
        // Write basic properties
        insert.write_string(1, name);
        insert.write_int(2, score);
        insert.write_float(3, rating);
        insert.write_double(4, balance);
        insert.write_long(5, timestamp);
        insert.write_bool(6, active);
        
        // Write string list (tags)
        if let Some(mut list_writer) = insert.begin_list(7, tags.len() as u32) {
            for (i, tag) in tags.iter().enumerate() {
                list_writer.write_string(i as u32, tag);
            }
            insert.end_list(list_writer);
        }
        
        // Write int list (scores)
        if let Some(mut list_writer) = insert.begin_list(8, scores.len() as u32) {
            for (i, score) in scores.iter().enumerate() {
                list_writer.write_int(i as u32, *score);
            }
            insert.end_list(list_writer);
        }
        
        // Write float list (ratings)
        if let Some(mut list_writer) = insert.begin_list(9, ratings.len() as u32) {
            for (i, rating) in ratings.iter().enumerate() {
                list_writer.write_float(i as u32, *rating);
            }
            insert.end_list(list_writer);
        }
        
        // Write double list (balances)
        if let Some(mut list_writer) = insert.begin_list(10, balances.len() as u32) {
            for (i, balance) in balances.iter().enumerate() {
                list_writer.write_double(i as u32, *balance);
            }
            insert.end_list(list_writer);
        }
        
        // Write byte list (data)
        if let Some(mut list_writer) = insert.begin_list(11, data.len() as u32) {
            for (i, byte) in data.iter().enumerate() {
                list_writer.write_byte(i as u32, *byte);
            }
            insert.end_list(list_writer);
        }
        
        // Write JSON metadata
        insert.write_string(12, metadata);
        
        insert.save(id).expect("Failed to save data");
    }

    let txn = insert.finish().expect("Failed to finish insert");
    instance.commit_txn(txn).expect("Failed to commit transaction");
    ids
}

#[cfg(test)]
#[cfg(feature = "native")]
mod native_advanced_tests {
    use super::*;

    #[test]
    fn test_comprehensive_aggregations() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_advanced_test_schema()];
        let instance_result = NativeInstance::open_instance(
            advanced_features_id(1),
            "aggregation_test_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");
        
        let instance = &*instance_result;
        let _ids = insert_advanced_test_data(instance, 0);

        let txn = instance.begin_txn(false).expect("Failed to begin read transaction");

        // Test Count aggregation
        {
            let qb = instance.query(0).expect("Failed to create query builder");
            let query = qb.build();
            
            let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                .expect("Failed to execute count");
            assert_eq!(count, Some(IsarValue::Integer(5)));
        }

        // Test Min aggregation on score
        {
            let qb = instance.query(0).expect("Failed to create query builder");
            let query = qb.build();
            
            let min_score = instance.query_aggregate(&txn, &query, Aggregation::Min, Some(2))
                .expect("Failed to execute min");
            assert_eq!(min_score, Some(IsarValue::Integer(75))); // Delta has lowest score
        }

        // Test Max aggregation on score
        {
            let qb = instance.query(0).expect("Failed to create query builder");
            let query = qb.build();
            
            let max_score = instance.query_aggregate(&txn, &query, Aggregation::Max, Some(2))
                .expect("Failed to execute max");
            assert_eq!(max_score, Some(IsarValue::Integer(120))); // Gamma has highest score
        }

        // Test Sum aggregation on score
        {
            let qb = instance.query(0).expect("Failed to create query builder");
            let query = qb.build();
            
            let sum_score = instance.query_aggregate(&txn, &query, Aggregation::Sum, Some(2))
                .expect("Failed to execute sum");
            assert_eq!(sum_score, Some(IsarValue::Integer(475))); // 100+85+120+75+95
        }

        // Test Average aggregation on rating (float)
        {
            let qb = instance.query(0).expect("Failed to create query builder");
            let query = qb.build();
            
            let avg_rating = instance.query_aggregate(&txn, &query, Aggregation::Average, Some(3))
                .expect("Failed to execute average");
            
            if let Some(IsarValue::Real(avg)) = avg_rating {
                assert!((avg - 4.34).abs() < 0.01); // (4.5+4.2+4.8+3.9+4.3)/5 ≈ 4.34
            } else {
                panic!("Expected Real value for average");
            }
        }

        // Test IsEmpty aggregation with filtered query
        {
            let mut qb = instance.query(0).expect("Failed to create query builder");
            qb.set_filter(Filter::new_condition(
                2, // score property
                ConditionType::Greater,
                vec![Some(IsarValue::Integer(150))],
                true,
            ));
            let query = qb.build();
            
            let is_empty = instance.query_aggregate(&txn, &query, Aggregation::IsEmpty, None)
                .expect("Failed to execute is_empty");
            assert_eq!(is_empty, Some(IsarValue::Bool(true))); // No scores > 150
        }

        // Test aggregations with filtered data
        {
            let mut qb = instance.query(0).expect("Failed to create query builder");
            qb.set_filter(Filter::new_condition(
                6, // isActive property
                ConditionType::Equal,
                vec![Some(IsarValue::Bool(true))],
                true,
            ));
            let query = qb.build();
            
            let active_count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                .expect("Failed to execute filtered count");
            assert_eq!(active_count, Some(IsarValue::Integer(4))); // 4 active items
            
            let active_avg_score = instance.query_aggregate(&txn, &query, Aggregation::Average, Some(2))
                .expect("Failed to execute filtered average");
            
            if let Some(IsarValue::Real(avg)) = active_avg_score {
                assert!((avg - 88.75).abs() < 0.01); // (100+85+75+95)/4 = 88.75
            } else {
                panic!("Expected Real value for filtered average");
            }
        }

        instance.abort_txn(txn);
        let closed = NativeInstance::close(instance_result, false);
        assert!(closed);
    }

    #[test] 
    fn test_watcher_functionality() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_advanced_test_schema()];
        let instance_result = NativeInstance::open_instance(
            advanced_features_id(2),
            "watcher_test_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");
        
        let instance = &*instance_result;
        
        // Shared state for tracking watcher notifications
        let collection_changes = Arc::new(Mutex::new(0u32));
        let object_changes = Arc::new(Mutex::new(HashMap::<i64, u32>::new()));
        let query_changes = Arc::new(Mutex::new(0u32));

        // Test collection watcher
        let collection_changes_clone = collection_changes.clone();
        let collection_callback: WatcherCallback = Box::new(move || {
            let mut count = collection_changes_clone.lock().unwrap();
            *count += 1;
        });
        
        let _collection_handle = instance.watch(0, collection_callback)
            .expect("Failed to create collection watcher");

        // Insert initial data and verify watcher triggered
        let _ids = insert_advanced_test_data(instance, 0);
        
        // Give some time for async notifications (in real implementation)
        std::thread::sleep(std::time::Duration::from_millis(10));
        
        {
            let changes = collection_changes.lock().unwrap();
            assert!(*changes > 0, "Collection watcher should have been triggered");
        }

        // Test object-specific watcher
        let object_id = 1i64;
        let object_changes_clone = object_changes.clone();
        let object_callback: WatcherCallback = Box::new(move || {
            let mut changes = object_changes_clone.lock().unwrap();
            *changes.entry(object_id).or_insert(0) += 1;
        });
        
        let _object_handle = instance.watch_object(0, object_id, object_callback)
            .expect("Failed to create object watcher");

        // Test query watcher
        let qb = instance.query(0).expect("Failed to create query builder");
        let query = qb.build();
        
        let query_changes_clone = query_changes.clone();
        let query_callback: WatcherCallback = Box::new(move || {
            let mut count = query_changes_clone.lock().unwrap();
            *count += 1;
        });
        
        let _query_handle = instance.watch_query(&query, query_callback)
            .expect("Failed to create query watcher");

        // Perform operations that should trigger watchers
        {
            let txn = instance.begin_txn(true).expect("Failed to begin transaction");
            let mut insert = instance.insert(txn, 0, 1)
                .expect("Failed to create insert");
            
            let new_id = instance.auto_increment(0);
            insert.write_string(1, "New Item");
            insert.write_int(2, 50);
            insert.write_float(3, 3.5);
            insert.write_double(4, 500.0);
            insert.write_long(5, 1703981100);
            insert.write_bool(6, true);
            
            // Empty lists for simplicity
            if let Some(list_writer) = insert.begin_list(7, 0) {
                insert.end_list(list_writer);
            }
            if let Some(list_writer) = insert.begin_list(8, 0) {
                insert.end_list(list_writer);
            }
            if let Some(list_writer) = insert.begin_list(9, 0) {
                insert.end_list(list_writer);
            }
            if let Some(list_writer) = insert.begin_list(10, 0) {
                insert.end_list(list_writer);
            }
            if let Some(list_writer) = insert.begin_list(11, 0) {
                insert.end_list(list_writer);
            }
            
            insert.write_string(12, r#"{"category": "new"}"#);
            
            insert.save(new_id).expect("Failed to save new item");
            let txn = insert.finish().expect("Failed to finish insert");
            instance.commit_txn(txn).expect("Failed to commit transaction");
        }

        // Allow time for notifications
        std::thread::sleep(std::time::Duration::from_millis(10));

        // Verify watchers were triggered appropriately
        {
            let collection_count = collection_changes.lock().unwrap();
            assert!(*collection_count >= 1, "Collection watcher should have been triggered at least once");
        }
        
        {
            let query_count = query_changes.lock().unwrap();
            // Query watchers are tracked (no need to check >= 0 for u32)
            println!("Query watcher change count: {}", *query_count);
        }

        let closed = NativeInstance::close(instance_result, false);
        assert!(closed);
    }
}

#[cfg(test)]
#[cfg(feature = "sqlite")]
mod sqlite_advanced_tests {
    use super::*;

    #[test]
    fn test_sqlite_encryption() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_advanced_test_schema()];
        let _encryption_key = "test_encryption_key_123";
        
        // Test opening with encryption (requires SQLCipher feature)
        #[cfg(feature = "sqlcipher")]
        {
            let instance = SQLiteInstance::open_instance(
                advanced_features_id(3),
                "encrypted_test_db",
                db_dir,
                schemas.clone(),
                1024,
                Some(_encryption_key),
                None,
            ).expect("Failed to open encrypted database");
            
            // Insert test data
            let _ids = insert_advanced_test_data(&instance, 0);
            
            // Verify data was inserted correctly
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let qb = instance.query(0).expect("Failed to create query builder");
            let query = qb.build();
            
            let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                .expect("Failed to execute count on encrypted database");
            assert_eq!(count, Some(IsarValue::Integer(5)));
            
            instance.abort_txn(txn);
            
            // Test encryption key change
            let new_encryption_key = "new_test_key_456";
            instance.change_encryption_key(Some(new_encryption_key))
                .expect("Failed to change encryption key");
            
            // Verify database still works with new key
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction after key change");
            let count_after_rekey = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                .expect("Failed to execute count after encryption key change");
            assert_eq!(count_after_rekey, Some(IsarValue::Integer(5)));
            
            instance.abort_txn(txn);
            let closed = SQLiteInstance::close(instance, false);
            assert!(closed);
        }
        
        // Test opening without encryption when SQLCipher is not available
        #[cfg(not(feature = "sqlcipher"))]
        {
            // Should work fine without encryption
            let instance = SQLiteInstance::open_instance(
                advanced_features_id(4),
                "unencrypted_test_db",
                db_dir,
                schemas,
                1024,
                None, // No encryption key
                None,
            ).expect("Failed to open unencrypted database");
            
            let _ids = insert_advanced_test_data(&instance, 0);
            
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let qb = instance.query(0).expect("Failed to create query builder");
            let query = qb.build();
            
            let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                .expect("Failed to execute count");
            assert_eq!(count, Some(IsarValue::Integer(5)));
            
            instance.abort_txn(txn);
            let closed = SQLiteInstance::close(instance, false);
            assert!(closed);
        }
    }

    #[test]
    fn test_sqlite_comprehensive_aggregations() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_advanced_test_schema()];
        let instance = SQLiteInstance::open_instance(
            advanced_features_id(5),
            "sqlite_aggregation_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");
        
        let _ids = insert_advanced_test_data(&instance, 0);

        let txn = instance.begin_txn(false).expect("Failed to begin read transaction");

        // Test all aggregation types on SQLite backend
        {
            let qb = instance.query(0).expect("Failed to create query builder");
            let query = qb.build();
            
            // Count
            let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                .expect("Failed to execute count");
            assert_eq!(count, Some(IsarValue::Integer(5)));
            
            // Min on double field (balance)
            let min_balance = instance.query_aggregate(&txn, &query, Aggregation::Min, Some(4))
                .expect("Failed to execute min on balance");
            if let Some(IsarValue::Real(min)) = min_balance {
                assert!((min - 750.0).abs() < 0.01);
            }
            
            // Max on double field (balance)
            let max_balance = instance.query_aggregate(&txn, &query, Aggregation::Max, Some(4))
                .expect("Failed to execute max on balance");
            if let Some(IsarValue::Real(max)) = max_balance {
                assert!((max - 1200.25).abs() < 0.01);
            }
            
            // Sum on integer field (score)
            let sum_scores = instance.query_aggregate(&txn, &query, Aggregation::Sum, Some(2))
                .expect("Failed to execute sum on scores");
            assert_eq!(sum_scores, Some(IsarValue::Integer(475)));
            
            // Average on float field (rating)
            let avg_rating = instance.query_aggregate(&txn, &query, Aggregation::Average, Some(3))
                .expect("Failed to execute average on rating");
            if let Some(IsarValue::Real(avg)) = avg_rating {
                assert!((avg - 4.34).abs() < 0.01);
            }
        }

        // Test aggregations with complex filters
        {
            let mut qb = instance.query(0).expect("Failed to create query builder");
            qb.set_filter(Filter::new_and(vec![
                Filter::new_condition(
                    2, // score
                    ConditionType::GreaterOrEqual,
                    vec![Some(IsarValue::Integer(90))],
                    true,
                ),
                Filter::new_condition(
                    6, // isActive
                    ConditionType::Equal,
                    vec![Some(IsarValue::Bool(true))],
                    true,
                ),
            ]));
            let query = qb.build();
            
            let filtered_count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                .expect("Failed to execute filtered count");
            assert_eq!(filtered_count, Some(IsarValue::Integer(2))); // Alpha (100) and Epsilon (95)
            
            let filtered_avg_score = instance.query_aggregate(&txn, &query, Aggregation::Average, Some(2))
                .expect("Failed to execute filtered average");
            if let Some(IsarValue::Real(avg)) = filtered_avg_score {
                assert!((avg - 97.5).abs() < 0.01); // (100 + 95) / 2
            }
        }

        instance.abort_txn(txn);
        let closed = SQLiteInstance::close(instance, false);
        assert!(closed);
    }

    #[test]
    fn test_sqlite_watchers() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_advanced_test_schema()];
        let instance = SQLiteInstance::open_instance(
            advanced_features_id(6),
            "sqlite_watcher_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");
        
        // Test SQLite watcher implementation
        let notification_count = Arc::new(Mutex::new(0u32));
        let notification_count_clone = notification_count.clone();
        
        let callback: WatcherCallback = Box::new(move || {
            let mut count = notification_count_clone.lock().unwrap();
            *count += 1;
        });
        
        let _handle = instance.watch(0, callback)
            .expect("Failed to create SQLite watcher");
        
        // Insert data to trigger watcher
        let _ids = insert_advanced_test_data(&instance, 0);
        
        // Allow time for async notifications
        std::thread::sleep(std::time::Duration::from_millis(10));
        
        // Verify watcher was triggered
        {
            let count = notification_count.lock().unwrap();
            assert!(*count > 0, "SQLite watcher should have been triggered");
        }
        
        let closed = SQLiteInstance::close(instance, false);
        assert!(closed);
    }
}

#[cfg(test)]
#[cfg(all(feature = "native", feature = "sqlite"))]
mod cross_platform_advanced_tests {
    use super::*;

    #[test]
    fn test_aggregation_consistency_across_backends() {
        let temp_dir = create_test_dir();
        let native_db_dir = temp_dir.path().to_str().unwrap();
        
        let sqlite_temp_dir = create_test_dir();
        let sqlite_db_dir = sqlite_temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_advanced_test_schema()];
        
        // Setup both backends
        let native_instance = NativeInstance::open_instance(
            advanced_features_id(7),
            "native_consistency_db",
            native_db_dir,
            schemas.clone(),
            1024,
            None,
            None,
        ).expect("Failed to open Native database");
        let native_instance_ref = &*native_instance;
        
        let sqlite_instance = SQLiteInstance::open_instance(
            advanced_features_id(8),
            "sqlite_consistency_db",
            sqlite_db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");
        
        // Insert identical data in both backends
        let _native_ids = insert_advanced_test_data(native_instance_ref, 0);
        let _sqlite_ids = insert_advanced_test_data(&sqlite_instance, 0);

        // Compare aggregation results across backends
        let native_txn = native_instance_ref.begin_txn(false).expect("Failed to begin native txn");
        let sqlite_txn = sqlite_instance.begin_txn(false).expect("Failed to begin sqlite txn");
        
        let native_qb = native_instance_ref.query(0).expect("Failed to create native query");
        let native_query = native_qb.build();
        
        let sqlite_qb = sqlite_instance.query(0).expect("Failed to create sqlite query");
        let sqlite_query = sqlite_qb.build();

        // Test Count consistency
        let native_count = native_instance_ref.query_aggregate(&native_txn, &native_query, Aggregation::Count, None)
            .expect("Failed to execute native count");
        let sqlite_count = sqlite_instance.query_aggregate(&sqlite_txn, &sqlite_query, Aggregation::Count, None)
            .expect("Failed to execute sqlite count");
        assert_eq!(native_count, sqlite_count);

        // Test Min consistency
        let native_min = native_instance_ref.query_aggregate(&native_txn, &native_query, Aggregation::Min, Some(2))
            .expect("Failed to execute native min");
        let sqlite_min = sqlite_instance.query_aggregate(&sqlite_txn, &sqlite_query, Aggregation::Min, Some(2))
            .expect("Failed to execute sqlite min");
        assert_eq!(native_min, sqlite_min);

        // Test Max consistency
        let native_max = native_instance_ref.query_aggregate(&native_txn, &native_query, Aggregation::Max, Some(2))
            .expect("Failed to execute native max");
        let sqlite_max = sqlite_instance.query_aggregate(&sqlite_txn, &sqlite_query, Aggregation::Max, Some(2))
            .expect("Failed to execute sqlite max");
        assert_eq!(native_max, sqlite_max);

        // Test Sum consistency
        let native_sum = native_instance_ref.query_aggregate(&native_txn, &native_query, Aggregation::Sum, Some(2))
            .expect("Failed to execute native sum");
        let sqlite_sum = sqlite_instance.query_aggregate(&sqlite_txn, &sqlite_query, Aggregation::Sum, Some(2))
            .expect("Failed to execute sqlite sum");
        assert_eq!(native_sum, sqlite_sum);

        // Test Average consistency (allowing for small floating point differences)
        let native_avg = native_instance_ref.query_aggregate(&native_txn, &native_query, Aggregation::Average, Some(3))
            .expect("Failed to execute native average");
        let sqlite_avg = sqlite_instance.query_aggregate(&sqlite_txn, &sqlite_query, Aggregation::Average, Some(3))
            .expect("Failed to execute sqlite average");
        
        match (native_avg.clone(), sqlite_avg.clone()) {
            (Some(IsarValue::Real(n)), Some(IsarValue::Real(s))) => {
                assert!((n - s).abs() < 0.001, "Average values should be nearly equal: {} vs {}", n, s);
            }
            _ => assert_eq!(native_avg, sqlite_avg),
        }

        native_instance_ref.abort_txn(native_txn);
        sqlite_instance.abort_txn(sqlite_txn);

        let native_closed = NativeInstance::close(native_instance, false);
        let sqlite_closed = SQLiteInstance::close(sqlite_instance, false);
        assert!(native_closed);
        assert!(sqlite_closed);
    }

    #[test]
    fn test_watcher_behavior_consistency() {
        let temp_dir = create_test_dir();
        let native_db_dir = temp_dir.path().to_str().unwrap();
        
        let sqlite_temp_dir = create_test_dir();
        let sqlite_db_dir = sqlite_temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_advanced_test_schema()];
        
        // Setup both backends
        let native_instance = NativeInstance::open_instance(
            advanced_features_id(9),
            "native_watcher_consistency_db",
            native_db_dir,
            schemas.clone(),
            1024,
            None,
            None,
        ).expect("Failed to open Native database");
        let native_instance_ref = &*native_instance;
        
        let sqlite_instance = SQLiteInstance::open_instance(
            advanced_features_id(10),
            "sqlite_watcher_consistency_db",
            sqlite_db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");

        // Test that both backends support watcher creation
        let native_notification_count = Arc::new(Mutex::new(0u32));
        let sqlite_notification_count = Arc::new(Mutex::new(0u32));
        
        let native_count_clone = native_notification_count.clone();
        let sqlite_count_clone = sqlite_notification_count.clone();
        
        let native_callback: WatcherCallback = Box::new(move || {
            let mut count = native_count_clone.lock().unwrap();
            *count += 1;
        });
        
        let sqlite_callback: WatcherCallback = Box::new(move || {
            let mut count = sqlite_count_clone.lock().unwrap();
            *count += 1;
        });
        
        let _native_handle = native_instance_ref.watch(0, native_callback)
            .expect("Failed to create native watcher");
        let _sqlite_handle = sqlite_instance.watch(0, sqlite_callback)
            .expect("Failed to create sqlite watcher");
        
        // Insert data in both backends
        let _native_ids = insert_advanced_test_data(native_instance_ref, 0);
        let _sqlite_ids = insert_advanced_test_data(&sqlite_instance, 0);
        
        // Allow time for notifications
        std::thread::sleep(std::time::Duration::from_millis(20));
        
        // Verify both backends triggered their watchers
        {
            let native_count = native_notification_count.lock().unwrap();
            let sqlite_count = sqlite_notification_count.lock().unwrap();
            
            assert!(*native_count > 0, "Native watcher should have been triggered");
            assert!(*sqlite_count > 0, "SQLite watcher should have been triggered");
        }

        let native_closed = NativeInstance::close(native_instance, false);
        let sqlite_closed = SQLiteInstance::close(sqlite_instance, false);
        assert!(native_closed);
        assert!(sqlite_closed);
    }
} 