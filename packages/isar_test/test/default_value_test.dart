import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'default_value_test.g.dart';

enum MyEnum with IsarEnum<String> {
  value1,
  value2,
  value3;

  @override
  String get isarValue => name;
}

@Embedded()
class MyEmbedded {
  const MyEmbedded([this.test = '']);

  final String test;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) => other is MyEmbedded && other.test == test;
}

@Name('Col')
@Collection()
class EmptyModel {
  EmptyModel(this.id);

  final Id id;
}

@Name('Col')
@Collection()
class Model {
  Model(
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

  final MyEnum enumValue;
}

@Name('Col')
@Collection()
class ListModel {
  ListModel(
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

  final List<MyEnum?> enumValue;
}

@Name('Col')
@Collection()
class ModelWithDefaults {
  ModelWithDefaults(
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
@Collection()
class ListModelWithDefaults {
  ListModelWithDefaults(
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
    isarTest('No default value', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 = await openTempIsar([ModelSchema], name: isarName);
      final obj = (await isar2.models.tGet(0))!;
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
      await isar2.close();
    });

    isarTest('No default list value', () async {
      final emptyObj = EmptyModel(0);
      final isar1 = await openTempIsar([EmptyModelSchema]);
      await isar1.tWriteTxn(() => isar1.emptyModels.tPut(emptyObj));
      final isarName = isar1.name;
      await isar1.close();

      final isar2 = await openTempIsar([ListModelSchema], name: isarName);
      final obj = (await isar2.listModels.tGet(0))!;
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
      await isar2.close();
    });
  });
}
