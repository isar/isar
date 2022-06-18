import '../helper.dart';
import '../isar_type.dart';
import '../object_info.dart';

import 'type_adapter_generator_common.dart';

String generateSerializeWeb(ObjectInfo object) {
  String code = '''
  Object ${object.serializeWebName}(IsarCollection<${object.dartName}> collection, ${object.dartName} object) {
    final jsObj = IsarNative.newJsObject();''';

  for (final ObjectProperty property in object.properties) {
    String write(String value) =>
        "IsarNative.jsObjectSet(jsObj, '${property.isarName.esc}', $value);";

    String propertyValue = 'object.${property.dartName}';
    if (property.converter != null) {
      propertyValue = property.toIsar(propertyValue, object);
    }

    final String nOp = property.nullable ? '?' : '';
    final String nElOp = property.elementNullable ? '?' : '';
    if (property.isarType == IsarType.dateTime) {
      code += write('$propertyValue$nOp.toUtc().millisecondsSinceEpoch');
    } else if (property.isarType == IsarType.dateTimeList) {
      code += write(
          '$propertyValue$nOp.map((e) => e$nElOp.toUtc().millisecondsSinceEpoch).toList()');
    } else {
      code += write(propertyValue);
    }
  }

  code += 'return jsObj;';

  return '$code}';
}

String generateDeserializeWeb(ObjectInfo object) {
  String deserProp(ObjectProperty p) => _deserializeProperty(object, p);

  String code = '''
  ${object.dartName} ${object.deserializeWebName}(IsarCollection<${object.dartName}> collection, Object jsObj) {
    ${deserializeMethodBody(object, deserProp)}''';

  if (object.links.isNotEmpty) {
    final String deserId = deserProp(object.idProperty);
    code += '${object.attachLinksName}(collection, $deserId, object);';
  }

  // ignore: leading_newlines_in_multiline_strings
  return '''$code
    return object;
  }''';
}

String generateDeserializePropWeb(ObjectInfo object) {
  String code = '''
  P ${object.deserializePropWebName}<P>(Object jsObj, String propertyName) {
    switch (propertyName) {''';

  for (final ObjectProperty property in object.properties) {
    final String deser = _deserializeProperty(object, property);
    code += "case '${property.isarName.esc}': return ($deser) as P;";
  }

  return '''
      $code
      default:
        throw 'Illegal propertyName';
      }
    }
    ''';
}

String _defaultVal(IsarType type) {
  if (type.isList && type != IsarType.bytes) {
    type = type.scalarType;
  }
  switch (type) {
    case IsarType.bool:
      return 'false';
    case IsarType.int:
    case IsarType.long:
      return '(double.negativeInfinity as int)';
    case IsarType.float:
    case IsarType.double:
      return 'double.negativeInfinity';
    case IsarType.dateTime:
      return 'DateTime.fromMillisecondsSinceEpoch(0)';
    case IsarType.string:
      return "''";
    case IsarType.bytes:
      return 'Uint8List(0)';
    // ignore: no_default_cases
    default:
      throw UnimplementedError();
  }
}

String _deserializeProperty(ObjectInfo object, ObjectProperty property) {
  final String read =
      "IsarNative.jsObjectGet(jsObj, '${property.isarName.esc}')";
  String convDate(String e, bool nullable) {
    final String c =
        'DateTime.fromMillisecondsSinceEpoch($e as int, isUtc: true).toLocal()';
    if (nullable) {
      return '$e != null ? $c : null';
    } else {
      return '$e != null ? $c : ${_defaultVal(property.isarType)}';
    }
  }

  String deser;
  if (property.isarType.isList && property.isarType != IsarType.bytes) {
    final String defaultList = property.nullable ? '' : '?? []';
    String? convert;
    if (property.isarType == IsarType.dateTimeList) {
      convert = convDate('e', property.elementNullable);
    } else if (!property.elementNullable) {
      convert = 'e ?? ${_defaultVal(property.isarType)}';
    }

    final String elType =
        property.isarType.scalarType.dartType(property.elementNullable, false);
    if (convert != null) {
      deser =
          '($read as List?)?.map((e) => $convert).toList().cast<$elType>() $defaultList';
    } else {
      deser = '($read as List?)?.cast<$elType>() $defaultList';
    }
  } else if (property.isarType == IsarType.dateTime) {
    deser = convDate(read, property.nullable);
  } else {
    final String defaultVal =
        property.nullable ? '' : '?? ${_defaultVal(property.isarType)}';
    deser = '$read $defaultVal';
  }

  return property.fromIsar(deser, object);
}
