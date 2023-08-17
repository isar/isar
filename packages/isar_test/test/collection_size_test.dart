import 'dart:math';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'collection_size_test.g.dart';

@collection
class ModelA {
  ModelA({
    required this.name,
  });

  int id = Random().nextInt(99999);

  @Index()
  String name;

  // We store a big buffer in order to better detect collection size changes,
  // since reported collection size is based on block size (eg. 4096, 8192, ...)
  final List<int> randomBuffer = List.filled(64000, 42);
}

@collection
class ModelB {
  int id = Random().nextInt(99999);

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

    isarTest('Size should start at 0', sqlite: false, web: false, () {
      expect(isar.modelAs.getSize(), 0);
      expect(isar.modelAs.getSize(), 0);

      expect(isar.modelAs.getSize(includeIndexes: true), 0);
      expect(isar.modelAs.getSize(includeIndexes: true), 0);
    });

    isarTest('Size should increase with more entries',
        sqlite: false, web: false, () {
      isar.write((isar) => isar.modelAs.put(objA0));
      final sizeA0 = isar.modelAs.getSize();
      expect(sizeA0, greaterThan(0));

      isar.write((isar) => isar.modelAs.putAll([objA1, objA2, objA3]));
      final sizeA1 = isar.modelAs.getSize();
      expect(sizeA1, greaterThan(sizeA0));

      isar.write((isar) => isar.modelAs.putAll([objA4, objA5]));
      final sizeA2 = isar.modelAs.getSize();
      expect(sizeA2, greaterThan(sizeA1));

      expect(isar.modelBs.getSize(), 0);

      isar.write((isar) => isar.modelBs.put(objB0));
      final sizeB0 = isar.modelBs.getSize();
      expect(sizeB0, greaterThan(0));

      isar.write((isar) => isar.modelBs.putAll([objB1, objB2, objB3]));
      final sizeB1 = isar.modelBs.getSize();
      expect(sizeB1, greaterThanOrEqualTo(sizeB0));

      isar.write((isar) => isar.modelBs.putAll([objB4, objB5]));
      final sizeB2 = isar.modelBs.getSize();
      expect(sizeB2, greaterThanOrEqualTo(sizeB1));
    });

    // enable when indexes are implemented
    /*isarTest('includeIndexes should change size', () {
      isar.write((isar) => isar.modelAs.putAll([objA0, objA1, objA3]));

      final sizeAWithoutIndexes = isar.modelAs.getSize();
      final sizeAWithIndexes = isar.modelAs.getSize(includeIndexes: true);
      expect(sizeAWithIndexes, greaterThan(sizeAWithoutIndexes));

      isar.write((isar) => isar.modelBs.putAll([objB0, objB3, objB4]));

      final sizeBWithoutIndexes = isar.modelBs.getSize();
      final sizeBWithIndexes = isar.modelBs.getSize(includeIndexes: true);
      // ModelB has no indexes, so should stay the same
      expect(sizeBWithIndexes, sizeBWithoutIndexes);
    });*/

    isarTest('Delete should decrease size', sqlite: false, web: false, () {
      isar.write((isar) {
        isar.modelAs.putAll([objA0, objA1, objA2, objA3]);
        isar.modelBs.putAll([objB0, objB1, objB2, objB3, objB4]);
      });

      final sizeA1 = isar.modelAs.getSize();

      isar.write((isar) => isar.modelAs.delete(objA0.id));
      final sizeA2 = isar.modelAs.getSize();

      expect(sizeA2, lessThan(sizeA1));

      isar.write((isar) => isar.modelAs.clear());
      final sizeA3 = isar.modelAs.getSize();
      expect(sizeA3, 0);

      final sizeB1 = isar.modelBs.getSize();

      isar.write((isar) => isar.modelBs.deleteAll([objB0.id, objB1.id]));
      final sizeB2 = isar.modelBs.getSize();

      expect(sizeB2, lessThan(sizeB1));

      isar.write((isar) => isar.modelBs.deleteAll([objB2.id, objB3.id]));
      final sizeB3 = isar.modelBs.getSize();

      expect(sizeB3, lessThan(sizeB2));
      expect(sizeB3, greaterThan(0));
    });

    isarTest('Update should change size', sqlite: false, web: false, () {
      isar.write((isar) {
        isar.modelAs.putAll([objA0, objA1, objA2, objA3]);
        isar.modelBs.putAll([objB0, objB1, objB2, objB3, objB4]);
      });

      final sizeA1 = isar.modelAs.getSize();
      final sizeB1 = isar.modelBs.getSize();

      objA0.name += String.fromCharCodes(List.filled(64000, 42));

      isar.write((isar) => isar.modelAs.put(objA0));
      final sizeA2 = isar.modelAs.getSize();
      final sizeB2 = isar.modelBs.getSize();

      expect(sizeA2, greaterThan(sizeA1));
      expect(sizeB2, sizeB1);

      objA0.name += String.fromCharCodes(List.filled(64000, 42));
      objA1.name += String.fromCharCodes(List.filled(64000, 42));

      isar.write((isar) => isar.modelAs.putAll([objA0, objA1]));
      final sizeA3 = isar.modelAs.getSize();
      final sizeB3 = isar.modelBs.getSize();

      expect(sizeA3, greaterThan(sizeA2));
      expect(sizeB3, sizeB2);
    });
  });
}
