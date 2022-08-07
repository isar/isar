import 'package:isar/isar.dart';
import 'package:isar_generator/src/code_gen/type_adapter_generator_common.dart';
import 'package:isar_generator/src/object_info.dart';

String generateSerializeWeb(ObjectInfo object) {
  var code = '''
  Object ${object.serializeWebName}(IsarCollection<${object.dartName}> collection, ${object.dartName} object) {
    /*final jsObj = IsarNative.newJsObject();*/''';

  /*for (final property in object.properties) {
    String write(String value) =>
        "IsarNative.jsObjectSet(jsObj, r'${property.isarName}', $value);";

    final value = 'object.${property.dartName}';

    final nOp = property.nullable ? '?' : '';
    final nElOp = property.elementNullable ? '?' : '';
    if (property.isarType == IsarType.dateTime) {
      code += write('$value$nOp.toUtc().millisecondsSinceEpoch');
    } else if (property.isarType == IsarType.dateTimeList) {
      code += write(
        '$value$nOp.map((e) => e$nElOp.toUtc() '
        '.millisecondsSinceEpoch).toList()',
      );
    } else {
      code += write(value);
    }
  }*/

  //code += 'return jsObj;';

  code += 'throw UnimplementedError();';

  return '$code}';
}

String generateDeserializeWeb(ObjectInfo object) {
  String deserProp(ObjectProperty p) => _deserializeProperty(object, p);

  var code = '''
  ${object.dartName} ${object.deserializeWebName}(IsarCollection<${object.dartName}> collection, Object jsObj) {
    /*${deserializeMethodBody(object, deserProp)}*/''';

  /*if (object.links.isNotEmpty) {
    final deserId = deserProp(object.idProperty);
    code += '${object.attachName}(collection, $deserId, object);';
  }*/

  // ignore: leading_newlines_in_multiline_strings
  return '''$code
    //return object;
    throw UnimplementedError();
  }''';
}

String generateDeserializePropWeb(ObjectInfo object) {
  var code = '''
  P ${object.deserializePropWebName}<P>(Object jsObj, String propertyName) {
    switch (propertyName) {''';

  /*for (final property in object.properties) {
    final deser = _deserializeProperty(object, property);
    code += "case r'${property.isarName}': return ($deser) as P;";
  }*/

  return '''
      $code
      default:
        throw IsarError('Illegal propertyName');
      }
    }
    ''';
}

String _defaultVal(ObjectProperty property) {
  if (property.isEnum) {
    return property.defaultEnum;
  }
  switch (property.isarType) {
    case IsarType.byte:
    case IsarType.byteList:
      return '0';
    case IsarType.bool:
    case IsarType.boolList:
      return 'false';
    case IsarType.int:
    case IsarType.intList:
    case IsarType.long:
    case IsarType.longList:
      return '(double.negativeInfinity as int)';
    case IsarType.float:
    case IsarType.floatList:
    case IsarType.double:
    case IsarType.doubleList:
      return 'double.negativeInfinity';
    case IsarType.dateTime:
    case IsarType.dateTimeList:
      return 'DateTime.fromMillisecondsSinceEpoch(0)';
    case IsarType.string:
    case IsarType.stringList:
      return "''";
    case IsarType.object:
    case IsarType.objectList:
      return '${property.typeClassName}()';
  }
}

String _deserializeProperty(ObjectInfo object, ObjectProperty property) {
  final read = "IsarNative.jsObjectGet(jsObj, r'${property.isarName}')";
  String convDate(String e, bool nullable) {
    final c =
        'DateTime.fromMillisecondsSinceEpoch($e as int, isUtc: true).toLocal()';
    if (nullable) {
      return '$e != null ? $c : null';
    } else {
      return '$e != null ? $c : ${_defaultVal(property)}';
    }
  }

  String deser;
  if (property.isarType.isList) {
    final defaultList = property.nullable ? '' : '?? []';
    String? convert;
    if (property.isarType == IsarType.dateTimeList) {
      convert = convDate('e', property.elementNullable);
    } else if (!property.elementNullable) {
      convert = 'e ?? ${_defaultVal(property)}';
    }

    final elType = property.scalarDartType;
    if (convert != null) {
      deser = '($read as List?)?.map((e) => $convert).toList().cast<$elType>() '
          '$defaultList';
    } else {
      deser = '($read as List?)?.cast<$elType>() $defaultList';
    }
  } else if (property.isarType == IsarType.dateTime) {
    deser = convDate(read, property.nullable);
  } else {
    final defaultVal = property.nullable || property.isarType == IsarType.byte
        ? ''
        : '?? ${_defaultVal(property)}';
    deser = '$read $defaultVal';
  }

  return deser;
}
