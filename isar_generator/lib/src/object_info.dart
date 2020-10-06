import 'package:json_annotation/json_annotation.dart';
import 'package:dartx/dartx.dart';

part 'object_info.g.dart';

@JsonSerializable(nullable: false, explicitToJson: true)
class ObjectInfo {
  @JsonKey(name: 'localName')
  final String type;
  @JsonKey(name: 'name')
  final String dbName;

  List<ObjectProperty> properties = [];
  List<ObjectIndex> indices = [];

  ObjectInfo(this.type, this.dbName);

  static ObjectInfo fromJson(Map<String, dynamic> json) {
    return _$ObjectInfoFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ObjectInfoToJson(this);
  }

  int getStaticSize() {
    return properties.sumBy((f) {
      if (f.type == DataType.Bool) {
        return 1;
      } else {
        return 8;
      }
    }).toInt();
  }

  ObjectProperty getProperty(String name) {
    return properties.filter((it) => it.name == name).first;
  }
}

@JsonSerializable(nullable: false, explicitToJson: true)
class ObjectProperty {
  @JsonKey(name: 'localName')
  final String name;
  @JsonKey(name: 'name')
  final String dbName;
  final DataType type;
  final bool nullable;
  final bool elementNullable;

  ObjectProperty(
      this.name, this.dbName, this.type, this.nullable, this.elementNullable);

  static ObjectProperty fromJson(Map<String, dynamic> json) {
    return _$ObjectPropertyFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ObjectPropertyToJson(this);
  }
}

@JsonSerializable(nullable: false, explicitToJson: true)
class ObjectIndex {
  List<String> properties;
  bool unique;
  bool hashValue;

  ObjectIndex(this.properties, this.unique, this.hashValue);

  static ObjectIndex fromJson(Map<String, dynamic> json) {
    return _$ObjectIndexFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ObjectIndexToJson(this);
  }
}

enum DataType {
  @JsonValue(0)
  Int,

  @JsonValue(1)
  Long,

  @JsonValue(2)
  Float,

  @JsonValue(3)
  Double,

  @JsonValue(4)
  Bool,

  @JsonValue(5)
  String,

  @JsonValue(6)
  Bytes,

  @JsonValue(7)
  IntList,

  @JsonValue(8)
  LongList,

  @JsonValue(9)
  FloatList,

  @JsonValue(10)
  DoubleList,

  @JsonValue(11)
  BoolList,

  @JsonValue(12)
  StringList,

  @JsonValue(13)
  BytesList,
}

extension DataTypeX on DataType {
  bool isDynamic() {
    return index >= DataType.String.index;
  }

  int staticSize() {
    if (this == DataType.Bool) {
      return 1;
    } else {
      return 8;
    }
  }

  String toTypeName() {
    for (var key in _typeMap.keys) {
      if (_typeMap[key].contains(this)) return key;
    }
    return null;
  }

  static DataType fromTypeName(String name) {
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
  'List<bool>': [DataType.Bool],
  'List<String>': [DataType.String],
  'List<Uint8List>': [DataType.BytesList]
};
