import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../mutli_type_model.dart';
import '../util/common.dart';
import '../util/sync_async_helper.dart';

void main() {
  group('Query property', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([MultiTypeModelSchema]);
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('id property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel(),
          MultiTypeModel(),
          MultiTypeModel(),
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().idProperty().tFindAll(),
        [1, 2, 3],
      );
    });

    isarTest('bool property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..boolValue = true,
          MultiTypeModel()..boolValue = false,
          MultiTypeModel()..boolValue = true,
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().boolValueProperty().tFindAll(),
        [true, false, true],
      );
    });

    isarTest('int property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..intValue = -5,
          MultiTypeModel()..intValue = 70,
          MultiTypeModel()..intValue = 9999,
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().intValueProperty().tFindAll(),
        [-5, 70, 9999],
      );
    });

    isarTest('float property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..floatValue = -5.5,
          MultiTypeModel()..floatValue = 70.7,
          MultiTypeModel()..floatValue = 999.999,
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().floatValueProperty().tFindAll(),
        [-5.5, 70.7, 999.999],
      );
    });

    isarTest('long property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..longValue = -5,
          MultiTypeModel()..longValue = 70,
          MultiTypeModel()..longValue = 9999,
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().longValueProperty().tFindAll(),
        [-5, 70, 9999],
      );
    });

    isarTest('double property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..doubleValue = -5.5,
          MultiTypeModel()..doubleValue = 70.7,
          MultiTypeModel()..doubleValue = 999.999,
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().doubleValueProperty().tFindAll(),
        [-5.5, 70.7, 999.999],
      );
    });

    isarTest('String property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..stringValue = 'Just',
          MultiTypeModel()..stringValue = 'a',
          MultiTypeModel()..stringValue = 'test',
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().stringValueProperty().tFindAll(),
        ['Just', 'a', 'test'],
      );
    });

    isarTest('bytes property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..bytesValue = Uint8List.fromList([0, 10, 255]),
          MultiTypeModel()..bytesValue = Uint8List.fromList([]),
          MultiTypeModel()..bytesValue = Uint8List.fromList([3]),
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().bytesValueProperty().tFindAll(),
        [
          Uint8List.fromList([0, 10, 255]),
          Uint8List.fromList([]),
          Uint8List.fromList([3])
        ],
      );
    });

    isarTest('bool list property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..boolList = [true, false, true],
          MultiTypeModel()..boolList = [],
          MultiTypeModel()..boolList = [true],
        ]),
      );

      await qEqual(isar.multiTypeModels.where().boolListProperty().tFindAll(), [
        [true, false, true],
        <bool>[],
        [true]
      ]);
    });

    isarTest('int list property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..intList = [-5, 70, 999],
          MultiTypeModel()..intList = [],
          MultiTypeModel()..intList = [0],
        ]),
      );

      await qEqual(isar.multiTypeModels.where().intListProperty().tFindAll(), [
        [-5, 70, 999],
        <int>[],
        [0]
      ]);
    });

    isarTest('float list property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..floatList = [-5.5, 70.7, 999.999],
          MultiTypeModel()..floatList = [],
          MultiTypeModel()..floatList = [0.0],
        ]),
      );

      await qEqual(
          isar.multiTypeModels.where().floatListProperty().tFindAll(), [
        [-5.5, 70.7, 999.999],
        <double>[],
        [0.0]
      ]);
    });

    isarTest('long list property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..longList = [-5, 70, 999],
          MultiTypeModel()..longList = [],
          MultiTypeModel()..longList = [0],
        ]),
      );

      await qEqual(isar.multiTypeModels.where().longListProperty().tFindAll(), [
        [-5, 70, 999],
        <int>[],
        [0]
      ]);
    });

    isarTest('double list property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..doubleList = [-5.5, 70.7, 999.999],
          MultiTypeModel()..doubleList = [],
          MultiTypeModel()..doubleList = [0.0],
        ]),
      );

      await qEqual(
          isar.multiTypeModels.where().doubleListProperty().tFindAll(), [
        [-5.5, 70.7, 999.999],
        <double>[],
        [0.0]
      ]);
    });

    isarTest('String list property', () async {
      await isar.tWriteTxn(
        () => isar.multiTypeModels.tPutAll([
          MultiTypeModel()..stringList = ['Just', 'a', 'test'],
          MultiTypeModel()..stringList = [],
          MultiTypeModel()..stringList = [''],
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().stringListProperty().tFindAll(),
        [
          ['Just', 'a', 'test'],
          <String>[],
          ['']
        ],
      );
    });
  });
}
