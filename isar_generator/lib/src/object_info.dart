import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:dartx/dartx.dart';

part 'object_info.g.dart';
part 'object_info.freezed.dart';

@freezed
abstract class ObjectInfo with _$ObjectInfo {
  const factory ObjectInfo({
    @JsonKey(name: 'localName') String type,
    @JsonKey(name: 'name') String dbName,
    @Default([]) List<ObjectProperty> properties,
    @Default([]) List<ObjectIndex> indices,
  }) = _ObjectInfo;

  factory ObjectInfo.fromJson(Map<String, dynamic> json) =>
      _$ObjectInfoFromJson(json);
}

extension ObjectInfoX on ObjectInfo {
  ObjectProperty getProperty(String name) {
    return properties.filter((it) => it.name == name).first;
  }

  int getStaticSize() {
    return properties.sumBy((p) => p.type.staticSize + p.staticPadding).toInt();
  }
}

@freezed
abstract class ObjectProperty with _$ObjectProperty {
  const factory ObjectProperty({
    @JsonKey(name: 'localName') String name,
    @JsonKey(name: 'name') String dbName,
    DataType type,
    int staticPadding,
    bool nullable,
    bool elementNullable,
  }) = _ObjectProperty;

  factory ObjectProperty.fromJson(Map<String, dynamic> json) =>
      _$ObjectPropertyFromJson(json);
}

@freezed
abstract class ObjectIndex with _$ObjectIndex {
  const factory ObjectIndex({
    List<String> properties,
    bool unique,
    bool hashValue,
  }) = _ObjectIndex;

  factory ObjectIndex.fromJson(Map<String, dynamic> json) =>
      _$ObjectIndexFromJson(json);
}

extension ObjectPropertyX on ObjectProperty {
  String get dartTypeNotNull {
    switch (type) {
      case DataType.Bool:
        return 'bool';
      case DataType.Int:
      case DataType.Long:
        return 'int';
      case DataType.Float:
      case DataType.Double:
        return 'double';
      case DataType.String:
        return 'String';
      case DataType.Bytes:
        return 'Uint8List';
      case DataType.BoolList:
        return 'List<bool>';
      case DataType.IntList:
      case DataType.LongList:
        return 'List<int>';
      case DataType.FloatList:
      case DataType.DoubleList:
        return 'List<double>';
      case DataType.StringList:
        return 'List<String>';
    }
    throw 'unreachable';
  }

  String get dartType {
    final typeName = dartTypeNotNull;
    if (this.nullable) {
      return typeName + '?';
    } else {
      return typeName;
    }
  }

  bool get isFloatDouble {
    return type == DataType.Float || type == DataType.Double;
  }
}

enum DataType {
  Bool,
  Int,
  Float,
  Long,
  Double,
  String,
  Bytes,
  BoolList,
  IntList,
  FloatList,
  LongList,
  DoubleList,
  StringList,
}

extension DataTypeX on DataType {
  bool get isDynamic {
    return index >= DataType.String.index;
  }

  int get staticSize {
    if (this == DataType.Bool) {
      return 1;
    } else if (this == DataType.Int || this == DataType.Float) {
      return 4;
    } else {
      return 8;
    }
  }

  int get elementAlignment {
    switch (this) {
      case DataType.String:
      case DataType.Bytes:
      case DataType.BoolList:
      case DataType.StringList:
        return 1;
      case DataType.IntList:
      case DataType.FloatList:
        return 4;
      case DataType.LongList:
      case DataType.DoubleList:
        return 8;
      default:
        return null;
    }
  }

  int get typeId {
    switch (this) {
      case DataType.Bool:
        return 0;
      case DataType.Int:
        return 1;
      case DataType.Float:
        return 2;
      case DataType.Long:
        return 3;
      case DataType.Double:
        return 4;
      case DataType.String:
        return 5;
      case DataType.Bytes:
      case DataType.BoolList:
        return 6;
      case DataType.IntList:
        return 7;
      case DataType.FloatList:
        return 8;
      case DataType.LongList:
        return 9;
      case DataType.DoubleList:
        return 10;
      case DataType.StringList:
        return 11;
    }
    return -1;
  }

  String get name {
    return toString().substring(9);
  }
}
