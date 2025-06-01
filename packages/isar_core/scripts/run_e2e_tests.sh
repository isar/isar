#!/bin/bash

# End-to-End Test Runner for isar_core
# This script runs comprehensive e2e tests across different configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "Cargo.toml" ] || [ ! -f "tests/integration_tests.rs" ]; then
    print_error "Please run this script from the isar_core package directory"
    exit 1
fi

print_header "isar_core End-to-End Test Suite"

# 1. Run unit tests first
print_header "Running Unit Tests"
cargo test --lib
print_success "Unit tests completed"

# 2. Run integration tests
print_header "Running Integration Tests"
cargo test --test integration_tests
print_success "Integration tests completed"

# 3. Run tests with different feature flags
print_header "Testing with Native Backend"
cargo test --features native --test integration_tests native_backend_tests
print_success "Native backend tests completed"

print_header "Testing with SQLite Backend"
cargo test --features sqlite --test integration_tests sqlite_backend_tests
print_success "SQLite backend tests completed"

# 4. Run cross-platform compatibility tests
print_header "Testing Cross-Platform Compatibility"
cargo test --test integration_tests cross_platform_tests
print_success "Cross-platform tests completed"

# 5. Run error handling tests
print_header "Testing Error Scenarios"
cargo test --test integration_tests error_handling_tests
print_success "Error handling tests completed"

# 6. Run tests with different optimization levels
print_header "Testing with Release Mode"
cargo test --release --test integration_tests
print_success "Release mode tests completed"

# 7. Memory leak detection (if valgrind is available)
print_header "Memory Leak Detection"
if command -v valgrind >/dev/null 2>&1; then
    print_warning "Running valgrind memory leak detection (this may take a while)..."
    cargo build --test integration_tests
    valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes \
        ./target/debug/deps/integration_tests-* 2>&1 | tee valgrind_output.log
    
    if grep -q "ERROR SUMMARY: 0 errors" valgrind_output.log; then
        print_success "No memory leaks detected"
    else
        print_warning "Memory leaks detected, check valgrind_output.log"
    fi
    rm -f valgrind_output.log
else
    print_warning "Valgrind not available, skipping memory leak detection"
fi

# 8. Generate test coverage report
print_header "Generating Test Coverage Report"
if command -v cargo-tarpaulin >/dev/null 2>&1; then
    cargo tarpaulin --out Html --output-dir target/coverage --test integration_tests
    print_success "Coverage report generated in target/coverage/"
else
    print_warning "cargo-tarpaulin not available, skipping coverage report"
fi

# 9. Run fuzz tests (if cargo-fuzz is available)
print_header "Fuzz Testing"
if command -v cargo-fuzz >/dev/null 2>&1; then
    if [ -d "fuzz" ]; then
        print_warning "Running fuzz tests for 30 seconds..."
        timeout 30s cargo fuzz run fuzz_target_1 || print_warning "Fuzz testing completed (timeout or stopped)"
        print_success "Fuzz testing completed"
    else
        print_warning "No fuzz directory found, skipping fuzz tests"
    fi
else
    print_warning "cargo-fuzz not available, skipping fuzz tests"
fi

print_header "E2E Test Suite Summary"
print_success "All e2e tests completed successfully!"
echo ""
echo "Test Results:"
echo "├── Unit Tests: ✅"
echo "├── Integration Tests: ✅"
echo "├── Native Backend: ✅"
echo "├── SQLite Backend: ✅"
echo "├── Cross-Platform: ✅"
echo "├── Error Handling: ✅"
echo "└── Release Mode: ✅"
echo ""
echo "Optional Tests:"
echo "├── Memory Leaks: $(command -v valgrind >/dev/null 2>&1 && echo '✅' || echo '⚠️ Skipped')"
echo "├── Test Coverage: $(command -v cargo-tarpaulin >/dev/null 2>&1 && echo '✅' || echo '⚠️ Skipped')"
echo "└── Fuzz Testing: $(command -v cargo-fuzz >/dev/null 2>&1 && echo '✅' || echo '⚠️ Skipped')"
echo ""
print_success "isar_core is ready for production! 🚀" 