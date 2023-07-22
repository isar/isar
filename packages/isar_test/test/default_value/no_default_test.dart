import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

import 'common.dart';

part 'no_default_test.g.dart';

@Name('Col')
@collection
class NoDefaultModel {
  NoDefaultModel(
    this.id,
    this.boolValue,
    this.byteValue,
    this.shortValue,
    this.intValue,
    this.floatValue,
    this.doubleValue,
    this.dateTimeValue,
    this.stringValue,
    this.embeddedValue,
    this.enumValue,
  );

  final int id;

  final bool boolValue;

  final byte byteValue;

  final short shortValue;

  final int intValue;

  final float floatValue;

  final double doubleValue;

  final DateTime dateTimeValue;

  final String stringValue;

  final MyEmbedded embeddedValue;

  final MyEnum enumValue;
}

@Name('Col')
@collection
class NoDefaultListModel {
  NoDefaultListModel(
    this.id,
    this.boolValue,
    this.byteValue,
    this.shortValue,
    this.intValue,
    this.floatValue,
    this.doubleValue,
    this.dateTimeValue,
    this.stringValue,
    this.embeddedValue,
    this.enumValue,
  );

  final int id;

  final List<bool?> boolValue;

  final List<byte> byteValue;

  final List<short?> shortValue;

  final List<int?> intValue;

  final List<float?> floatValue;

  final List<double?> doubleValue;

  final List<DateTime?> dateTimeValue;

  final List<String?> stringValue;

  final List<MyEmbedded?> embeddedValue;

  final List<MyEnum?> enumValue;
}

void main() {
  group('No default value', () {
    isarTest('scalar', () {
      final emptyObj = EmptyModel(0);
      final isar1 = openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 = openTempIsar([NoDefaultModelSchema], name: isarName);
      final obj = isar2.noDefaultModels.get(0)!;
      expect(obj.boolValue, false);
      expect(obj.byteValue, 0);
      expect(obj.shortValue, -2147483648);
      expect(obj.intValue, -9223372036854775808);
      expect(obj.floatValue, isNaN);
      expect(obj.doubleValue, isNaN);
      expect(
        obj.dateTimeValue,
        DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(obj.stringValue, '');
      expect(obj.embeddedValue, const MyEmbedded());
      expect(obj.enumValue, MyEnum.value1);
    });

    isarTest('scalar property', () {
      final emptyObj = EmptyModel(0);
      final isar1 = openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 = openTempIsar([NoDefaultModelSchema], name: isarName);
      expect(
        isar2.noDefaultModels.where().boolValueProperty().findFirst(),
        false,
      );
      expect(
        isar2.noDefaultModels.where().byteValueProperty().findFirst(),
        0,
      );
      expect(
        isar2.noDefaultModels.where().shortValueProperty().findFirst(),
        -2147483648,
      );
      expect(
        isar2.noDefaultModels.where().intValueProperty().findFirst(),
        -9223372036854775808,
      );
      expect(
        isar2.noDefaultModels.where().floatValueProperty().findFirst(),
        isNaN,
      );
      expect(
        isar2.noDefaultModels.where().doubleValueProperty().findFirst(),
        isNaN,
      );
      expect(
        isar2.noDefaultModels.where().dateTimeValueProperty().findFirst(),
        DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(
        isar2.noDefaultModels.where().stringValueProperty().findFirst(),
        '',
      );
      expect(
        isar2.noDefaultModels.where().embeddedValueProperty().findFirst(),
        const MyEmbedded(),
      );
      expect(
        isar2.noDefaultModels.where().enumValueProperty().findFirst(),
        MyEnum.value1,
      );
    });

    isarTest('list', () {
      final emptyObj = EmptyModel(0);
      final isar1 = openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 = openTempIsar([NoDefaultListModelSchema], name: isarName);
      final obj = isar2.noDefaultListModels.get(0)!;
      expect(obj.boolValue, isEmpty);
      expect(obj.byteValue, isEmpty);
      expect(obj.shortValue, isEmpty);
      expect(obj.intValue, isEmpty);
      expect(obj.floatValue, isEmpty);
      expect(obj.doubleValue, isEmpty);
      expect(obj.dateTimeValue, isEmpty);
      expect(obj.stringValue, isEmpty);
      expect(obj.embeddedValue, isEmpty);
      expect(obj.enumValue, isEmpty);
    });

    isarTest('list property', () {
      final emptyObj = EmptyModel(0);
      final isar1 = openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 = openTempIsar([NoDefaultListModelSchema], name: isarName);
      expect(
        isar2.noDefaultListModels.where().boolValueProperty().findFirst(),
        isEmpty,
      );
      expect(
        isar2.noDefaultListModels.where().byteValueProperty().findFirst(),
        isEmpty,
      );
      expect(
        isar2.noDefaultListModels.where().shortValueProperty().findFirst(),
        isEmpty,
      );
      expect(
        isar2.noDefaultListModels.where().intValueProperty().findFirst(),
        isEmpty,
      );
      expect(
        isar2.noDefaultListModels.where().floatValueProperty().findFirst(),
        isEmpty,
      );
      expect(
        isar2.noDefaultListModels.where().doubleValueProperty().findFirst(),
        isEmpty,
      );
      expect(
        isar2.noDefaultListModels.where().dateTimeValueProperty().findFirst(),
        isEmpty,
      );
      expect(
        isar2.noDefaultListModels.where().stringValueProperty().findFirst(),
        isEmpty,
      );
      expect(
        isar2.noDefaultListModels.where().embeddedValueProperty().findFirst(),
        isEmpty,
      );
      expect(
        isar2.noDefaultListModels.where().enumValueProperty().findFirst(),
        isEmpty,
      );
    });
  });
}
