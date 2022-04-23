import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateCollectionSchema(ObjectInfo object) {
  final schema = _generateSchema(object);

  final propertyIds = object.objectProperties
      .mapIndexed((index, p) => "'${p.isarName.esc}': $index")
      .join(',');
  final listProperties = object.objectProperties
      .filter((p) => p.isarType.isList)
      .map((p) => "'${p.isarName.esc}'")
      .join(',');
  final indexIds = object.indexes
      .mapIndexed((index, i) => "'${i.name.esc}': $index")
      .join(',');
  final indexValueTypes = object.indexes
      .map((i) =>
          "'${i.name.esc}': [${i.properties.map((e) => e.indexValueTypeEnum).join(',')},]")
      .join(',');
  final linkIds = object.links
      .mapIndexed((i, link) => "'${link.isarName.esc}': $i")
      .join(',');
  final backlinkLinkNames = object.links
      .where((e) => e.backlink)
      .map((link) => "'${link.isarName.esc}': '${link.targetIsarName}'")
      .join(',');

  return '''
    const ${object.dartName.capitalize()}Schema = CollectionSchema(
      name: '${object.isarName.esc}',
      schema: '$schema',
      
      idName: '${object.idProperty.isarName.esc}',
      propertyIds: {$propertyIds},
      listProperties: {$listProperties},
      indexIds: {$indexIds},
      indexValueTypes: {$indexValueTypes},
      linkIds: {$linkIds},
      backlinkLinkNames: {$backlinkLinkNames},

      getId: ${object.getIdName},
      ${object.idProperty.assignable ? 'setId: ${object.setIdName},' : ''}
      getLinks: ${object.getLinksName},
      attachLinks: ${object.attachLinksName},

      serializeNative: ${object.serializeNativeName},
      deserializeNative: ${object.deserializeNativeName},
      deserializePropNative: ${object.deserializePropNativeName},

      serializeWeb: ${object.serializeWebName},
      deserializeWeb: ${object.deserializeWebName},
      deserializePropWeb: ${object.deserializePropWebName},

      version: ${CollectionSchema.generatorVersion},
    );
    
    ${_generateGetId(object)}
    ${_generateSetId(object)}
    ${_generateGetLinks(object)}
    ''';
}

String _generateSchema(ObjectInfo object) {
  final json = {
    'name': object.isarName,
    'idName': object.idProperty.isarName,
    'properties': [
      for (var property in object.objectProperties)
        {
          'name': property.isarName,
          'type': property.isarType.name,
        },
    ],
    'indexes': [
      for (var index in object.indexes)
        {
          'name': index.name,
          'unique': index.unique,
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
  return jsonEncode(json).esc;
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

String _generateSetId(ObjectInfo object) {
  if (!object.idProperty.assignable) return '';

  return '''
    void ${object.setIdName}(${object.dartName} object, int id) {
      object.${object.idProperty.dartName} = id;
    }
  ''';
}

String _generateGetLinks(ObjectInfo object) {
  return '''
    List<IsarLinkBase> ${object.getLinksName}(${object.dartName} object) {
      return [${object.links.map((e) => 'object.${e.dartName}').join(',')}];
    }
  ''';
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
