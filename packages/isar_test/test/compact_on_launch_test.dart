@TestOn('vm')
library;

import 'dart:io';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'compact_on_launch_test.g.dart';

@Collection()
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

  @override
  String toString() {
    return 'Model{id: $id}';
  }
}

void main() {
  group('Compact on launch', () {
    late Isar isar;
    late final isarName = getRandomName();
    late File file;

    setUp(() async {
      isar = await openTempIsar([ModelSchema], name: isarName);
      if (isSQLite) {
        file = File('${isar.directory}/$isarName.sqlite');
      } else {
        file = File('${isar.directory}/$isarName.isar');
      }

      isar.write(
        (isar) => isar.models.putAll(List.generate(100, Model.new)),
      );
    });

    isarTest('No compact on launch', () async {
      isar.close();
      final size1 = file.lengthSync();

      isar = await openTempIsar([ModelSchema], name: isarName);
      isar.write((isar) => isar.models.where().deleteAll(limit: 50));
      isar.close();

      final size2 = file.lengthSync();

      isar = await openTempIsar([ModelSchema], name: isarName);

      expect(size1, size2);
    });

    isarTest('minFileSize', sqlite: false, () async {
      isar.close();
      final size1 = file.lengthSync();

      isar = await openTempIsar([ModelSchema], name: isarName);
      isar.write((isar) => isar.models.where().deleteAll(limit: 50));
      isar.close();

      isar = await openTempIsar(
        [ModelSchema],
        name: isarName,
        compactOnLaunch: CompactCondition(minFileSize: size1 * 2),
      );
      isar.close();
      final size2 = file.lengthSync();
      expect(size1, size2);

      isar = await openTempIsar(
        [ModelSchema],
        name: isarName,
        compactOnLaunch: CompactCondition(minFileSize: size1 ~/ 2),
      );
      final size3 = file.lengthSync();
      expect(size3, lessThan(size2));
    });

    isarTest('minBytes', sqlite: false, () async {
      isar.close();
      final size1 = file.lengthSync();

      isar = await openTempIsar([ModelSchema], name: isarName);
      isar.write((isar) => isar.models.where().deleteAll(limit: 10));
      isar.close();

      isar = await openTempIsar(
        [ModelSchema],
        name: isarName,
        compactOnLaunch: CompactCondition(minBytes: size1 ~/ 2),
      );
      isar.close();
      final size2 = file.lengthSync();
      expect(size1, size2);

      isar = await openTempIsar(
        [ModelSchema],
        name: isarName,
        compactOnLaunch: CompactCondition(minBytes: size1 ~/ 2),
      );
      isar.write((isar) => isar.models.where().deleteAll(limit: 90));
      isar.close();
      final size3 = file.lengthSync();
      expect(size3, size2);

      isar = await openTempIsar(
        [ModelSchema],
        name: isarName,
        compactOnLaunch: CompactCondition(minBytes: size1 ~/ 2),
      );
      final size4 = file.lengthSync();
      expect(size4, lessThan(size3));
    });

    isarTest('minRatio', sqlite: false, () async {
      isar.close();
      final size1 = file.lengthSync();

      isar = await openTempIsar([ModelSchema], name: isarName);
      isar.write((isar) => isar.models.where().deleteAll(limit: 10));
      isar.close();

      isar = await openTempIsar(
        [ModelSchema],
        name: isarName,
        compactOnLaunch: const CompactCondition(minRatio: 2),
      );
      isar.close();
      final size2 = file.lengthSync();
      expect(size1, size2);

      isar = await openTempIsar(
        [ModelSchema],
        name: isarName,
        compactOnLaunch: const CompactCondition(minRatio: 2),
      );
      isar.write((isar) => isar.models.where().deleteAll(limit: 80));
      isar.close();
      final size3 = file.lengthSync();
      expect(size3, size2);

      isar = await openTempIsar(
        [ModelSchema],
        name: isarName,
        compactOnLaunch: const CompactCondition(minRatio: 2),
      );
      final size4 = file.lengthSync();
      expect(size4, lessThan(size3));
    });
  });
}
