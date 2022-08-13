import 'package:test/test.dart';
import 'package:isar/isar.dart';

import 'util/common.dart';

part 'enum_test.g.dart';

enum ByteEnum with IsarEnum<byte> {
  byte1,
  byte2;

  @override
  byte get value => index;
}

@Collection()
class ByteEnumModel {
  Id? id;

  late ByteEnum value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is ByteEnumModel && other.id == id && other.value == value;
}

enum StringEnum with IsarEnum<String> {
  option1,
  option2,
  option3;

  @override
  String get value => name;
}

enum StringEnum2 with IsarEnum<String> {
  option1,
  option3;

  @override
  String get value => name;
}

@Collection()
class StringEnumModel {
  Id? id;

  late StringEnum value;

  StringEnum? nValue;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is StringEnumModel &&
      other.id == id &&
      other.value == value &&
      other.nValue == nValue;
}

@Collection()
@Name('StringEnumModel')
class StringEnumModel2 {
  Id? id;

  late StringEnum value;

  StringEnum? nValue;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is StringEnumModel2 &&
      other.id == id &&
      other.value == value &&
      other.nValue == nValue;
}

enum DateTimeEnum with IsarEnum<DateTime> {
  option1,
  option2,
  option3;

  @override
  DateTime get value => DateTime(2000 + index);
}

@Collection()
class DateEnumModel {
  Id? id;

  DateTimeEnum? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is DateEnumModel && other.id == id && other.value == value;
}

void main() {
  group('Enum', () {
    isarTest('Byte Enum', () {});

    isarTest('String Enum', () {});

    isarTest('DateTime Enum', () {});

    isarTest('Added value', () {});

    isarTest('Removed value', () {});

    isarTest('.exportJson()', () {});

    isarTest('.importJson()', () {});
  });
}
