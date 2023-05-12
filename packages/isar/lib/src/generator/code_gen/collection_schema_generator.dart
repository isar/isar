import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:isar/src/generator/helper.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

String generateSchema(ObjectInfo object) {
  final schemaJson = _generateSchemaJson(object);

  var code = 'const ${object.schemaName} = ';
  if (object.isEmbedded) {
    code += '''
    const ${object.dartName.decapitalize()}SchemaHash = ${Isar.fastHash(schemaJson)};
    Schema(''';
  } else {
    code += 'CollectionSchema(';
  }

  code += '''
    schema: '${_generateSchemaJson(object)}',
    converter: ObjectConverter<${object.idProperty!.dartType}, ${object.dartName}>(
      serialize: ${object.serializeName},
      deserialize: ${object.deserializeName},
      deserializeProp: ${object.deserializePropName},
    ),''';

  if (!object.isEmbedded) {
    final embeddedSchemas = object.embeddedDartNames
        .map((e) => '${e.capitalize()}Schema')
        .join(',');
    var hash = Isar.fastHash(schemaJson).toString();
    for (final embedded in object.embeddedDartNames) {
      hash = '($hash * 31 + ${embedded.decapitalize()}SchemaHash)';
    }

    code += '''
      embeddedSchemas: [$embeddedSchemas],
      hash: $hash,
    ''';
  }

  return '$code);';
}

String _generateSchemaJson(ObjectInfo object) {
  final json = {
    'name': object.isarName,
    'embedded': object.isEmbedded,
    'properties': [
      for (final prop in object.properties)
        if (!prop.isId || prop.type != PropertyType.long)
          {
            'name': prop.isarName,
            'type': prop.type.name.capitalize(),
            if (prop.type.isObject) 'target': prop.targetIsarName,
            if (prop.isEnum) 'enumMap': prop.enumMap,
          }
    ],
    'indexes': <void>[],
  };
  return jsonEncode(json);
}
