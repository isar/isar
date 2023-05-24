import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:isar/src/generator/helper.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

String generateSchema(ObjectInfo object) {
  final json = {
    'name': object.isarName,
    if (object.isEmbedded) 'embedded': object.isEmbedded,
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
    //'indexes': <void>[],
  };
  final schemaJson = jsonEncode(json);

  if (object.isEmbedded) {
    return '''
    const ${object.dartName.decapitalize()}SchemaHash = ${Isar.fastHash(schemaJson)};
    const ${object.dartName.capitalize()}Schema = Schema(
      schema: '$schemaJson',
      converter: ObjectConverter<void, ${object.dartName}>(
        serialize: serialize${object.dartName},
        deserialize: deserialize${object.dartName},
      ),
    );''';
  } else {
    final embeddedSchemas = object.embeddedDartNames
        .map((e) => '${e.capitalize()}Schema')
        .join(',');
    var hash = Isar.fastHash(schemaJson).toString();
    for (final embedded in object.embeddedDartNames) {
      hash = '($hash * 31 + ${embedded.decapitalize()}SchemaHash)';
    }

    return '''
    const ${object.dartName.capitalize()}Schema = CollectionSchema(
      schema: '$schemaJson',
      converter: ObjectConverter<${object.idProperty!.dartType}, ${object.dartName}>(
        serialize: serialize${object.dartName},
        deserialize: deserialize${object.dartName},
        deserializeProperty: deserialize${object.dartName}Prop,
      ),
      embeddedSchemas: [$embeddedSchemas],
      hash: $hash,
    );''';
  }
}
