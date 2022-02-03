import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateNativeTypeAdapter(ObjectInfo object) {
  return '''
    class ${object.nativeAdapterName} extends IsarNativeTypeAdapter<${object.dartName}> {

      const ${object.nativeAdapterName}();

      ${_generateSerialize(object)}
      ${_generateDeserialize(object)}
      ${_generateDeserializeProperty(object)}
      ${_generateAttachLinks(object)}
    }
    ''';
}

String _generatePrepareSerialize(ObjectInfo object) {
  final staticSize = object.staticSize;
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
        code += 'dynamicSize += $accessor$nOp.length $nLen;';
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
    final size = dynamicSize + $staticSize;
    ''';

  return code;
}

String _generateSerialize(ObjectInfo object) {
  var code = '''
  @override  
  void serialize(IsarCollection<${object.dartName}> collection, IsarRawObject rawObj, ${object.dartName} object, List<int> offsets, AdapterAlloc alloc) {
    ${_generatePrepareSerialize(object)}
    rawObj.buffer = alloc(size);
    rawObj.buffer_length = size;
    final buffer = isarBufAsBytes(rawObj.buffer, size);
    final writer = IsarBinaryWriter(buffer, ${object.staticSize});
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

  if (object.links.isNotEmpty) {
    code += 'attachLinks(collection.isar, object);';
  }

  return '$code}';
}

String _generateDeserialize(ObjectInfo object) {
  var code = '''
  @override
  ${object.dartName} deserialize(IsarCollection<${object.dartName}> collection, int id, IsarBinaryReader reader, List<int> offsets) {
    final object = ${object.dartName}(''';
  final propertiesByMode = object.properties.groupBy((p) => p.deserialize);
  final positional = propertiesByMode[PropertyDeser.positionalParam] ?? [];
  final sortedPositional = positional.sortedBy((p) => p.constructorPosition!);
  for (var p in sortedPositional) {
    final index = object.objectProperties.indexOf(p);
    final deser = _deserializeProperty(object, p, 'offsets[$index]');
    code += '$deser,';
  }

  final named = propertiesByMode[PropertyDeser.namedParam] ?? [];
  for (var p in named) {
    final index = object.objectProperties.indexOf(p);
    final deser = _deserializeProperty(object, p, 'offsets[$index]');
    code += '${p.dartName}: $deser,';
  }

  code += ');';

  final assign = propertiesByMode[PropertyDeser.assign] ?? [];
  for (var p in assign) {
    final index = object.objectProperties.indexOf(p);
    final deser = _deserializeProperty(object, p, 'offsets[$index]');
    code += 'object.${p.dartName} = $deser;';
  }

  if (object.links.isNotEmpty) {
    code += 'attachLinks(collection.isar, object);';
  }

  return '''
    $code
    return object;
  }
  ''';
}

String _generateDeserializeProperty(ObjectInfo object) {
  var code = '''
  @override
  P deserializeProperty<P>(int id, IsarBinaryReader reader, int propertyIndex, int offset) {
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
      return 'reader.readBool$orNull($propertyOffset)';
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

String _generateAttachLinks(ObjectInfo object) {
  if (object.links.isEmpty) {
    return '';
  }

  var code = 'void attachLinks(Isar isar, ${object.dartName} object) {';

  for (var link in object.links) {
    code += '''object.${link.dartName}.attach(
      isar.${object.accessor},
      isar.getCollection<${link.targetCollectionDartName}>("${link.targetCollectionDartName.esc}"),
      object,
      "${link.dartName.esc}",
      ${link.backlink},
    );
    ''';
  }
  return code + '}';
}
