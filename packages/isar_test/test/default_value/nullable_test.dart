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

  final Id id;

  final bool? boolValue;

  final short? shortValue;

  final int? intValue;

  final float? floatValue;

  final double? doubleValue;

  final DateTime? dateTimeValue;

  final String? stringValue;

  final MyEmbedded? embeddedValue;

  @Enumerated(EnumType.name)
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

  final Id id;

  final List<bool>? boolValue;

  final List<byte>? byteValue;

  final List<short>? shortValue;

  final List<int>? intValue;

  final List<float>? floatValue;

  final List<double>? doubleValue;

  final List<DateTime>? dateTimeValue;

  final List<String>? stringValue;

  final List<MyEmbedded>? embeddedValue;

  @enumerated
  final List<MyEnum>? enumValue;
}

void main() {
  group('Nullable value', () {
    isarTest('scalar', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 = await openTempIsar([NullableModelSchema], name: isarName);
      final obj = (await isar2.nullableModels.tGet(0))!;
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

    isarTest('scalar property', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 = await openTempIsar([NullableModelSchema], name: isarName);
      expect(
        await isar2.nullableModels.where().boolValueProperty().tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableModels.where().shortValueProperty().tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableModels.where().intValueProperty().tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableModels.where().floatValueProperty().tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableModels.where().doubleValueProperty().tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableModels.where().dateTimeValueProperty().tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableModels.where().stringValueProperty().tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableModels.where().embeddedValueProperty().tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableModels.where().enumValueProperty().tFindFirst(),
        null,
      );
    });

    isarTest('list', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 =
          await openTempIsar([NullableListModelSchema], name: isarName);
      final obj = (await isar2.nullableListModels.tGet(0))!;
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

    isarTest('list property', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 =
          await openTempIsar([NullableListModelSchema], name: isarName);
      expect(
        await isar2.nullableListModels.where().boolValueProperty().tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableListModels
            .where()
            .shortValueProperty()
            .tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableListModels.where().intValueProperty().tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableListModels
            .where()
            .floatValueProperty()
            .tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableListModels
            .where()
            .doubleValueProperty()
            .tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableListModels
            .where()
            .dateTimeValueProperty()
            .tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableListModels
            .where()
            .stringValueProperty()
            .tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableListModels
            .where()
            .embeddedValueProperty()
            .tFindFirst(),
        null,
      );
      expect(
        await isar2.nullableListModels.where().enumValueProperty().tFindFirst(),
        null,
      );
    });
  });
}
