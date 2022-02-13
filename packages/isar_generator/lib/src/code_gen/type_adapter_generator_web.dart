import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

import 'type_adapter_generator_common.dart';

String generateWebTypeAdapter(ObjectInfo object) {
  return '''
    class ${object.webAdapterName} extends IsarWebTypeAdapter<${object.dartName}> {

      const ${object.webAdapterName}();

      ${_generateSerialize(object)}
      ${_generateDeserialize(object)}
      ${_generateDeserializeProperty(object)}
      ${generateAttachLinks(object)}
    }
    ''';
}

String _generateSerialize(ObjectInfo object) {
  var code = '''
  @override  
  Object serialize(IsarCollection<${object.dartName}> collection, ${object.dartName} object) {
    final jsObj = IsarNative.newJsObject();''';

  for (var property in object.properties) {
    String write(String value) =>
        "IsarNative.jsObjectSet(jsObj, '${property.isarName.esc}', $value);";

    var propertyValue = 'object.${property.dartName}';
    if (property.converter != null) {
      propertyValue = property.toIsar(propertyValue, object);
    }

    final nOp = property.nullable ? '?' : '';
    final nElOp = property.elementNullable ? '?' : '';
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

String _generateDeserialize(ObjectInfo object) {
  String deserProp(ObjectProperty p) => _deserializeProperty(object, p);

  var code = '''
  @override  
  ${object.dartName} deserialize(IsarCollection<${object.dartName}> collection, dynamic jsObj) {
    ${deserializeMethodBody(object, deserProp)}''';

  if (object.links.isNotEmpty) {
    final deserId = deserProp(object.idProperty);
    code += 'attachLinks(collection.isar, $deserId, object);';
  }

  return '''$code
    return object;
  }''';
}

String _generateDeserializeProperty(ObjectInfo object) {
  var code = '''
  @override
  P deserializeProperty<P>(Object jsObj, String propertyName) {
    switch (propertyName) {''';

  for (var property in object.properties) {
    final deser = _deserializeProperty(object, property);
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
    case IsarType.float:
    case IsarType.long:
    case IsarType.double:
      return 'double.negativeInfinity';
    case IsarType.dateTime:
      return 'DateTime.fromMillisecondsSinceEpoch(0)';
    case IsarType.string:
      return "''";
    case IsarType.bytes:
      return 'Uint8List(0)';
    default:
      throw UnimplementedError();
  }
}

String _deserializeProperty(ObjectInfo object, ObjectProperty property) {
  final read = "IsarNative.jsObjectGet(jsObj, '${property.isarName.esc}')";
  String convDate(String e, bool nullable) {
    final c = 'DateTime.fromMillisecondsSinceEpoch($e, isUtc: true).toLocal()';
    if (nullable) {
      return '$e != null ? $c : null';
    } else {
      return '$e != null ? $c : ${_defaultVal(property.isarType)}';
    }
  }

  String deser;
  if (property.isarType.isList && property.isarType != IsarType.bytes) {
    final defaultList = property.nullable ? '' : '?? []';
    String? convert;
    if (property.isarType == IsarType.dateTimeList) {
      convert = convDate('e', property.elementNullable);
    } else if (!property.elementNullable) {
      convert = 'e ?? ${_defaultVal(property.isarType)}';
    }

    final elType =
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
    final defaultVal =
        property.nullable ? '' : '?? ${_defaultVal(property.isarType)}';
    deser = '$read $defaultVal';
  }

  return property.fromIsar(deser, object);
}
