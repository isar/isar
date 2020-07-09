import 'package:isar_generator/src/object_info.dart';

String generateObjectAdapter(ObjectInfo object) {
  return """
    class _${object.name}Adapter extends TypeAdapter<${object.name}> {
      ${_generateSerialize(object)}
      ${_generateDeserialize(object)}
    }
    """;
}

String _generateSerialize(ObjectInfo object) {
  var code = "void serialize(${object.name} object, RawObject raw) {";
  var hasDynamicFields = object.fields.any((it) => it.type.isDynamic());
  if (hasDynamicFields) {
    code += "var dynamicSize = 0;";
    for (var field in object.fields.where((it) => it.type.isDynamic())) {
      if (field.type == DataType.String) {
        code += """
          var ${field.name}Bytes = utf8Encoder.convert(object.${field.name});
          dynamicSize += ${field.name}Bytes.length;
          """;
      } else if (field.type == DataType.Bytes ||
          field.type == DataType.BoolList) {
        code += "dynamicSize += object.${field.name}.length;";
      } else if (field.type == DataType.IntList ||
          field.type == DataType.DoubleList) {
        code += "dynamicSize += object.${field.name}.length * 8;";
      }
    }
  }
  var staticSize = object.getStaticSize();
  code += """
    var bufferSize = $staticSize + dynamicSize;
    var ptr = allocate<Uint8>(count: bufferSize);
    var buffer = ptr.asTypedList(bufferSize);
    var writer = BinaryWriter(buffer, $staticSize);
    
    """;
  for (var field in object.fields) {
    var accessor = "object.${field.name}";
    if (field.type == DataType.Int) {
      code += "writer.writeInt($accessor);";
    } else if (field.type == DataType.Double) {
      code += "writer.writeDouble($accessor);";
    } else if (field.type == DataType.Bool) {
      code += "writer.writeBool($accessor);";
    } else if (field.type == DataType.String) {
      code += "writer.writeBytes(${field.name}Bytes);";
    } else if (field.type == DataType.Bytes) {
      code += "writer.writeBytes($accessor);";
    } else if (field.type == DataType.IntList) {
      code += "writer.writeIntList($accessor);";
    } else if (field.type == DataType.DoubleList) {
      code += "writer.writeDoubleList($accessor);";
    } else if (field.type == DataType.BoolList) {
      code += "writer.writeBoolList($accessor);";
    } else if (field.type == DataType.StringList) {
      code += "writer.writeBytesList($accessor);";
    } else if (field.type == DataType.BytesList) {
      code += "writer.writeBytesList($accessor);";
    }
  }

  return """
      $code
      
      if (object.id != null) {
        raw.oid = object.id;
      } else {
        raw.oid = 0;
      }
      raw.data = ptr;
      raw.length = bufferSize;
    }
    """;
}

String _generateDeserialize(ObjectInfo object) {
  var code = """
    ${object.name} deserialize(RawObject raw) {
      var buffer = raw.data.asTypedList(raw.length);
      var reader = BinaryReader(buffer);
      var object = ${object.name}();
    """;
  for (var field in object.fields) {
    var accessor = "object.${field.name}";
    var orNull = field.nullable ? "OrNull" : "";
    if (field.type == DataType.Int) {
      code += "$accessor = reader.readInt$orNull();";
    } else if (field.type == DataType.Double) {
      code += "$accessor = reader.readDouble$orNull();";
    } else if (field.type == DataType.Bool) {
      code += "$accessor = reader.readBool$orNull();";
    } else if (field.type == DataType.String) {
      code += "$accessor = reader.readString$orNull();";
    } else if (field.type == DataType.Bytes) {
      code += "$accessor = reader.readBytes$orNull();";
    } else if (field.type == DataType.IntList) {
      code += "$accessor = reader.readIntList$orNull();";
    } else if (field.type == DataType.DoubleList) {
      code += "$accessor = reader.readDoubleList$orNull();";
    } else if (field.type == DataType.BoolList) {
      code += "$accessor = reader.readBoolList$orNull();";
    } else if (field.type == DataType.StringList) {
      code += "$accessor = reader.readStringList$orNull();";
    } else if (field.type == DataType.BytesList) {
      code += "$accessor = reader.readBytesList$orNull();";
    }
  }

  return """
      $code
      return object;
    }
    """;
}
