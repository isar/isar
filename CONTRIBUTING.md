# Contributing to Isar Database

Thank you for your interest in contributing to Isar! 🎉 We appreciate your help in making Isar the best NoSQL database for Flutter.

## 📚 Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Contributing Guidelines](#contributing-guidelines)
- [Code Style](#code-style)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)
- [Community](#community)

## 📋 Project Status

**Current State**: Isar 3.x is stable and production-ready for mobile and desktop platforms.

**What's Next**: We're actively working on Isar 4.0, which will bring exciting new features including full web support, enhanced performance, and additional capabilities.

**Timeline**: Our lead maintainer Simon is dedicating significant effort to this major release, though development timelines depend on the complexity of features and available bandwidth. We appreciate your patience as we work to deliver a high-quality update.

**How You Can Help**: Contributions, testing, and community feedback are invaluable during this development phase. Even if reviews take some time, your input helps shape the future of Isar.

## 🚀 Getting Started

Before you begin:

1. **Star the repository** ⭐ - Show your support!
2. **Read the documentation** - Familiarize yourself with [Isar's features and API](https://isar.dev)
3. **Join our community** - Connect with us on [Telegram](https://t.me/isardb)
4. **Check existing issues** - See what's already being worked on

## 🛠 Development Setup

### Prerequisites

- **Flutter SDK** (latest stable version)
- **Rust** (latest stable version)
- **Git**
- **Docker** (for cross-platform builds)

### Setting up the Development Environment

1. **Fork and clone the repository:**

   ```bash
   git clone https://github.com/YOUR_USERNAME/isar.git
   cd isar
   ```

2. **Install dependencies:**

   ```bash
   # Install Dart/Flutter dependencies for all packages
   flutter pub get
   dart pub get --directory=packages/isar
   flutter pub get --directory=packages/isar_flutter_libs
   flutter pub get --directory=packages/isar_inspector
   flutter pub get --directory=packages/isar_test
   ```

3. **Build Isar Core (Rust components):**

   ```bash
   # For desktop development
   ./tool/build.sh

   # For web development
   ./tool/build_wasm.sh
   ```

4. **Prepare test environment:**
   ```bash
   ./tool/prepare_tests.sh
   ```

### Verify Your Setup

Run the tests to make sure everything works:

```bash
# Run Rust tests
cargo test

# Run Dart tests (from packages/isar_test)
cd packages/isar_test
flutter test -j 1

# Run web tests
dart test -p chrome
```

## 📁 Project Structure

```
isar/
├── .github/                 # GitHub workflows and templates
├── docs/                    # Documentation source
├── examples/                # Example applications
├── packages/
│   ├── isar/               # Main Dart package & code generator
│   ├── isar_core/          # Core Rust implementation
│   ├── isar_core_ffi/      # FFI bindings
│   ├── isar_flutter_libs/  # Flutter platform integration
│   ├── isar_inspector/     # Database inspector tool
│   ├── isar_test/          # Test suite
│   └── mdbx_sys/           # MDBX database bindings
└── tool/                   # Build scripts and utilities
```

### Key Components

- **Dart Layer** (`packages/isar/`): High-level API, code generation, and Flutter integration
- **Rust Core** (`packages/isar_core/`): Database engine, query processing, and performance-critical operations
- **FFI Bridge** (`packages/isar_core_ffi/`): Communication between Dart and Rust
- **Inspector** (`packages/isar_inspector/`): Real-time database inspection tool

## 🤝 Contributing Guidelines

### Types of Contributions

We welcome various types of contributions:

- 🐛 **Bug fixes** - Fix issues and improve stability
- ✨ **New features** - Add functionality that benefits the community
- 📝 **Documentation** - Improve docs, examples, and tutorials
- 🧪 **Tests** - Increase test coverage and reliability
- 🎨 **UI/UX** - Enhance the Inspector and developer tools
- ⚡ **Performance** - Optimize speed and memory usage

### Before You Start

1. **Check existing issues** - Someone might already be working on it
2. **Create an issue** - Discuss significant changes before implementing
3. **Follow our roadmap** - Align with project goals and priorities

## 🎨 Code Style

### Dart Code Style

- Follow [Dart's style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` to format your code
- Run `flutter analyze` to check for issues
- Maximum line length: 80 characters

### Rust Code Style

- Follow [Rust's style guide](https://doc.rust-lang.org/1.0.0/style/)
- Use `cargo fmt` to format your code
- Run `cargo clippy` for linting
- Use descriptive variable names and add comments for complex logic

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

Types: feat, fix, docs, style, refactor, test, chore
Scopes: core, dart, inspector, docs, examples

Examples:
feat(core): add compound index support
fix(dart): resolve memory leak in query watchers
docs: update installation guide
test(core): add integration tests for transactions
```

## 🧪 Testing

### Test Requirements

- **All tests must pass** before submitting a PR
- **Add tests** for new features and bug fixes
- **Maintain coverage** - aim for >80% code coverage

### Running Tests

```bash
# Run format check
dart format -o none . --set-exit-if-changed

# Run lint check
flutter analyze

# Run Rust unit tests
cargo test

# Build Isar Core and run Dart unit tests
./tool/build.sh
./tool/prepare_tests.sh
cd packages/isar_test
flutter test -j 1

# Run web tests
cd ../..
./tool/build_wasm.sh
cd packages/isar_test
dart test -p chrome

# Run generator tests
cd ../isar
dart pub get
dart test
```

### Test Organization

- **Unit tests**: Test individual functions and classes
- **Integration tests**: Test complete workflows and platform integration
- **Performance tests**: Benchmark critical operations
- **Regression tests**: Prevent previously fixed bugs from returning

## 📤 Pull Request Process

### Before Submitting

1. **Create a feature branch:**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**

   - Write clean, well-documented code
   - Add tests for new functionality
   - Update documentation if needed

3. **Test thoroughly:**

   ```bash
   # Run format check
   dart format -o none . --set-exit-if-changed

   # Run lint check
   flutter analyze

   # Run Rust unit tests
   cargo test

   # Build Isar Core and run Dart unit tests
   ./tool/build.sh
   ./tool/prepare_tests.sh
   cd packages/isar_test
   flutter test -j 1

   # Run web tests
   cd ../..
   ./tool/build_wasm.sh
   cd packages/isar_test
   dart test -p chrome

   # Run generator tests
   cd ../isar
   dart pub get
   dart test
   ```

4. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat(scope): your change description"
   ```

### Submitting the PR

1. **Push to your fork:**

   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create the pull request:**

   - Use our [PR template](.github/pull_request_template.md)
   - Provide a clear description of changes
   - Link related issues
   - Add screenshots for UI changes

3. **Respond to feedback:**
   - Address review comments promptly
   - Make requested changes in new commits
   - Update tests if needed

### PR Requirements

- ✅ All CI checks pass
- ✅ Code review approval from maintainers
- ✅ No merge conflicts
- ✅ Documentation updated (if applicable)
- ✅ Tests added/updated
- ✅ Breaking changes documented

## 🐛 Issue Guidelines

### Reporting Bugs

Use our [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:

- **Isar version** and Flutter version
- **Platform** (iOS, Android, Web, Desktop)
- **Minimal reproduction** code
- **Expected vs actual** behavior
- **Stack trace** or error messages

### Requesting Features

Use our [feature request template](.github/ISSUE_TEMPLATE/feature_request.md) and include:

- **Use case** and motivation
- **Detailed description** of the feature
- **Alternatives considered**
- **Additional context** or mockups

### Issue Labels

- `bug` - Something isn't working
- `enhancement` - New feature or improvement
- `documentation` - Documentation related
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `priority: high` - Critical issues
- `platform: *` - Platform-specific issues

## 🌟 Community

### Getting Help

- 💬 **Telegram**: [Join our chat](https://t.me/isardb)
- 🐛 **Issues**: [GitHub Issues](https://github.com/isar/isar/issues)
- 💡 **Discussions**: [GitHub Discussions](https://github.com/isar/isar/discussions)
- 📖 **Documentation**: [isar.dev](https://isar.dev)

### Recognition

Contributors are recognized in our:

- **README.md** contributors section
- **All Contributors** specification
- **Release notes** for significant contributions

## 🎉 Thank You!

Your contributions make Isar better for everyone. Whether it's code, documentation, bug reports, or feature suggestions - every contribution matters!

---

**Questions?** Feel free to reach out on [Telegram](https://t.me/isardb) or open a [discussion](https://github.com/isar/isar/discussions).

**Happy coding!** 🚀
