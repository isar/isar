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

  int get staticSize {
    return properties.sumBy((p) => p.isarType.staticSize).toInt() + 2;
  }

  String get adapterName => '_${dartName}Adapter';
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
    int? constructorPosition,
  }) = _ObjectProperty;

  factory ObjectProperty.fromJson(Map<String, dynamic> json) =>
      _$ObjectPropertyFromJson(json);

  String toIsar(String input, ObjectInfo oi) {
    if (converter != null) {
      return '${oi.adapterName}._$converter.toIsar($input)';
    } else {
      return input;
    }
  }

  String fromIsar(String input, ObjectInfo oi) {
    if (converter != null) {
      return '${oi.adapterName}._$converter.fromIsar($input)';
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

  String get indexTypeEnum {
    switch (property.isarType) {
      case IsarType.bool:
        return 'NativeIndexType.bool';
      case IsarType.int:
        return 'NativeIndexType.int';
      case IsarType.float:
        return 'NativeIndexType.float';
      case IsarType.long:
      case IsarType.dateTime:
        return 'NativeIndexType.long';
      case IsarType.double:
        return 'NativeIndexType.double';
      case IsarType.string:
        if (caseSensitive) {
          return type == IndexType.hash
              ? 'NativeIndexType.stringHash'
              : 'NativeIndexType.string';
        } else {
          return type == IndexType.hash
              ? 'NativeIndexType.stringHashCIS'
              : 'NativeIndexType.stringCIS';
        }
      case IsarType.bytes:
        assert(type == IndexType.hash);
        return 'NativeIndexType.bytesHash';
      case IsarType.boolList:
        if (type == IndexType.hash) {
          return 'NativeIndexType.boolListHash';
        } else {
          return 'NativeIndexType.bool';
        }
      case IsarType.intList:
        if (type == IndexType.hash) {
          return 'NativeIndexType.intListHash';
        } else {
          return 'NativeIndexType.int';
        }
      case IsarType.floatList:
        assert(type == IndexType.value);
        return 'NativeIndexType.float';
      case IsarType.longList:
      case IsarType.dateTimeList:
        if (type == IndexType.hash) {
          return 'NativeIndexType.longListHash';
        } else {
          return 'NativeIndexType.long';
        }
      case IsarType.doubleList:
        assert(type == IndexType.value);
        return 'NativeIndexType.double';
      case IsarType.stringList:
        if (caseSensitive) {
          if (type == IndexType.hash) {
            return 'NativeIndexType.stringListHash';
          } else if (type == IndexType.hashElements) {
            return 'NativeIndexType.stringHash';
          } else {
            return 'NativeIndexType.string';
          }
        } else {
          if (type == IndexType.hash) {
            return 'NativeIndexType.stringListHashCIS';
          } else if (type == IndexType.hashElements) {
            return 'NativeIndexType.stringHashCIS';
          } else {
            return 'NativeIndexType.stringCIS';
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
    required bool links,
    required bool backlink,
  }) = _ObjectLink;

  factory ObjectLink.fromJson(Map<String, dynamic> json) =>
      _$ObjectLinkFromJson(json);
}
