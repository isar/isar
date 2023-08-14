// ignore_for_file: public_member_api_docs

part of isar_generator;

class ObjectInfo {
  const ObjectInfo({
    required this.dartName,
    required this.isarName,
    required this.properties,
    this.indexes = const [],
    this.accessor,
    this.embeddedDartNames = const {},
  });

  final String dartName;
  final String isarName;
  final String? accessor;
  final List<PropertyInfo> properties;
  final List<IndexInfo> indexes;
  final Set<String> embeddedDartNames;

  bool get isEmbedded => accessor == null;

  PropertyInfo? get idProperty => properties.where((it) => it.isId).firstOrNull;
}

enum DeserializeMode {
  none,
  assign,
  positionalParam,
  namedParam,
}

class PropertyInfo {
  PropertyInfo({
    required this.index,
    required this.dartName,
    required this.isarName,
    required this.typeClassName,
    required this.targetIsarName,
    required this.type,
    required this.isId,
    required this.enumMap,
    required this.enumProperty,
    required this.nullable,
    required this.elementNullable,
    required this.defaultValue,
    required this.elementDefaultValue,
    required this.utc,
    required this.mode,
    required this.assignable,
    required this.constructorPosition,
  });

  final int index;

  final String dartName;
  final String isarName;
  final String typeClassName;
  final String? targetIsarName;

  final IsarType type;
  final bool isId;
  final Map<String, dynamic>? enumMap;
  final String? enumProperty;

  final bool nullable;
  final bool? elementNullable;
  final String defaultValue;
  final String? elementDefaultValue;
  final bool utc;

  final DeserializeMode mode;
  final bool assignable;
  final int? constructorPosition;

  bool get isEnum => enumMap != null;

  String get scalarDartTypeNotNull {
    if (isEnum) {
      return typeClassName;
    }

    switch (type) {
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
      case IsarType.json:
        if (typeClassName == 'List') {
          return 'List<dynamic>';
        } else if (typeClassName == 'Map') {
          return 'Map<String, dynamic>';
        } else {
          return 'dynamic';
        }
    }
  }

  String get scalarDartType {
    final sNN = scalarDartTypeNotNull;
    return type.isList
        ? '$sNN${elementNullable! && typeClassName != 'dynamic' ? '?' : ''}'
        : '$sNN${nullable && typeClassName != 'dynamic' ? '?' : ''}';
  }

  String get dartType => type.isList
      ? 'List<$scalarDartType>${nullable ? '?' : ''}'
      : scalarDartType;

  String enumMapName(ObjectInfo object) =>
      '_${object.dartName.decapitalize()}${dartName.capitalize()}';
}

class IndexInfo {
  IndexInfo({
    required this.name,
    required this.properties,
    required this.unique,
    required this.hash,
  });

  final String name;
  final List<String> properties;
  final bool unique;
  final bool hash;
}
