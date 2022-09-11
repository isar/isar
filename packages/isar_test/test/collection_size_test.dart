import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'collection_size_test.g.dart';

@collection
class ModelA {
  ModelA({
    required this.name,
  });

  Id id = Isar.autoIncrement;

  @Index()
  String name;

  final bObj = IsarLink<ModelB>();
  final bObjs = IsarLinks<ModelB>();

  // We store a big buffer in order to better detect collection size changes,
  // since reported collection size is based on block size (eg. 4096, 8192, ...)
  final List<int> randomBuffer = List.filled(64000, 42);
}

@collection
class ModelB {
  Id id = Isar.autoIncrement;

  final List<int> randomBuffer = List.filled(64000, 42);
}

void main() {
  group('Collection size', () {
    late Isar isar;

    late ModelA objA0;
    late ModelA objA1;
    late ModelA objA2;
    late ModelA objA3;
    late ModelA objA4;
    late ModelA objA5;

    late ModelB objB0;
    late ModelB objB1;
    late ModelB objB2;
    late ModelB objB3;
    late ModelB objB4;
    late ModelB objB5;

    setUp(() async {
      isar = await openTempIsar([ModelASchema, ModelBSchema]);

      objA0 = ModelA(name: 'Obj A0');
      objA1 = ModelA(name: 'Obj A1');
      objA2 = ModelA(name: 'Obj A2');
      objA3 = ModelA(name: 'Obj A3');
      objA4 = ModelA(name: 'Obj A4');
      objA5 = ModelA(name: 'Obj A5');

      objB0 = ModelB();
      objB1 = ModelB();
      objB2 = ModelB();
      objB3 = ModelB();
      objB4 = ModelB();
      objB5 = ModelB();
    });

    isarTest('Size should start at 0', () async {
      expect(await isar.modelAs.tGetSize(), 0);
      expect(await isar.modelAs.tGetSize(), 0);

      expect(await isar.modelAs.tGetSize(includeIndexes: true), 0);
      expect(await isar.modelAs.tGetSize(includeIndexes: true), 0);

      expect(await isar.modelAs.tGetSize(includeLinks: true), 0);
      expect(await isar.modelAs.tGetSize(includeLinks: true), 0);

      expect(
        await isar.modelAs.tGetSize(includeIndexes: true, includeLinks: true),
        0,
      );
      expect(
        await isar.modelAs.tGetSize(includeIndexes: true, includeLinks: true),
        0,
      );
    });

    isarTest('Size should increase with more entries', () async {
      await isar.tWriteTxn(() => isar.modelAs.tPut(objA0));
      final sizeA0 = await isar.modelAs.tGetSize();
      expect(sizeA0, greaterThan(0));

      await isar.tWriteTxn(() => isar.modelAs.tPutAll([objA1, objA2, objA3]));
      final sizeA1 = await isar.modelAs.tGetSize();
      expect(sizeA1, greaterThan(sizeA0));

      await isar.tWriteTxn(() => isar.modelAs.tPutAll([objA4, objA5]));
      final sizeA2 = await isar.modelAs.tGetSize();
      expect(sizeA2, greaterThan(sizeA1));

      expect(await isar.modelBs.tGetSize(), 0);

      await isar.tWriteTxn(() => isar.modelBs.tPut(objB0));
      final sizeB0 = await isar.modelBs.tGetSize();
      expect(sizeB0, greaterThan(0));

      await isar.tWriteTxn(() => isar.modelBs.tPutAll([objB1, objB2, objB3]));
      final sizeB1 = await isar.modelBs.tGetSize();
      expect(sizeB1, greaterThanOrEqualTo(sizeB0));

      await isar.tWriteTxn(() => isar.modelBs.tPutAll([objB4, objB5]));
      final sizeB2 = await isar.modelBs.tGetSize();
      expect(sizeB2, greaterThanOrEqualTo(sizeB1));
    });

    isarTest('includeIndexes should change size', () async {
      await isar.tWriteTxn(() => isar.modelAs.tPutAll([objA0, objA1, objA3]));

      final sizeAWithoutIndexes = await isar.modelAs.tGetSize();
      final sizeAWithIndexes =
          await isar.modelAs.tGetSize(includeIndexes: true);
      expect(sizeAWithIndexes, greaterThan(sizeAWithoutIndexes));

      await isar.tWriteTxn(() => isar.modelBs.tPutAll([objB0, objB3, objB4]));

      final sizeBWithoutIndexes = await isar.modelBs.tGetSize();
      final sizeBWithIndexes =
          await isar.modelBs.tGetSize(includeIndexes: true);
      // ModelB has no indexes, so should stay the same
      expect(sizeBWithIndexes, sizeBWithoutIndexes);
    });

    isarTest('includeLinks should change size', () async {
      await isar.tWriteTxn(
        () => Future.wait([
          isar.modelAs.tPutAll([objA0, objA1, objA2, objA3]),
          isar.modelBs.tPutAll([objB0, objB1, objB2, objB3, objB4]),
        ]),
      );

      objA1.bObj.value = objB0;
      objA2.bObjs.addAll([objB0, objB1, objB4]);
      objA3.bObj.value = objB0;
      objA3.bObjs.addAll([objB0, objB1, objB3, objB4]);

      final size1 = await isar.modelAs.tGetSize();
      final size2 = await isar.modelAs.tGetSize(includeLinks: true);
      expect(size1, size2);

      await isar.tWriteTxn(
        () => Future.wait([
          objA1.bObj.tSave(),
          objA2.bObjs.tSave(),
          objA3.bObj.tSave(),
          objA3.bObjs.tSave(),
        ]),
      );

      final size3 = await isar.modelAs.tGetSize();
      final size4 = await isar.modelAs.tGetSize(includeLinks: true);
      expect(size3, lessThan(size4));
    });

    isarTest('includeIndexes and includeLinks should change size', () async {
      await isar.tWriteTxn(
        () => Future.wait([
          isar.modelAs.tPutAll([objA0, objA1, objA2, objA3]),
          isar.modelBs.tPutAll([objB0, objB1, objB2, objB3, objB4]),
        ]),
      );

      objA1.bObj.value = objB0;
      objA2.bObjs.addAll([objB0, objB1, objB4]);
      objA3.bObj.value = objB0;
      objA3.bObjs.addAll([objB0, objB1, objB3, objB4]);

      await isar.tWriteTxn(
        () => Future.wait([
          objA1.bObj.tSave(),
          objA2.bObjs.tSave(),
          objA3.bObj.tSave(),
          objA3.bObjs.tSave(),
        ]),
      );

      final size = await isar.modelAs.tGetSize();
      final sizeWithIndexes = await isar.modelAs.tGetSize(includeIndexes: true);
      final sizeWithLinks = await isar.modelAs.tGetSize(includeLinks: true);
      final sizeWithIndexesAndLinks = await isar.modelAs.tGetSize(
        includeIndexes: true,
        includeLinks: true,
      );
      expect(size, lessThan(sizeWithIndexes));
      expect(size, lessThan(sizeWithLinks));
      expect(sizeWithIndexes, lessThan(sizeWithIndexesAndLinks));
      expect(sizeWithLinks, lessThan(sizeWithIndexesAndLinks));
    });

    isarTest('Delete should decrease size', () async {
      await isar.tWriteTxn(
        () => Future.wait([
          isar.modelAs.tPutAll([objA0, objA1, objA2, objA3]),
          isar.modelBs.tPutAll([objB0, objB1, objB2, objB3, objB4]),
        ]),
      );

      final sizeA1 = await isar.modelAs.tGetSize();

      await isar.tWriteTxn(() => isar.modelAs.tDelete(objA0.id));
      final sizeA2 = await isar.modelAs.tGetSize();

      expect(sizeA2, lessThan(sizeA1));

      await isar.tWriteTxn(() => isar.modelAs.tClear());
      final sizeA3 = await isar.modelAs.tGetSize();
      expect(sizeA3, 0);

      final sizeB1 = await isar.modelBs.tGetSize();

      await isar.tWriteTxn(() => isar.modelBs.tDeleteAll([objB0.id, objB1.id]));
      final sizeB2 = await isar.modelBs.tGetSize();

      expect(sizeB2, lessThan(sizeB1));

      await isar.tWriteTxn(() => isar.modelBs.tDeleteAll([objB2.id, objB3.id]));
      final sizeB3 = await isar.modelBs.tGetSize();

      expect(sizeB3, lessThan(sizeB2));
      expect(sizeB3, greaterThan(0));
    });

    isarTest('Update should change size', () async {
      await isar.tWriteTxn(
        () => Future.wait([
          isar.modelAs.tPutAll([objA0, objA1, objA2, objA3]),
          isar.modelBs.tPutAll([objB0, objB1, objB2, objB3, objB4]),
        ]),
      );

      final sizeA1 = await isar.modelAs.tGetSize();
      final sizeB1 = await isar.modelBs.tGetSize();

      objA0.name += String.fromCharCodes(List.filled(64000, 42));

      await isar.tWriteTxn(() => isar.modelAs.tPut(objA0));
      final sizeA2 = await isar.modelAs.tGetSize();
      final sizeB2 = await isar.modelBs.tGetSize();

      expect(sizeA2, greaterThan(sizeA1));
      expect(sizeB2, sizeB1);

      objA0.name += String.fromCharCodes(List.filled(64000, 42));
      objA1.name += String.fromCharCodes(List.filled(64000, 42));

      await isar.tWriteTxn(() => isar.modelAs.tPutAll([objA0, objA1]));
      final sizeA3 = await isar.modelAs.tGetSize();
      final sizeB3 = await isar.modelBs.tGetSize();

      expect(sizeA3, greaterThan(sizeA2));
      expect(sizeB3, sizeB2);
    });
  });
}
