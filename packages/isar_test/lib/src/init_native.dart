import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:isar_test/src/common.dart';
import 'package:path/path.dart' as path;

var _setUp = false;
Future<void> prepareTest() async {
  if (!_setUp) {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      try {
        await Isar.initialize(getBinaryPath());
        if (testTempPath == null) {
          final dartToolDir = path.join(Directory.current.path, '.dart_tool');
          testTempPath = path.join(dartToolDir, 'test', 'tmp');
          Directory(testTempPath!).createSync(recursive: true);
        }
      } catch (_) {}
    }
    _setUp = true;
  }
}

String getBinaryPath() {
  final rootDir = path.dirname(path.dirname(Directory.current.path));
  final binaryName = Platform.isWindows
      ? 'isar.dll'
      : Platform.isMacOS
          ? 'libisar.dylib'
          : 'libisar.so';
  return switch (Abi.current()) {
    Abi.macosArm64 => path.join(
        rootDir,
        'target',
        'debug',
        binaryName,
      ),
    Abi.macosX64 => path.join(
        rootDir,
        'target',
        'x86_64-apple-darwin',
        'release',
        binaryName,
      ),
    Abi.linuxArm64 => path.join(
        rootDir,
        'target',
        'aarch64-unknown-linux-gnu',
        'release',
        binaryName,
      ),
    Abi.linuxX64 => path.join(
        rootDir,
        'target',
        'x86_64-unknown-linux-gnu',
        'release',
        binaryName,
      ),
    Abi.windowsX64 => path.join(
        rootDir,
        'target',
        'x86_64-pc-windows-msvc',
        'release',
        binaryName,
      ),
    _ => '',
  };
}
