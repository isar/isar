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
    this.embeddedValue = const MyEmbedded('abc'),
  ]);

  final int id;

  final bool boolValue;

  final byte byteValue;

  final short shortValue;

  final int intValue;

  final float floatValue;

  final double doubleValue;

  final String stringValue;

  final MyEmbedded embeddedValue;
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
    this.embeddedValue = const [null, MyEmbedded('test')],
  ]);

  final int id;

  final List<bool?> boolValue;

  final List<byte> byteValue;

  final List<short?> shortValue;

  final List<int?> intValue;

  final List<float?> floatValue;

  final List<double?> doubleValue;

  final List<String?> stringValue;

  final List<MyEmbedded?> embeddedValue;
}

void main() {
  group('Default value', () {
    isarTest('scalar', () {
      final emptyObj = EmptyModel(0);
      final isar1 = openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar1.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 = openTempIsar([DefaultModelSchema], name: isarName);
      final obj = isar2.defaultModels.get(0)!;
      expect(obj.boolValue, true);
      expect(obj.byteValue, 55);
      expect(obj.shortValue, 123);
      expect(obj.intValue, 1234);
      expect(obj.floatValue, 5.2);
      expect(obj.doubleValue, 10.10);
      expect(obj.stringValue, 'hello');
      expect(obj.embeddedValue, const MyEmbedded('abc'));
    });

    isarTest('scalar property', () {
      final emptyObj = EmptyModel(0);
      final isar1 = openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 = openTempIsar([DefaultModelSchema], name: isarName);
      expect(
        isar2.defaultModels.where().boolValueProperty().findFirst(),
        true,
      );
      expect(
        isar2.defaultModels.where().byteValueProperty().findFirst(),
        55,
      );
      expect(
        isar2.defaultModels.where().shortValueProperty().findFirst(),
        123,
      );
      expect(
        isar2.defaultModels.where().intValueProperty().findFirst(),
        1234,
      );
      expect(
        isar2.defaultModels.where().floatValueProperty().findFirst(),
        5.2,
      );
      expect(
        isar2.defaultModels.where().doubleValueProperty().findFirst(),
        10.10,
      );
      expect(
        isar2.defaultModels.where().stringValueProperty().findFirst(),
        'hello',
      );
      expect(
        isar2.defaultModels.where().embeddedValueProperty().findFirst(),
        const MyEmbedded('abc'),
      );
    });

    isarTest('list', () {
      final emptyObj = EmptyModel(0);
      final isar1 = openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 = openTempIsar([DefaultListModelSchema], name: isarName);
      final obj = isar2.defaultListModels.get(0)!;
      expect(obj.boolValue, [true, false]);
      expect(obj.byteValue, [1, 3]);
      expect(obj.shortValue, [null, 23, 34]);
      expect(obj.intValue, [123, 234, null]);
      expect(obj.floatValue, [5.5, null]);
      expect(obj.doubleValue, [null, 10.10]);
      expect(obj.stringValue, ['abc', null, 'def']);
      expect(obj.embeddedValue, [null, const MyEmbedded('test')]);
    });

    isarTest('list property', () {
      final emptyObj = EmptyModel(0);
      final isar1 = openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar1.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 = openTempIsar([DefaultListModelSchema], name: isarName);
      expect(
        isar2.defaultListModels.where().boolValueProperty().findFirst(),
        [true, false],
      );
      expect(
        isar2.defaultListModels.where().byteValueProperty().findFirst(),
        [1, 3],
      );
      expect(
        isar2.defaultListModels.where().shortValueProperty().findFirst(),
        [null, 23, 34],
      );
      expect(
        isar2.defaultListModels.where().intValueProperty().findFirst(),
        [123, 234, null],
      );
      expect(
        isar2.defaultListModels.where().floatValueProperty().findFirst(),
        [5.5, null],
      );
      expect(
        isar2.defaultListModels.where().doubleValueProperty().findFirst(),
        [null, 10.10],
      );
      expect(
        isar2.defaultListModels.where().stringValueProperty().findFirst(),
        ['abc', null, 'def'],
      );
      expect(
        isar2.defaultListModels.where().embeddedValueProperty().findFirst(),
        [null, const MyEmbedded('test')],
      );
    });
  });
}
