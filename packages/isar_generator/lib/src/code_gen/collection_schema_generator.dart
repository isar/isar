import 'dart:convert';

import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';

import '../helper.dart';
import '../isar_type.dart';
import '../object_info.dart';

String generateCollectionSchema(ObjectInfo object) {
  final String schema = _generateSchema(object);

  final String propertyIds = object.objectProperties
      .mapIndexed(
          (int index, ObjectProperty p) => "'${p.isarName.esc}': $index")
      .join(',');
  final String listProperties = object.objectProperties
      .filter((ObjectProperty p) => p.isarType.isList)
      .map((ObjectProperty p) => "'${p.isarName.esc}'")
      .join(',');
  final String indexIds = object.indexes
      .mapIndexed((int index, ObjectIndex i) => "'${i.name.esc}': $index")
      .join(',');
  final String indexValueTypes = object.indexes
      .map((ObjectIndex i) =>
          "'${i.name.esc}': [${i.properties.map((ObjectIndexProperty e) => e.indexValueTypeEnum).join(',')},]")
      .join(',');
  final String linkIds = object.links
      .mapIndexed((int i, ObjectLink link) => "'${link.isarName.esc}': $i")
      .join(',');
  final String backlinkLinkNames = object.links
      .where((ObjectLink e) => e.backlink)
      .map((ObjectLink link) =>
          "'${link.isarName.esc}': '${link.targetIsarName}'")
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
  final Map<String, Object> json = {
    'name': object.isarName,
    'idName': object.idProperty.isarName,
    'properties': [
      for (ObjectProperty property in object.objectProperties)
        {
          'name': property.isarName,
          'type': property.isarType.name,
        },
    ],
    'indexes': [
      for (ObjectIndex index in object.indexes)
        {
          'name': index.name,
          'unique': index.unique,
          'replace': index.replace,
          'properties': [
            for (ObjectIndexProperty indexProperty in index.properties)
              {
                'name': indexProperty.property.isarName,
                'type': indexProperty.type.name,
                'caseSensitive': indexProperty.caseSensitive,
              }
          ]
        }
    ],
    'links': [
      for (ObjectLink link in object.links) ...[
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
  if (!object.idProperty.assignable) {
    return '';
  }

  return '''
    void ${object.setIdName}(${object.dartName} object, int id) {
      object.${object.idProperty.dartName} = id;
    }
  ''';
}

String _generateGetLinks(ObjectInfo object) {
  return '''
    List<IsarLinkBase<dynamic>> ${object.getLinksName}(${object.dartName} object) {
      return [${object.links.map((ObjectLink e) => 'object.${e.dartName}').join(',')}];
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
