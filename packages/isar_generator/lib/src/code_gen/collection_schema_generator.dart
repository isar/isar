import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateCollectionSchema(ObjectInfo object) {
  final schema = generateSchema(object);
  final propertyIds = object.objectProperties
      .mapIndexed((index, p) => "'${p.dartName}': $index")
      .join(',');
  final indexIds = object.indexes
      .mapIndexed(
          (index, i) => "'${i.properties.first.property.dartName}': $index")
      .join(',');
  final indexTypes = object.indexes
      .map((i) =>
          "'${i.properties.first.property.dartName}': [${i.properties.map((e) => e.indexTypeEnum).join(',')},]")
      .join(',');
  final linkIds = object.links
      .where((l) => !l.backlink)
      .mapIndexed((i, link) => "'${link.dartName}': $i")
      .join(',');
  final backlinkIds = object.links
      .where((l) => l.backlink)
      .mapIndexed((i, link) => "'${link.dartName}': $i")
      .join(',');
  final linkedCollections = object.links
      .map((e) => "'${e.targetCollectionDartName}'")
      .distinct()
      .join(',');
  final getLinks =
      '(obj) => [${object.links.map((e) => 'obj.${e.dartName}').join(',')}]';

  final setId = '(obj, id) => obj.${object.idProperty.dartName} = id';
  return '''
    final ${object.dartName.capitalize()}Schema = CollectionSchema(
      name: '${object.dartName}',
      schema: '$schema',
      adapter: const ${object.adapterName}(),
      idName: '${object.idProperty.isarName}',
      propertyIds: {$propertyIds},
      indexIds: {$indexIds},
      indexTypes: {$indexTypes},
      linkIds: {$linkIds},
      backlinkIds: {$backlinkIds},
      linkedCollections: [$linkedCollections],
      getId: (obj) => obj.${object.idProperty.dartName},
      setId: ${object.idProperty.assignable ? setId : 'null'},
      getLinks: $getLinks,
      version: ${CollectionSchema.generatorVersion},
    );''';
}

String generateSchema(ObjectInfo object) {
  final json = {
    'name': object.isarName,
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
  return jsonEncode(json);
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

extension on IsarType {
  String get name {
    switch (this) {
      case IsarType.bool:
        return "Byte";
      case IsarType.int:
        return "Int";
      case IsarType.float:
        return "Float";
      case IsarType.long:
      case IsarType.dateTime:
        return "Long";
      case IsarType.double:
        return "Double";
      case IsarType.string:
        return "String";
      case IsarType.bytes:
      case IsarType.boolList:
        return "ByteList";
      case IsarType.intList:
        return "IntList";
      case IsarType.floatList:
        return "FloatList";
      case IsarType.longList:
      case IsarType.dateTimeList:
        return "LongList";
      case IsarType.doubleList:
        return "DoubleList";
      case IsarType.stringList:
        return "StringList";
    }
  }
}
