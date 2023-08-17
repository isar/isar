import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

import '../type_models.dart';

void main() {
  group('Query property', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([
        BoolModelSchema,
        ByteModelSchema,
        ShortModelSchema,
        IntModelSchema,
        FloatModelSchema,
        DoubleModelSchema,
        DateTimeModelSchema,
        StringModelSchema,
        EnumModelSchema,
        ObjectModelSchema,
      ]);
    });

    isarTest('id property', () {
      isar.write(
        (isar) => isar.boolModels.putAll([
          BoolModel(0),
          BoolModel(1),
          BoolModel(2),
        ]),
      );

      expect(
        isar.boolModels.where().idProperty().findAll(),
        [0, 1, 2],
      );
    });

    isarTest('bool property', () {
      isar.write(
        (isar) => isar.boolModels.putAll([
          BoolModel(0)
            ..value = true
            ..nValue = false,
          BoolModel(1)
            ..value = false
            ..nValue = true,
          BoolModel(2)..value = true,
        ]),
      );

      expect(
        isar.boolModels.where().valueProperty().findAll(),
        [true, false, true],
      );

      expect(
        isar.boolModels.where().nValueProperty().findAll(),
        [false, true, null],
      );
    });

    isarTest('byte property', () {
      isar.write(
        (isar) => isar.byteModels.putAll([
          ByteModel(0)..value = 5,
          ByteModel(1)..value = 123,
          ByteModel(2)..value = 0,
        ]),
      );

      expect(
        isar.byteModels.where().valueProperty().findAll(),
        [5, 123, 0],
      );
    });

    isarTest('short property', () {
      isar.write(
        (isar) => isar.shortModels.putAll([
          ShortModel(0)
            ..value = 1234
            ..nValue = 55,
          ShortModel(1)..value = 444,
          ShortModel(2)
            ..value = 321321
            ..nValue = 1,
        ]),
      );

      expect(
        isar.shortModels.where().valueProperty().findAll(),
        [1234, 444, 321321],
      );

      expect(
        isar.shortModels.where().nValueProperty().findAll(),
        [55, null, 1],
      );
    });

    isarTest('int property', () {
      isar.write(
        (isar) => isar.intModels.putAll([
          IntModel(0)
            ..value = -5
            ..nValue = -99999,
          IntModel(1)
            ..value = -9999
            ..nValue = 0,
          IntModel(2)..value = 9999,
        ]),
      );

      expect(
        isar.intModels.where().valueProperty().findAll(),
        [-5, -9999, 9999],
      );

      expect(
        isar.intModels.where().nValueProperty().findAll(),
        [-99999, 0, null],
      );
    });

    isarTest('float property', () {
      isar.write(
        (isar) => isar.floatModels.putAll([
          FloatModel(0)
            ..value = -5.5
            ..nValue = double.infinity,
          FloatModel(1)..value = 70.7,
          FloatModel(2)
            ..value = double.nan
            ..nValue = double.negativeInfinity,
        ]),
      );

      expect(
        listEquals(
          isar.floatModels.where().valueProperty().findAll(),
          [-5.5, 70.7, double.nan],
        ),
        true,
      );

      expect(
        listEquals(
          isar.floatModels.where().nValueProperty().findAll(),
          [double.infinity, null, double.negativeInfinity],
        ),
        true,
      );
    });

    isarTest('double property', () {
      isar.write(
        (isar) => isar.doubleModels.putAll([
          DoubleModel(0)
            ..value = -5.5
            ..nValue = double.infinity,
          DoubleModel(1)..value = 70.7,
          DoubleModel(2)
            ..value = double.nan
            ..nValue = double.negativeInfinity,
        ]),
      );

      expect(
        listEquals(
          isar.doubleModels.where().valueProperty().findAll(),
          [-5.5, 70.7, double.nan],
        ),
        true,
      );

      expect(
        isar.doubleModels.where().nValueProperty().findAll(),
        [double.infinity, null, double.negativeInfinity],
      );
    });

    isarTest('DateTime property', () {
      isar.write(
        (isar) => isar.dateTimeModels.putAll([
          DateTimeModel(0)..value = DateTime(2022),
          DateTimeModel(1)
            ..value = DateTime(2020)
            ..nValue = DateTime(2010),
          DateTimeModel(2)..value = DateTime(1999),
        ]),
      );

      expect(
        isar.dateTimeModels.where().valueProperty().findAll(),
        [DateTime(2022), DateTime(2020), DateTime(1999)],
      );

      expect(
        isar.dateTimeModels.where().nValueProperty().findAll(),
        [null, DateTime(2010), null],
      );
    });

    isarTest('String property', () {
      isar.write(
        (isar) => isar.stringModels.putAll([
          StringModel(0)
            ..value = 'Just'
            ..nValue = 'A',
          StringModel(1)..value = 'a',
          StringModel(2)
            ..value = 'test'
            ..nValue = 'Z',
        ]),
      );

      expect(
        isar.stringModels.where().valueProperty().findAll(),
        ['Just', 'a', 'test'],
      );

      expect(
        isar.stringModels.where().nValueProperty().findAll(),
        ['A', null, 'Z'],
      );
    });

    isarTest('Object property', () {
      isar.write(
        (isar) => isar.objectModels.putAll([
          ObjectModel(0)
            ..value = EmbeddedModel('E1')
            ..nValue = EmbeddedModel('XXX'),
          ObjectModel(1)
            ..value = EmbeddedModel('E2')
            ..nValue = EmbeddedModel('YYY'),
          ObjectModel(2)..value = EmbeddedModel('E3'),
        ]),
      );

      expect(
        isar.objectModels.where().valueProperty().findAll(),
        [EmbeddedModel('E1'), EmbeddedModel('E2'), EmbeddedModel('E3')],
      );

      expect(
        isar.objectModels.where().nValueProperty().findAll(),
        [EmbeddedModel('XXX'), EmbeddedModel('YYY'), null],
      );
    });

    isarTest('Enum property', () {
      isar.write(
        (isar) => isar.enumModels.putAll([
          EnumModel(0)..value = TestEnum.option2,
          EnumModel(1)
            ..value = TestEnum.option3
            ..nValue = TestEnum.option3,
          EnumModel(2)..value = TestEnum.option2,
        ]),
      );

      expect(
        isar.enumModels.where().valueProperty().findAll(),
        [TestEnum.option2, TestEnum.option3, TestEnum.option2],
      );

      expect(
        isar.enumModels.where().nValueProperty().findAll(),
        [null, TestEnum.option3, null],
      );
    });

    isarTest('bool list property', () {
      isar.write(
        (isar) => isar.boolModels.putAll([
          BoolModel(0)
            ..list = [true, false, true]
            ..nList = [false],
          BoolModel(1)..list = [],
          BoolModel(2)
            ..list = [true]
            ..nList = [],
        ]),
      );

      expect(isar.boolModels.where().listProperty().findAll(), [
        [true, false, true],
        <bool>[],
        [true],
      ]);

      expect(isar.boolModels.where().nListProperty().findAll(), [
        [false],
        null,
        <bool>[],
      ]);
    });

    isarTest('byte list property', () {
      isar.write(
        (isar) => isar.byteModels.putAll([
          ByteModel(0)..list = Uint8List.fromList([0, 10, 255]),
          ByteModel(1)
            ..list = []
            ..nList = [1, 2, 3, 4, 5],
          ByteModel(2)..list = [3],
        ]),
      );

      expect(
        isar.byteModels.where().listProperty().findAll(),
        [
          Uint8List.fromList([0, 10, 255]),
          Uint8List.fromList([]),
          Uint8List.fromList([3]),
        ],
      );

      expect(
        isar.byteModels.where().nListProperty().findAll(),
        [
          null,
          Uint8List.fromList([1, 2, 3, 4, 5]),
          null,
        ],
      );
    });

    isarTest('short list property', () {
      isar.write(
        (isar) => isar.shortModels.putAll([
          ShortModel(0)
            ..list = [-5, 70, 999]
            ..nList = [],
          ShortModel(1)
            ..list = []
            ..nList = [1, 2, 3],
          ShortModel(2)..list = [0],
        ]),
      );

      expect(isar.shortModels.where().listProperty().findAll(), [
        [-5, 70, 999],
        <int>[],
        [0],
      ]);

      expect(isar.shortModels.where().nListProperty().findAll(), [
        <int>[],
        [1, 2, 3],
        null,
      ]);
    });

    isarTest('int list property', () {
      isar.write(
        (isar) => isar.intModels.putAll([
          IntModel(0)
            ..list = [-5, 70, 999]
            ..nList = [],
          IntModel(1)
            ..list = []
            ..nList = [1, 2, 3],
          IntModel(2)..list = [0],
        ]),
      );

      expect(isar.intModels.where().listProperty().findAll(), [
        [-5, 70, 999],
        <int>[],
        [0],
      ]);

      expect(isar.intModels.where().nListProperty().findAll(), [
        <int>[],
        [1, 2, 3],
        null,
      ]);
    });

    isarTest('float list property', () {
      isar.write(
        (isar) => isar.floatModels.putAll([
          FloatModel(0)
            ..list = [-5.5, 70.7, 999.999]
            ..nList = [1919191],
          FloatModel(1)..list = [],
          FloatModel(2)
            ..list = [0.0]
            ..nList = [-1919191],
        ]),
      );

      expect(
        listEquals(
          isar.floatModels.where().listProperty().findAll(),
          [
            [-5.5, 70.7, 999.999],
            <double>[],
            [0.0],
          ],
        ),
        true,
      );

      expect(
        listEquals(
          isar.floatModels.where().nListProperty().findAll(),
          [
            [1919191],
            null,
            [-1919191],
          ],
        ),
        true,
      );
    });

    isarTest('double list property', () {
      isar.write(
        (isar) => isar.doubleModels.putAll([
          DoubleModel(0)
            ..list = [-5.5, 70.7, 999.999]
            ..nList = [1919191.1919191],
          DoubleModel(1)..list = [],
          DoubleModel(2)
            ..list = [0.0]
            ..nList = [double.maxFinite],
        ]),
      );

      expect(isar.doubleModels.where().listProperty().findAll(), [
        [-5.5, 70.7, 999.999],
        <double>[],
        [0.0],
      ]);

      expect(isar.doubleModels.where().nListProperty().findAll(), [
        [1919191.1919191],
        null,
        [double.maxFinite],
      ]);
    });

    isarTest('DateTime list property', () {
      isar.write(
        (isar) => isar.dateTimeModels.putAll([
          DateTimeModel(0)
            ..list = [DateTime(2019), DateTime(2020)]
            ..nList = [DateTime(2000), DateTime(2001)],
          DateTimeModel(1)
            ..list = [DateTime(2020)]
            ..nList = [DateTime(2000)],
          DateTimeModel(2)..list = [],
        ]),
      );

      expect(isar.dateTimeModels.where().listProperty().findAll(), [
        [DateTime(2019), DateTime(2020)],
        [DateTime(2020)],
        <DateTime>[],
      ]);

      expect(isar.dateTimeModels.where().nListProperty().findAll(), [
        [DateTime(2000), DateTime(2001)],
        [DateTime(2000)],
        null,
      ]);
    });

    isarTest('String list property', () {
      isar.write(
        (isar) => isar.stringModels.putAll([
          StringModel(0)..list = ['Just', 'a', 'test'],
          StringModel(1)..list = [],
          StringModel(2)
            ..list = ['']
            ..nList = ['HELLO'],
        ]),
      );

      expect(
        isar.stringModels.where().listProperty().findAll(),
        [
          ['Just', 'a', 'test'],
          <String>[],
          [''],
        ],
      );

      expect(
        isar.stringModels.where().nListProperty().findAll(),
        [
          null,
          null,
          ['HELLO'],
        ],
      );
    });

    isarTest('Object list property', () {
      isar.write(
        (isar) => isar.objectModels.putAll([
          ObjectModel(0)
            ..list = []
            ..nList = [EmbeddedModel('abc'), EmbeddedModel('def')],
          ObjectModel(1)..list = [EmbeddedModel('abc'), EmbeddedModel('def')],
          ObjectModel(2)
            ..list = [EmbeddedModel()]
            ..nList = [EmbeddedModel()],
        ]),
      );

      expect(
        isar.objectModels.where().listProperty().findAll(),
        [
          <EmbeddedModel>[],
          [EmbeddedModel('abc'), EmbeddedModel('def')],
          [EmbeddedModel()],
        ],
      );

      expect(
        isar.objectModels.where().nListProperty().findAll(),
        [
          [EmbeddedModel('abc'), EmbeddedModel('def')],
          null,
          [EmbeddedModel()],
        ],
      );
    });

    isarTest('Enum list property', () {
      isar.write(
        (isar) => isar.enumModels.putAll([
          EnumModel(0)
            ..list = [TestEnum.option2]
            ..nList = [TestEnum.option2, TestEnum.option3],
          EnumModel(1)..list = [TestEnum.option1],
          EnumModel(2)..list = [],
        ]),
      );

      expect(
        isar.enumModels.where().listProperty().findAll(),
        [
          [TestEnum.option2],
          [TestEnum.option1],
          <TestEnum>[],
        ],
      );

      expect(
        isar.enumModels.where().nListProperty().findAll(),
        [
          [TestEnum.option2, TestEnum.option3],
          null,
          null,
        ],
      );
    });
  });
}
