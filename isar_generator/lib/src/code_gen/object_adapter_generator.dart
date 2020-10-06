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
  var hasDynamicProperties = object.properties.any((it) => it.type.isDynamic());
  if (hasDynamicProperties) {
    code += 'var dynamicSize = 0;';
    for (var property in object.properties.where((it) => it.type.isDynamic())) {
      if (property.type == DataType.String) {
        code += '''
          var ${property.name}Bytes = utf8Encoder.convert(object.${property.name});
          dynamicSize += ${property.name}Bytes.length;
          ''';
      } else if (property.type == DataType.Bytes ||
          property.type == DataType.BoolList) {
        code += 'dynamicSize += object.${property.name}.length;';
      } else if (property.type == DataType.IntList ||
          property.type == DataType.DoubleList) {
        code += 'dynamicSize += object.${property.name}.length * 8;';
      }
    }
  }
  var staticSize = object.getStaticSize();
  code += '''
    var bufferSize = $staticSize + dynamicSize;
    var ptr = allocate<Uint8>(count: bufferSize);
    var buffer = ptr.asTypedList(bufferSize);
    var writer = BinaryWriter(buffer, $staticSize);
    ''';
  for (var property in object.properties) {
    var accessor = 'object.${property.name}';
    if (property.type == DataType.Int) {
      code += 'writer.writeInt($accessor);';
    } else if (property.type == DataType.Double) {
      code += 'writer.writeDouble($accessor);';
    } else if (property.type == DataType.Bool) {
      code += 'writer.writeBool($accessor);';
    } else if (property.type == DataType.String) {
      code += 'writer.writeBytes(${property.name}Bytes);';
    } else if (property.type == DataType.Bytes) {
      code += 'writer.writeBytes($accessor);';
    } else if (property.type == DataType.IntList) {
      code += 'writer.writeIntList($accessor);';
    } else if (property.type == DataType.DoubleList) {
      code += 'writer.writeDoubleList($accessor);';
    } else if (property.type == DataType.BoolList) {
      code += 'writer.writeBoolList($accessor);';
    } else if (property.type == DataType.StringList) {
      code += 'writer.writeBytesList($accessor);';
    } else if (property.type == DataType.BytesList) {
      code += 'writer.writeBytesList($accessor);';
    }
  }

  return '''
      $code
      
      if (object.id != null) {
        raw.oid = object.id;
      } else {
        raw.oid = 0;
      }
      raw.data = ptr;
      raw.length = bufferSize;
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
    var accessor = 'object.${property.name}';
    var orNull = property.nullable ? 'OrNull' : '';
    if (property.type == DataType.Int) {
      code += '$accessor = reader.readInt$orNull();';
    } else if (property.type == DataType.Double) {
      code += '$accessor = reader.readDouble$orNull();';
    } else if (property.type == DataType.Bool) {
      code += '$accessor = reader.readBool$orNull();';
    } else if (property.type == DataType.String) {
      code += '$accessor = reader.readString$orNull();';
    } else if (property.type == DataType.Bytes) {
      code += '$accessor = reader.readBytes$orNull();';
    } else if (property.type == DataType.IntList) {
      code += '$accessor = reader.readIntList$orNull();';
    } else if (property.type == DataType.DoubleList) {
      code += '$accessor = reader.readDoubleList$orNull();';
    } else if (property.type == DataType.BoolList) {
      code += '$accessor = reader.readBoolList$orNull();';
    } else if (property.type == DataType.StringList) {
      code += '$accessor = reader.readStringList$orNull();';
    } else if (property.type == DataType.BytesList) {
      code += '$accessor = reader.readBytesList$orNull();';
    }
  }

  return '''
      $code
      return object;
    }
    ''';
}
