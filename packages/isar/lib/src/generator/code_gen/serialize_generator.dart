import 'package:isar/src/generator/consts.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

String generateSerialize(ObjectInfo object) {
  var code = '''
  int ${object.serializeName}(
    ${object.dartName} object, 
    IsarWriter writer,
  ) {''';

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
    );
  }

  final idProp = object.idProperty;
  if (idProp != null) {
    if (idProp.type == PropertyType.long) {
      code += 'return object.${idProp.dartName};';
    } else {
      code += 'return IsarContext.fastHash(object.${idProp.dartName});';
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
}) {
  switch (type) {
    case PropertyType.bool:
      if (nullable) {
        return 'IsarCore.isar_write_bool($writer, $value ?? false, $value == null);';
      } else {
        return 'IsarCore.isar_write_bool($writer, $value, false);';
      }
    case PropertyType.byte:
      final orNull = nullable ? '?? $nullByte' : '';
      return 'IsarCore.isar_write_byte($writer, $value $orNull);';
    case PropertyType.int:
      final orNull = nullable ? '?? $nullInt' : '';
      return 'IsarCore.isar_write_int($writer, $value $orNull);';
    case PropertyType.float:
      final orNull = nullable ? '?? $nullFloat' : '';
      return 'IsarCore.isar_write_float($writer, $value $orNull);';
    case PropertyType.long:
      final orNull = nullable ? '?? $nullLong' : '';
      return 'IsarCore.isar_write_long($writer, $value $orNull);';
    case PropertyType.dateTime:
      final converted = nullable
          ? '$value?.toUtc().microsecondsSinceEpoch ?? $nullLong'
          : '$value.toUtc().microsecondsSinceEpoch';
      return 'IsarCore.isar_write_long($writer, $converted);';
    case PropertyType.double:
      final orNull = nullable ? '?? $nullDouble' : '';
      return 'IsarCore.isar_write_double($writer, $value $orNull);';
    case PropertyType.string:
      return 'IsarCore.isar_write_string($writer, IsarCore.toNativeString($value));';
    case PropertyType.object:
      var code = '''
      {
        final value = $value;''';
      if (nullable) {
        code += '''
        if (value == null) {
          IsarCore.isar_write_null($writer);
        } else {''';
      }
      code += '''
      final objectWriter = IsarCore.isar_begin_object($writer);
      serialize$typeClassName(objectWriter, value);
      IsarCore.isar_end_object($writer, objectWriter);''';
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
          IsarCore.isar_write_null($writer);
        } else {''';
      }
      code += '''
      final listWriter = IsarCore.isar_begin_list(writer, value.length);
      for (final item in value) {
        ${_writeProperty(
        writer: 'listWriter',
        type: type.scalarType,
        nullable: elementNullable!,
        typeClassName: typeClassName,
        value: 'item',
      )}
      }
      IsarCore.isar_end_list(writer, listWriter);
      ''';
      if (nullable) {
        code += '}';
      }
      return '$code}';
  }
}
