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

  final MyEmbedded? embeddedValue;

  final MyEnum? enumValue;
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

  final List<MyEmbedded>? embeddedValue;

  final List<MyEnum>? enumValue;
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
      expect(
        isar2.nullableModels.where().boolValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableModels.where().shortValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableModels.where().intValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableModels.where().floatValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableModels.where().doubleValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableModels.where().dateTimeValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableModels.where().stringValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableModels.where().embeddedValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableModels.where().enumValueProperty().findFirst(),
        null,
      );
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
    });

    isarTest('list property', web: false, () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      isar1.write((isar) => isar.emptyModels.put(emptyObj));
      final isarName = isar1.name;
      isar1.close();

      final isar2 =
          await openTempIsar([NullableListModelSchema], name: isarName);
      expect(
        isar2.nullableListModels.where().boolValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableListModels.where().shortValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableListModels.where().intValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableListModels.where().floatValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableListModels.where().doubleValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableListModels.where().dateTimeValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableListModels.where().stringValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableListModels.where().embeddedValueProperty().findFirst(),
        null,
      );
      expect(
        isar2.nullableListModels.where().enumValueProperty().findFirst(),
        null,
      );
    });
  });
}
