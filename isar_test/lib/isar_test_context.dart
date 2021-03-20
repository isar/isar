import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'isar.g.dart' as gen;
import 'package:test/test.dart' as dartTest;

abstract class IsarTestContext {
  final bool encryption;
  var _success = true;

  IsarTestContext(this.encryption);

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
    var name = Random().nextInt(pow(2, 32) as int);
    var dir = Directory(path.join(tempPath, '${name}_tmp'));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    Uint8List? encryptionKey;
    if (encryption) {
      encryptionKey = Isar.generateSecureKey();
    }

    return gen.openIsar(
      name: dir.path,
      directory: dir.path,
      encryptionKey: encryptionKey,
    );
  }
}
