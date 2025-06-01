# End-to-End Testing Guide for isar_core

This guide explains how to write, run, and maintain comprehensive end-to-end (e2e) tests for the isar_core database engine.

## 🎯 **What Are E2E Tests?**

End-to-end tests for isar_core verify the complete functionality of the database engine across different scenarios:

- **Full Database Lifecycle**: Create, open, close, and migrate databases
- **CRUD Operations**: Complete Create, Read, Update, Delete workflows
- **Transaction Management**: ACID compliance and concurrency control
- **Backend Compatibility**: Native (MDBX) and SQLite backend consistency
- **Performance Characteristics**: Bulk operations and query optimization
- **Error Handling**: Graceful failure and recovery mechanisms
- **Cross-Platform Compatibility**: Consistent behavior across different OS

## 📁 **Test Structure**

```
packages/isar_core/
├── tests/
│   └── integration_tests.rs        # Main e2e test file
├── scripts/
│   └── run_e2e_tests.sh           # Comprehensive test runner
└── E2E_TESTING.md                 # This guide
```

## 🏗️ **Test Categories**

### 1. **Native Backend Tests** (`native_backend_tests`)

Tests the complete MDBX-based native backend functionality:

```rust
#[test]
fn test_native_crud_operations() {
    // Tests complete CRUD workflow on native backend
    // - Database creation and opening
    // - Transaction management
    // - Insert, read, update, delete operations
    // - Query execution with filters
    // - Proper resource cleanup
}

#[test]
fn test_schema_migration() {
    // Tests database schema evolution
    // - Open with initial schema
    // - Insert data
    // - Reopen with updated schema
    // - Verify data integrity
}

#[test]
fn test_concurrent_transactions() {
    // Tests concurrent access patterns
    // - Multiple read transactions
    // - Write transaction exclusivity
    // - Transaction isolation
}

#[test]
fn test_large_dataset_operations() {
    // Tests performance with large datasets
    // - Bulk insert operations
    // - Query performance on large tables
    // - Memory management
}
```

### 2. **SQLite Backend Tests** (`sqlite_backend_tests`)

Tests the SQLite-based backend functionality:

```rust
#[test]
fn test_sqlite_crud_operations() {
    // Equivalent CRUD tests for SQLite backend
}

#[test]
fn test_sqlite_json_operations() {
    // Tests JSON field handling in SQLite
    // - JSON storage and retrieval
    // - JSON path queries
    // - Complex nested JSON operations
}
```

### 3. **Cross-Platform Tests** (`cross_platform_tests`)

Ensures consistent behavior across backends:

```rust
#[test]
fn test_backend_compatibility() {
    // Tests data consistency between backends
    // - Same operations on both backends
    // - Verify identical results
    // - Schema compatibility
}
```

### 4. **Error Handling Tests** (`error_handling_tests`)

Verifies robust error handling:

```rust
#[test]
fn test_error_scenarios() {
    // Tests constraint violations
    // - Unique constraint enforcement
    // - Transaction rollback
    // - Error recovery
}

#[test]
fn test_corruption_recovery() {
    // Tests database corruption scenarios
    // - Corruption detection
    // - Recovery mechanisms
    // - Data integrity verification
}
```

### 5. **Performance Tests** (`performance_tests`)

Benchmarks critical operations:

```rust
#[test]
fn benchmark_basic_operations() {
    // Benchmarks core operations
    // - Bulk insert performance
    // - Query execution time
    // - Performance regression detection
}
```

## 🚀 **Running E2E Tests**

### **Quick Start**

```bash
# Navigate to isar_core directory
cd packages/isar_core

# Run all e2e tests
./scripts/run_e2e_tests.sh
```

### **Manual Test Execution**

#### **1. Basic Integration Tests**

```bash
cargo test --test integration_tests
```

#### **2. Backend-Specific Tests**

```bash
# Test native backend only
cargo test --features native --test integration_tests native_backend_tests

# Test SQLite backend only
cargo test --features sqlite --test integration_tests sqlite_backend_tests
```

#### **3. Specific Test Categories**

```bash
# Cross-platform compatibility
cargo test --test integration_tests cross_platform_tests

# Error handling
cargo test --test integration_tests error_handling_tests

# Performance benchmarks
cargo test --test integration_tests performance_tests -- --nocapture
```

#### **4. Release Mode Testing**

```bash
cargo test --release --test integration_tests
```

### **Advanced Testing**

#### **Memory Leak Detection**

