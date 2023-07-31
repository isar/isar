// ignore_for_file: use_string_buffers
// ignore_for_file: always_put_required_named_parameters_first

part of isar_generator;

String _generateSerialize(ObjectInfo object) {
  var code = '''
  @isarProtected
  int serialize${object.dartName}(IsarWriter writer, ${object.dartName} object) {''';

  for (final property in object.properties) {
    if (property.isId && property.type == PropertyType.long) {
      continue;
    }

    code += _writeProperty(
      index: property.index.toString(),
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
  required String index,
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
            IsarCore.writeNull($writer, $index);
          } else {
            IsarCore.writeBool($writer, $index, value);
          }
        }''';
      } else {
        return 'IsarCore.writeBool($writer, $index, $value$enumGetter);';
      }
    case PropertyType.byte:
      return 'IsarCore.writeByte($writer, $index, $value$enumGetter);';
    case PropertyType.int:
      final orNull = nullable ? '?? $_nullInt' : '';
      return 'IsarCore.writeInt($writer, $index, $value$enumGetter $orNull);';
    case PropertyType.float:
      final orNull = nullable ? '?? double.nan' : '';
      return 'IsarCore.writeFloat($writer, $index, $value$enumGetter $orNull);';
    case PropertyType.long:
      final orNull = nullable ? '?? $_nullLong' : '';
      return 'IsarCore.writeLong($writer, $index, $value$enumGetter $orNull);';
    case PropertyType.dateTime:
      final converted = nullable
          ? '$value$enumGetter?.toUtc().microsecondsSinceEpoch ?? $_nullLong'
          : '$value$enumGetter.toUtc().microsecondsSinceEpoch';
      return 'IsarCore.writeLong($writer, $index, $converted);';
    case PropertyType.double:
      final orNull = nullable ? '?? double.nan' : '';
      return 'IsarCore.writeDouble($writer, $index, $value$enumGetter$orNull);';
    case PropertyType.string:
      if (nullable) {
        return '''
        {
          final value = $value$enumGetter;
          if (value == null) {
            IsarCore.writeNull($writer, $index);
          } else {
            IsarCore.writeString($writer, $index, value);
          }
        }''';
      } else {
        return '''
        IsarCore.writeString($writer, $index, $value$enumGetter);''';
      }
    case PropertyType.object:
      var code = '''
      {
        final value = $value;''';
      if (nullable) {
        code += '''
        if (value == null) {
          IsarCore.writeNull($writer, $index);
        } else {''';
      }
      code += '''
      final objectWriter = IsarCore.beginObject($writer, $index);
      serialize$typeClassName(objectWriter, value);
      IsarCore.endObject($writer, objectWriter);''';
      if (nullable) {
        code += '}';
      }
      return '$code}';
    case PropertyType.json:
      return 'IsarCore.writeString($writer, $index, isarJsonEncode($value));';
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
        final list = $value;''';
      if (nullable) {
        code += '''
        if (list == null) {
          IsarCore.writeNull($writer, $index);
        } else {''';
      }
      code += '''
      final listWriter = IsarCore.beginList(writer, $index, list.length);
      for (var i = 0; i < list.length; i++) {
        ${_writeProperty(
        writer: 'listWriter',
        index: 'i',
        type: type.scalarType,
        nullable: elementNullable!,
        typeClassName: typeClassName,
        value: 'list[i]',
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
