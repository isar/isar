// ignore_for_file: public_member_api_docs

part of isar_generator;

class ObjectInfo {
  const ObjectInfo({
    required this.dartName,
    required this.isarName,
    this.accessor,
    required this.properties,
    this.embeddedDartNames = const {},
  });

  final String dartName;
  final String isarName;
  final String? accessor;
  final List<PropertyInfo> properties;
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

  final PropertyType type;
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
      case PropertyType.bool:
      case PropertyType.boolList:
        return 'bool';
      case PropertyType.byte:
      case PropertyType.byteList:
      case PropertyType.int:
      case PropertyType.intList:
      case PropertyType.long:
      case PropertyType.longList:
        return 'int';
      case PropertyType.float:
      case PropertyType.floatList:
      case PropertyType.double:
      case PropertyType.doubleList:
        return 'double';
      case PropertyType.dateTime:
      case PropertyType.dateTimeList:
        return 'DateTime';
      case PropertyType.object:
      case PropertyType.objectList:
        return typeClassName;
      case PropertyType.string:
      case PropertyType.stringList:
        return 'String';
      case PropertyType.json:
        if (typeClassName == 'List') {
          return 'List<dynamic>';
        } else if (typeClassName == 'Map') {
          return 'Map<String, dynamic>';
        } else {
          return typeClassName;
        }
    }
  }

  String get scalarDartType => type.isList
      ? '$scalarDartTypeNotNull${elementNullable! ? '?' : ''}'
      : '$scalarDartTypeNotNull${nullable ? '?' : ''}';

  String get dartType => type.isList
      ? 'List<$scalarDartType>${nullable ? '?' : ''}'
      : scalarDartType;
}

extension PropX on PropertyInfo {
  String enumMapName(ObjectInfo object) =>
      '_${object.dartName.decapitalize()}${dartName.capitalize()}';
}
