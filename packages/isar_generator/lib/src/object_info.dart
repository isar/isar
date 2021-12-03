import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:dartx/dartx.dart';

part 'object_info.g.dart';
part 'object_info.freezed.dart';

@freezed
class ObjectInfo with _$ObjectInfo {
  const ObjectInfo._();

  const factory ObjectInfo({
    required String dartName,
    required String isarName,
    @Default([]) List<ObjectProperty> properties,
    @Default([]) List<ObjectIndex> indexes,
    @Default([]) List<ObjectLink> links,
    @Default([]) List<String> imports,
  }) = _ObjectInfo;

  factory ObjectInfo.fromJson(Map<String, dynamic> json) =>
      _$ObjectInfoFromJson(json);

  ObjectProperty getProperty(String isarName) {
    return properties.filter(((it) => it.isarName == isarName)).first;
  }

  ObjectProperty get idProperty => properties.firstWhere((it) => it.isId);

  int get staticSize {
    return properties.sumBy((p) => p.isarType.staticSize).toInt() + 2;
  }

  String get adapterName => '_${dartName}Adapter';

  String get collectionVar => '_${dartName.decapitalize()}Collection';

  String get collectionAccessor => '${dartName.decapitalize()}s';
}

enum PropertyDeser {
  None,
  Assign,
  PositionalParam,
  NamedParam,
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

  String get dartTypeNotNull {
    return dartType.removeSuffix('?');
  }

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
    required IndexType indexType,
    required bool? caseSensitive,
  }) = _ObjectIndexProperty;

  factory ObjectIndexProperty.fromJson(Map<String, dynamic> json) =>
      _$ObjectIndexPropertyFromJson(json);

  String get indexTypeEnum {
    switch (property.isarType) {
      case IsarType.Bool:
        return 'NativeIndexType.Bool';
      case IsarType.Int:
        return 'NativeIndexType.Int';
      case IsarType.Float:
        return 'NativeIndexType.Float';
      case IsarType.Long:
        return 'NativeIndexType.Long';
      case IsarType.Double:
        return 'NativeIndexType.Double';
      case IsarType.DateTime:
        return 'NativeIndexType.Long';
      case IsarType.String:
        switch (indexType) {
          case IndexType.value:
            if (caseSensitive ?? true) {
              return 'NativeIndexType.StringValue';
            } else {
              return 'NativeIndexType.StringValueCIS';
            }
          case IndexType.hash:
            if (caseSensitive ?? true) {
              return 'NativeIndexType.StringHash';
            } else {
              return 'NativeIndexType.StringHashCIS';
            }
          case IndexType.words:
            if (caseSensitive ?? true) {
              return 'NativeIndexType.StringWords';
            } else {
              return 'NativeIndexType.StringWordsCIS';
            }
        }
      default:
        throw 'unreachable';
    }
  }
}

@freezed
class ObjectIndex with _$ObjectIndex {
  const ObjectIndex._();

  const factory ObjectIndex({
    required List<ObjectIndexProperty> properties,
    required bool unique,
    required bool replace,
  }) = _ObjectIndex;

  factory ObjectIndex.fromJson(Map<String, dynamic> json) =>
      _$ObjectIndexFromJson(json);

  String get name =>
      properties.map((e) => e.property.dartName.capitalize()).join();
}

@freezed
class ObjectLink with _$ObjectLink {
  const factory ObjectLink({
    required String dartName,
    required String isarName,
    required String? targetDartName,
    required String targetCollectionDartName,
    required bool links,
    required bool backlink,
    @Default(-1) int linkIndex,
  }) = _ObjectLink;

  factory ObjectLink.fromJson(Map<String, dynamic> json) =>
      _$ObjectLinkFromJson(json);
}

enum IsarType {
  Bool,
  Int,
  Float,
  Long,
  Double,
  DateTime,
  String,
  Bytes,
  BoolList,
  IntList,
  FloatList,
  LongList,
  DoubleList,
  DateTimeList,
  StringList,
}

extension IsarTypeX on IsarType {
  bool get isFloatDouble {
    return this == IsarType.Float || this == IsarType.Double;
  }

  bool get isDynamic {
    return index >= IsarType.String.index;
  }

  bool get isList {
    return index > IsarType.String.index;
  }

  int get staticSize {
    if (this == IsarType.Bool) {
      return 1;
    } else if (this == IsarType.Int || this == IsarType.Float) {
      return 4;
    } else {
      return 8;
    }
  }

  int get elementSize {
    switch (this) {
      case IsarType.Bytes:
      case IsarType.BoolList:
        return 1;
      case IsarType.IntList:
      case IsarType.FloatList:
        return 4;
      case IsarType.LongList:
      case IsarType.DoubleList:
      case IsarType.DateTimeList:
        return 8;
      default:
        return 0;
    }
  }

  int get typeId {
    switch (this) {
      case IsarType.Bool:
        return 0;
      case IsarType.Int:
        return 1;
      case IsarType.Float:
        return 2;
      case IsarType.Long:
      case IsarType.DateTime:
        return 3;
      case IsarType.Double:
        return 4;
      case IsarType.String:
        return 5;
      case IsarType.Bytes:
      case IsarType.BoolList:
        return 6;
      case IsarType.IntList:
        return 7;
      case IsarType.FloatList:
        return 8;
      case IsarType.LongList:
      case IsarType.DateTimeList:
        return 9;
      case IsarType.DoubleList:
        return 10;
      case IsarType.StringList:
        return 11;
    }
  }

  String get name {
    return toString().substring(9);
  }
}
