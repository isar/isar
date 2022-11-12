import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;

Future<void> init() async {
  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    final rootDir = path.dirname(path.dirname(Directory.current.path));
    final binaryName = Platform.isWindows
        ? 'isar.dll'
        : Platform.isMacOS
            ? 'libisar.dylib'
            : 'libisar.so';
    try {
      await Isar.initializeIsarCore();
    } catch (e) {
      await Isar.initializeIsarCore(
        libraries: {
          Abi.macosArm64: path.join(
            rootDir,
            'target',
            'aarch64-apple-darwin',
            'release',
            binaryName,
          ),
          Abi.macosX64: path.join(
            rootDir,
            'target',
            'x86_64-apple-darwin',
            'release',
            binaryName,
          ),
          Abi.linuxArm64: path.join(
            rootDir,
            'target',
            'aarch64-unknown-linux-gnu',
            'release',
            binaryName,
          ),
          Abi.linuxX64: path.join(
            rootDir,
            'target',
            'x86_64-unknown-linux-gnu',
            'release',
            binaryName,
          ),
          Abi.windowsX64: path.join(
            rootDir,
            'target',
            'x86_64-pc-windows-msvc',
            'release',
            binaryName,
          ),
        },
      );
    }
  }
}
