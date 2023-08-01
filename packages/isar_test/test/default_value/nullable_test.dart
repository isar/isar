import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

import 'common.dart';

part 'nullable_test.g.dart';

@Name('Col')
@collection
class NullableModel {
  NullableModel(
    this.id,
    this.boolValue,
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

  final bool? boolValue;

  final short? shortValue;

  final int? intValue;

  final float? floatValue;

  final double? doubleValue;

  final DateTime? dateTimeValue;

  final String? stringValue;

  final MyEnum? enumValue;

  final MyEmbedded? embeddedValue;
}

@Name('Col')
@collection
class NullableListModel {
  NullableListModel(
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
    this.jsonValue,
    this.jsonObjectValue,
  );

  final int id;

  final List<bool>? boolValue;

  final List<byte>? byteValue;

  final List<short>? shortValue;

  final List<int>? intValue;

  final List<float>? floatValue;

  final List<double>? doubleValue;

  final List<DateTime>? dateTimeValue;

  final List<String>? stringValue;

  final List<MyEnum>? enumValue;

  final List<MyEmbedded>? embeddedValue;

  final List<dynamic>? jsonValue;

  final Map<String, dynamic>? jsonObjectValue;
}

void main() {
  group('Nullable value', () {
    isarTest('scalar', web: false, () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 = await openTempIsar([NullableModelSchema], name: isarName);
      final obj = isar2.nullableModels.get(0)!;
      expect(obj.boolValue, null);
      expect(obj.shortValue, null);
      expect(obj.intValue, null);
      expect(obj.floatValue, null);
      expect(obj.doubleValue, null);
      expect(obj.dateTimeValue, null);
      expect(obj.stringValue, null);
      expect(obj.embeddedValue, null);
      expect(obj.enumValue, null);
    });

    isarTest('scalar property', web: false, () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 = await openTempIsar([NullableModelSchema], name: isarName);
      final col = isar2.nullableModels;
      expect(col.where().boolValueProperty().findFirst(), null);
      expect(col.where().shortValueProperty().findFirst(), null);
      expect(col.where().intValueProperty().findFirst(), null);
      expect(col.where().floatValueProperty().findFirst(), null);
      expect(col.where().doubleValueProperty().findFirst(), null);
      expect(col.where().dateTimeValueProperty().findFirst(), null);
      expect(col.where().stringValueProperty().findFirst(), null);
      expect(col.where().embeddedValueProperty().findFirst(), null);
      expect(col.where().enumValueProperty().findFirst(), null);
    });

    isarTest('list', web: false, () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 =
          await openTempIsar([NullableListModelSchema], name: isarName);
      final obj = isar2.nullableListModels.get(0)!;
      expect(obj.boolValue, null);
      expect(obj.shortValue, null);
      expect(obj.intValue, null);
      expect(obj.floatValue, null);
      expect(obj.doubleValue, null);
      expect(obj.dateTimeValue, null);
      expect(obj.stringValue, null);
      expect(obj.embeddedValue, null);
      expect(obj.enumValue, null);
      expect(obj.jsonValue, null);
      expect(obj.jsonObjectValue, null);
    });

    isarTest('list property', web: false, () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 =
          await openTempIsar([NullableListModelSchema], name: isarName);
      final col = isar2.nullableListModels;
      expect(col.where().boolValueProperty().findFirst(), null);
      expect(col.where().shortValueProperty().findFirst(), null);
      expect(col.where().intValueProperty().findFirst(), null);
      expect(col.where().floatValueProperty().findFirst(), null);
      expect(col.where().doubleValueProperty().findFirst(), null);
      expect(col.where().dateTimeValueProperty().findFirst(), null);
      expect(col.where().stringValueProperty().findFirst(), null);
      expect(col.where().embeddedValueProperty().findFirst(), null);
      expect(col.where().enumValueProperty().findFirst(), null);
      expect(col.where().jsonValueProperty().findFirst(), null);
      expect(col.where().jsonObjectValueProperty().findFirst(), null);
    });
  });
}
