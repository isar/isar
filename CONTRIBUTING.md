# How to contribute to the Isar project

Hey there! It's very cool that you want to contribute to the project. We need more people like you 🥰

First of all, join the Isar Telegram channel: [t.me/isardb](https://t.me/isardb)

Right now, the most helpful contributions are tests! The goal is to have at least 1k unit and integration tests by the end of 2022. Also, don't hesitate to refactor tests.

# Isar Dart 🎯

Isar Dart is the main Isar repository (the one you are looking at right now).

## Project Strucutre 🏛

- `isar` package in _packages/isar_ is the only library that has runtime Dart code. It contains all the public API interfaces as well as platform specific implementations (_src/native_ and _src/web_) to communicate with the respective backend.
- `isar_flutter_libs` does not contain any Dart code but a native project for every platform to ensure that compiled Isar Code binaries are shipped correctly.
- `isar_generator` generates the schema specific code like the query extension methods and serializers/parsers for native and web platforms.
- `isar_inspector` is a standalone package that contains the Isar inspector and communicates with the _packages/isar_ package via the Dart Observatory protocol.
- `isar_test` contains all the tests for Isar. The reason why we have a separate package is that tests can be run in two modes: As unit tests on your development machine and as integration tests on any supported device.

## Running tests 💨

You can run the tests as unit or integration tests. Either way, the first step is to run the generator to create all necessary files. Run the following in _packages/isar_test_:

```shell
flutter pub run build_runner build
```

### Unit tests 🧪

To run the Isar tests on your development machine you need to download the Isar Core binaries to the test directory. Run in _packages/isar_test_:

```shell
sh tool/download_binaries.sh
```

Now you can run the unit tests like you would normally do:

```shell
flutter test
```

or for web:

```shell
dart test -p chrome
```

To see what is going wrong with a specific web test, you can run it inside a browser window:

```shell
flutter run test/some_test.dart
```

### Integration tests 📲

To run the tests on an actual device, we use the Flutter test driver. First you need to generate the test file:

```shell
dart tool/generate_all_tests.dart
```

Now the fun part: Running the tests on a device.

```shell
flutter drive --driver=test_driver/isar_test.dart --target=test_driver/isar.dart
```

## Contributing ⛹️‍♂️

There are two areas where contributions are most helpful: Tests and Isar Inspector improvements.

### Tests 🧪

The major limit for new features right now is not enough tests to make sure that the new features work as expected.  
The goal is complete test coverage. Every edge case of every feature should be tested.

As you know, Isar has web and native backends and writing tests in Dart allows testing both at once.

Currently, many features are not tested well enough. When you write tests, make sure to cover:

- all data types
- all query modifiers
- sync and async methods

### Isar Inspector 🔎

Currently, the Inspector is lacking support for lists and links. Also we need to update the CI to build for Windows and Linux.

Finally, it would be nice to have integration tests that check whether the connection between the Inspector and Isar still works correctly.

---

# Isar Core 👨‍🔧

[Isar Core](https://github.com/isar/isar-core) is the backend on Android, iOS, macOS, and Windows. It's written in Rust and gets compiled to binaries for every platform and processor architecture before shipping it to pub.dev.

Isar Core depends on the [mdbx](https://github.com/isar/libmdbx) key-value database to handle storing the data.

## Setup ⚙️

To get started you first need to install Rust on your machine: Use [rustup](https://rustup.rs) and follow the instructions. It's easy 😉

Next, you need an IDE to write your code in. I recommend [CLion](https://www.jetbrains.com/clion/) with the [Rust plugin](https://www.jetbrains.com/rust/), but you can also use [VSCode](https://code.visualstudio.com/) with the [rust-analyzer extension](https://rust-analyzer.github.io).

If you choose CLion, choose `External linter: Clippy` and `Run linter on the fly: true` in _Settings > Languages and Frameworks > Rust > External Linters_.

## Project Structure 🏛

The entire repository is a cargo project and the _src_ folder contains the actual code.

- `dart-ffi` contains the native bindings for the Dart language and takes care of handling the thread pool.
- `mdbx-sys` contains the build script and bindings for libmdbx.
- the integration tests can be found in `tests`.

## Contributing ⛹️‍♂️

Currently, the most helpful contributions are unit and integration tests.

Unit tests should be used for code that has very limited dependencies and complexity (for example the serialization in _src/object/object_builder.rs_).

All other tests should be created in the integration tests folder.

Examples for missing tests: migration tests, query tests, index tests etc. Please make sure to handle all edge cases if you work on a specific feature.

As a rule of thumb, all platform independent tests should be located in Isar Dart. Rust specific tests like migration, storage validation etc. should happen in Isar Core.

Once you are done, open a PR and briefly explain your contribution 🙌

## Testing in combination with Isar Dart 🪢

To test your code together with the Dart bindings and Isar Dart, you need to build dart-ffi for your platform.

Then point the `Isar.initializeLibraries` call in Isar Dart `packages/isar_test/test/common.dart` to the local build of dart-ffi.

If you change the `dart-ffi` bindings, don't forget to run `ffigen` to update the bindings file in Dart.

---

# Isar Web 🕸

[Isar Web](https://github.com/isar/isar-web) is the backend for browsers. It's written in TypeScript and gets compiled to JavaScript before shipping it to pub.dev.

Currently, there are no tests for Isar Web. Like for Isar Core it would be very beneficial to have some integration tests that verify that the data is stored correctly. Unfortunately this cannot be verified with Dart tests.

If you are interested in contributing to Isar Web, tests are very welcome.
