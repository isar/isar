import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';
import 'package:isar_generator/src/isar_type.dart';

import 'package:isar_generator/src/object_info.dart';

String generateSchema(ObjectInfo object) {
  var code = 'const ${object.dartName.capitalize()}Schema = ';
  if (!object.isEmbedded) {
    code += 'CollectionSchema(';
  } else {
    code += 'Schema(';
  }

  final properties = object.objectProperties
      .mapIndexed(
        (i, e) => "r'${e.isarName}': ${_generatePropertySchema(object, i)}",
      )
      .join(',');

  code += '''
    name: r'${object.isarName}',
    id: ${object.id},
    properties: {$properties},

    estimateSize: ${object.estimateSizeName},
    serialize: ${object.serializeName},
    deserialize: ${object.deserializeName},
    deserializeProp: ${object.deserializePropName},''';

  if (!object.isEmbedded) {
    final indexes = object.indexes
        .map((e) => "r'${e.name}': ${_generateIndexSchema(e)}")
        .join(',');
    final links = object.links
        .map((e) => "r'${e.isarName}': ${_generateLinkSchema(object, e)}")
        .join(',');
    final embeddedSchemas = object.embeddedDartNames.entries
        .map((e) => "r'${e.key}': ${e.value.capitalize()}Schema")
        .join(',');

    code += '''
      idName: r'${object.idProperty.isarName}',
      indexes: {$indexes},
      links: {$links},
      embeddedSchemas: {$embeddedSchemas},

      getId: ${object.getIdName},
      getLinks: ${object.getLinksName},
      attach: ${object.attachName},
      version: '${Isar.version}',
    ''';
  }

  return '$code);';
}

String _generatePropertySchema(ObjectInfo object, int index) {
  final property = object.objectProperties[index];
  var enumMap = '';
  if (property.isEnum) {
    enumMap = 'enumMap: ${property.enumValueMapName(object)},';
  }
  var target = '';
  if (property.targetIsarName != null) {
    target = "target: r'${property.targetIsarName}',";
  }
  return '''
  PropertySchema(
    id: $index,
    name: r'${property.isarName}',
    type: IsarType.${property.isarType.name},
    $enumMap
    $target
  )
  ''';
}

String _generateIndexSchema(ObjectIndex index) {
  final properties = index.properties.map((e) {
    return '''
      IndexPropertySchema(
        name: r'${e.property.isarName}',
        type: IndexType.${e.type.name},
        caseSensitive: ${e.caseSensitive},
      )''';
  }).join(',');

  return '''
    IndexSchema(
      id: ${index.id},
      name: r'${index.name}',
      unique: ${index.unique},
      replace: ${index.replace},
      properties: [$properties],
    )''';
}

String _generateLinkSchema(ObjectInfo object, ObjectLink link) {
  var linkName = '';
  if (link.isBacklink) {
    linkName = "linkName: r'${link.targetLinkIsarName}',";
  }
  return '''
    LinkSchema(
      id: ${link.id(object.isarName)},
      name: r'${link.isarName}',
      target: r'${link.targetCollectionIsarName}',
      single: ${link.isSingle},
      $linkName
    )''';
}
