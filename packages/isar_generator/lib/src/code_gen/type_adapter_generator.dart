import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';
import 'package:isar_generator/src/object_info.dart';

String _prepareSerialize(
  bool nullable,
  String value,
  String Function(String) size,
) {
  var code = '';
  if (nullable) {
    code += '''
      {
        final value = $value;
        if (value != null) {''';
    value = 'value';
  }
  code += 'bytesCount += ${size(value)};';
  if (nullable) {
    code += '}}';
  }
  return code;
}

String _prepareSerializeList(
  bool nullable,
  bool elementNullable,
  String value,
  String size, [
  String? prepare,
]) {
  var code = '';
  if (nullable) {
    code += '''
      {
        final list = $value;
        if (list != null) {''';
    value = 'list';
  }
  code += '''
    bytesCount += 3 + $value.length * 3;
    {
      ${prepare ?? ''}
      for (var i = 0; i < $value.length; i++) {
        final value = $value[i];''';
  if (elementNullable) {
    code += 'if (value != null) {';
  }
  code += 'bytesCount += $size;';
  if (elementNullable) {
    code += '}';
  }
  code += '}}';
  if (nullable) {
    code += '}}';
  }
  return code;
}

String generateEstimateSerialize(ObjectInfo object) {
  var code = '''
    int ${object.estimateSizeName}(
      ${object.dartName} object,
      List<int> offsets,
      Map<Type, List<int>> allOffsets,
    ) {
      var bytesCount = offsets.last;''';

  for (final property in object.properties) {
    final value = 'object.${property.dartName}';

    switch (property.isarType) {
      case IsarType.string:
        final enumValue = property.isEnum ? '.${property.enumProperty}' : '';
        code += _prepareSerialize(
          property.nullable,
          value,
          (value) => '3 + $value$enumValue.length * 3',
        );
        break;

      case IsarType.stringList:
        final enumValue = property.isEnum ? '.${property.enumProperty}' : '';
        code += _prepareSerializeList(
          property.nullable,
          property.elementNullable,
          value,
          'value$enumValue.length * 3',
        );
        break;

      case IsarType.object:
        code += _prepareSerialize(
          property.nullable,
          value,
          (value) {
            return '3 + ${property.targetSchema}.estimateSize($value, '
                'allOffsets[${property.scalarDartType}]!, allOffsets)';
          },
        );
        break;

      case IsarType.objectList:
        code += _prepareSerializeList(
          property.nullable,
          property.elementNullable,
          value,
          '${property.targetSchema}.estimateSize(value, offsets, allOffsets)',
          'final offsets = allOffsets[${property.scalarDartType}]!;',
        );
        break;

      case IsarType.byteList:
      case IsarType.boolList:
        code += _prepareSerialize(
          property.nullable,
          value,
          (value) => '3 + $value.length',
        );
        break;
      case IsarType.intList:
      case IsarType.floatList:
        code += _prepareSerialize(
          property.nullable,
          value,
          (value) => '3 + $value.length * 4',
        );
        break;
      case IsarType.longList:
      case IsarType.doubleList:
      case IsarType.dateTimeList:
        code += _prepareSerialize(
          property.nullable,
          value,
          (value) => '3 + $value.length * 8',
        );
        break;

      // ignore: no_default_cases
      default:
        break;
    }
  }

  return '''
      $code
      return bytesCount;
    }''';
}

