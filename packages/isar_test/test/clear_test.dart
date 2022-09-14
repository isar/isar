import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'clear_test.g.dart';

@collection
class ModelA {
  Id? id;
}

@collection
class ModelB {
  Id? id;
}

void main() {
  group('Clear', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([ModelASchema, ModelBSchema]);
    });

    isarTest('Clear should empty target collection', () async {
      final modelAs = List.generate(100, (_) => ModelA());
      final modelBs = List.generate(200, (_) => ModelB());

      await isar.tWriteTxn(() async {
        await Future.wait([
          isar.modelAs.tPutAll(modelAs),
          isar.modelBs.tPutAll(modelBs),
        ]);
      });

      await isar.modelAs.verify(modelAs);
      await isar.modelBs.verify(modelBs);

      await isar.tWriteTxn(
        () => isar.modelAs.tClear(),
      );

      await isar.modelAs.verify([]);
      await isar.modelBs.verify(modelBs);
    });

    isarTest('Isar clear should clear every collection', () async {
      final modelAs = List.generate(250, (_) => ModelA());
      final modelBs = List.generate(500, (_) => ModelB());

      await isar.tWriteTxn(() async {
        await Future.wait([
          isar.modelAs.tPutAll(modelAs),
          isar.modelBs.tPutAll(modelBs),
        ]);
      });

      await isar.modelAs.verify(modelAs);
      await isar.modelBs.verify(modelBs);

      await isar.tWriteTxn(() => isar.tClear());

      await isar.modelAs.verify([]);
      await isar.modelBs.verify([]);
    });

    isarTest('Clear already cleared collection', () async {
      await isar.tWriteTxn(
        () => isar.modelAs.tPutAll(List.generate(42, (_) => ModelA())),
      );
      final count1 = await isar.modelAs.where().tCount();
      expect(count1, 42);

      await isar.tWriteTxn(() => isar.modelAs.tClear());
      final count2 = await isar.modelAs.where().tCount();
      expect(count2, 0);

      await isar.tWriteTxn(() => isar.modelAs.tClear());
      await isar.tWriteTxn(() => isar.modelAs.tClear());
      await isar.tWriteTxn(() => isar.modelAs.tClear());

      final count3 = await isar.modelAs.where().tCount();
      expect(count3, 0);
    });

    isarTest('Clear should reset auto increment', () async {
      final ids = await isar.tWriteTxn(
        () => isar.modelAs.tPutAll(List.generate(20, (_) => ModelA())),
      );

      await isar.tWriteTxn(() => isar.modelAs.tClear());

      final newIds = await isar.tWriteTxn(
        () => isar.modelAs.tPutAll(List.generate(20, (_) => ModelA())),
      );
      expect(newIds, ids);
    });
  });
}
