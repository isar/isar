// ignore_for_file: avoid_positional_boolean_parameters

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

import 'common.dart';

part 'default_test.g.dart';

@Name('Col')
@collection
class DefaultModel {
  DefaultModel(
    this.id, [
    this.boolValue = true,
    this.byteValue = 55,
    this.shortValue = 123,
    this.intValue = 1234,
    this.floatValue = 5.2,
    this.doubleValue = 10.10,
    this.stringValue = 'hello',
    this.enumValue = MyEnum.value2,
    this.embeddedValue = const MyEmbedded('abc'),
    this.jsonValue = const {'a': 1, 'b': '2'},
  ]);

  final int id;

  final bool boolValue;

  final byte byteValue;

  final short shortValue;

  final int intValue;

  final float floatValue;

  final double doubleValue;

  final String stringValue;

  final MyEnum enumValue;

  final MyEmbedded embeddedValue;

  final dynamic jsonValue;
}

@Name('Col')
@collection
class DefaultListModel {
  DefaultListModel(
    this.id, [
    this.boolValue = const [true, false],
    this.byteValue = const [1, 3],
    this.shortValue = const [null, 23, 34],
    this.intValue = const [123, 234, null],
    this.floatValue = const [5.5, null],
    this.doubleValue = const [null, 10.10],
    this.stringValue = const ['abc', null, 'def'],
    this.enumValue = const [MyEnum.value1, null, MyEnum.value2],
    this.embeddedValue = const [null, MyEmbedded('test')],
    this.jsonValue = const [null, 'a', 33, true],
    this.jsonObjectValue = const {'a': 1, 'b': '2'},
  ]);

  final int id;

  final List<bool?> boolValue;

  final List<byte> byteValue;

  final List<short?> shortValue;

  final List<int?> intValue;

  final List<float?> floatValue;

  final List<double?> doubleValue;

  final List<String?> stringValue;

  final List<MyEnum?> enumValue;

  final List<MyEmbedded?> embeddedValue;

  final List<dynamic> jsonValue;

  final Map<String, dynamic> jsonObjectValue;
}

void main() {
  group('Default value', () {
    isarTest('scalar', web: false, () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar1.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 = await openTempIsar([DefaultModelSchema], name: isarName);
      final obj = isar2.defaultModels.get(0)!;
      expect(obj.boolValue, true);
      expect(obj.byteValue, 55);
      expect(obj.shortValue, 123);
      expect(obj.intValue, 1234);
      expect(obj.floatValue, 5.2);
      expect(obj.doubleValue, 10.10);
      expect(obj.stringValue, 'hello');
      expect(obj.enumValue, MyEnum.value2);
      expect(obj.embeddedValue, const MyEmbedded('abc'));
      expect(obj.jsonValue, const {'a': 1, 'b': '2'});
    });

    isarTest('scalar property', web: false, () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 = await openTempIsar([DefaultModelSchema], name: isarName);
      final col = isar2.defaultModels;
      expect(col.where().boolValueProperty().findFirst(), true);
      expect(col.where().byteValueProperty().findFirst(), 55);
      expect(col.where().shortValueProperty().findFirst(), 123);
      expect(col.where().intValueProperty().findFirst(), 1234);
      expect(col.where().floatValueProperty().findFirst(), 5.2);
      expect(col.where().doubleValueProperty().findFirst(), 10.10);
      expect(col.where().stringValueProperty().findFirst(), 'hello');
      expect(col.where().enumValueProperty().findFirst(), MyEnum.value2);
      expect(
        col.where().embeddedValueProperty().findFirst(),
        const MyEmbedded('abc'),
      );
      expect(
        col.where().jsonValueProperty().findFirst(),
        const {'a': 1, 'b': '2'},
      );
    });

    isarTest('list', web: false, () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 =
          await openTempIsar([DefaultListModelSchema], name: isarName);
      final obj = isar2.defaultListModels.get(0)!;
      expect(obj.boolValue, [true, false]);
      expect(obj.byteValue, [1, 3]);
      expect(obj.shortValue, [null, 23, 34]);
      expect(obj.intValue, [123, 234, null]);
      expect(obj.floatValue, [5.5, null]);
      expect(obj.doubleValue, [null, 10.10]);
      expect(obj.stringValue, ['abc', null, 'def']);
      expect(obj.enumValue, [MyEnum.value1, null, MyEnum.value2]);
      expect(obj.embeddedValue, [null, const MyEmbedded('test')]);
      expect(obj.jsonValue, [null, 'a', 33, true]);
      expect(obj.jsonObjectValue, {'a': 1, 'b': '2'});
    });

    isarTest('list property', web: false, () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar1.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 =
          await openTempIsar([DefaultListModelSchema], name: isarName);
      final col = isar2.defaultListModels;
      expect(col.where().boolValueProperty().findFirst(), [true, false]);
      expect(col.where().byteValueProperty().findFirst(), [1, 3]);
      expect(col.where().shortValueProperty().findFirst(), [null, 23, 34]);
      expect(col.where().intValueProperty().findFirst(), [123, 234, null]);
      expect(col.where().floatValueProperty().findFirst(), [5.5, null]);
      expect(col.where().doubleValueProperty().findFirst(), [null, 10.10]);
      expect(
        col.where().stringValueProperty().findFirst(),
        ['abc', null, 'def'],
      );
      expect(
        col.where().enumValueProperty().findFirst(),
        [MyEnum.value1, null, MyEnum.value2],
      );
      expect(
        col.where().embeddedValueProperty().findFirst(),
        [null, const MyEmbedded('test')],
      );
      expect(
        col.where().jsonValueProperty().findFirst(),
        [null, 'a', 33, true],
      );
      expect(
        col.where().jsonObjectValueProperty().findFirst(),
        {'a': 1, 'b': '2'},
      );
    });
  });
}
