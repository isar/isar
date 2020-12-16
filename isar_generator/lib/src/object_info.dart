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

extension ObjectPropertyX on ObjectInfo {
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

enum DataType {
  @JsonValue(0)
  Bool,

  @JsonValue(1)
  Int,

  @JsonValue(2)
  Float,

  @JsonValue(3)
  Long,

  @JsonValue(4)
  Double,

  @JsonValue(5)
  String,

  @JsonValue(6)
  Bytes,

  @JsonValue(7)
  BoolList,

  @JsonValue(8)
  StringList,

  @JsonValue(9)
  BytesList,

  @JsonValue(10)
  IntList,

  @JsonValue(11)
  FloatList,

  @JsonValue(12)
  LongList,

  @JsonValue(13)
  DoubleList,
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
      case DataType.BytesList:
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

  String toTypeName() {
    for (var key in _typeMap.keys) {
      if (_typeMap[key].contains(this)) return key;
    }
    return null;
  }

  static DataType fromTypeName(String name) {
    print(name);
    return _typeMap[name][0];
  }
}

const _typeMap = {
  'int': [DataType.Int, DataType.Long],
  'double': [DataType.Float, DataType.Double],
  'bool': [DataType.Bool],
  'String': [DataType.String],
  'Uint8List': [DataType.Bytes],
  'List<int>': [DataType.IntList, DataType.LongList],
  'List<double>': [DataType.FloatList, DataType.DoubleList],
  'List<bool>': [DataType.BoolList],
  'List<String>': [DataType.StringList],
  'List<Uint8List>': [DataType.BytesList]
};
