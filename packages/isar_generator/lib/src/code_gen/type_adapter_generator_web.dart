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

    switch (property.isarType) {
      case IsarType.bool:
        code += write('IsarJsConverter.boolToJs($propertyValue)');
        break;
      case IsarType.int:
      case IsarType.long:
      case IsarType.float:
      case IsarType.double:
        code += write('IsarJsConverter.numToJs($propertyValue)');
        break;
      case IsarType.dateTime:
        code += write('IsarJsConverter.dateToJs($propertyValue)');
        break;
      /*case IsarType.boolList:
        code += '$accessor = value$i ? $trueBool : $falseBool;';
        break;*/
      default:
        code += write(propertyValue);
        break;
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

String _deserializeProperty(ObjectInfo object, ObjectProperty property) {
  final orNull = property.nullable ? 'OrNull' : '';
  final orNullList = property.nullable ? '' : '?? []';
  final orElNull = property.elementNullable ? 'OrNull' : '';

  final read = "IsarNative.jsObjectGet(jsObj, '${property.isarName.esc}')";

  String? deser;
  switch (property.isarType) {
    case IsarType.bool:
      deser = 'IsarJsConverter.bool${orNull}FromJs($read)';
      break;
    case IsarType.int:
    case IsarType.float:
    case IsarType.long:
    case IsarType.double:
      deser = 'IsarJsConverter.num${orNull}FromJs($read)';
      break;
    case IsarType.dateTime:
      deser = 'IsarJsConverter.dateTime${orNull}FromJs($read)';
      break;
    case IsarType.string:
      deser = 'IsarJsConverter.string${orNull}FromJs($read)';
      break;
    /*case IsarType.bytes:
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
      break;*/
    default:
      deser = '(null as dynamic)';
  }

  return property.fromIsar(deser, object);
}
