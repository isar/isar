import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:dartx/dartx.dart';
import 'package:isar_annotation/isar_annotation.dart';

part 'object_info.g.dart';
part 'object_info.freezed.dart';

@freezed
abstract class ObjectInfo with _$ObjectInfo {
  const factory ObjectInfo({
    String dartName,
    String isarName,
    @Default([]) List<ObjectProperty> properties,
    @Default([]) List<ObjectIndex> indexes,
    @Default([]) List<String> converterImports,
  }) = _ObjectInfo;

  factory ObjectInfo.fromJson(Map<String, dynamic> json) =>
      _$ObjectInfoFromJson(json);
}

extension ObjectInfoX on ObjectInfo {
  ObjectProperty getProperty(String isarName) {
    return properties.filter((it) => it.isarName == isarName).first;
  }

  ObjectProperty get oidProperty =>
      properties.firstWhere((it) => it.isObjectId);

  int get staticSize {
    return properties.sumBy((p) => p.isarType.staticSize).toInt() + 2;
  }

  String get adapterName => '_${dartName}Adapter';

  String get collectionVar => '_${dartName.decapitalize()}Collection';
}

@freezed
abstract class ObjectProperty with _$ObjectProperty {
  const factory ObjectProperty({
    String dartName,
    String isarName,
    String dartType,
    IsarType isarType,
    bool isObjectId,
    String converter,
    bool nullable,
    bool elementNullable,
  }) = _ObjectProperty;

  factory ObjectProperty.fromJson(Map<String, dynamic> json) =>
      _$ObjectPropertyFromJson(json);
}

extension ObjectPropertyX on ObjectProperty {
  String get dartTypeNotNull {
    return dartType.removeSuffix('?');
  }

  String toIsar(String input, ObjectInfo oi) {
    if (converter != null) {
      return '${oi.adapterName}._${converter}.toIsar($input)';
    } else {
      return input;
    }
  }

  String fromIsar(String input, ObjectInfo oi) {
    if (converter != null) {
      return '${oi.adapterName}._${converter}.fromIsar($input)';
    } else {
      return input;
    }
  }
}

@freezed
abstract class ObjectIndexProperty with _$ObjectIndexProperty {
  const factory ObjectIndexProperty({
    ObjectProperty property,
    IndexType indexType,
    bool caseSensitive,
  }) = _ObjectIndexProperty;

  factory ObjectIndexProperty.fromJson(Map<String, dynamic> json) =>
      _$ObjectIndexPropertyFromJson(json);
}

@freezed
abstract class ObjectIndex with _$ObjectIndex {
  const factory ObjectIndex({
    List<ObjectIndexProperty> properties,
    bool unique,
    bool replace,
  }) = _ObjectIndex;

  factory ObjectIndex.fromJson(Map<String, dynamic> json) =>
      _$ObjectIndexFromJson(json);
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
    return -1;
  }

  String get name {
    return toString().substring(9);
  }
}
