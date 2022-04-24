import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';

import 'isar_type.dart';

class ObjectInfo {
  final String dartName;
  final String isarName;
  final String accessor;
  final List<ObjectProperty> properties;
  final List<ObjectIndex> indexes;
  final List<ObjectLink> links;

  const ObjectInfo({
    required this.dartName,
    required this.isarName,
    required this.accessor,
    required this.properties,
    required this.indexes,
    required this.links,
  });

  ObjectProperty get idProperty => properties.firstWhere((it) => it.isId);

  List<ObjectProperty> get objectProperties =>
      properties.where((p) => !p.isId).toList();

  String get getIdName => '_${dartName.decapitalize()}GetId';
  String get setIdName => '_${dartName.decapitalize()}SetId';
  String get getLinksName => '_${dartName.decapitalize()}GetLinks';
  String get attachLinksName => '_${dartName.decapitalize()}AttachLinks';

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
  final String dartName;
  final String isarName;
  final String dartType;
  final IsarType isarType;
  final bool isId;
  final String? converter;
  final bool nullable;
  final bool elementNullable;
  final PropertyDeser deserialize;
  final bool assignable;
  final int? constructorPosition;

  const ObjectProperty({
    required this.dartName,
    required this.isarName,
    required this.dartType,
    required this.isarType,
    required this.isId,
    this.converter,
    required this.nullable,
    required this.elementNullable,
    required this.deserialize,
    required this.assignable,
    this.constructorPosition,
  });

  ObjectProperty copyWithIsId(bool isId) {
    return ObjectProperty(
      dartName: dartName,
      isarName: isarName,
      dartType: dartType,
      isarType: isarType,
      isId: isId,
      converter: converter,
      nullable: nullable,
      elementNullable: elementNullable,
      deserialize: deserialize,
      assignable: assignable,
      constructorPosition: constructorPosition,
    );
  }

  String converterName(ObjectInfo oi) =>
      '_${oi.dartName.decapitalize()}${converter?.capitalize()}';

  String toIsar(String input, ObjectInfo oi) {
    if (converter != null) {
      return '${converterName(oi)}.toIsar($input)';
    } else {
      return input;
    }
  }

  String fromIsar(String input, ObjectInfo oi) {
    if (converter != null) {
      return '${converterName(oi)}.fromIsar($input)';
    } else {
      return input;
    }
  }
}

class ObjectIndexProperty {
  final ObjectProperty property;
  final IndexType type;
  final bool caseSensitive;

  const ObjectIndexProperty({
    required this.property,
    required this.type,
    required this.caseSensitive,
  });

  IsarType get isarType => property.isarType;

  IsarType get scalarType => property.isarType.scalarType;

  String get indexValueTypeEnum {
    switch (property.isarType) {
      case IsarType.bool:
        return 'IndexValueType.bool';
      case IsarType.int:
        return 'IndexValueType.int';
      case IsarType.float:
        return 'IndexValueType.float';
      case IsarType.long:
      case IsarType.dateTime:
        return 'IndexValueType.long';
      case IsarType.double:
        return 'IndexValueType.double';
      case IsarType.string:
        if (caseSensitive) {
          return type == IndexType.hash
              ? 'IndexValueType.stringHash'
              : 'IndexValueType.string';
        } else {
          return type == IndexType.hash
              ? 'IndexValueType.stringHashCIS'
              : 'IndexValueType.stringCIS';
        }
      case IsarType.bytes:
        assert(type == IndexType.hash);
        return 'IndexValueType.bytesHash';
      case IsarType.boolList:
        if (type == IndexType.hash) {
          return 'IndexValueType.boolListHash';
        } else {
          return 'IndexValueType.bool';
        }
      case IsarType.intList:
        if (type == IndexType.hash) {
          return 'IndexValueType.intListHash';
        } else {
          return 'IndexValueType.int';
        }
      case IsarType.floatList:
        assert(type == IndexType.value);
        return 'IndexValueType.float';
      case IsarType.longList:
      case IsarType.dateTimeList:
        if (type == IndexType.hash) {
          return 'IndexValueType.longListHash';
        } else {
          return 'IndexValueType.long';
        }
      case IsarType.doubleList:
        assert(type == IndexType.value);
        return 'IndexValueType.double';
      case IsarType.stringList:
        if (caseSensitive) {
          if (type == IndexType.hash) {
            return 'IndexValueType.stringListHash';
          } else if (type == IndexType.hashElements) {
            return 'IndexValueType.stringHash';
          } else {
            return 'IndexValueType.string';
          }
        } else {
          if (type == IndexType.hash) {
            return 'IndexValueType.stringListHashCIS';
          } else if (type == IndexType.hashElements) {
            return 'IndexValueType.stringHashCIS';
          } else {
            return 'IndexValueType.stringCIS';
          }
        }
    }
  }
}

class ObjectIndex {
  final String name;
  final List<ObjectIndexProperty> properties;
  final bool unique;

  const ObjectIndex({
    required this.name,
    required this.properties,
    required this.unique,
  });
}

class ObjectLink {
  final String dartName;
  final String isarName;

  // isar name of the original link (only for backlinks)
  final String? targetIsarName;
  final String targetCollectionDartName;
  final String targetCollectionIsarName;
  final String targetCollectionAccessor;
  final bool links;
  final bool backlink;

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
}
