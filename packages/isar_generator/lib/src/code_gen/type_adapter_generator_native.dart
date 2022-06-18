import 'package:isar_generator/src/code_gen/type_adapter_generator_common.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

class _GetPropResult {
  final String code;
  final String value;
  final String? dynamicSize;

  _GetPropResult({
    required this.code,
    required this.value,
    required this.dynamicSize,
  });
}

_GetPropResult _generateGetPropertyValue(
    ObjectProperty property, ObjectInfo object) {
  var code = '';
  var value = 'object.${property.dartName}';
  String? dynamicSize;

  if (property.converter != null) {
    final convertedValue = '${property.dartName}\$Converted';
    code += 'final $convertedValue = ${property.toIsar(value, object)};';
    value = convertedValue;
  }

  final nOp = property.nullable ? '?' : '';
  final nLen = property.nullable ? '?? 0' : '';
  switch (property.isarType) {
    case IsarType.string:
      final stringBytes = '${property.dartName}\$Bytes';
      if (property.nullable) {
        final stringValue = '${property.dartName}\$Value';
        code += '''
          IsarUint8List? $stringBytes;
          final $stringValue = $value;
          if ($stringValue != null) {
            $stringBytes = IsarBinaryWriter.utf8Encoder.convert($stringValue);
          }
          ''';
      } else {
        code +=
            'final $stringBytes = IsarBinaryWriter.utf8Encoder.convert($value);';
      }
      value = stringBytes;
      dynamicSize = '($stringBytes$nOp.length $nLen)';
      break;
    case IsarType.stringList:
      final stringBytesList = '${property.dartName}\$BytesList';
      dynamicSize = '${property.dartName}\$BytesCount';
      code += 'var $dynamicSize = ($value$nOp.length $nLen) * 8;';

      if (property.nullable) {
        final stringValue = '${property.dartName}\$Value';
        code += '''
          List<IsarUint8List?>? $stringBytesList;
          final $stringValue = $value;
          if ($stringValue != null) {
            $stringBytesList = [];
            for (var str in $stringValue) {''';
      } else {
        final elNOp = property.elementNullable ? '?' : '';
        code += '''
          final $stringBytesList = <IsarUint8List$elNOp>[];
          for (var str in $value) {''';
      }
      if (property.elementNullable) {
        code += 'if (str != null) {';
      }
      code += '''
        final bytes = IsarBinaryWriter.utf8Encoder.convert(str);
        $stringBytesList.add(bytes);
        $dynamicSize += bytes.length as int;''';
      if (property.elementNullable) {
        code += '''
          } else {
            $stringBytesList.add(null);
          }''';
      }
      if (property.nullable) {
        code += '}';
      }
      code += '}';
      value = stringBytesList;
      break;
    case IsarType.bytes:
    case IsarType.boolList:
      dynamicSize = '($value$nOp.length $nLen)';
      break;
    case IsarType.intList:
    case IsarType.floatList:
    case IsarType.longList:
    case IsarType.doubleList:
    case IsarType.dateTimeList:
      dynamicSize =
          '($value$nOp.length $nLen) * ${property.isarType.elementSize}';
      break;
    default:
      break;
  }

  return _GetPropResult(code: code, value: value, dynamicSize: dynamicSize);
}

String generateSerializeNative(ObjectInfo object) {
  var code =
      'void ${object.serializeNativeName}(IsarCollection<${object.dartName}>'
      ' collection, IsarCObject cObj, ${object.dartName} object, '
      'int staticSize, List<int> offsets, AdapterAlloc alloc) {';

  final values = <String>[];
  final sizes = <String>['staticSize'];
  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];
    final serialize = _generateGetPropertyValue(property, object);

    code += serialize.code;
    values.add(serialize.value);
    if (serialize.dynamicSize != null) {
      sizes.add(serialize.dynamicSize!);
    }
  }

  code += '''
    final size = (${sizes.join(' + ')}) as int;
    cObj.buffer = alloc(size);
    cObj.buffer_length = size;

    final buffer = IsarNative.bufAsBytes(cObj.buffer, size);
    final writer = IsarBinaryWriter(buffer, staticSize);
  ''';
  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];
    switch (property.isarType) {
      case IsarType.bool:
        code += 'writer.writeBool(offsets[$i], ${values[i]});';
        break;
      case IsarType.int:
        code += 'writer.writeInt(offsets[$i], ${values[i]});';
        break;
      case IsarType.float:
        code += 'writer.writeFloat(offsets[$i], ${values[i]});';
        break;
      case IsarType.long:
        code += 'writer.writeLong(offsets[$i], ${values[i]});';
        break;
      case IsarType.double:
        code += 'writer.writeDouble(offsets[$i], ${values[i]});';
        break;
      case IsarType.dateTime:
        code += 'writer.writeDateTime(offsets[$i], ${values[i]});';
        break;
      case IsarType.string:
        code += 'writer.writeBytes(offsets[$i], ${values[i]});';
        break;
      case IsarType.bytes:
        code += 'writer.writeBytes(offsets[$i], ${values[i]});';
        break;
      case IsarType.boolList:
        code += 'writer.writeBoolList(offsets[$i], ${values[i]});';
        break;
      case IsarType.stringList:
        code += 'writer.writeStringList(offsets[$i], ${values[i]});';
        break;
      case IsarType.intList:
        code += 'writer.writeIntList(offsets[$i], ${values[i]});';
        break;
      case IsarType.longList:
        code += 'writer.writeLongList(offsets[$i], ${values[i]});';
        break;
      case IsarType.floatList:
        code += 'writer.writeFloatList(offsets[$i], ${values[i]});';
        break;
      case IsarType.doubleList:
        code += 'writer.writeDoubleList(offsets[$i], ${values[i]});';
        break;
      case IsarType.dateTimeList:
        code += 'writer.writeDateTimeList(offsets[$i], ${values[i]});';
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
