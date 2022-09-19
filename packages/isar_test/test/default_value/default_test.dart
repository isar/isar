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

  final Id id;

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

  final Id id;

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
    isarTest('scalar', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 = await openTempIsar([DefaultModelSchema], name: isarName);
      final obj = (await isar2.defaultModels.tGet(0))!;
      expect(obj.boolValue, true);
      expect(obj.byteValue, 55);
      expect(obj.shortValue, 123);
      expect(obj.intValue, 1234);
      expect(obj.floatValue, 5.2);
      expect(obj.doubleValue, 10.10);
      expect(obj.stringValue, 'hello');
      expect(obj.embeddedValue, const MyEmbedded('abc'));
    });

    isarTest('scalar property', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 = await openTempIsar([DefaultModelSchema], name: isarName);
      expect(
        await isar2.defaultModels.where().boolValueProperty().tFindFirst(),
        true,
      );
      expect(
        await isar2.defaultModels.where().byteValueProperty().tFindFirst(),
        55,
      );
      expect(
        await isar2.defaultModels.where().shortValueProperty().tFindFirst(),
        123,
      );
      expect(
        await isar2.defaultModels.where().intValueProperty().tFindFirst(),
        1234,
      );
      expect(
        await isar2.defaultModels.where().floatValueProperty().tFindFirst(),
        5.2,
      );
      expect(
        await isar2.defaultModels.where().doubleValueProperty().tFindFirst(),
        10.10,
      );
      expect(
        await isar2.defaultModels.where().stringValueProperty().tFindFirst(),
        'hello',
      );
      expect(
        await isar2.defaultModels.where().embeddedValueProperty().tFindFirst(),
        const MyEmbedded('abc'),
      );
    });

    isarTest('list', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 =
          await openTempIsar([DefaultListModelSchema], name: isarName);
      final obj = (await isar2.defaultListModels.tGet(0))!;
      expect(obj.boolValue, [true, false]);
      expect(obj.byteValue, [1, 3]);
      expect(obj.shortValue, [null, 23, 34]);
      expect(obj.intValue, [123, 234, null]);
      expect(obj.floatValue, [5.5, null]);
      expect(obj.doubleValue, [null, 10.10]);
      expect(obj.stringValue, ['abc', null, 'def']);
      expect(obj.embeddedValue, [null, const MyEmbedded('test')]);
    });

    isarTest('list property', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 =
          await openTempIsar([DefaultListModelSchema], name: isarName);
      expect(
        await isar2.defaultListModels.where().boolValueProperty().tFindFirst(),
        [true, false],
      );
      expect(
        await isar2.defaultListModels.where().byteValueProperty().tFindFirst(),
        [1, 3],
      );
      expect(
        await isar2.defaultListModels.where().shortValueProperty().tFindFirst(),
        [null, 23, 34],
      );
      expect(
        await isar2.defaultListModels.where().intValueProperty().tFindFirst(),
        [123, 234, null],
      );
      expect(
        await isar2.defaultListModels.where().floatValueProperty().tFindFirst(),
        [5.5, null],
      );
      expect(
        await isar2.defaultListModels
            .where()
            .doubleValueProperty()
            .tFindFirst(),
        [null, 10.10],
      );
      expect(
        await isar2.defaultListModels
            .where()
            .stringValueProperty()
            .tFindFirst(),
        ['abc', null, 'def'],
      );
      expect(
        await isar2.defaultListModels
            .where()
            .embeddedValueProperty()
            .tFindFirst(),
        [null, const MyEmbedded('test')],
      );
    });
  });
}
