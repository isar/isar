@TestOn('vm')
library;

import 'dart:io';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

part 'copy_to_file_test.g.dart';

@collection
class Model {
  Model(this.id);

  final int id;

  List<int> buffer = List.filled(16000, 42);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listEquals(buffer, other.buffer);
}

void main() {
  group('Copy to file', () {
    late Isar isar;

    setUp(() async {
      // disable WAL for SQLite
      isar = await openTempIsar([ModelSchema], maxSizeMiB: isSQLite ? 0 : 20);

      isar.write(
        (isar) => isar.models.putAll(List.generate(100, Model.new)),
      );
    });

    isarTest('.copyToFile() should create a new file', () {
      final copiedDbFile = File(path.join(isar.directory, getRandomName()));
      expect(copiedDbFile.existsSync(), false);

      isar.copyToFile(copiedDbFile.path);

      expect(copiedDbFile.existsSync(), true);
      expect(copiedDbFile.lengthSync(), greaterThan(0));
      copiedDbFile.delete();
    });

    isarTest('.copyToFile() should keep the same content', () async {
      final name = getRandomName();
      final copiedDbFile = File(
        path.join(isar.directory, isSQLite ? '$name.sqlite' : '$name.isar'),
      );

      isar.copyToFile(copiedDbFile.path);

      final copiedIsar = await openTempIsar(
        [ModelSchema],
        directory: isar.directory,
        name: name,
        maxSizeMiB: 20,
      );

      expect(
        copiedIsar.models.where().findAll(),
        isar.models.where().findAll(),
      );
    });

    isarTest('.copyToFile() should compact copied file', () async {
      final dbFile = File(
        path.join(
          isar.directory,
          isSQLite ? '${isar.name}.sqlite' : '${isar.name}.isar',
        ),
      );
      isar.write((isar) => isar.models.where().deleteAll(limit: 50));

      final name1 = getRandomName();
      final copiedDbFile1 = File(
        path.join(isar.directory, isSQLite ? '$name1.sqlite' : '$name1.isar'),
      );

      isar.copyToFile(copiedDbFile1.path);

      final isarCopy1 = await openTempIsar(
        [ModelSchema],
        directory: isar.directory,
        name: name1,
        maxSizeMiB: 20,
      );

      expect(copiedDbFile1.lengthSync(), greaterThan(0));
      expect(copiedDbFile1.lengthSync(), lessThan(dbFile.lengthSync()));

      isarCopy1.write((isar) => isarCopy1.models.where().deleteAll(limit: 25));

      final name2 = getRandomName();
      final copiedDbFile2 = File(
        path.join(isar.directory, isSQLite ? '$name2.sqlite' : '$name2.isar'),
      );
      isarCopy1.copyToFile(copiedDbFile2.path);

      expect(copiedDbFile2.lengthSync(), greaterThan(0));
      expect(copiedDbFile2.lengthSync(), lessThan(copiedDbFile1.lengthSync()));
      copiedDbFile2.deleteSync();
    });

    isarTest('Copies should be the same size', () async {
      final name1 = getRandomName();
      final copiedDbFile1 = File(
        path.join(isar.directory, isSQLite ? '$name1.sqlite' : '$name1.isar'),
      );

      final name2 = getRandomName();
      final copiedDbFile2 = File(
        path.join(isar.directory, isSQLite ? '$name2.sqlite' : '$name2.isar'),
      );

      isar.copyToFile(copiedDbFile1.path);
      isar.copyToFile(copiedDbFile2.path);

      expect(copiedDbFile1.lengthSync(), copiedDbFile2.lengthSync());
      copiedDbFile2.deleteSync();

      final isarCopy = await openTempIsar(
        [ModelSchema],
        directory: isar.directory,
        name: name1,
        maxSizeMiB: 20,
      );

      final name3 = getRandomName();
      final copiedDbFile3 = File(
        path.join(isar.directory, isSQLite ? '$name3.sqlite' : '$name3.isar'),
      );

      isarCopy.copyToFile(copiedDbFile3.path);

      expect(copiedDbFile3.lengthSync(), copiedDbFile1.lengthSync());
      copiedDbFile3.deleteSync();
    });
  });
}
