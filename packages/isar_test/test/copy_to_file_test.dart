import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'copy_to_file_test.g.dart';

@collection
class Model {
  Id id = Isar.autoIncrement;

  List<int> buffer = List.filled(16000, 42);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listEquals(buffer, other.buffer);

  @override
  String toString() {
    return 'Model{id: $id}';
  }
}

void main() {
  group('Copy to file', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);

      await isar.tWriteTxn(
        () => isar.models.tPutAll(List.filled(100, Model())),
      );
    });

    isarTestVm('.copyToFile() should create a new file', () async {
      final copiedDbFile = File(path.join(isar.directory!, getRandomName()));
      expect(copiedDbFile.existsSync(), false);

      await isar.copyToFile(copiedDbFile.path);

      expect(copiedDbFile.existsSync(), true);
      expect(copiedDbFile.lengthSync(), greaterThan(0));
    });

    isarTestVm('.copyToFile() should keep the same content', () async {
      final copiedDbFilename = getRandomName();
      final copiedDbFile = File(
        path.join(
          isar.directory!,
          '$copiedDbFilename.isar',
        ),
      );

      await isar.copyToFile(copiedDbFile.path);

      final copiedIsar = await openTempIsar(
        [ModelSchema],
        directory: isar.directory,
        name: copiedDbFilename,
      );

      final originalObjs = await isar.models.where().tFindAll();
      await qEqual(
        copiedIsar.models.where(),
        originalObjs,
      );
    });

    isarTestVm('.copyToFile() should compact copied file', () async {
      await isar.tWriteTxn(() => isar.models.where().limit(50).tDeleteAll());

      final copiedDbFilename1 = getRandomName();
      final copiedDbFile1 = File(
        path.join(
          isar.directory!,
          '$copiedDbFilename1.isar',
        ),
      );

      await isar.copyToFile(copiedDbFile1.path);

      final isarCopy1 = await openTempIsar(
        [ModelSchema],
        directory: isar.directory,
        name: copiedDbFilename1,
      );

      expect(copiedDbFile1.lengthSync(), greaterThan(0));
      expect(
        copiedDbFile1.lengthSync(),
        lessThan(File(isar.path!).lengthSync()),
      );

      await isarCopy1.tWriteTxn(
        () => isarCopy1.models.where().limit(25).tDeleteAll(),
      );

      final copiedDbFilename2 = getRandomName();
      final copiedDbFile2 = File(
        path.join(
          isar.directory!,
          '$copiedDbFilename2.isar',
        ),
      );
      await isarCopy1.copyToFile(copiedDbFile2.path);

      expect(copiedDbFile2.lengthSync(), greaterThan(0));
      expect(
        copiedDbFile2.lengthSync(),
        lessThan(copiedDbFile1.lengthSync()),
      );
    });

    isarTestVm('Copies should be the same size', () async {
      final copiedDbFilename1 = getRandomName();
      final copiedDbFile1 = File(
        path.join(
          isar.directory!,
          '$copiedDbFilename1.isar',
        ),
      );

      final copiedDbFilename2 = getRandomName();
      final copiedDbFile2 = File(
        path.join(
          isar.directory!,
          '$copiedDbFilename2.isar',
        ),
      );

      await isar.copyToFile(copiedDbFile1.path);
      await isar.copyToFile(copiedDbFile2.path);

      expect(copiedDbFile1.lengthSync(), copiedDbFile2.lengthSync());

      final isarCopy = await openTempIsar(
        [ModelSchema],
        directory: isar.directory,
        name: copiedDbFilename1,
      );

      final copiedDbFilename3 = getRandomName();
      final copiedDbFile3 = File(
        path.join(
          isar.directory!,
          '$copiedDbFilename3.isar',
        ),
      );

      await isarCopy.copyToFile(copiedDbFile3.path);

      expect(copiedDbFile3.lengthSync(), copiedDbFile1.lengthSync());
    });
  });
}
