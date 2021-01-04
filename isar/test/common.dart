import 'dart:ffi';
import 'dart:io';
import 'package:isar/isar_native.dart';
import 'package:isar/src/native/bindings.dart';
import 'package:path/path.dart' as path;

import 'dart:math';

final random = Random();
final tempPath = path.join(Directory.current.path, '.dart_tool', 'test', 'tmp');

Future<Directory> getTempDir() async {
  var name = random.nextInt(pow(2, 32) as int);
  var dir = Directory(path.join(tempPath, '${name}_tmp'));
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
  await dir.create(recursive: true);
  return dir;
}

var _setUp = false;
void setupIsar() {
  if (!_setUp) {
    IC = IsarCoreBindings(DynamicLibrary.open(
        '/Users/simon/Documents/GitHub/isar-core/dart-ffi/target/x86_64-apple-darwin/release/libisar_core_dart_ffi.dylib'));
    _setUp = true;
  }
}
