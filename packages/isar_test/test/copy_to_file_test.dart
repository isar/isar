import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'copy_to_file_test.g.dart';

@Collection()
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
  group(
    'Copy to file',
    skip: kIsWeb, // Unsupported on web
    () {
      late Isar isar;
      late File originalDbFile;

      late Directory directory;

      setUp(() async {
        isar = await openTempIsar([ModelSchema]);
        originalDbFile = File(isar.path!);

        await isar.tWriteTxn(
          () => isar.models.tPutAll(List.filled(100, Model())),
        );

        directory = Directory('copy-to-file-test-database-copies');
        await directory.create(recursive: true);
      });

      tearDown(() async {
        await isar.close(deleteFromDisk: true);
        await directory.delete(recursive: true);
      });

      isarTest('.copyToFile() should create a new file', () async {
        final copiedDbFile = File(path.join(directory.path, getRandomName()));
        expect(copiedDbFile.existsSync(), false);

        await isar.copyToFile(copiedDbFile.path);

        expect(copiedDbFile.existsSync(), true);
        expect(copiedDbFile.lengthSync(), greaterThan(0));
      });

      isarTest('.copyToFile() should keep the same content', () async {
        final copiedDbFilename = getRandomName();
        final copiedDbFile = File(
          path.join(
            directory.path,
            '$copiedDbFilename.isar',
          ),
        );

        await isar.copyToFile(copiedDbFile.path);

        final copiedIsar = await tOpen(
          schemas: [ModelSchema],
          directory: directory.path,
          name: copiedDbFilename,
        );
        addTearDown(() => copiedIsar.close(deleteFromDisk: true));

        final originalObjs = await isar.models.where().tFindAll();
        await qEqualSet(
          copiedIsar.models.where().tFindAll(),
          originalObjs,
        );
      });

      isarTest('.copyToFile() should compact copied file', () async {
        await isar.tWriteTxn(() => isar.models.where().limit(50).tDeleteAll());

        final copiedDbFilename1 = getRandomName();
        final copiedDbFile1 = File(
          path.join(
            directory.path,
            '$copiedDbFilename1.isar',
          ),
        );

        await isar.copyToFile(copiedDbFile1.path);

        final isarCopy1 = await tOpen(
          schemas: [ModelSchema],
          directory: directory.path,
          name: copiedDbFilename1,
        );
        addTearDown(() => isarCopy1.close(deleteFromDisk: true));

        expect(copiedDbFile1.lengthSync(), greaterThan(0));
        expect(
          copiedDbFile1.lengthSync(),
          lessThan(originalDbFile.lengthSync()),
        );

        await isarCopy1.tWriteTxn(
          () => isarCopy1.models.where().limit(25).tDeleteAll(),
        );

        final copiedDbFilename2 = getRandomName();
        final copiedDbFile2 = File(
          path.join(
            directory.path,
            '$copiedDbFilename2.isar',
          ),
        );

        final isarCopy2 = await tOpen(
          schemas: [ModelSchema],
          directory: directory.path,
          name: copiedDbFilename2,
        );
        addTearDown(() => isarCopy2.close(deleteFromDisk: true));

        expect(copiedDbFile2.lengthSync(), greaterThan(0));
        expect(
          copiedDbFile2.lengthSync(),
          lessThan(copiedDbFile1.lengthSync()),
        );
      });

      isarTest('Copies should be the same size', () async {
        final copiedDbFilename1 = getRandomName();
        final copiedDbFile1 = File(
          path.join(
            directory.path,
            '$copiedDbFilename1.isar',
          ),
        );

        final copiedDbFilename2 = getRandomName();
        final copiedDbFile2 = File(
          path.join(
            directory.path,
            '$copiedDbFilename2.isar',
          ),
        );

        await isar.copyToFile(copiedDbFile1.path);
        await isar.copyToFile(copiedDbFile2.path);

        expect(copiedDbFile1.lengthSync(), copiedDbFile2.lengthSync());

        final isarCopy = await tOpen(
          schemas: [ModelSchema],
          directory: directory.path,
          name: copiedDbFilename1,
        );
        addTearDown(() => isarCopy.close(deleteFromDisk: true));

        final copiedDbFilename3 = getRandomName();
        final copiedDbFile3 = File(
          path.join(
            directory.path,
            '$copiedDbFilename3.isar',
          ),
        );

        await isarCopy.copyToFile(copiedDbFile3.path);

        expect(copiedDbFile3.lengthSync(), copiedDbFile1.lengthSync());
      });
    },
  );
}
