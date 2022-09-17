import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:isar_test/src/rust_target.dart';
import 'package:path/path.dart' as path;

String getBinaryPath() {
  final rootDir = path.dirname(path.dirname(Directory.current.path));
  final target = getRustTarget();
  final binaryName = Platform.isWindows
      ? 'isar.dll'
      : Platform.isMacOS
          ? 'libisar.dylib'
          : 'libisar.so';
  return path.join(rootDir, 'target', target, 'debug', binaryName);
}

Future<void> init() async {
  final isFlutterTest = Platform.environment.containsKey('FLUTTER_TEST');
  if (isFlutterTest) {
    return;
  }
  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    await Isar.initializeIsarCore(
      libraries: {Abi.current(): getBinaryPath()},
    );
  }
}
