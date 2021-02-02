import 'package:isar_generator/src/object_info.dart';
import 'package:isar_generator/src/code_gen/util.dart';
import 'package:dartx/dartx.dart';

String generateObjectAdapter(ObjectInfo object) {
  return '''
    class _${object.dartName}Adapter extends TypeAdapter<${object.dartName}> {

      ${generateConverterFields(object)}

      ${_generateSerialize(object)}
      ${_generateDeserialize(object)}
    }
    ''';
}

String generateConverterFields(ObjectInfo object) {
  return object.properties
      .mapNotNull((it) => it.converter)
      .toSet()
      .map((it) => 'static const _$it = $it();')
      .join('\n');
}

String _generatePrepareSerialize(ObjectInfo object) {
  final staticSize = object.getStaticSize();
  var code = 'var dynamicSize = 0;';
  for (var i = 0; i < object.properties.length; i++) {
    final property = object.properties[i];
    var propertyValue = 'object.${property.dartName}';
    if (property.converter != null) {
      propertyValue = property.toIsar(propertyValue, object);
    }
    code += 'final value$i = $propertyValue;';

    final nOp = property.nullable ? '?' : '';
    final nLen = property.nullable ? '?? 0' : '';
    final accessor = '_${property.isarName}';
    switch (property.isarType) {
      case IsarType.String:
        if (property.nullable) {
          code += '''
          Uint8List? $accessor;
          if (value$i != null) {
            $accessor = _utf8Encoder.convert(value$i);
          }
          ''';
        } else {
          code += 'final $accessor = _utf8Encoder.convert(value$i);';
        }
        code += 'dynamicSize += $accessor$nOp.length $nLen;';
        break;
      case IsarType.Bytes:
      case IsarType.BoolList:
        code += 'dynamicSize += value$i$nOp.length $nLen;';
        break;
      case IsarType.StringList:
        code += '''
          dynamicSize += (value$i$nOp.length $nLen) * 8;
          List<Uint8List?>? bytesList$i;''';
        if (property.nullable) {
          code += '''
          if (value$i != null) {
            bytesList$i = [];''';
        }
        code += 'for (var str in value$i) {';
        if (property.elementNullable) {
          code += 'if (str != null) {';
        }
        code += '''
          final bytes = _utf8Encoder.convert(str);
          bytesList$i.add(bytes);
          dynamicSize += bytes.length;''';
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
      case IsarType.IntList:
      case IsarType.FloatList:
        code += 'dynamicSize += (value$i$nOp.length $nLen) * 4;';
        break;
      case IsarType.LongList:
      case IsarType.DoubleList:
        code += 'dynamicSize += (value$i$nOp.length $nLen) * 8;';
        break;
      default:
        break;
    }
    if (property.isarType != IsarType.String &&
        property.isarType != IsarType.StringList) {
      code += 'final $accessor = value$i;';
    }
  }
  code += '''
    final size = dynamicSize + $staticSize;
    ''';

  return code;
}

String _generateSerialize(ObjectInfo object) {
  var code = '''
  @override  
  void serialize(RawObject rawObj, ${object.dartName} object, List<int> offsets) {
    ${_generatePrepareSerialize(object)}
    final ptr = calloc<Uint8>(size);
    rawObj.data = ptr;
    rawObj.data_length = size;
    final buffer = ptr.asTypedList(size);
    final writer = BinaryWriter(buffer, ${object.getStaticSize()});
  ''';
  for (var i = 0; i < object.properties.length; i++) {
    final property = object.properties[i];
    final accessor = '_${property.isarName}';
    switch (property.isarType) {
      case IsarType.Bool:
        code += 'writer.writeBool(offsets[$i], $accessor);';
        break;
      case IsarType.Int:
        code += 'writer.writeInt(offsets[$i], $accessor);';
        break;
      case IsarType.Float:
        code += 'writer.writeFloat(offsets[$i], $accessor);';
        break;
      case IsarType.Long:
        code += 'writer.writeLong(offsets[$i], $accessor);';
        break;
      case IsarType.Double:
        code += 'writer.writeDouble(offsets[$i], $accessor);';
        break;
      case IsarType.String:
        code += 'writer.writeBytes(offsets[$i], $accessor);';
        break;
      case IsarType.Bytes:
        code += 'writer.writeBytes(offsets[$i], $accessor);';
        break;
      case IsarType.BoolList:
        code += 'writer.writeBoolList(offsets[$i], $accessor);';
        break;
      case IsarType.StringList:
        code += 'writer.writeStringList(offsets[$i], $accessor);';
        break;
      case IsarType.IntList:
        code += 'writer.writeIntList(offsets[$i], $accessor);';
        break;
      case IsarType.LongList:
        code += 'writer.writeLongList(offsets[$i], $accessor);';
        break;
      case IsarType.FloatList:
        code += 'writer.writeFloatList(offsets[$i], $accessor);';
        break;
      case IsarType.DoubleList:
        code += 'writer.writeDoubleList(offsets[$i], $accessor);';
        break;
    }
  }

  return '$code}';
}

String _generateDeserialize(ObjectInfo object) {
  var code = '''
  @override
  ${object.dartName} deserialize(BinaryReader reader, List<int> offsets) {
    final object = ${object.dartName}();''';
  for (var i = 0; i < object.properties.length; i++) {
    final property = object.properties[i];
    final accessor = 'object.${property.isarName}';
    final orNull = property.nullable ? 'OrNull' : '';
    final orNullList = property.nullable ? '' : '?? []';
    final orElNull = property.elementNullable ? 'OrNull' : '';

    String deser;
    switch (property.isarType) {
      case IsarType.Bool:
        deser = 'reader.readBool$orNull(offsets[$i])';
        break;
      case IsarType.Int:
        deser = 'reader.readInt$orNull(offsets[$i])';
        break;
      case IsarType.Float:
        deser = 'reader.readFloat$orNull(offsets[$i])';
        break;
      case IsarType.Long:
        deser = 'reader.readLong$orNull(offsets[$i])';
        break;
      case IsarType.Double:
        deser = 'reader.readDouble$orNull(offsets[$i])';
        break;
      case IsarType.String:
        deser = 'reader.readString$orNull(offsets[$i])';
        break;
      case IsarType.Bytes:
        deser = 'reader.readBytes$orNull(offsets[$i]) $orNullList';
        break;
      case IsarType.BoolList:
        deser = 'reader.readBool${orElNull}List(offsets[$i]) $orNullList';
        break;
      case IsarType.StringList:
        deser = 'reader.readString${orElNull}List(offsets[$i]) $orNullList';
        break;
      case IsarType.IntList:
        deser = 'reader.readInt${orElNull}List(offsets[$i]) $orNullList';
        break;
      case IsarType.FloatList:
        deser = 'reader.readFloat${orElNull}List(offsets[$i]) $orNullList';
        break;
      case IsarType.LongList:
        deser = 'reader.readLong${orElNull}List(offsets[$i]) $orNullList';
        break;
      case IsarType.DoubleList:
        deser = 'reader.readDouble${orElNull}List(offsets[$i]) $orNullList';
        break;
    }
    code += '$accessor = ${property.fromIsar(deser, object)};';
  }

  return '''
      $code
      return object;
    }
    ''';
}
