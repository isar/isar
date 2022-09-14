import 'dart:io';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'compact_on_launch_test.g.dart';

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
  group('Compact on launch', () {
    late Isar isar;
    late File file;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
      file = File(isar.path!);

      await isar.tWriteTxn(
        () => isar.models.tPutAll(List.filled(100, Model())),
      );
    });

    isarTestVm('No compact on launch', () async {
      await isar.close();
      final size1 = file.lengthSync();

      isar = await openTempIsar([ModelSchema], name: isar.name);
      await isar.tWriteTxn(() => isar.models.where().limit(50).tDeleteAll());
      await isar.close();

      final size2 = file.lengthSync();

      isar = await openTempIsar([ModelSchema], name: isar.name);

      expect(size1, size2);
    });

    isarTestVm('minFileSize', () async {
      await isar.close();
      final size1 = file.lengthSync();

      isar = await openTempIsar([ModelSchema], name: isar.name);
      await isar.tWriteTxn(() => isar.models.where().limit(50).tDeleteAll());
      await isar.close();

      isar = await openTempIsar(
        [ModelSchema],
        name: isar.name,
        compactOnLaunch: CompactCondition(minFileSize: size1 * 2),
      );
      await isar.close();
      final size2 = file.lengthSync();
      expect(size1, size2);

      isar = await openTempIsar(
        [ModelSchema],
        name: isar.name,
        compactOnLaunch: CompactCondition(minFileSize: size1 ~/ 2),
      );
      final size3 = file.lengthSync();
      expect(size3, lessThan(size2));
    });

    isarTestVm('minBytes', () async {
      await isar.close();
      final size1 = file.lengthSync();

      isar = await openTempIsar([ModelSchema], name: isar.name);
      await isar.tWriteTxn(() => isar.models.where().limit(10).tDeleteAll());
      await isar.close();

      isar = await openTempIsar(
        [ModelSchema],
        name: isar.name,
        compactOnLaunch: CompactCondition(minBytes: size1 ~/ 2),
      );
      await isar.close();
      final size2 = file.lengthSync();
      expect(size1, size2);

      isar = await openTempIsar(
        [ModelSchema],
        name: isar.name,
        compactOnLaunch: CompactCondition(minBytes: size1 ~/ 2),
      );
      await isar.tWriteTxn(() => isar.models.where().limit(80).tDeleteAll());
      await isar.close();
      final size3 = file.lengthSync();
      expect(size3, size2);

      isar = await openTempIsar(
        [ModelSchema],
        name: isar.name,
        compactOnLaunch: CompactCondition(minBytes: size1 ~/ 2),
      );
      final size4 = file.lengthSync();
      expect(size4, lessThan(size3));
    });

    isarTestVm('minRatio', () async {
      await isar.close();
      final size1 = file.lengthSync();

      isar = await openTempIsar([ModelSchema], name: isar.name);
      await isar.tWriteTxn(() => isar.models.where().limit(10).tDeleteAll());
      await isar.close();

      isar = await openTempIsar(
        [ModelSchema],
        name: isar.name,
        compactOnLaunch: const CompactCondition(minRatio: 2),
      );
      await isar.close();
      final size2 = file.lengthSync();
      expect(size1, size2);

      isar = await openTempIsar(
        [ModelSchema],
        name: isar.name,
        compactOnLaunch: const CompactCondition(minRatio: 2),
      );
      await isar.tWriteTxn(() => isar.models.where().limit(80).tDeleteAll());
      await isar.close();
      final size3 = file.lengthSync();
      expect(size3, size2);

      isar = await openTempIsar(
        [ModelSchema],
        name: isar.name,
        compactOnLaunch: const CompactCondition(minRatio: 2),
      );
      final size4 = file.lengthSync();
      expect(size4, lessThan(size3));
    });
  });
}
