---
title: Dart
---

# Dart

If you want to use Isar database in unit tests or Dart code, call

````dart

await Isar.initializeIsarCore(
    download: true,
    libraries: const {
        Abi.windowsX64: '/some/directory/',
        }
);

``` before using Isar in your tests.

Isar NoSQL database will automatically download the correct binary for your platform. You can also pass a `libraries` map to adjust the download location for each platform.

## Unit Tests


Make sure to use `flutter test -j 1` to avoid tests running in parallel. This would break the automatic download.
````
