import 'package:isar_generator/src/isar_analyzer.dart';
import 'package:isar_generator/src/object_info.dart';

String generateObjectAdapter(ObjectInfo object) {
  return '''
    class _${object.type}Adapter extends TypeAdapter<${object.type}> {
      @override
      final staticSize = ${object.getStaticSize()};

      ${_generatePrepareSerialize(object)}
      ${_generateSerialize(object)}
      ${_generateDeserialize(object)}
    }
    ''';
}

String _generatePrepareSerialize(ObjectInfo object) {
  var code = '''
  @override  
  int prepareSerialize(${object.type} object, Map<String, dynamic> cache) {''';
  final staticSize = object.getStaticSize();
  final dynamicProperties =
      object.properties.where((it) => it.type.isDynamic).toList();
  if (dynamicProperties.isNotEmpty) {
    code += 'var dynamicSize = 0;';
    for (var property in dynamicProperties) {
      if (property.type.elementAlignment != 1) {
        code += '''
        {
          final padding = -(dynamicSize + $staticSize) % ${property.type.elementAlignment};
          cache['${property.name}Padding'] = padding;
          dynamicSize += padding;
        }
        ''';
      }
      switch (property.type) {
        case DataType.String:
          code += '''
          {
            final bytes = utf8Encoder.convert(object.${property.name});
            cache['${property.name}Bytes'] = bytes;
            dynamicSize += bytes.length;
          }
          ''';
          break;
        case DataType.Bytes:
        case DataType.BoolList:
          code += 'dynamicSize += object.${property.name}.length;';
          break;
        case DataType.StringList:
          code += '''
          {
            dynamicSize += object.${property.name}.length * 8;
            final bytesList = <Uint8List>[];
            for (var str in object.${property.name}) {
              final bytes = utf8Encoder.convert(str);
              bytesList.add(bytes);
              dynamicSize += bytes.length;
            }
            cache['${property.name}BytesList'] = bytesList;
          }
          ''';
          break;
        case DataType.IntList:
        case DataType.FloatList:
          code += 'dynamicSize += object.${property.name}.length * 4;';
          break;
        case DataType.LongList:
        case DataType.DoubleList:
          code += 'dynamicSize += object.${property.name}.length * 8;';
          break;
        default:
          break;
      }
    }
    code += '''
    final size = dynamicSize + $staticSize;
    return size + (-(size + $OBJECT_ID_SIZE) % 8);
    ''';
  } else {
    code += 'return ${staticSize + (-(staticSize + OBJECT_ID_SIZE) % 8)};';
  }

  code += '}';
  return code;
}

String _generateSerialize(ObjectInfo object) {
  var code = '''
  @override  
  void serialize(${object.type} object, Map<String, dynamic> cache, BinaryWriter writer) {''';
  for (var property in object.properties) {
    if (property.staticPadding != 0) {
      code += 'writer.pad(${property.staticPadding});';
    }
    if (property.type.isDynamic && property.type.elementAlignment != 1) {
      code += "writer.padDynamic(cache['${property.name}Padding'] as int);";
    }
    var accessor = 'object.${property.name}';
    switch (property.type) {
      case DataType.Bool:
        code += 'writer.writeBool($accessor);';
        break;
      case DataType.Int:
        code += 'writer.writeInt($accessor);';
        break;
      case DataType.Float:
        code += 'writer.writeFloat($accessor);';
        break;
      case DataType.Long:
        code += 'writer.writeLong($accessor);';
        break;
      case DataType.Double:
        code += 'writer.writeDouble($accessor);';
        break;
      case DataType.String:
        code +=
            "writer.writeBytes(cache['${property.name}Bytes'] as Uint8List);";
        break;
      case DataType.Bytes:
        code += 'writer.writeBytes($accessor);';
        break;
      case DataType.BoolList:
        code += 'writer.writeBoolList($accessor);';
        break;
      case DataType.StringList:
        code +=
            "writer.writeBytesList((cache['${property.name}Bytes'] as List).cast());";
        break;
      case DataType.IntList:
        code += 'writer.writeIntList($accessor);';
        break;
      case DataType.LongList:
        code += 'writer.writeLongList($accessor);';
        break;
      case DataType.FloatList:
        code += 'writer.writeFloatList($accessor);';
        break;
      case DataType.DoubleList:
        code += 'writer.writeDoubleList($accessor);';
        break;
    }
  }

  return code + '}';
}

String _generateDeserialize(ObjectInfo object) {
  var code = '''
  @override
  ${object.type} deserialize(BinaryReader reader) {
    final object = ${object.type}();''';
  for (var property in object.properties) {
    if (property.staticPadding != 0) {
      code += 'reader.skip(${property.staticPadding});';
    }
    final accessor = 'object.${property.name}';
    final orNull = property.nullable ? 'OrNull' : '';
    final orElNull = property.elementNullable ? 'OrNull' : '';

    final skipNullList = property.nullable
        ? (String listCode) {
            code += 'if (!reader.skipListIfNull()) {';
            code += listCode;
            code += '}';
          }
        : (String listCode) {
            code += listCode;
          };
    switch (property.type) {
      case DataType.Bool:
        code += '$accessor = reader.readBool$orNull();';
        break;
      case DataType.Int:
        code += '$accessor = reader.readInt$orNull();';
        break;
      case DataType.Float:
        code += '$accessor = reader.readFloat$orNull();';
        break;
      case DataType.Long:
        code += '$accessor = reader.readLong$orNull();';
        break;
      case DataType.Double:
        code += '$accessor = reader.readDouble$orNull();';
        break;
      case DataType.String:
        code += '$accessor = reader.readString$orNull();';
        break;
      case DataType.Bytes:
        code += '$accessor = reader.readBytes$orNull();';
        break;
      case DataType.BoolList:
        skipNullList('$accessor = reader.readBool${orElNull}List();');
        break;
      case DataType.StringList:
        skipNullList('$accessor = reader.readString${orElNull}List();');
        break;
      case DataType.IntList:
        skipNullList('$accessor = reader.readInt${orElNull}List();');
        break;
      case DataType.FloatList:
        skipNullList('$accessor = reader.readFloat${orElNull}List();');
        break;
      case DataType.LongList:
        skipNullList('$accessor = reader.readLong${orElNull}List();');
        break;
      case DataType.DoubleList:
        skipNullList('$accessor = reader.readDouble${orElNull}List();');
        break;
    }
  }

  return '''
      $code
      return object;
    }
    ''';
}
