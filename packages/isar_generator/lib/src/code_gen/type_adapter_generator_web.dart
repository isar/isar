import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

const falseBool = 1;
const trueBool = 2;
const nullValue = 'double.negativeInfinity';

String generateWebTypeAdapter(ObjectInfo object) {
  return '''
    class ${object.webAdapterName} extends IsarWebTypeAdapter<${object.dartName}> {

      const ${object.webAdapterName}();

      ${_generateSerialize(object)}

      @override
      ${object.dartName} deserialize(IsarCollection<${object.dartName}> collection, IsarJsObject object) {
        throw UnimplementedError();
      }

      @override
      P deserializeProperty<P>(IsarJsObject object, int propertyIndex) {
        throw UnimplementedError();
      }
    }
    ''';
}

String _generateSerialize(ObjectInfo object) {
  var code = '''
  @override  
  IsarJsObject serialize(IsarCollection<${object.dartName}> collection, ${object.dartName} object) {
    final jsObj = isarCreateJsObject();
  ''';
  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];

    String write(String value) => "jsObj['${property.isarName.esc}'] = $value;";

    var propertyValue = 'object.${property.dartName}';
    if (property.converter != null) {
      propertyValue = property.toIsar(propertyValue, object);
    }
    code += 'final value$i = $propertyValue;';

    if (property.nullable) {
      code += '''if (value$i == null) {
          ${write(nullValue)}
        } else {
        ''';
    }

    switch (property.isarType) {
      case IsarType.bool:
        code += write('value$i ? $trueBool : $falseBool');
        break;
      case IsarType.float:
      case IsarType.double:
        code += write('value$i.isNaN ? $nullValue : value$i');
        break;
      case IsarType.dateTime:
        code += write('value$i.toUtc().millisecondsSinceEpoch');
        break;
      /*case IsarType.boolList:
        code += '$accessor = value$i ? $trueBool : $falseBool;';
        break;*/
      default:
        code += write('value$i');
        break;
    }
    if (property.nullable) {
      code += '}';
    }
  }

  code += 'return jsObj;';

  return '$code}';
}