String generateSerialize(ObjectInfo object) {
  var code = '''
  void ${object.serializeName}(
    ${object.dartName} object, 
    IsarWriter writer,
    List<int> offsets, 
    Map<Type, List<int>> allOffsets,
  ) {''';

  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];
    var value = 'object.${property.dartName}';
    if (property.isEnum) {
      final nOp = property.nullable ? '?' : '';
      final elNOp = property.elementNullable ? '?' : '';
      value = property.isarType.isList
          ? '$value$nOp.map((e) => e$elNOp.${property.enumProperty}).toList()'
          : '$value$nOp.${property.enumProperty}';
    }

    switch (property.isarType) {
      case IsarType.bool:
        code += 'writer.writeBool(offsets[$i], $value);';
        break;
      case IsarType.byte:
        code += 'writer.writeByte(offsets[$i], $value);';
        break;
      case IsarType.int:
        code += 'writer.writeInt(offsets[$i], $value);';
        break;
      case IsarType.float:
        code += 'writer.writeFloat(offsets[$i], $value);';
        break;
      case IsarType.long:
        code += 'writer.writeLong(offsets[$i], $value);';
        break;
      case IsarType.double:
        code += 'writer.writeDouble(offsets[$i], $value);';
        break;
      case IsarType.dateTime:
        code += 'writer.writeDateTime(offsets[$i], $value);';
        break;
      case IsarType.string:
        code += 'writer.writeString(offsets[$i], $value);';
        break;
      case IsarType.object:
        code += '''
          writer.writeObject<${property.typeClassName}>(
            offsets[$i],
            allOffsets,
            ${property.targetSchema}.serialize,
            $value,
          );''';
        break;
      case IsarType.byteList:
        code += 'writer.writeByteList(offsets[$i], $value);';
        break;
      case IsarType.boolList:
        code += 'writer.writeBoolList(offsets[$i], $value);';
        break;
      case IsarType.intList:
        code += 'writer.writeIntList(offsets[$i], $value);';
        break;
      case IsarType.longList:
        code += 'writer.writeLongList(offsets[$i], $value);';
        break;
      case IsarType.floatList:
        code += 'writer.writeFloatList(offsets[$i], $value);';
        break;
      case IsarType.doubleList:
        code += 'writer.writeDoubleList(offsets[$i], $value);';
        break;
      case IsarType.dateTimeList:
        code += 'writer.writeDateTimeList(offsets[$i], $value);';
        break;
      case IsarType.stringList:
        code += 'writer.writeStringList(offsets[$i], $value);';
        break;
      case IsarType.objectList:
        code += '''
          writer.writeObjectList<${property.typeClassName}>(
            offsets[$i],
            allOffsets,
            ${property.targetSchema}.serialize,
            $value,
          );''';
        break;
    }
  }

  return '$code}';
}

String generateDeserialize(ObjectInfo object) {
  var code = '''
    ${object.dartName} ${object.deserializeName}(
      Id id,
      IsarReader reader,
      List<int> offsets,
      Map<Type, List<int>> allOffsets,
    ) {
      final object = ${object.dartName}(''';

  final propertiesByMode =
      object.properties.groupBy((ObjectProperty p) => p.deserialize);
  final positional = propertiesByMode[PropertyDeser.positionalParam] ?? [];
  final sortedPositional =
      positional.sortedBy((ObjectProperty p) => p.constructorPosition!);
  for (final p in sortedPositional) {
    final index = object.objectProperties.indexOf(p);
    final deser = _deserializeProperty(object, p, 'offsets[$index]');
    code += '$deser,';
  }

  final named = propertiesByMode[PropertyDeser.namedParam] ?? [];
  for (final p in named) {
    final index = object.objectProperties.indexOf(p);
    final deser = _deserializeProperty(object, p, 'offsets[$index]');
    code += '${p.dartName}: $deser,';
  }

  code += ');';

  final assign = propertiesByMode[PropertyDeser.assign] ?? [];
  for (final p in assign) {
    final index = object.objectProperties.indexOf(p);
    final deser = _deserializeProperty(object, p, 'offsets[$index]');
    code += 'object.${p.dartName} = $deser;';
  }

  return '''
    $code
    return object;
  }''';
}

String generateDeserializeProp(ObjectInfo object) {
  var code = '''
    P ${object.deserializePropName}<P>(
      IsarReader reader,
      int propertyId,
      int offset,
      Map<Type,
      List<int>> allOffsets,
    ) {
      switch (propertyId) {''';

  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];
    final deser = _deserializeProperty(object, property, 'offset');
    code += 'case $i: return ($deser) as P;';
  }

  return '''
      $code
      default:
        throw IsarError('Unknown property with id \$propertyId');
      }
    }
    ''';
}

String _deserializeProperty(
  ObjectInfo object,
  ObjectProperty property,
  String propertyOffset,
) {
  if (property.isId) {
    return 'id';
  }

  final deser = _deserialize(property, propertyOffset);

  var defaultValue = '';
  if (!property.nullable) {
    if (property.userDefaultValue != null) {
      defaultValue = '?? ${property.userDefaultValue}';
    } else if (property.isarType == IsarType.object) {
      defaultValue = '?? ${property.typeClassName}()';
    } else if (property.isarType.isList) {
      defaultValue = '?? []';
    } else if (property.isEnum) {
      defaultValue = '?? ${property.defaultEnumElement}';
    }
  }

  if (property.isEnum) {
    if (property.isarType.isList) {
      final elDefault =
          !property.elementNullable ? '?? ${property.defaultEnumElement}' : '';
      return '$deser?.map((e) => ${property.valueEnumMapName(object)}[e] '
          '$elDefault).toList() $defaultValue';
    } else {
      return '${property.valueEnumMapName(object)}[$deser] $defaultValue';
    }
  } else {
    return '$deser $defaultValue';
  }
}