```bash
# Install valgrind (Linux/macOS)
sudo apt-get install valgrind  # Ubuntu
brew install valgrind          # macOS

# Run with memory leak detection
cargo build --test integration_tests
valgrind --leak-check=full ./target/debug/deps/integration_tests-*
```

#### **Test Coverage Analysis**

```bash
# Install cargo-tarpaulin
cargo install cargo-tarpaulin

# Generate coverage report
cargo tarpaulin --out Html --output-dir target/coverage --test integration_tests
open target/coverage/tarpaulin-report.html
```

#### **Fuzz Testing**

```bash
# Install cargo-fuzz
cargo install cargo-fuzz

# Initialize fuzz testing
cargo fuzz init

# Run fuzz tests
cargo fuzz run fuzz_target_1
```

## ✏️ **Writing New E2E Tests**

### **Test Template**

```rust
#[test]
fn test_your_feature() {
    // 1. Setup test environment
    let temp_dir = create_test_dir();
    let db_path = temp_dir.path().join("test_feature.isar");

    // 2. Create schemas
    let schemas = vec![create_user_schema()];

    // 3. Open database instance
    let instance = IsarInstance::open_native(
        "test_db",
        db_path.to_str().unwrap(),
        &schemas,
        None,
    ).expect("Failed to open database");

    // 4. Execute test operations
    {
        let txn = instance.begin_txn(true).expect("Failed to begin transaction");

        // Your test logic here
        let data = vec![
            ("field".to_string(), IsarValue::String("value".to_string())),
        ];
        let id = instance.insert(&txn, "Collection", data).expect("Insert failed");

        // Verify results
        let result = instance.get(&txn, "Collection", id).expect("Get failed");
        assert!(result.is_some());

        txn.commit().expect("Commit failed");
    }

    // 5. Cleanup
    instance.close().expect("Failed to close database");
}
```

### **Best Practices**

#### **1. Test Isolation**

- Each test creates its own temporary database
- Use `create_test_dir()` for test-specific directories
- Clean up resources in all code paths

#### **2. Error Testing**

```rust
// Test expected failures
let result = instance.insert(&txn, "Collection", invalid_data);
assert!(result.is_err(), "Expected operation to fail");

// Test specific error types
match result {
    Err(IsarError::ConstraintViolation(_)) => {
        // Expected error type
    },
    _ => panic!("Unexpected error type"),
}
```

#### **3. Performance Assertions**

```rust
let start = Instant::now();
// ... test operations ...
let duration = start.elapsed();

assert!(duration.as_millis() < 1000, "Operation too slow: {:?}", duration);
```

#### **4. Cross-Backend Testing**

```rust
// Test same logic on both backends
fn test_feature_on_backend(backend_type: BackendType) {
    let instance = match backend_type {
        BackendType::Native => IsarInstance::open_native(/* ... */),
        BackendType::Sqlite => IsarInstance::open_sqlite(/* ... */),
    };

    // Common test logic
}

#[test]
fn test_feature_native() {
    test_feature_on_backend(BackendType::Native);
}

#[test]
fn test_feature_sqlite() {
    test_feature_on_backend(BackendType::Sqlite);
}
```

## 📊 **Test Coverage Goals**

Target coverage areas for e2e tests:

- **Core Operations**: 100% (CRUD, transactions, queries)
- **Schema Management**: 95% (migrations, validation)
- **Error Handling**: 90% (constraint violations, recovery)
- **Backend Compatibility**: 100% (feature parity)
- **Performance**: 80% (critical path benchmarks)

## 🔧 **CI/CD Integration**

### **GitHub Actions Integration** ✅

Our comprehensive e2e tests are fully integrated into the existing CI workflow in `.github/workflows/test.yaml`:

#### **1. Enhanced Core Test Job** (`test_core`)

- **Multi-platform testing**: Ubuntu, macOS, and Windows
- **Comprehensive test coverage**: Unit tests + all e2e test categories
- **Backend-specific testing**: Native (MDBX) and SQLite backends
- **Performance monitoring**: Built-in performance benchmarks
- **Release mode validation**: Optimized build testing

#### **2. Dedicated E2E Test Job** (`test_core_e2e`)

- **Complete test suite**: Uses our `run_e2e_tests.sh` script
- **Advanced features**: Memory leak detection, coverage reporting, fuzz testing
- **Cross-platform validation**: Ensures consistency across operating systems
- **Artifact collection**: Saves test results and coverage reports
- **Optional tooling**: Gracefully handles missing tools (valgrind, cargo-fuzz)

