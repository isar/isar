import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';

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
        (i, e) => "r'${e.isarName}': ${_generatePropertySchema(i, e)}",
      )
      .join(',');

  code += '''
    name: r'${object.isarName}',
    id: ${object.id},
    properties: {$properties},

    estimateSize: ${object.estimateSize},
    serializeNative: ${object.serializeNativeName},
    deserializeNative: ${object.deserializeNativeName},
    deserializePropNative: ${object.deserializePropNativeName},

    serializeWeb: ${object.serializeWebName},
    deserializeWeb: ${object.deserializeWebName},
    deserializePropWeb: ${object.deserializePropWebName},''';

  if (!object.isEmbedded) {
    final indexes = object.indexes
        .map((e) => "r'${e.name}': ${_generateIndexSchema(e)}")
        .join(',');
    final links = object.links
        .map((e) => "r'${e.isarName}': ${_generateLinkSchema(object, e)}")
        .join(',');
    final embeddedSchemas = object.properties
        .where((e) =>
            e.isarType == IsarType.object || e.isarType == IsarType.objectList)
        .distinctBy((e) => e.targetSchema)
        .map((e) => "r'${e.typeClassName}': ${e.targetSchema}")
        .join(',');

    code += '''
      idName: r'${object.idProperty.isarName}',
      indexes: {$indexes},
      links: {$links},
      embeddedSchemas: {$embeddedSchemas},

      getId: ${object.getIdName},
      getLinks: ${object.getLinksName},
      attach: ${object.attachName},
      version: ${CollectionSchema.generatorVersion},
    ''';
  }

  return '$code);';
}

String _generatePropertySchema(int index, ObjectProperty property) {
  var target = '';
  if (property.isarType == IsarType.object ||
      property.isarType == IsarType.objectList) {
    target = "target: r'${property.scalarDartType}',";
  }
  return '''
  PropertySchema(
    id: $index,
    name: r'${property.isarName}',
    type: IsarType.${property.isarType.name},
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
      isSingle: ${link.isSingle},
      $linkName
    )''';
}
