import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'clear_test.g.dart';

@Collection()
class ModelA {
  Id? id;
}

@Collection()
class ModelB {
  Id? id;
}

void main() {
  group('Clear', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([ModelASchema, ModelBSchema]);
    });

    tearDown(() => isar.close());

    isarTest('Clear should empty target collection', () async {
      await isar.tWriteTxn(() async {
        await Future.wait([
          isar.modelAs.tPutAll(List.generate(100, (_) => ModelA())),
          isar.modelBs.tPutAll(List.generate(200, (_) => ModelB())),
        ]);
      });

      final modelACount = await isar.modelAs.where().tCount();
      expect(modelACount, 100);

      final modelBCount = await isar.modelBs.where().tCount();
      expect(modelBCount, 200);

      await isar.tWriteTxn(
        () => isar.modelAs.tClear(),
      );

      final newModelACount = await isar.modelAs.where().tCount();
      expect(newModelACount, 0);

      final newModelBCount = await isar.modelBs.where().tCount();
      expect(newModelBCount, 200);
    });

    isarTest('Isar clear should clear every collection', () async {
      await isar.tWriteTxn(() async {
        await Future.wait([
          isar.modelAs.tPutAll(List.generate(250, (_) => ModelA())),
          isar.modelBs.tPutAll(List.generate(500, (_) => ModelB())),
        ]);
      });

      final modelACount = await isar.modelAs.where().tCount();
      expect(modelACount, 250);

      final modelBCount = await isar.modelBs.where().tCount();
      expect(modelBCount, 500);

      await isar.tWriteTxn(() => isar.tClear());

      final newModelACount = await isar.modelAs.where().tCount();
      expect(newModelACount, 0);

      final newModelBCount = await isar.modelBs.where().tCount();
      expect(newModelBCount, 0);
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
