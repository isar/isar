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

    setUp(() {
      isar = openTempIsar([ModelSchema], maxSizeMiB: 20);

      isar.writeTxn(
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

    isarTest('.copyToFile() should keep the same content', () {
      final copiedDbFilename = getRandomName();
      final copiedDbFile =
          File(path.join(isar.directory, '$copiedDbFilename.isar'));

      isar.copyToFile(copiedDbFile.path);

      final copiedIsar = openTempIsar(
        [ModelSchema],
        directory: isar.directory,
        name: copiedDbFilename,
        maxSizeMiB: 20,
      );

      expect(
        copiedIsar.models.where().findAll(),
        isar.models.where().findAll(),
      );
    });

    isarTest('.copyToFile() should compact copied file', () {
      isar.writeTxn((isar) => isar.models.where().deleteAll(limit: 50));

      final copiedDbFilename1 = getRandomName();
      final copiedDbFile1 = File(
        path.join(
          isar.directory,
          '$copiedDbFilename1.isar',
        ),
      );

      isar.copyToFile(copiedDbFile1.path);

      final isarCopy1 = openTempIsar(
        [ModelSchema],
        directory: isar.directory,
        name: copiedDbFilename1,
        maxSizeMiB: 20,
      );

      expect(copiedDbFile1.lengthSync(), greaterThan(0));
      expect(
        copiedDbFile1.lengthSync(),
        lessThan(File('${isar.directory}/${isar.name}.isar').lengthSync()),
      );

      isarCopy1
          .writeTxn((isar) => isarCopy1.models.where().deleteAll(limit: 25));

      final copiedDbFilename2 = getRandomName();
      final copiedDbFile2 =
          File(path.join(isar.directory, '$copiedDbFilename2.isar'));
      isarCopy1.copyToFile(copiedDbFile2.path);

      expect(copiedDbFile2.lengthSync(), greaterThan(0));
      expect(
        copiedDbFile2.lengthSync(),
        lessThan(copiedDbFile1.lengthSync()),
      );
      copiedDbFile2.delete();
    });

    isarTest('Copies should be the same size', () {
      final copiedDbFilename1 = getRandomName();
      final copiedDbFile1 =
          File(path.join(isar.directory, '$copiedDbFilename1.isar'));

      final copiedDbFilename2 = getRandomName();
      final copiedDbFile2 = File(
        path.join(
          isar.directory,
          '$copiedDbFilename2.isar',
        ),
      );

      isar.copyToFile(copiedDbFile1.path);
      isar.copyToFile(copiedDbFile2.path);

      expect(copiedDbFile1.lengthSync(), copiedDbFile2.lengthSync());
      copiedDbFile2.delete();

      final isarCopy = openTempIsar(
        [ModelSchema],
        directory: isar.directory,
        name: copiedDbFilename1,
        maxSizeMiB: 20,
      );

      final copiedDbFilename3 = getRandomName();
      final copiedDbFile3 = File(
        path.join(
          isar.directory,
          '$copiedDbFilename3.isar',
        ),
      );

      isarCopy.copyToFile(copiedDbFile3.path);

      expect(copiedDbFile3.lengthSync(), copiedDbFile1.lengthSync());
      copiedDbFile3.delete();
    });
  });
}