String _deserialize(ObjectProperty property, String propertyOffset) {
  final orNull =
      property.nullable || property.userDefaultValue != null || property.isEnum
          ? 'OrNull'
          : '';
  final orElNull = property.elementNullable ? 'OrNull' : '';

  switch (property.isarType) {
    case IsarType.bool:
      return 'reader.readBool$orNull($propertyOffset)';
    case IsarType.byte:
      return 'reader.readByte$orNull($propertyOffset)';
    case IsarType.int:
      return 'reader.readInt$orNull($propertyOffset)';
    case IsarType.float:
      return 'reader.readFloat$orNull($propertyOffset)';
    case IsarType.long:
      return 'reader.readLong$orNull($propertyOffset)';
    case IsarType.double:
      return 'reader.readDouble$orNull($propertyOffset)';
    case IsarType.dateTime:
      return 'reader.readDateTime$orNull($propertyOffset)';
    case IsarType.string:
      return 'reader.readString$orNull($propertyOffset)';
    case IsarType.object:
      return '''
        reader.readObjectOrNull<${property.typeClassName}>(
          $propertyOffset,
          ${property.targetSchema}.deserialize,
          allOffsets,
        )''';
    case IsarType.boolList:
      return 'reader.readBool${orElNull}List($propertyOffset)';
    case IsarType.byteList:
      return 'reader.readByteList($propertyOffset)';
    case IsarType.intList:
      return 'reader.readInt${orElNull}List($propertyOffset)';
    case IsarType.floatList:
      return 'reader.readFloat${orElNull}List($propertyOffset)';
    case IsarType.longList:
      return 'reader.readLong${orElNull}List($propertyOffset)';
    case IsarType.doubleList:
      return 'reader.readDouble${orElNull}List($propertyOffset)';
    case IsarType.dateTimeList:
      return 'reader.readDateTime${orElNull}List($propertyOffset)';
    case IsarType.stringList:
      return 'reader.readString${orElNull}List($propertyOffset)';
    case IsarType.objectList:
      return '''
        reader.readObject${orElNull}List<${property.typeClassName}>(
          $propertyOffset,
          ${property.targetSchema}.deserialize,
          allOffsets,
          ${!property.elementNullable ? '${property.typeClassName}(),' : ''}
        )''';
  }
}

String generateGetId(ObjectInfo object) {
  final defaultVal = object.idProperty.nullable ? '?? Isar.autoIncrement' : '';
  return '''
    Id ${object.getIdName}(${object.dartName} object) {
      return object.${object.idProperty.dartName} $defaultVal;
    }
  ''';
}

String generateGetLinks(ObjectInfo object) {
  return '''
    List<IsarLinkBase<dynamic>> ${object.getLinksName}(${object.dartName} object) {
      return [${object.links.map((e) => 'object.${e.dartName}').join(',')}];
    }
  ''';
}

String generateAttach(ObjectInfo object) {
  var code = '''
  void ${object.attachName}(IsarCollection<dynamic> col, Id id, ${object.dartName} object) {''';

  if (object.idProperty.assignable) {
    code += 'object.${object.idProperty.dartName} = id;';
  }

  for (final link in object.links) {
    // ignore: leading_newlines_in_multiline_strings
    code += '''object.${link.dartName}.attach(
      col,
      col.isar.collection<${link.targetCollectionDartName}>(),
      r'${link.isarName}',
      id
    );''';
  }
  return '$code}';
}

String generateEnumMaps(ObjectInfo object) {
  var code = '';
  for (final property in object.properties) {
    final enumName = property.typeClassName;
    if (property.isEnum) {
      code += 'const ${property.enumValueMapName(object)} = {';
      for (final enumElementName in property.enumMap!.keys) {
        final value = property.enumMap![enumElementName];
        if (value is String) {
          code += "r'$enumElementName': r'$value',";
        } else {
          code += "'$enumElementName': $value,";
        }
      }
      code += '};';

      code += 'const ${property.valueEnumMapName(object)} = {';
      for (final enumElementName in property.enumMap!.keys) {
        final value = property.enumMap![enumElementName];
        if (value is String) {
          code += "r'$value': $enumName.$enumElementName,";
        } else {
          code += '$value: $enumName.$enumElementName,';
        }
      }
      code += '};';
    }
  }

  return code;
}
