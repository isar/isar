import 'dart:convert';
import 'dart:io';
import 'package:isar/isar_native.dart';
import 'package:path/path.dart' as path;

import 'dart:math';

import 'package:test/test.dart';

import 'isar.g.dart';

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
    final dartToolDir = path.join(Directory.current.path, '.dart_tool');
    initializeIsarCore(dylibs: {
      'windows': path.join(dartToolDir, 'isar_windows_x64.dll'),
      'macos': path.join(dartToolDir, 'libisar_macos_x64.dylib'),
      'linux': path.join(dartToolDir, 'libisar_linux_x64.so'),
    });
    _setUp = true;
  }
}

Future qEqualSet<T>(Future<Iterable<T>> actual, Iterable<T> target) async {
  expect((await actual).toSet(), target.toSet());
}

Future qEqual<T>(Future<Iterable<T>> actual, List<T> target) async {
  expect((await actual).toList(), target);
}

extension IsarJson on IsarCollection {
  Future<List<Map<String, dynamic>>> jsonMap() {
    return exportJson((bytes) {
      return jsonDecode(Utf8Decoder().convert(bytes))
          .cast<Map<String, dynamic>>();
    }, includeLinks: true);
  }
}
