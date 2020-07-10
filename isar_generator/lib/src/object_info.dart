import 'package:json_annotation/json_annotation.dart';
import 'package:dartx/dartx.dart';

part 'object_info.g.dart';

@JsonSerializable(nullable: false, explicitToJson: true)
class ObjectInfo {
  @JsonKey(name: 'localName')
  final String type;
  @JsonKey(name: 'name')
  final String dbName;

  List<ObjectField> fields = [];
  List<ObjectIndex> indices = [];

  ObjectInfo(this.type, this.dbName);

  static ObjectInfo fromJson(Map<String, dynamic> json) {
    return _$ObjectInfoFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ObjectInfoToJson(this);
  }

  int getStaticSize() {
    return fields.sumBy((f) {
      if (f.type == DataType.Bool) {
        return 1;
      } else {
        return 8;
      }
    }).toInt();
  }

  ObjectField getField(String name) {
    return fields.filter((it) => it.name == name).first;
  }
}

@JsonSerializable(nullable: false, explicitToJson: true)
class ObjectField {
  @JsonKey(name: 'localName')
  final String name;
  @JsonKey(name: 'name')
  final String dbName;
  final DataType type;
  final bool nullable;

  ObjectField(this.name, this.dbName, this.type, this.nullable);

  static ObjectField fromJson(Map<String, dynamic> json) {
    return _$ObjectFieldFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ObjectFieldToJson(this);
  }
}

@JsonSerializable(nullable: false, explicitToJson: true)
class ObjectIndex {
  List<String> fields;
  bool unique;
  bool hashValue;

  ObjectIndex(this.fields, this.unique, this.hashValue);

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
  Double,

  @JsonValue(2)
  Bool,

  @JsonValue(3)
  String,

  @JsonValue(4)
  Bytes,

  @JsonValue(5)
  IntList,

  @JsonValue(6)
  DoubleList,

  @JsonValue(7)
  BoolList,

  @JsonValue(8)
  StringList,

  @JsonValue(9)
  BytesList,
}

extension DataTypeX on DataType {
  bool isDynamic() {
    return this.index >= DataType.String.index;
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
      if (_typeMap[key] == this) return key;
    }
    return null;
  }

  static DataType fromTypeName(String name) {
    return _typeMap[name];
  }
}

const _typeMap = {
  'int': DataType.Int,
  'double': DataType.Double,
  'bool': DataType.Bool,
  'String': DataType.String,
  'Uint8List': DataType.Bytes,
  'List<int>': DataType.IntList,
  'List<double>': DataType.Double,
  'List<bool>': DataType.Bool,
  'List<String>': DataType.String,
  'List<Uint8List>': DataType.BytesList
};
