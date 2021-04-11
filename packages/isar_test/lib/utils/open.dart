import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar_test/isar.g.dart' as gen;
import 'package:isar_test/utils/common.dart';

Future<Isar> openTempIsar() async {
  registerBinaries();

  Uint8List? encryptionKey;
  if (testEncryption) {
    encryptionKey = Isar.generateSecureKey();
  }

  return gen.openIsar(
    name: getRandomName(),
    directory: testTempPath,
    encryptionKey: encryptionKey,
  );
}
