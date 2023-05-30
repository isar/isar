// ignore_for_file: use_string_buffers

import 'package:isar/src/generator/consts.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

String generateSerialize(ObjectInfo object) {
  var code = '''
  @isarProtected
  int serialize${object.dartName}(IsarWriter writer, ${object.dartName} object) {''';

  for (final property in object.properties) {
    if (property.isId && property.type == PropertyType.long) {
      continue;
    }

    code += _writeProperty(
      type: property.type,
      nullable: property.nullable,
      elementNullable: property.elementNullable,
      typeClassName: property.typeClassName,
      value: 'object.${property.dartName}',
      enumProperty: property.enumProperty,
    );
  }

  final idProp = object.idProperty;
  if (idProp != null) {
    if (idProp.type == PropertyType.long) {
      code += 'return object.${idProp.dartName};';
    } else {
      code += 'return Isar.fastHash(object.${idProp.dartName});';
    }
  } else {
    code += 'return 0;';
  }

  return '$code}';
}

String _writeProperty({
  String writer = 'writer',
  required PropertyType type,
  required bool nullable,
  bool? elementNullable,
  required String typeClassName,
  required String value,
  required String? enumProperty,
}) {
  final enumGetter = enumProperty != null
      ? nullable
          ? '?.$enumProperty'
          : '.$enumProperty'
      : '';
  switch (type) {
    case PropertyType.bool:
      if (nullable) {
        return '''
        {
          final value = $value$enumGetter;
          if (value == null) {
            IsarCore.writeNull($writer);
          } else {
            IsarCore.writeBool($writer, value);
          }
        }''';
      } else {
        return 'IsarCore.writeBool($writer, $value$enumGetter);';
      }
    case PropertyType.byte:
      final orNull = nullable ? '?? $nullByte' : '';
      return 'IsarCore.writeByte($writer, $value$enumGetter $orNull);';
    case PropertyType.int:
      final orNull = nullable ? '?? $nullInt' : '';
      return 'IsarCore.writeInt($writer, $value$enumGetter $orNull);';
    case PropertyType.float:
      final orNull = nullable ? '?? double.nan' : '';
      return 'IsarCore.writeFloat($writer, $value$enumGetter $orNull);';
    case PropertyType.long:
      final orNull = nullable ? '?? $nullLong' : '';
      return 'IsarCore.writeLong($writer, $value$enumGetter $orNull);';
    case PropertyType.dateTime:
      final converted = nullable
          ? '$value$enumGetter?.toUtc().microsecondsSinceEpoch ?? $nullLong'
          : '$value$enumGetter.toUtc().microsecondsSinceEpoch';
      return 'IsarCore.writeLong($writer, $converted);';
    case PropertyType.double:
      final orNull = nullable ? '?? double.nan' : '';
      return 'IsarCore.writeDouble($writer, $value$enumGetter $orNull);';
    case PropertyType.string:
      if (nullable) {
        return '''
        {
          final value = $value$enumGetter;
          if (value == null) {
            IsarCore.writeNull($writer);
          } else {
            IsarCore.writeString($writer, IsarCore.toNativeString(value));
          }
        }''';
      } else {
        return 'IsarCore.writeString($writer, IsarCore.toNativeString($value$enumGetter));';
      }
    case PropertyType.object:
      var code = '''
      {
        final value = $value;''';
      if (nullable) {
        code += '''
        if (value == null) {
          IsarCore.writeNull($writer);
        } else {''';
      }
      code += '''
      final objectWriter = IsarCore.beginObject($writer);
      serialize$typeClassName(objectWriter, value);
      IsarCore.endObject($writer, objectWriter);''';
      if (nullable) {
        code += '}';
      }
      return '$code}';
    case PropertyType.json:
      return '''
      IsarCore.writeString(
        $writer,
        IsarCore.toNativeString(isarJsonEncode($value)),
      );''';
    case PropertyType.boolList:
    case PropertyType.byteList:
    case PropertyType.intList:
    case PropertyType.floatList:
    case PropertyType.longList:
    case PropertyType.dateTimeList:
    case PropertyType.doubleList:
    case PropertyType.stringList:
    case PropertyType.objectList:
      var code = '''
      {
        final value = $value;''';
      if (nullable) {
        code += '''
        if (value == null) {
          IsarCore.writeNull($writer);
        } else {''';
      }
      code += '''
      final listWriter = IsarCore.beginList(writer, value.length);
      for (final item in value) {
        ${_writeProperty(
        writer: 'listWriter',
        type: type.scalarType,
        nullable: elementNullable!,
        typeClassName: typeClassName,
        value: 'item',
        enumProperty: enumProperty,
      )}
      }
      IsarCore.endList(writer, listWriter);
      ''';
      if (nullable) {
        code += '}';
      }
      return '$code}';
  }
}
