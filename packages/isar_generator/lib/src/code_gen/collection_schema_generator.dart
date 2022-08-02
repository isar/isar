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
      .map((e) => "r'${e.isarName}': ${_generatePropertySchema(e)}")
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

    code += '''
      idName: r'${object.idProperty.isarName}',
      indexes: {$indexes},
      links: {$links},
      embeddedSchemas: {},

      getId: ${object.getIdName},
      getLinks: ${object.getLinksName},
      attach: ${object.attachName},
      version: ${CollectionSchema.generatorVersion},
    ''';
  }
  //print(code);

  return '''
    $code
    );
    
    ${_generateGetId(object)}
    ${_generateGetLinks(object)}
    ${_generateAttach(object)}''';
}

String _generatePropertySchema(ObjectProperty property) {
  var target = '';
  if (property.isarType == IsarType.object ||
      property.isarType == IsarType.objectList) {
    target = "target: r'${property.scalarDartType}',";
  }
  return '''
  PropertySchema(
    id: ${property.id},
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

String _generateGetId(ObjectInfo object) {
  return '''
    int? ${object.getIdName}(${object.dartName} object) {
      if (object.${object.idProperty.dartName} == Isar.autoIncrement) {
        return null;
      } else {
        return object.${object.idProperty.dartName};
      }
    }
  ''';
}

String _generateGetLinks(ObjectInfo object) {
  return '''
    List<IsarLinkBase<dynamic>> ${object.getLinksName}(${object.dartName} object) {
      return [${object.links.map((e) => 'object.${e.dartName}').join(',')}];
    }
  ''';
}

String _generateAttach(ObjectInfo object) {
  var code = '''
  void ${object.attachName}(IsarCollection<dynamic> col, Id id, ${object.dartName} object) {''';

  if (object.idProperty.assignable) {
    code += 'object.${object.idProperty.dartName} = id;';
  }

  for (final link in object.links) {
    // ignore: leading_newlines_in_multiline_strings
    code += '''object.${link.dartName}.attach(
      col,
      col.isar.collection<${link.targetCollectionDartName}>,
      r'${link.isarName}',
      id
    );''';
  }
  return '$code}';
}
