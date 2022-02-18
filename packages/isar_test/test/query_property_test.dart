import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'mutli_type_model.dart';

void main() async {
  group('Query property', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([MultiTypeModelSchema]);
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('bool property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..boolValue = true,
          MultiTypeModel()..boolValue = false,
          MultiTypeModel()..boolValue = true,
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().boolValueProperty().findAll(),
        [true, false, true],
      );
    });

    isarTest('int property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..intValue = -5,
          MultiTypeModel()..intValue = 70,
          MultiTypeModel()..intValue = 9999,
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().intValueProperty().findAll(),
        [-5, 70, 9999],
      );
    });

    isarTest('float property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..floatValue = -5.5,
          MultiTypeModel()..floatValue = 70.7,
          MultiTypeModel()..floatValue = 999.999,
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().floatValueProperty().findAll(),
        [-5.5, 70.7, 999.999],
      );
    });

    isarTest('long property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..longValue = -5,
          MultiTypeModel()..longValue = 70,
          MultiTypeModel()..longValue = 9999,
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().longValueProperty().findAll(),
        [-5, 70, 9999],
      );
    });

    isarTest('double property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..doubleValue = -5.5,
          MultiTypeModel()..doubleValue = 70.7,
          MultiTypeModel()..doubleValue = 999.999,
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().doubleValueProperty().findAll(),
        [-5.5, 70.7, 999.999],
      );
    });

    isarTest('String property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..stringValue = 'Just',
          MultiTypeModel()..stringValue = 'a',
          MultiTypeModel()..stringValue = 'test',
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().stringValueProperty().findAll(),
        ['Just', 'a', 'test'],
      );
    });

    isarTest('bytes property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..bytesValue = Uint8List.fromList([0, 10, 255]),
          MultiTypeModel()..bytesValue = Uint8List.fromList([]),
          MultiTypeModel()..bytesValue = Uint8List.fromList([3]),
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().bytesValueProperty().findAll(),
        [
          Uint8List.fromList([0, 10, 255]),
          Uint8List.fromList([]),
          Uint8List.fromList([3])
        ],
      );
    });

    isarTest('bool list property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..boolList = [true, false, true],
          MultiTypeModel()..boolList = [],
          MultiTypeModel()..boolList = [true],
        ]),
      );

      await qEqual(isar.multiTypeModels.where().boolListProperty().findAll(), [
        [true, false, true],
        [],
        [true]
      ]);
    });

    isarTest('int list property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..intList = [-5, 70, 999],
          MultiTypeModel()..intList = [],
          MultiTypeModel()..intList = [0],
        ]),
      );

      await qEqual(isar.multiTypeModels.where().intListProperty().findAll(), [
        [-5, 70, 999],
        [],
        [0]
      ]);
    });

    isarTest('float list property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..floatList = [-5.5, 70.7, 999.999],
          MultiTypeModel()..floatList = [],
          MultiTypeModel()..floatList = [0.0],
        ]),
      );

      await qEqual(isar.multiTypeModels.where().floatListProperty().findAll(), [
        [-5.5, 70.7, 999.999],
        [],
        [0.0]
      ]);
    });

    isarTest('long list property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..longList = [-5, 70, 999],
          MultiTypeModel()..longList = [],
          MultiTypeModel()..longList = [0],
        ]),
      );

      await qEqual(isar.multiTypeModels.where().longListProperty().findAll(), [
        [-5, 70, 999],
        [],
        [0]
      ]);
    });

    isarTest('double list property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..doubleList = [-5.5, 70.7, 999.999],
          MultiTypeModel()..doubleList = [],
          MultiTypeModel()..doubleList = [0.0],
        ]),
      );

      await qEqual(
          isar.multiTypeModels.where().doubleListProperty().findAll(), [
        [-5.5, 70.7, 999.999],
        [],
        [0.0]
      ]);
    });

    isarTest('String list property', () async {
      await isar.writeTxn(
        (isar) => isar.multiTypeModels.putAll([
          MultiTypeModel()..stringList = ['Just', 'a', 'test'],
          MultiTypeModel()..stringList = [],
          MultiTypeModel()..stringList = [''],
        ]),
      );

      await qEqual(
        isar.multiTypeModels.where().stringListProperty().findAll(),
        [
          ['Just', 'a', 'test'],
          [],
          ['']
        ],
      );
    });
  });
}
