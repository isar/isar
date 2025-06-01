//! Integration Tests for isar_core
//! 
//! This file serves as the main entry point for integration tests.
//! Individual test suites are organized in separate files by functionality.

// Import test modules - each module contains related tests
mod native_backend_tests;
mod sqlite_backend_tests;
mod crud_operations_tests;
mod query_tests;
mod cross_platform_tests;
mod error_handling_tests;

// Re-export common utilities for use by other test files
pub mod common;

/// Main integration test to verify all backends are accessible
#[cfg(test)]
mod main_integration_tests {
    use super::common::*;

    #[test]
    fn test_basic_functionality() {
        // Basic smoke test to ensure the test framework is working
        let temp_dir = create_test_dir();
        assert!(temp_dir.path().exists());
        
        // Test schema creation
        let user_schema = create_user_schema();
        assert_eq!(user_schema.name(), "User");
        
        let post_schema = create_post_schema();
        assert_eq!(post_schema.name(), "Post");
        
        let comprehensive_schema = create_comprehensive_schema();
        assert_eq!(comprehensive_schema.name(), "Comprehensive");
        
        let query_schema = create_query_test_schema();
        assert_eq!(query_schema.name(), "QueryTest");
    }

    #[test]
    fn test_feature_detection() {
        // Test that feature flags are working correctly
        #[cfg(feature = "native")]
        {
            println!("Native backend feature is enabled");
        }
        
        #[cfg(feature = "sqlite")]
        {
            println!("SQLite backend feature is enabled");
        }
        
        #[cfg(not(any(feature = "native", feature = "sqlite")))]
        {
            panic!("At least one backend feature must be enabled for testing");
        }
    }
} 