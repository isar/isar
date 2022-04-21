import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';

import 'isar_type.dart';

part 'object_info.g.dart';
part 'object_info.freezed.dart';

@freezed
class ObjectInfo with _$ObjectInfo {
  const ObjectInfo._();

  const factory ObjectInfo({
    required String dartName,
    required String isarName,
    required String accessor,
    required List<ObjectProperty> properties,
    required List<ObjectIndex> indexes,
    required List<ObjectLink> links,
  }) = _ObjectInfo;

  factory ObjectInfo.fromJson(Map<String, dynamic> json) =>
      _$ObjectInfoFromJson(json);

  ObjectProperty getProperty(String isarName) {
    return properties.filter(((it) => it.isarName == isarName)).first;
  }

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

@freezed
class ObjectProperty with _$ObjectProperty {
  const ObjectProperty._();

  const factory ObjectProperty({
    required String dartName,
    required String isarName,
    required String dartType,
    required IsarType isarType,
    required bool isId,
    String? converter,
    required bool nullable,
    required bool elementNullable,
    required PropertyDeser deserialize,
    required bool assignable,
    int? constructorPosition,
  }) = _ObjectProperty;

  factory ObjectProperty.fromJson(Map<String, dynamic> json) =>
      _$ObjectPropertyFromJson(json);

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

@freezed
class ObjectIndexProperty with _$ObjectIndexProperty {
  const ObjectIndexProperty._();

  const factory ObjectIndexProperty({
    required ObjectProperty property,
    required IndexType type,
    required bool caseSensitive,
  }) = _ObjectIndexProperty;

  factory ObjectIndexProperty.fromJson(Map<String, dynamic> json) =>
      _$ObjectIndexPropertyFromJson(json);

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

@freezed
class ObjectIndex with _$ObjectIndex {
  const ObjectIndex._();

  const factory ObjectIndex({
    required String name,
    required List<ObjectIndexProperty> properties,
    required bool unique,
  }) = _ObjectIndex;

  factory ObjectIndex.fromJson(Map<String, dynamic> json) =>
      _$ObjectIndexFromJson(json);
}

@freezed
class ObjectLink with _$ObjectLink {
  const factory ObjectLink({
    required String dartName,
    required String isarName,
    required String? targetIsarName,
    required String targetCollectionDartName,
    required String targetCollectionIsarName,
    required String targetCollectionAccessor,
    required bool links,
    required bool backlink,
  }) = _ObjectLink;

  factory ObjectLink.fromJson(Map<String, dynamic> json) =>
      _$ObjectLinkFromJson(json);
}
