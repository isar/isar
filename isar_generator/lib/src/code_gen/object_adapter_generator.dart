import 'package:isar_generator/src/object_info.dart';

String generateObjectAdapter(ObjectInfo object) {
  return '''
    class _${object.type}Adapter extends TypeAdapter<${object.type}> {
      ${_generateSerialize(object)}
      ${_generateDeserialize(object)}
    }
    ''';
}

String _generateSerialize(ObjectInfo object) {
  var code = 'void serialize(${object.type} object, RawObject raw) {';
  var staticSize = object.getStaticSize();
  code += 'final staticSize = $staticSize;';
  var dynamicProperties =
      object.properties.where((it) => it.type.isDynamic).toList();
  if (dynamicProperties.isNotEmpty) {
    code += 'var dynamicSize = 0;';
    for (var property in dynamicProperties) {
      if (property.type.elementAlignment != 1) {
        code += '''
        final ${property.name}Padding = -(staticSize + dynamicSize) % ${property.type.elementAlignment};
        dynamicSize += ${property.name}Padding;
        ''';
      }
      switch (property.type) {
        case DataType.String:
          code += '''
          final ${property.name}Bytes = utf8Encoder.convert(object.${property.name});
          dynamicSize += ${property.name}Bytes.length;
          ''';
          break;
        case DataType.Bytes:
        case DataType.BoolList:
          code += 'dynamicSize += object.${property.name}.length;';
          break;
        case DataType.StringList:
          code += '''
          dynamicSize += object.${property.name}.length * 8;
          final ${property.name}Bytes = <Uint8List>[];
          for (var str in object.${property.name}) {
            final bytes = utf8Encoder.convert(str);
            ${property.name}Bytes.add(bytes);
            dynamicSize += bytes.length;
          }
          ''';
          break;
        case DataType.BytesList:
          code += '''
          dynamicSize += object.${property.name}.length * 8;
          for (var bytes in object.${property.name}) {
            dynamicSize += bytes.length;
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
  }

  code += '''
    final bufferSize = staticSize + dynamicSize;
    final ptr = allocate<Uint8>(count: bufferSize);
    final buffer = ptr.asTypedList(bufferSize);
    final writer = BinaryWriter(buffer, staticSize);
    ''';
  for (var property in object.properties) {
    if (property.staticPadding != 0) {
      code += 'writer.skip(${property.staticPadding});';
    }
    if (property.type.isDynamic && property.type.elementAlignment != 1) {
      code += 'writer.skipDynamic(${property.name}Padding);';
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
        code += 'writer.writeBytes(${property.name}Bytes);';
        break;
      case DataType.Bytes:
        code += 'writer.writeBytes($accessor);';
        break;
      case DataType.BoolList:
        code += 'writer.writeBoolList($accessor);';
        break;
      case DataType.StringList:
        code += 'writer.writeBytesList(${property.name}Bytes);';
        break;
      case DataType.BytesList:
        code += 'writer.writeBytesList($accessor);';
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

  return '''
      $code
      
      raw.oid = object.id;
      
      raw.data = ptr;
      raw.data_length = bufferSize;
    }
    ''';
}

String _generateDeserialize(ObjectInfo object) {
  var code = '''
    ${object.type} deserialize(RawObject raw) {
      var buffer = raw.data.asTypedList(raw.length);
      var reader = BinaryReader(buffer);
      var object = ${object.type}();
    ''';
  for (var property in object.properties) {
    if (property.staticPadding != 0) {
      code += 'reader.skip(${property.staticPadding});';
    }
    var accessor = 'object.${property.name}';
    var orNull = property.nullable ? 'OrNull' : '';
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
        code += '$accessor = reader.readlong$orNull();';
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
        code += '$accessor = reader.readBoolList$orNull();';
        break;
      case DataType.StringList:
        code += '$accessor = reader.readStringList$orNull();';
        break;
      case DataType.BytesList:
        code += '$accessor = reader.readBytesList$orNull();';
        break;
      case DataType.IntList:
        code += '$accessor = reader.readIntList$orNull();';
        break;
      case DataType.FloatList:
        code += '$accessor = reader.readFloatList$orNull();';
        break;
      case DataType.LongList:
        code += '$accessor = reader.readLongList$orNull();';
        break;
      case DataType.DoubleList:
        code += '$accessor = reader.readDoubleList$orNull();';
        break;
    }
  }

  return '''
      $code
      return object;
    }
    ''';
}