#### **3. Enhanced Coverage Reporting**

- **Integration test coverage**: Dedicated coverage from e2e tests
- **Multi-source coverage**: Combines unit tests and integration tests
- **Codecov integration**: Automatic upload with proper flags (`core`, `e2e`)

### **Current CI Test Matrix**

```yaml
# From .github/workflows/test.yaml
test_core:
  strategy:
    matrix:
      os: [ubuntu-latest, macos-latest, windows-latest]
  steps:
    - Run Rust Unit tests
    - Run Integration Tests
    - Run Native Backend Tests
    - Run SQLite Backend Tests
    - Run Cross-Platform Tests
    - Run Error Handling Tests
    - Run Performance Tests
    - Run Release Mode Tests

test_core_e2e:
  strategy:
    matrix:
      os: [ubuntu-latest, macos-latest, windows-latest]
  steps:
    - Run Comprehensive E2E Tests (via script)
    - Generate Coverage Reports
    - Upload Test Artifacts
```

### **Test Results Dashboard**

Every CI run now provides:

- **✅ 257 Unit Tests**: Core functionality validation
- **✅ 10 Integration Tests**: End-to-end workflow validation
- **✅ Cross-Platform**: Native + SQLite backend compatibility
- **✅ Performance Monitoring**: Automated benchmark tracking
- **✅ 15.64% E2E Coverage**: Additional coverage from integration tests
- **✅ Multi-OS Support**: Ubuntu, macOS, Windows validation

### **Coverage Reporting**

- **Primary Coverage**: Unit tests via `cargo tarpaulin`
- **E2E Coverage**: Integration tests with dedicated flag
- **Codecov Integration**: Automatic uploads with proper categorization
- **HTML Reports**: Detailed coverage analysis available as artifacts

## 🐛 **Debugging E2E Test Failures**

### **Common Issues**

#### **1. Temporary Directory Cleanup**

```rust
// Ensure proper cleanup even on test failure
let _temp_dir = create_test_dir(); // Automatic cleanup on drop
```

#### **2. Resource Leaks**

```rust
// Always close database instances
let instance = /* ... */;
// ... test operations ...
instance.close().expect("Failed to close database");
```

#### **3. Timing Issues**

```rust
// Use proper synchronization for concurrent tests
let barrier = Arc::new(Barrier::new(2));
// ... coordinate concurrent operations ...
```

### **Debug Output**

```bash
# Run with debug output
RUST_LOG=debug cargo test --test integration_tests -- --nocapture

# Run specific test with trace output
RUST_LOG=trace cargo test --test integration_tests specific_test_name -- --nocapture
```

## 📈 **Performance Monitoring**

### **Benchmark Thresholds**

```rust
// Set performance expectations
const MAX_INSERT_TIME_MS: u128 = 10;
const MAX_QUERY_TIME_MS: u128 = 100;
const MAX_BULK_INSERT_TIME_MS: u128 = 5000;

assert!(duration.as_millis() < MAX_INSERT_TIME_MS,
    "Insert performance degraded: {}ms > {}ms",
    duration.as_millis(), MAX_INSERT_TIME_MS);
```

### **Memory Usage Monitoring**

```rust
// Monitor memory usage in tests
let memory_before = get_memory_usage();
// ... test operations ...
let memory_after = get_memory_usage();
let memory_delta = memory_after - memory_before;

assert!(memory_delta < MAX_MEMORY_INCREASE,
    "Memory usage increased too much: {} bytes", memory_delta);
```

## 🔮 **Future Enhancements**

Planned improvements for e2e testing:

1. **Property-Based Testing**: Use QuickCheck for generating test cases
2. **Chaos Engineering**: Random failure injection during tests
3. **Load Testing**: Concurrent user simulation
4. **Database Fuzzing**: Random schema and data generation
5. **Cross-Platform Binary Testing**: Test compiled binaries across platforms
6. **Integration with Real Apps**: Test with actual Flutter/Dart applications

## 📚 **Additional Resources**

- [Rust Testing Guide](https://doc.rust-lang.org/rust-by-example/testing.html)
- [Cargo Test Documentation](https://doc.rust-lang.org/cargo/commands/cargo-test.html)
- [Integration Testing Best Practices](https://blog.rust-lang.org/2018/11/27/Cargo-test.html)
- [Database Testing Strategies](https://martinfowler.com/articles/practical-test-pyramid.html)
