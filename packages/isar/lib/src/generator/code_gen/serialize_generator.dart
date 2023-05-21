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

    var value = 'object.${property.dartName}';
    code += _writeProperty(
      type: property.type,
      nullable: property.nullable,
      elementNullable: property.elementNullable,
      typeClassName: property.typeClassName,
      value: value,
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
            IsarCore.isarWriteNull($writer);
          } else {
            IsarCore.isarWriteBool($writer, value);
          }
        }''';
      } else {
        return 'IsarCore.isarWriteBool($writer, $value$enumGetter);';
      }
    case PropertyType.byte:
      final orNull = nullable ? '?? $nullByte' : '';
      return 'IsarCore.isarWriteByte($writer, $value$enumGetter $orNull);';
    case PropertyType.int:
      final orNull = nullable ? '?? $nullInt' : '';
      return 'IsarCore.isarWriteInt($writer, $value$enumGetter $orNull);';
    case PropertyType.float:
      final orNull = nullable ? '?? double.nan' : '';
      return 'IsarCore.isarWriteFloat($writer, $value$enumGetter $orNull);';
    case PropertyType.long:
      final orNull = nullable ? '?? $nullLong' : '';
      return 'IsarCore.isarWriteLong($writer, $value$enumGetter $orNull);';
    case PropertyType.dateTime:
      final converted = nullable
          ? '$value$enumGetter?.toUtc().microsecondsSinceEpoch ?? $nullLong'
          : '$value$enumGetter.toUtc().microsecondsSinceEpoch';
      return 'IsarCore.isarWriteLong($writer, $converted);';
    case PropertyType.double:
      final orNull = nullable ? '?? double.nan' : '';
      return 'IsarCore.isarWriteDouble($writer, $value$enumGetter $orNull);';
    case PropertyType.string:
      if (nullable) {
        return '''
        {
          final value = $value$enumGetter;
          if (value == null) {
            IsarCore.isarWriteNull($writer);
          } else {
            IsarCore.isarWriteString($writer, IsarCore.toNativeString(value));
          }
        }''';
      } else {
        return 'IsarCore.isarWriteString($writer, IsarCore.toNativeString($value$enumGetter));';
      }
    case PropertyType.object:
      var code = '''
      {
        final value = $value;''';
      if (nullable) {
        code += '''
        if (value == null) {
          IsarCore.isarWriteNull($writer);
        } else {''';
      }
      code += '''
      final objectWriter = IsarCore.isarBeginObject($writer);
      serialize$typeClassName(objectWriter, value);
      IsarCore.isarEndObject($writer, objectWriter);''';
      if (nullable) {
        code += '}';
      }
      return '$code}';
    default:
      var code = '''
      {
        final value = $value;''';
      if (nullable) {
        code += '''
        if (value == null) {
          IsarCore.isarWriteNull($writer);
        } else {''';
      }
      code += '''
      final listWriter = IsarCore.isarBeginList(writer, value.length);
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
      IsarCore.isarEndList(writer, listWriter);
      ''';
      if (nullable) {
        code += '}';
      }
      return '$code}';
  }
}
