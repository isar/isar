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

  final Id id;

  final bool boolValue;

  final byte byteValue;

  final short shortValue;

  final int intValue;

  final float floatValue;

  final double doubleValue;

  final DateTime dateTimeValue;

  final String stringValue;

  final MyEmbedded embeddedValue;

  @Enumerated(EnumType.name)
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

  final Id id;

  final List<bool?> boolValue;

  final List<byte> byteValue;

  final List<short?> shortValue;

  final List<int?> intValue;

  final List<float?> floatValue;

  final List<double?> doubleValue;

  final List<DateTime?> dateTimeValue;

  final List<String?> stringValue;

  final List<MyEmbedded?> embeddedValue;

  @Enumerated(EnumType.name)
  final List<MyEnum?> enumValue;
}

void main() {
  group('No default value', () {
    isarTest('scalar', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 = await openTempIsar([NoDefaultModelSchema], name: isarName);
      final obj = (await isar2.noDefaultModels.tGet(0))!;
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

    isarTest('scalar property', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 = await openTempIsar([NoDefaultModelSchema], name: isarName);
      expect(
        await isar2.noDefaultModels.where().boolValueProperty().tFindFirst(),
        false,
      );
      expect(
        await isar2.noDefaultModels.where().byteValueProperty().tFindFirst(),
        0,
      );
      expect(
        await isar2.noDefaultModels.where().shortValueProperty().tFindFirst(),
        -2147483648,
      );
      expect(
        await isar2.noDefaultModels.where().intValueProperty().tFindFirst(),
        -9223372036854775808,
      );
      expect(
        await isar2.noDefaultModels.where().floatValueProperty().tFindFirst(),
        isNaN,
      );
      expect(
        await isar2.noDefaultModels.where().doubleValueProperty().tFindFirst(),
        isNaN,
      );
      expect(
        await isar2.noDefaultModels
            .where()
            .dateTimeValueProperty()
            .tFindFirst(),
        DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(
        await isar2.noDefaultModels.where().stringValueProperty().tFindFirst(),
        '',
      );
      expect(
        await isar2.noDefaultModels
            .where()
            .embeddedValueProperty()
            .tFindFirst(),
        const MyEmbedded(),
      );
      expect(
        await isar2.noDefaultModels.where().enumValueProperty().tFindFirst(),
        MyEnum.value1,
      );
    });

    isarTest('list', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 =
          await openTempIsar([NoDefaultListModelSchema], name: isarName);
      final obj = (await isar2.noDefaultListModels.tGet(0))!;
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

    isarTest('list property', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 =
          await openTempIsar([NoDefaultListModelSchema], name: isarName);
      expect(
        await isar2.noDefaultListModels
            .where()
            .boolValueProperty()
            .tFindFirst(),
        isEmpty,
      );
      expect(
        await isar2.noDefaultListModels
            .where()
            .byteValueProperty()
            .tFindFirst(),
        isEmpty,
      );
      expect(
        await isar2.noDefaultListModels
            .where()
            .shortValueProperty()
            .tFindFirst(),
        isEmpty,
      );
      expect(
        await isar2.noDefaultListModels.where().intValueProperty().tFindFirst(),
        isEmpty,
      );
      expect(
        await isar2.noDefaultListModels
            .where()
            .floatValueProperty()
            .tFindFirst(),
        isEmpty,
      );
      expect(
        await isar2.noDefaultListModels
            .where()
            .doubleValueProperty()
            .tFindFirst(),
        isEmpty,
      );
      expect(
        await isar2.noDefaultListModels
            .where()
            .dateTimeValueProperty()
            .tFindFirst(),
        isEmpty,
      );
      expect(
        await isar2.noDefaultListModels
            .where()
            .stringValueProperty()
            .tFindFirst(),
        isEmpty,
      );
      expect(
        await isar2.noDefaultListModels
            .where()
            .embeddedValueProperty()
            .tFindFirst(),
        isEmpty,
      );
      expect(
        await isar2.noDefaultListModels
            .where()
            .enumValueProperty()
            .tFindFirst(),
        isEmpty,
      );
    });
  });
}
