import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';

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

  List<ObjectProperty> get objectProperties =>
      properties.where((p) => !p.isId).toList();

  int get staticSize {
    return properties.sumBy((p) => p.isarType.staticSize).toInt() + 2;
  }

  String get adapterName => '_${dartName}Adapter';

  String get collectionAccessor => '${dartName.decapitalize()}s';
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
        if (type == IndexType.hash) {
          return 'NativeIndexType.floatListHash';
        } else {
          return 'NativeIndexType.float';
        }
      case IsarType.longList:
      case IsarType.dateTimeList:
        if (type == IndexType.hash) {
          return 'NativeIndexType.longListHash';
        } else {
          return 'NativeIndexType.long';
        }
      case IsarType.doubleList:
        if (type == IndexType.hash) {
          return 'NativeIndexType.doubleListHash';
        } else {
          return 'NativeIndexType.double';
        }
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
    required String? targetDartName,
    required String targetCollectionDartName,
    required String targetCollectionIsarName,
    required bool links,
    required bool backlink,
  }) = _ObjectLink;

  factory ObjectLink.fromJson(Map<String, dynamic> json) =>
      _$ObjectLinkFromJson(json);
}

enum IsarType {
  bool,
  int,
  float,
  long,
  double,
  dateTime,
  string,
  bytes,
  boolList,
  intList,
  floatList,
  longList,
  doubleList,
  dateTimeList,
  stringList,
}

extension IsarTypeX on IsarType {
  bool get isFloatDouble {
    return this == IsarType.float || this == IsarType.double;
  }

  bool get isDynamic {
    return index >= IsarType.string.index;
  }

  bool get isList {
    return index > IsarType.string.index;
  }

  bool get containsString =>
      index == IsarType.string.index || index == IsarType.stringList.index;

  int get staticSize {
    if (this == IsarType.bool) {
      return 1;
    } else if (this == IsarType.int || this == IsarType.float) {
      return 4;
    } else {
      return 8;
    }
  }

  int get elementSize {
    switch (this) {
      case IsarType.bytes:
      case IsarType.boolList:
        return 1;
      case IsarType.intList:
      case IsarType.floatList:
        return 4;
      case IsarType.longList:
      case IsarType.doubleList:
      case IsarType.dateTimeList:
        return 8;
      default:
        return 0;
    }
  }

  int get typeId {
    switch (this) {
      case IsarType.bool:
        return 0;
      case IsarType.int:
        return 1;
      case IsarType.float:
        return 2;
      case IsarType.long:
      case IsarType.dateTime:
        return 3;
      case IsarType.double:
        return 4;
      case IsarType.string:
        return 5;
      case IsarType.bytes:
      case IsarType.boolList:
        return 6;
      case IsarType.intList:
        return 7;
      case IsarType.floatList:
        return 8;
      case IsarType.longList:
      case IsarType.dateTimeList:
        return 9;
      case IsarType.doubleList:
        return 10;
      case IsarType.stringList:
        return 11;
    }
  }

  IsarType get scalarType {
    switch (this) {
      case IsarType.boolList:
        return IsarType.bool;
      case IsarType.intList:
        return IsarType.int;
      case IsarType.floatList:
        return IsarType.float;
      case IsarType.longList:
        return IsarType.long;
      case IsarType.doubleList:
        return IsarType.double;
      case IsarType.dateTimeList:
        return IsarType.dateTime;
      case IsarType.stringList:
        return IsarType.string;
      default:
        return this;
    }
  }

  String dartType(bool nullable, bool elementNullable) {
    final nQ = nullable ? '?' : '';
    final nEQ = elementNullable ? '?' : '';
    switch (this) {
      case IsarType.bool:
        return 'bool$nQ';
      case IsarType.int:
      case IsarType.long:
        return 'int$nQ';
      case IsarType.double:
      case IsarType.float:
        return 'double$nQ';
      case IsarType.dateTime:
        return 'DateTime$nQ';
      case IsarType.string:
        return 'String$nQ';
      case IsarType.bytes:
        return 'Uint8List$nQ';
      case IsarType.boolList:
        return 'List<bool$nEQ>$nQ';
      case IsarType.intList:
      case IsarType.longList:
        return 'List<int$nEQ>$nQ';
      case IsarType.floatList:
      case IsarType.doubleList:
        return 'List<double$nEQ>$nQ';
      case IsarType.dateTimeList:
        return 'List<DateTime$nEQ>$nQ';
      case IsarType.stringList:
        return 'List<String$nEQ>$nQ';
    }
  }
}
