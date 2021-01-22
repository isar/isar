import 'package:isar_generator/src/isar_analyzer.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:isar_generator/src/code_gen/util.dart';
import 'package:dartx/dartx.dart';

String generateObjectAdapter(ObjectInfo object) {
  return '''
    class _${object.dartName}Adapter extends TypeAdapter<${object.dartName}> {

      ${generateConverterFields(object)}

      @override
      final staticSize = ${object.getStaticSize()};

      ${_generatePrepareSerialize(object)}
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
  var code = '''
  @override  
  int prepareSerialize(${object.dartName} object, Map<String, dynamic> cache) {''';
  final staticSize = object.getStaticSize();
  final dynamicConvertedProperties = object.properties
      .where((it) => it.isarType.isDynamic || it.converter != null)
      .toList();
  if (dynamicConvertedProperties.isNotEmpty) {
    code += 'var dynamicSize = 0;';
    for (var property in dynamicConvertedProperties) {
      if (property.isarType.isDynamic &&
          property.isarType.elementAlignment != 1) {
        code += '''
        {
          final padding = -(dynamicSize + $staticSize) % ${property.isarType.elementAlignment};
          cache['${property.isarName}Padding'] = padding;
          dynamicSize += padding;
        }
        ''';
      }
      code += '{';
      var accessor = 'object.${property.dartName}';
      if (property.converter != null) {
        accessor = property.toIsar(accessor, object);
      }
      code += 'final value = $accessor;';
      switch (property.isarType) {
        case IsarType.String:
          code += '''
          final bytes = utf8Encoder.convert(value);
          cache['${property.isarName}'] = bytes;
          dynamicSize += bytes.length;
          ''';
          break;
        case IsarType.Bytes:
        case IsarType.BoolList:
          code += 'dynamicSize += value.length;';
          break;
        case IsarType.StringList:
          code += '''
          dynamicSize += value.length * 8;
          final bytesList = <Uint8List>[];
          for (var str in value) {
            final bytes = utf8Encoder.convert(str);
            bytesList.add(bytes);
            dynamicSize += bytes.length;
          }
          cache['${property.isarName}'] = bytesList;
          ''';
          break;
        case IsarType.IntList:
        case IsarType.FloatList:
          code += 'dynamicSize += value.length * 4;';
          break;
        case IsarType.LongList:
        case IsarType.DoubleList:
          code += 'dynamicSize += value.length * 8;';
          break;
        default:
          break;
      }
      if (property.converter != null &&
          property.isarType != IsarType.String &&
          property.isarType != IsarType.StringList) {
        code += "cache['${property.isarName}'] = value;";
      }
      code += '}';
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
  void serialize(${object.dartName} object, Map<String, dynamic> cache, BinaryWriter writer) {''';
  for (var property in object.properties) {
    if (property.staticPadding != 0) {
      code += 'writer.pad(${property.staticPadding});';
    }
    if (property.isarType.isDynamic &&
        property.isarType.elementAlignment != 1) {
      code += "writer.padDynamic(cache['${property.isarName}Padding'] as int);";
    }

    final accessor = _getSerializeAccessor(property);
    switch (property.isarType) {
      case IsarType.Bool:
        code += 'writer.writeBool($accessor);';
        break;
      case IsarType.Int:
        code += 'writer.writeInt($accessor);';
        break;
      case IsarType.Float:
        code += 'writer.writeFloat($accessor);';
        break;
      case IsarType.Long:
        code += 'writer.writeLong($accessor);';
        break;
      case IsarType.Double:
        code += 'writer.writeDouble($accessor);';
        break;
      case IsarType.String:
        code += 'writer.writeBytes($accessor);';
        break;
      case IsarType.Bytes:
        code += 'writer.writeBytes($accessor);';
        break;
      case IsarType.BoolList:
        code += 'writer.writeBoolList($accessor);';
        break;
      case IsarType.StringList:
        code += 'writer.writeBytesList($accessor);';
        break;
      case IsarType.IntList:
        code += 'writer.writeIntList($accessor);';
        break;
      case IsarType.LongList:
        code += 'writer.writeLongList($accessor);';
        break;
      case IsarType.FloatList:
        code += 'writer.writeFloatList($accessor);';
        break;
      case IsarType.DoubleList:
        code += 'writer.writeDoubleList($accessor);';
        break;
    }
  }

  return code + '}';
}

String _getSerializeAccessor(ObjectProperty property) {
  if (property.isarType == IsarType.String ||
      property.isarType == IsarType.StringList ||
      property.converter != null) {
    var accessor = "cache['${property.isarName}']";
    final nullModifier = property.nullable ? '?' : '';
    switch (property.isarType) {
      case IsarType.Bool:
        accessor += ' as bool$nullModifier';
        break;
      case IsarType.Int:
      case IsarType.Long:
        accessor += ' as int$nullModifier';
        break;
      case IsarType.Float:
      case IsarType.Double:
        accessor += ' as double$nullModifier';
        break;
      case IsarType.String:
      case IsarType.Bytes:
        accessor += ' as Uint8List$nullModifier';
        break;
      default:
        accessor = '($accessor as List$nullModifier)$nullModifier.cast()';
        break;
    }
    return accessor;
  } else {
    return 'object.${property.dartName}';
  }
}

String _generateDeserialize(ObjectInfo object) {
  var code = '''
  @override
  ${object.dartName} deserialize(BinaryReader reader) {
    final object = ${object.dartName}();''';
  for (var property in object.properties) {
    if (property.staticPadding != 0) {
      code += 'reader.skip(${property.staticPadding});';
    }
    final accessor = 'object.${property.isarName}';
    final orNull = property.nullable ? 'OrNull' : '';
    final orElNull = property.elementNullable ? 'OrNull' : '';

    final skipNullList = property.nullable
        ? (String listCode) {
            return '!reader.skipListIfNull() ? $listCode : null';
          }
        : (String listCode) {
            return listCode;
          };

    String deser;
    switch (property.isarType) {
      case IsarType.Bool:
        deser = 'reader.readBool$orNull()';
        break;
      case IsarType.Int:
        deser = 'reader.readInt$orNull()';
        break;
      case IsarType.Float:
        deser = 'reader.readFloat$orNull()';
        break;
      case IsarType.Long:
        deser = 'reader.readLong$orNull()';
        break;
      case IsarType.Double:
        deser = 'reader.readDouble$orNull()';
        break;
      case IsarType.String:
        deser = 'reader.readString$orNull()';
        break;
      case IsarType.Bytes:
        deser = 'reader.readBytes$orNull()';
        break;
      case IsarType.BoolList:
        deser = skipNullList('reader.readBool${orElNull}List()');
        break;
      case IsarType.StringList:
        deser = skipNullList('reader.readString${orElNull}List()');
        break;
      case IsarType.IntList:
        deser = skipNullList('reader.readInt${orElNull}List()');
        break;
      case IsarType.FloatList:
        deser = skipNullList('reader.readFloat${orElNull}List();');
        break;
      case IsarType.LongList:
        deser = skipNullList('reader.readLong${orElNull}List()');
        break;
      case IsarType.DoubleList:
        deser = skipNullList('reader.readDouble${orElNull}List()');
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
