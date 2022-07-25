import 'dart:convert';
import 'dart:typed_data';

import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';

import 'package:isar_generator/src/isar_type.dart';
import 'package:xxh3/xxh3.dart';

class ObjectInfo {
  const ObjectInfo({
    required this.dartName,
    required this.isarName,
    this.accessor,
    required this.properties,
    this.indexes = const [],
    this.links = const [],
  });
  final String dartName;
  final String isarName;
  final String? accessor;
  final List<ObjectProperty> properties;
  final List<ObjectIndex> indexes;
  final List<ObjectLink> links;

  int get id => xxh3(utf8.encode(isarName) as Uint8List);

  bool get isEmbedded => accessor == null;

  ObjectProperty get idProperty =>
      properties.firstWhere((ObjectProperty it) => it.isarType == IsarType.id);

  List<ObjectProperty> get objectProperties => properties
      .where((ObjectProperty it) => it.isarType != IsarType.id)
      .toList();

  String get getIdName => '_${dartName.decapitalize()}GetId';
  String get getLinksName => '_${dartName.decapitalize()}GetLinks';
  String get attachName => '_${dartName.decapitalize()}Attach';

  String get estimateSize => '_${dartName.decapitalize()}EstimateSize';
  String get serializeNativeName =>
      '_${dartName.decapitalize()}SerializeNative';
  String get deserializeNativeName =>
      '_${dartName.decapitalize()}DeserializeNative';
  String get deserializePropNativeName =>
      '_${dartName.decapitalize()}DeserializePropNative';

  String get serializeWebName => '_${dartName.decapitalize()}SerializeWeb';
  String get deserializeWebName => '_${dartName.decapitalize()}DeserializeWeb';
  String get deserializePropWebName =>
      '_${dartName.decapitalize()}DeserializePropWeb';
}

enum PropertyDeser {
  none,
  assign,
  positionalParam,
  namedParam,
}

class ObjectProperty {
  const ObjectProperty({
    required this.dartName,
    required this.isarName,
    required this.scalarDartType,
    required this.isarType,
    required this.nullable,
    required this.elementNullable,
    this.defaultValue,
    required this.deserialize,
    required this.assignable,
    this.constructorPosition,
  });

  final String dartName;
  final String isarName;
  final String scalarDartType;
  final IsarType isarType;

  final bool nullable;
  final bool elementNullable;
  final String? defaultValue;

  final PropertyDeser deserialize;
  final bool assignable;
  final int? constructorPosition;

  int get id => xxh3(utf8.encode(isarName) as Uint8List);

  String get dartType => isarType.isList
      ? 'List<$scalarDartType${elementNullable ? '?' : ''}>${nullable ? '?' : ''}'
      : '$scalarDartType${nullable ? '?' : ''}';

  String get targetSchema => '${scalarDartType.capitalize()}Schema';
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
  const ObjectIndex({
    required this.name,
    required this.properties,
    required this.unique,
    required this.replace,
  });

  final String name;
  final List<ObjectIndexProperty> properties;
  final bool unique;
  final bool replace;

  int get id => xxh3(utf8.encode(name) as Uint8List);
}

class ObjectLink {
  const ObjectLink({
    required this.dartName,
    required this.isarName,
    this.targetIsarName,
    required this.targetCollectionDartName,
    required this.targetCollectionIsarName,
    required this.targetCollectionAccessor,
    required this.links,
    required this.backlink,
  });

  final String dartName;
  final String isarName;

  // isar name of the original link (only for backlinks)
  final String? targetIsarName;
  final String targetCollectionDartName;
  final String targetCollectionIsarName;
  final String targetCollectionAccessor;
  final bool links;
  final bool backlink;

  int id(String objectIsarName) {
    final col = backlink ? targetCollectionIsarName : objectIsarName;
    final colId = xxh3(utf8.encode(col) as Uint8List, seed: backlink ? 1 : 0);

    final name = backlink ? targetIsarName! : isarName;
    return xxh3(utf8.encode(name) as Uint8List, seed: colId);
  }
}
