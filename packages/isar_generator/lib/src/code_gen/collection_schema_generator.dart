import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateCollectionSchema(ObjectInfo object) {
  final schema = generateSchema(object);
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
  final indexTypes = object.indexes
      .map((i) =>
          "'${i.name.esc}': [${i.properties.map((e) => e.indexTypeEnum).join(',')},]")
      .join(',');
  final linkIds = object.links
      .where((e) => !e.backlink)
      .mapIndexed((i, link) => "'${link.isarName.esc}': $i")
      .join(',');
  final backlinkCollections = object.links
      .where((e) => e.backlink)
      .map((link) => "'${link.isarName.esc}': ${link.targetCollectionIsarName}")
      .join(',');
  final linkedCollections = object.links
      .map((e) => "'${e.targetCollectionIsarName.esc}'")
      .distinct()
      .join(',');
  final getLinks =
      '(obj) => [${object.links.map((e) => 'obj.${e.dartName}').join(',')}]';

  final setId = '(obj, id) => obj.${object.idProperty.dartName} = id';
  return '''
    final ${object.dartName.capitalize()}Schema = CollectionSchema(
      name: '${object.isarName.esc}',
      schema: '$schema',
      nativeAdapter: const ${object.nativeAdapterName}(),
      webAdapter: const ${object.webAdapterName}(),
      idName: '${object.idProperty.isarName.esc}',
      propertyIds: {$propertyIds},
      listProperties: {$listProperties},
      indexIds: {$indexIds},
      indexTypes: {$indexTypes},
      linkIds: {$linkIds},
      linkedCollections: [$linkedCollections],
      getId: (obj) {
        if (obj.${object.idProperty.dartName} == Isar.autoIncrement) {
          return null;
        } else {
          return obj.${object.idProperty.dartName};
        }
      },
      setId: ${object.idProperty.assignable ? setId : 'null'},
      getLinks: $getLinks,
      version: ${CollectionSchema.generatorVersion},
    );''';
}

String generateSchema(ObjectInfo object) {
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
