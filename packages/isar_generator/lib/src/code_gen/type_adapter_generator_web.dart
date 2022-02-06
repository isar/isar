import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

import 'type_adapter_generator_common.dart';

const falseBool = 1;
const trueBool = 2;
const nullValue = 'double.negativeInfinity';

String generateWebTypeAdapter(ObjectInfo object) {
  return '''
    class ${object.webAdapterName} extends IsarWebTypeAdapter<${object.dartName}> {

      const ${object.webAdapterName}();

      ${_generateSerialize(object)}

      ${_generateDeserialize(object)}

      @override
      P deserializeProperty<P>(Object object, String propertyName) {
        throw UnimplementedError();
      }

      @override
      void attachLinks(Isar isar, ${object.dartName} object) {
      }
    }
    ''';
}

String _generateSerialize(ObjectInfo object) {
  var code = '''
  @override  
  Object serialize(IsarCollection<${object.dartName}> collection, ${object.dartName} object) {
    final jsObj = IsarNative.newJsObject();
    if (object.${object.idProperty.dartName} != null) {
      IsarNative.jsObjectSet(jsObj, '${object.idProperty.isarName.esc}', object.${object.idProperty.dartName});
    }
  ''';
  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];

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

  return '''
  @override  
  ${object.dartName} deserialize(IsarCollection<${object.dartName}> collection, dynamic jsObj) {
    ${deserializeMethodBody(object, deserProp)}
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
    final defaultList = property.nullable ? '?? []' : '';
    String? convert;
    if (property.isarType == IsarType.dateTimeList) {
      convert = convDate('e', property.elementNullable);
    } else if (!property.elementNullable) {
      convert = 'e ?? ${_defaultVal(property.isarType)}';
    }
    if (convert != null) {
      final nOp = property.nullable ? '?' : '';
      deser = '$read$nOp.map((e) => $convert).toList() $defaultList';
    } else {
      deser = '$read $defaultList';
    }
  } else if (property.isarType == IsarType.dateTime) {
    deser = convDate(read, property.nullable);
  } else {
    final defaultVal =
        property.nullable ? '?? ${_defaultVal(property.isarType)}' : '';
    deser = '$read $defaultVal';
  }

  return property.fromIsar(deser, object);
}
