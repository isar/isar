import 'dart:io';

import 'package:isar/src/isar_native.dart';
import 'package:isar_test/isar_test_context.dart';
import 'package:path/path.dart' as path;
import 'package:isar_test/all_test.dart' as tests;

void main() {
  final context = TestContext(false);
  tests.run(context);

  final encryptionContext = TestContext(true);
  tests.run(encryptionContext);
}

class TestContext extends IsarTestContext {
  TestContext(bool encryption) : super(encryption);

  var _setUp = false;
  void setupIsar() {
    if (!_setUp) {
      final dartToolDir = path.join(Directory.current.path, '.dart_tool');
      initializeIsarCore(dylibs: {
        'windows': path.join(dartToolDir, 'isar_windows_x64.dll'),
        'macos': path.join(dartToolDir, 'libisar_macos_x64.dylib'),
        'linux': path.join(dartToolDir, 'libisar_linux_x64.so'),
      });
      _setUp = true;
    }
  }

  @override
  Future<String> getTempPath() {
    setupIsar();
    final dir = path.join(Directory.current.path, '.dart_tool', 'test', 'tmp');
    return Future.value(dir);
  }
}
