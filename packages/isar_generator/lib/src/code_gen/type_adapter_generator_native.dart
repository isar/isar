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
  String size,
) {
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
    var value = 'object.${property.dartName}';
    if (property.converter != null && property.isarType.isDynamic) {
      final convertedValue = '${property.dartName}\$Converted';
      code += 'final $convertedValue = ${property.toIsar(value, object)};';
      value = convertedValue;
    }

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
          (value) => '3',
        );
        break;

      case IsarType.objectList:
        if (property.converter != null) {
          code += 'cache.add($value);';
        }
        break;

      case IsarType.byteList:
      case IsarType.boolList:
      case IsarType.intList:
      case IsarType.floatList:
      case IsarType.longList:
      case IsarType.doubleList:
      case IsarType.dateTimeList:
        final elSize = property.isarType.elementSize;
        code += _prepareSerialize(
          property.nullable,
          value,
          (value) => '3 + $value.length * $elSize',
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
    var value = 'object.${property.dartName}';
    if (property.converter != null) {
      final convertedValue = '${property.dartName}\$Converted';
      code += 'final $convertedValue = ${property.toIsar(value, object)};';
      value = convertedValue;
    }
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
  final orNull = property.nullable ? 'OrNull' : '';
  final orNullList = property.nullable ? '' : '?? []';
  final orElNull = property.elementNullable ? 'OrNull' : '';

  String? deser;
  switch (property.isarType) {
    case IsarType.id:
      return 'id';
    case IsarType.bool:
      deser = 'reader.readBool$orNull($propertyOffset)';
      break;
    case IsarType.byte:
      deser = 'reader.readByte($propertyOffset)';
      break;
    case IsarType.int:
      deser = 'reader.readInt$orNull($propertyOffset)';
      break;
    case IsarType.float:
      deser = 'reader.readFloat$orNull($propertyOffset)';
      break;
    case IsarType.long:
      deser = 'reader.readLong$orNull($propertyOffset)';
      break;
    case IsarType.double:
      deser = 'reader.readDouble$orNull($propertyOffset)';
      break;
    case IsarType.dateTime:
      deser = 'reader.readDateTime$orNull($propertyOffset)';
      break;
    case IsarType.string:
      deser = 'reader.readString$orNull($propertyOffset)';
      break;
    case IsarType.byteList:
      deser = 'reader.readByteList$orNull($propertyOffset)';
      break;
    case IsarType.boolList:
      deser = 'reader.readBool${orElNull}List($propertyOffset) $orNullList';
      break;
    case IsarType.stringList:
      deser = 'reader.readString${orElNull}List($propertyOffset) $orNullList';
      break;
    case IsarType.intList:
      deser = 'reader.readInt${orElNull}List($propertyOffset) $orNullList';
      break;
    case IsarType.floatList:
      deser = 'reader.readFloat${orElNull}List($propertyOffset) $orNullList';
      break;
    case IsarType.longList:
      deser = 'reader.readLong${orElNull}List($propertyOffset) $orNullList';
      break;
    case IsarType.doubleList:
      deser = 'reader.readDouble${orElNull}List($propertyOffset) $orNullList';
      break;
    case IsarType.dateTimeList:
      deser = 'reader.readDateTime${orElNull}List($propertyOffset) $orNullList';
      break;
  }

  return property.fromIsar(deser!, object);
}
