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
    ObjectProperty oidProperty,
    @Default([]) List<ObjectProperty> properties,
    @Default([]) List<ObjectIndex> indices,
    @Default([]) List<String> converterImports,
  }) = _ObjectInfo;

  factory ObjectInfo.fromJson(Map<String, dynamic> json) =>
      _$ObjectInfoFromJson(json);
}

extension ObjectInfoX on ObjectInfo {
  ObjectProperty getProperty(String isarName) {
    return properties.filter((it) => it.isarName == isarName).first;
  }

  String get adapterName => '_${dartName}Adapter';

  int getStaticSize() {
    return properties.sumBy((p) => p.isarType.staticSize).toInt() + 2;
  }
}

@freezed
abstract class ObjectProperty with _$ObjectProperty {
  const factory ObjectProperty({
    String dartName,
    String isarName,
    String dartType,
    IsarType isarType,
    String converter,
    bool nullable,
    bool elementNullable,
  }) = _ObjectProperty;

  factory ObjectProperty.fromJson(Map<String, dynamic> json) =>
      _$ObjectPropertyFromJson(json);
}

@freezed
abstract class ObjectIndexProperty with _$ObjectIndexProperty {
  const factory ObjectIndexProperty({
    String isarName,
    StringIndexType stringType,
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
  }) = _ObjectIndex;

  factory ObjectIndex.fromJson(Map<String, dynamic> json) =>
      _$ObjectIndexFromJson(json);
}

extension ObjectPropertyX on ObjectProperty {
  String get isarDartType {
    final elementNullModifier = elementNullable ? '?' : '';

    String type;
    switch (isarType) {
      case IsarType.Bool:
        type = 'bool';
        break;
      case IsarType.Int:
      case IsarType.Long:
        type = 'int';
        break;
      case IsarType.Float:
      case IsarType.Double:
        type = 'double';
        break;
      case IsarType.String:
        type = 'String';
        break;
      case IsarType.Bytes:
        type = 'Uint8List';
        break;
      case IsarType.BoolList:
        type = 'List<bool$elementNullModifier>';
        break;
      case IsarType.IntList:
      case IsarType.LongList:
        type = 'List<int$elementNullModifier>';
        break;
      case IsarType.FloatList:
      case IsarType.DoubleList:
        type = 'List<double$elementNullModifier>';
        break;
      case IsarType.StringList:
        type = 'List<String$elementNullModifier>';
        break;
    }

    if (this.nullable) {
      type += '?';
    }

    return type;
  }

  String get dartTypeNotNull {
    return dartType.removeSuffix('?');
  }
}

enum IsarType {
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

  int get typeId {
    switch (this) {
      case IsarType.Bool:
        return 0;
      case IsarType.Int:
        return 1;
      case IsarType.Float:
        return 2;
      case IsarType.Long:
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
