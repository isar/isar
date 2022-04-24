import 'package:isar_generator/src/code_gen/type_adapter_generator_common.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

String _generatePrepareSerialize(ObjectInfo object) {
  var code = 'var dynamicSize = 0;';
  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];
    var propertyValue = 'object.${property.dartName}';
    if (property.converter != null) {
      propertyValue = property.toIsar(propertyValue, object);
    }
    code += 'final value$i = $propertyValue;';

    final nOp = property.nullable ? '?' : '';
    final elNOp = property.elementNullable ? '?' : '';
    final nLen = property.nullable ? '?? 0' : '';
    final accessor = '_${property.isarName}';
    switch (property.isarType) {
      case IsarType.string:
        if (property.nullable) {
          code += '''
          IsarUint8List? $accessor;
          if (value$i != null) {
            $accessor = IsarBinaryWriter.utf8Encoder.convert(value$i);
          }
          ''';
        } else {
          code +=
              'final $accessor = IsarBinaryWriter.utf8Encoder.convert(value$i);';
        }
        code += 'dynamicSize += ($accessor$nOp.length $nLen) as int;';
        break;
      case IsarType.stringList:
        code += 'dynamicSize += (value$i$nOp.length $nLen) * 8;';
        if (property.nullable) {
          code += '''
          List<IsarUint8List?>? bytesList$i;
          if (value$i != null) {
            bytesList$i = [];''';
        } else {
          code += 'final bytesList$i = <IsarUint8List$elNOp>[];';
        }
        code += 'for (var str in value$i) {';
        if (property.elementNullable) {
          code += 'if (str != null) {';
        }
        code += '''
          final bytes = IsarBinaryWriter.utf8Encoder.convert(str);
          bytesList$i.add(bytes);
          dynamicSize += bytes.length as int;''';
        if (property.elementNullable) {
          code += '''
          } else {
            bytesList$i.add(null);
          }''';
        }
        if (property.nullable) {
          code += '}';
        }
        code += '''
        }
        final $accessor = bytesList$i;''';
        break;
      case IsarType.bytes:
      case IsarType.boolList:
      case IsarType.intList:
      case IsarType.floatList:
      case IsarType.longList:
      case IsarType.doubleList:
      case IsarType.dateTimeList:
        code +=
            'dynamicSize += (value$i$nOp.length $nLen) * ${property.isarType.elementSize};';
        break;
      default:
        break;
    }
    if (property.isarType != IsarType.string &&
        property.isarType != IsarType.stringList) {
      code += 'final $accessor = value$i;';
    }
  }
  code += '''
    final size = staticSize + dynamicSize;
    ''';

  return code;
}

String generateSerializeNative(ObjectInfo object) {
  var code = '''
  void ${object.serializeNativeName}(IsarCollection<${object.dartName}> collection, IsarRawObject rawObj, ${object.dartName} object, int staticSize, List<int> offsets, AdapterAlloc alloc) {
    ${_generatePrepareSerialize(object)}
    rawObj.buffer = alloc(size);
    rawObj.buffer_length = size;
    final buffer = IsarNative.bufAsBytes(rawObj.buffer, size);
    final writer = IsarBinaryWriter(buffer, staticSize);
  ''';
  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];
    final accessor = '_${property.isarName}';
    switch (property.isarType) {
      case IsarType.bool:
        code += 'writer.writeBool(offsets[$i], $accessor);';
        break;
      case IsarType.int:
        code += 'writer.writeInt(offsets[$i], $accessor);';
        break;
      case IsarType.float:
        code += 'writer.writeFloat(offsets[$i], $accessor);';
        break;
      case IsarType.long:
        code += 'writer.writeLong(offsets[$i], $accessor);';
        break;
      case IsarType.double:
        code += 'writer.writeDouble(offsets[$i], $accessor);';
        break;
      case IsarType.dateTime:
        code += 'writer.writeDateTime(offsets[$i], $accessor);';
        break;
      case IsarType.string:
        code += 'writer.writeBytes(offsets[$i], $accessor);';
        break;
      case IsarType.bytes:
        code += 'writer.writeBytes(offsets[$i], $accessor);';
        break;
      case IsarType.boolList:
        code += 'writer.writeBoolList(offsets[$i], $accessor);';
        break;
      case IsarType.stringList:
        code += 'writer.writeStringList(offsets[$i], $accessor);';
        break;
      case IsarType.intList:
        code += 'writer.writeIntList(offsets[$i], $accessor);';
        break;
      case IsarType.longList:
        code += 'writer.writeLongList(offsets[$i], $accessor);';
        break;
      case IsarType.floatList:
        code += 'writer.writeFloatList(offsets[$i], $accessor);';
        break;
      case IsarType.doubleList:
        code += 'writer.writeDoubleList(offsets[$i], $accessor);';
        break;
      case IsarType.dateTimeList:
        code += 'writer.writeDateTimeList(offsets[$i], $accessor);';
        break;
    }
  }

  return '$code}';
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
    code += '${object.attachLinksName}(collection, id, object);';
  }

  return '''$code
    return object;
  }''';
}

String generateDeserializePropNative(ObjectInfo object) {
  var code = '''
  P ${object.deserializePropNativeName}<P>(int id, IsarBinaryReader reader, int propertyIndex, int offset) {
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
        throw 'Illegal propertyIndex';
      }
    }
    ''';
}

String _deserializeProperty(
    ObjectInfo object, ObjectProperty property, String propertyOffset) {
  final orNull = property.nullable ? 'OrNull' : '';
  final orNullList = property.nullable ? '' : '?? []';
  final orElNull = property.elementNullable ? 'OrNull' : '';

  if (property.isId) {
    return 'id';
  }

  String? deser;
  switch (property.isarType) {
    case IsarType.bool:
      deser = 'reader.readBool$orNull($propertyOffset)';
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
    case IsarType.bytes:
      deser = 'reader.readBytes$orNull($propertyOffset)';
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

  return property.fromIsar(deser, object);
}
