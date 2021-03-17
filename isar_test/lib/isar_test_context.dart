import 'dart:io';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'isar.g.dart' as gen;
import 'package:test/test.dart' as dartTest;

abstract class IsarTestContext {
  var _success = true;

  bool get success => _success;

  void test(String name, Future Function() callback) {
    dartTest.test(name, () async {
      try {
        await callback();
      } catch (e) {
        _success = false;
        rethrow;
      }
    });
  }

  Future<String> getTempPath();

  Future<Isar> openIsar() async {
    final tempPath = await getTempPath();
    print(tempPath);
    var name = Random().nextInt(pow(2, 32) as int);
    var dir = Directory(path.join(tempPath, '${name}_tmp'));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    return gen.openIsar(directory: dir.path);
  }
}
