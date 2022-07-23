import 'package:isar_generator/src/code_gen/type_adapter_generator_common.dart';
import 'package:isar_generator/src/isar_type.dart';
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
  code += '}';
  if (nullable) {
    code += '}}';
  }
  return code;
}

String generateEstimateSerializeNative(ObjectInfo object) {
  var code = '''
    int ${object.estimateSize}(${object.dartName} object, List<int> offsets, Map<Type, List<int>> allOffsets) {
      var bytesCount = offsets.last;''';

  for (final property in object.properties) {
    final value = 'object.${property.dartName}';
    switch (property.isarType) {
      case IsarType.string:
        code += _prepareSerialize(
          property.nullable,
          value,
          (value) => '3 + $value.length * 3',
        );
        break;

      case IsarType.stringList:
        code += _prepareSerializeList(
          property.nullable,
          property.elementNullable,
          value,
          'value.length * 3',
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
          '${property.targetSchema}.estimateSize(value, off, allOffsets)',
          'final off = allOffsets[${property.scalarDartType}]!;',
        );
        break;

      case IsarType.byteList:
      case IsarType.boolList:
      case IsarType.enumerationList:
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

String generateSerializeNative(ObjectInfo object) {
  var code = 'int ${object.serializeNativeName}(${object.dartName} object, '
      'IsarBinaryWriter writer, List<int> offsets, '
      'Map<Type, List<int>> allOffsets,) {';

  code += 'writer.writeHeader();';
  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];
    final value = 'object.${property.dartName}';
    switch (property.isarType) {
      case IsarType.id:
        throw UnimplementedError();
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
      case IsarType.enumeration:
        code += 'writer.writeEnum(offsets[$i], $value);';
        break;
      case IsarType.string:
        code += 'writer.writeString(offsets[$i], $value);';
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
      case IsarType.enumerationList:
        code += 'writer.writeEnumList(offsets[$i], $value);';
        break;
      case IsarType.stringList:
        code += 'writer.writeStringList(offsets[$i], $value);';
        break;
    }
  }

  return '''
    $code
    return writer.usedBytes;
  }''';
}

String generateDeserializeNative(ObjectInfo object) {
  String deserProp(ObjectProperty p) {
    final index = object.objectProperties.indexOf(p);
    return _deserializeProperty(object, p, 'offsets[$index]');
  }

  var code = '''
  ${object.dartName} ${object.deserializeNativeName}(IsarCollection<${object.dartName}> collection, int id, IsarBinaryReader reader, List<int> offsets) {
    ${deserializeMethodBody(object, deserProp)}''';

  if (object.links.isNotEmpty) {
    code += '${object.attachName}(collection, id, object);';
  }

  // ignore: leading_newlines_in_multiline_strings
  return '''$code
    return object;
  }''';
}

String generateDeserializePropNative(ObjectInfo object) {
  var code = '''
  P ${object.deserializePropNativeName}<P>(Id id, IsarBinaryReader reader, int propertyIndex, int offset) {
    switch (propertyIndex) {
      case -1:
        return id as P;''';

  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];
    final deser = _deserializeProperty(object, property, 'offset');
    code += 'case $i: return ($deser) as P;';
  }

  return '''
      $code
      default:
        throw IsarError('Illegal propertyIndex');
      }
    }
    ''';
}

String _deserializeProperty(
  ObjectInfo object,
  ObjectProperty property,
  String propertyOffset,
) {
  final orNull =
      property.nullable || property.defaultValue != null ? 'OrNull' : '';
  final orElNull = property.elementNullable ? 'OrNull' : '';

  var defaultValue = '';
  if (!property.nullable) {
    if (property.defaultValue != null) {
      defaultValue = '?? ${property.defaultValue}';
    } else if (property.isarType == IsarType.byteList) {
      defaultValue = '?? Uint8List(0)';
    } else if (property.isarType.isList) {
      defaultValue = '?? []';
    }
  }

  switch (property.isarType) {
    case IsarType.id:
      return 'id';
    case IsarType.bool:
      return 'reader.readBool$orNull($propertyOffset) $defaultValue';
    case IsarType.byte:
      return 'reader.readByte($propertyOffset) $defaultValue';
    case IsarType.int:
      return 'reader.readInt$orNull($propertyOffset) $defaultValue';
    case IsarType.float:
      return 'reader.readFloat$orNull($propertyOffset) $defaultValue';
    case IsarType.long:
      return 'reader.readLong$orNull($propertyOffset) $defaultValue';
    case IsarType.double:
      return 'reader.readDouble$orNull($propertyOffset) $defaultValue';
    case IsarType.dateTime:
      return 'reader.readDateTime$orNull($propertyOffset) $defaultValue';
    case IsarType.enumeration:
      final values = '${property.scalarDartType}.values';
      return 'reader.readEnum$orNull($propertyOffset, $values) $defaultValue';
    case IsarType.string:
      return 'reader.readString$orNull($propertyOffset) $defaultValue';
    case IsarType.boolList:
      return 'reader.readBool${orElNull}List($propertyOffset) $defaultValue';
    case IsarType.byteList:
      return 'reader.readByteList($propertyOffset) $defaultValue';
    case IsarType.intList:
      return 'reader.readInt${orElNull}List($propertyOffset) $defaultValue';
    case IsarType.floatList:
      return 'reader.readFloat${orElNull}List($propertyOffset) $defaultValue';
    case IsarType.longList:
      return 'reader.readLong${orElNull}List($propertyOffset) $defaultValue';
    case IsarType.doubleList:
      return 'reader.readDouble${orElNull}List($propertyOffset) $defaultValue';
    case IsarType.dateTimeList:
      return 'reader.readDateTime${orElNull}List($propertyOffset) $defaultValue';
    case IsarType.enumerationList:
      final values = '${property.scalarDartType}.values';
      return 'reader.readEnum${orElNull}List($propertyOffset, $values) $defaultValue';
    case IsarType.stringList:
      return 'reader.readString${orElNull}List($propertyOffset) $defaultValue';
    case IsarType.object:
      throw UnimplementedError();
    case IsarType.objectList:
      throw UnimplementedError();
  }
}
