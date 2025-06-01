use tempfile::TempDir;
use isar_core::core::schema::*;
use isar_core::core::data_type::DataType;

/// Helper functions to get unique instance ID ranges for different test files
/// This prevents conflicts between test files while keeping IDs predictable

/// Get instance IDs for native backend tests (1000-1099)
pub fn native_backend_id(offset: u32) -> u32 {
    1000 + offset
}

/// Get instance IDs for SQLite backend tests (1100-1199)  
pub fn sqlite_backend_id(offset: u32) -> u32 {
    1100 + offset
}

/// Get instance IDs for CRUD tests (1200-1299)
pub fn crud_tests_id(offset: u32) -> u32 {
    1200 + offset
}

/// Get instance IDs for query tests (1300-1399)
pub fn query_tests_id(offset: u32) -> u32 {
    1300 + offset
}

/// Get instance IDs for cross-platform tests (1400-1499)
pub fn cross_platform_id(offset: u32) -> u32 {
    1400 + offset
}

/// Get instance IDs for error handling tests (1500-1599)
pub fn error_handling_id(offset: u32) -> u32 {
    1500 + offset
}

/// Test helper to create a temporary directory for database files
pub fn create_test_dir() -> TempDir {
    tempfile::tempdir().expect("Failed to create temp directory")
}

/// Create a test schema for User collection
pub fn create_user_schema() -> IsarSchema {
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
pub fn create_post_schema() -> IsarSchema {
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
pub fn create_comprehensive_schema() -> IsarSchema {
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

/// Create a test schema with varied data types for comprehensive query testing
pub fn create_query_test_schema() -> IsarSchema {
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