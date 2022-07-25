import 'dart:convert';

import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';

import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

String generateCollectionSchema(ObjectInfo object) {
  final schema = _generateSchema(object);

  final propertyIds =
      object.objectProperties.map((p) => "r'${p.isarName}': ${p.id}").join(',');
  final listProperties = object.objectProperties
      .filter((p) => p.isarType.isList)
      .map((p) => "r'${p.isarName}'")
      .join(',');

  final indexIds = object.indexes.map((i) => "r'${i.name}': ${i.id}").join(',');
  final indexValueTypes = object.indexes.map((i) {
    final types = i.properties.map((e) => e.indexValueTypeEnum).join(',');
    return "r'${i.name}': [$types,]";
  }).join(',');

  final linkIds = object.links
      .map((l) => "r'${l.isarName}': ${l.id(object.isarName)}")
      .join(',');
  final backlinkLinkNames = object.links
      .where((e) => e.backlink)
      .map((link) => "r'${link.isarName}': r'${link.targetIsarName}'")
      .join(',');
  final linkedSchemaNames =
      object.links.map((l) => "r'${l.targetCollectionIsarName}'").join(',');

  final embeddedSchemas = object.properties
      .where(
        (e) =>
            e.isarType == IsarType.object || e.isarType == IsarType.objectList,
      )
      .map((e) => e.dartName)
      .where((e) => e != object.dartName)
      .toSet()
      .map((e) => "r'$e': ${e.capitalize()}Schema")
      .join(',');

  return '''
    const ${object.dartName.capitalize()}Schema = CollectionSchema(
      name: r'${object.isarName}',
      id: ${object.id},
      schema: r'$schema',
      
      idName: r'${object.idProperty.isarName}',
      propertyIds: {$propertyIds},
      listProperties: {$listProperties},
      indexIds: {$indexIds},
      indexValueTypes: {$indexValueTypes},
      linkIds: {$linkIds},
      backlinkLinkNames: {$backlinkLinkNames},
      linkedSchemaNames: [$linkedSchemaNames],

      embeddedSchemas: {$embeddedSchemas},

      getId: ${object.getIdName},
      getLinks: ${object.getLinksName},
      attach: ${object.attachName},

      estimateSize: ${object.estimateSize},
      serializeNative: ${object.serializeNativeName},
      deserializeNative: ${object.deserializeNativeName},
      deserializePropNative: ${object.deserializePropNativeName},

      serializeWeb: ${object.serializeWebName},
      deserializeWeb: ${object.deserializeWebName},
      deserializePropWeb: ${object.deserializePropWebName},

      version: ${CollectionSchema.generatorVersion},
    );
    
    ${_generateGetId(object)}
    ${_generateGetLinks(object)}
    ${_generateAttach(object)}
    ''';
}

String _generateSchema(ObjectInfo object) {
  final json = <String, Object>{
    'name': object.isarName,
    'embedded': object.isEmbedded,
    'idName': object.idProperty.isarName,
    'properties': [
      for (var property in object.objectProperties)
        {
          'name': property.isarName,
          'type': property.isarType.name,
          if (property.isarType == IsarType.object ||
              property.isarType == IsarType.objectList)
            'target': property.scalarDartType,
        },
    ],
    'indexes': [
      for (var index in object.indexes)
        {
          'name': index.name,
          'unique': index.unique,
          'replace': index.replace,
          'properties': [
            for (var indexProperty in index.properties)
              {
                'name': indexProperty.property.isarName,
                'type': indexProperty.type.name,
                'caseSensitive': indexProperty.caseSensitive,
              }
          ]
        }
    ],
    'links': [
      for (var link in object.links) ...[
        if (!link.backlink)
          {
            'name': link.isarName,
            'target': link.targetCollectionIsarName,
          }
      ]
    ]
  };
  return jsonEncode(json);
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
      col.isar.${link.targetCollectionAccessor},
      r'${link.isarName}',
      id
    );''';
  }
  return '$code}';
}

extension on IndexType {
  String get name {
    switch (this) {
      case IndexType.value:
        return 'Value';
      case IndexType.hash:
        return 'Hash';
      case IndexType.hashElements:
        return 'HashElements';
    }
  }
}
