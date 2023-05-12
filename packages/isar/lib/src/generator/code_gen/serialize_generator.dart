import 'package:isar/src/generator/consts.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

String generateSerialize(ObjectInfo object) {
  var code =
      'int ${object.serializeName}(${object.dartName} object, IsarWriter writer) {';

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
        return 'IsarCore.isarWriteBool($writer, $value ?? false, $value == null);';
      } else {
        return 'IsarCore.isarWriteBool($writer, $value, false);';
      }
    case PropertyType.byte:
      final orNull = nullable ? '?? $nullByte' : '';
      return 'IsarCore.isarWriteByte($writer, $value $orNull);';
    case PropertyType.int:
      final orNull = nullable ? '?? $nullInt' : '';
      return 'IsarCore.isarWriteInt($writer, $value $orNull);';
    case PropertyType.float:
      final orNull = nullable ? '?? $nullFloat' : '';
      return 'IsarCore.isarWriteFloat($writer, $value $orNull);';
    case PropertyType.long:
      final orNull = nullable ? '?? $nullLong' : '';
      return 'IsarCore.isarWriteLong($writer, $value $orNull);';
    case PropertyType.dateTime:
      final converted = nullable
          ? '$value?.toUtc().microsecondsSinceEpoch ?? $nullLong'
          : '$value.toUtc().microsecondsSinceEpoch';
      return 'IsarCore.isarWriteLong($writer, $converted);';
    case PropertyType.double:
      final orNull = nullable ? '?? $nullDouble' : '';
      return 'IsarCore.isarWriteDouble($writer, $value $orNull);';
    case PropertyType.string:
      return 'IsarCore.isarWriteString($writer, IsarCore.toNativeString($value));';
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
