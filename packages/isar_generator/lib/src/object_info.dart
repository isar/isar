import 'dart:convert';
import 'dart:typed_data';

import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';

import 'package:xxh3/xxh3.dart';

class ObjectInfo {
  ObjectInfo({
    required this.dartName,
    required this.isarName,
    this.accessor,
    required List<ObjectProperty> properties,
    this.embeddedDartNames = const {},
    this.indexes = const [],
    this.links = const [],
  }) {
    this.properties = properties.sortedBy((e) => e.isarName).toList();
  }

  final String dartName;
  final String isarName;
  final String? accessor;
  late final List<ObjectProperty> properties;
  final Map<String, String> embeddedDartNames;
  final List<ObjectIndex> indexes;
  final List<ObjectLink> links;

  int get id => xxh3(utf8.encode(isarName) as Uint8List);

  bool get isEmbedded => accessor == null;

  ObjectProperty get idProperty => properties.firstWhere((it) => it.isId);

  List<ObjectProperty> get objectProperties =>
      properties.where((it) => !it.isId).toList();

  String get getIdName => '_${dartName.decapitalize()}GetId';
  String get getLinksName => '_${dartName.decapitalize()}GetLinks';
  String get attachName => '_${dartName.decapitalize()}Attach';

  String get estimateSizeName => '_${dartName.decapitalize()}EstimateSize';
  String get serializeName => '_${dartName.decapitalize()}Serialize';
  String get deserializeName => '_${dartName.decapitalize()}Deserialize';
  String get deserializePropName =>
      '_${dartName.decapitalize()}DeserializeProp';
}

enum PropertyDeser {
  none,
  assign,
  positionalParam,
  namedParam,
}

class ObjectProperty {
  ObjectProperty({
    required this.dartName,
    required this.isarName,
    required this.typeClassName,
    required this.isarType,
    required this.isId,
    required this.enumMap,
    required this.enumProperty,
    required this.defaultEnumElement,
    required this.nullable,
    required this.elementNullable,
    this.userDefaultValue,
    required this.deserialize,
    required this.assignable,
    this.constructorPosition,
  });

  final String dartName;
  final String isarName;
  final String typeClassName;

  final bool isId;
  final IsarType isarType;
  final Map<String, dynamic>? enumMap;
  final String? enumProperty;
  final String? defaultEnumElement;

  final bool nullable;
  final bool elementNullable;
  final String? userDefaultValue;

  final PropertyDeser deserialize;
  final bool assignable;
  final int? constructorPosition;

  bool get isEnum => enumMap != null;

  String get scalarDartType {
    if (isId) {
      return 'Id';
    } else if (isEnum) {
      return typeClassName;
    }

    switch (isarType) {
      case IsarType.bool:
      case IsarType.boolList:
        return 'bool';
      case IsarType.byte:
      case IsarType.byteList:
      case IsarType.int:
      case IsarType.intList:
      case IsarType.long:
      case IsarType.longList:
        return 'int';
      case IsarType.float:
      case IsarType.floatList:
      case IsarType.double:
      case IsarType.doubleList:
        return 'double';
      case IsarType.dateTime:
      case IsarType.dateTimeList:
        return 'DateTime';
      case IsarType.object:
      case IsarType.objectList:
        return typeClassName;
      case IsarType.string:
      case IsarType.stringList:
        return 'String';
    }
  }

  String get nScalarDartType => isarType.isList
      ? '$scalarDartType${elementNullable ? '?' : ''}'
      : '$scalarDartType${nullable ? '?' : ''}';

  String get dartType => isarType.isList
      ? 'List<$nScalarDartType>${nullable ? '?' : ''}'
      : nScalarDartType;

  String get targetSchema => '${scalarDartType.capitalize()}Schema';

  String enumValueMapName(ObjectInfo object) {
    return '_${object.dartName}${dartName}EnumValueMap';
  }

  String valueEnumMapName(ObjectInfo object) {
    return '_${object.dartName}${dartName}ValueEnumMap';
  }
}

class ObjectIndexProperty {
  const ObjectIndexProperty({
    required this.property,
    required this.type,
    required this.caseSensitive,
  });

  final ObjectProperty property;
  final IndexType type;
  final bool caseSensitive;

  IsarType get isarType => property.isarType;

  bool get isMultiEntry => isarType.isList && type != IndexType.hash;
}

class ObjectIndex {
  ObjectIndex({
    required this.name,
    required this.properties,
    required this.unique,
    required this.replace,
  });

  final String name;
  final List<ObjectIndexProperty> properties;
  final bool unique;
  final bool replace;

  late final id = xxh3(utf8.encode(name) as Uint8List);
}

class ObjectLink {
  const ObjectLink({
    required this.dartName,
    required this.isarName,
    this.targetLinkIsarName,
    required this.targetCollectionDartName,
    required this.targetCollectionIsarName,
    required this.isSingle,
  });

  final String dartName;
  final String isarName;

  // isar name of the original link (only for backlinks)
  final String? targetLinkIsarName;
  final String targetCollectionDartName;
  final String targetCollectionIsarName;
  final bool isSingle;

  bool get isBacklink => targetLinkIsarName != null;

  int id(String objectIsarName) {
    final col = isBacklink ? targetCollectionIsarName : objectIsarName;
    final colId = xxh3(utf8.encode(col) as Uint8List, seed: isBacklink ? 1 : 0);

    final name = targetLinkIsarName ?? isarName;
    return xxh3(utf8.encode(name) as Uint8List, seed: colId);
  }
}
