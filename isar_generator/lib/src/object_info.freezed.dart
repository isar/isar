// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies

part of 'object_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;
ObjectInfo _$ObjectInfoFromJson(Map<String, dynamic> json) {
  return _ObjectInfo.fromJson(json);
}

/// @nodoc
class _$ObjectInfoTearOff {
  const _$ObjectInfoTearOff();

// ignore: unused_element
  _ObjectInfo call(
      {@JsonKey(name: 'localName') String type,
      @JsonKey(name: 'name') String dbName,
      List<ObjectProperty> properties = const [],
      List<ObjectIndex> indices = const []}) {
    return _ObjectInfo(
      type: type,
      dbName: dbName,
      properties: properties,
      indices: indices,
    );
  }

// ignore: unused_element
  ObjectInfo fromJson(Map<String, Object> json) {
    return ObjectInfo.fromJson(json);
  }
}

/// @nodoc
// ignore: unused_element
const $ObjectInfo = _$ObjectInfoTearOff();

/// @nodoc
mixin _$ObjectInfo {
  @JsonKey(name: 'localName')
  String get type;
  @JsonKey(name: 'name')
  String get dbName;
  List<ObjectProperty> get properties;
  List<ObjectIndex> get indices;

  Map<String, dynamic> toJson();
  $ObjectInfoCopyWith<ObjectInfo> get copyWith;
}

/// @nodoc
abstract class $ObjectInfoCopyWith<$Res> {
  factory $ObjectInfoCopyWith(
          ObjectInfo value, $Res Function(ObjectInfo) then) =
      _$ObjectInfoCopyWithImpl<$Res>;
  $Res call(
      {@JsonKey(name: 'localName') String type,
      @JsonKey(name: 'name') String dbName,
      List<ObjectProperty> properties,
      List<ObjectIndex> indices});
}

/// @nodoc
class _$ObjectInfoCopyWithImpl<$Res> implements $ObjectInfoCopyWith<$Res> {
  _$ObjectInfoCopyWithImpl(this._value, this._then);

  final ObjectInfo _value;
  // ignore: unused_field
  final $Res Function(ObjectInfo) _then;

  @override
  $Res call({
    Object type = freezed,
    Object dbName = freezed,
    Object properties = freezed,
    Object indices = freezed,
  }) {
    return _then(_value.copyWith(
      type: type == freezed ? _value.type : type as String,
      dbName: dbName == freezed ? _value.dbName : dbName as String,
      properties: properties == freezed
          ? _value.properties
          : properties as List<ObjectProperty>,
      indices:
          indices == freezed ? _value.indices : indices as List<ObjectIndex>,
    ));
  }
}

/// @nodoc
abstract class _$ObjectInfoCopyWith<$Res> implements $ObjectInfoCopyWith<$Res> {
  factory _$ObjectInfoCopyWith(
          _ObjectInfo value, $Res Function(_ObjectInfo) then) =
      __$ObjectInfoCopyWithImpl<$Res>;
  @override
  $Res call(
      {@JsonKey(name: 'localName') String type,
      @JsonKey(name: 'name') String dbName,
      List<ObjectProperty> properties,
      List<ObjectIndex> indices});
}

/// @nodoc
class __$ObjectInfoCopyWithImpl<$Res> extends _$ObjectInfoCopyWithImpl<$Res>
    implements _$ObjectInfoCopyWith<$Res> {
  __$ObjectInfoCopyWithImpl(
      _ObjectInfo _value, $Res Function(_ObjectInfo) _then)
      : super(_value, (v) => _then(v as _ObjectInfo));

  @override
  _ObjectInfo get _value => super._value as _ObjectInfo;

  @override
  $Res call({
    Object type = freezed,
    Object dbName = freezed,
    Object properties = freezed,
    Object indices = freezed,
  }) {
    return _then(_ObjectInfo(
      type: type == freezed ? _value.type : type as String,
      dbName: dbName == freezed ? _value.dbName : dbName as String,
      properties: properties == freezed
          ? _value.properties
          : properties as List<ObjectProperty>,
      indices:
          indices == freezed ? _value.indices : indices as List<ObjectIndex>,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectInfo implements _ObjectInfo {
  const _$_ObjectInfo(
      {@JsonKey(name: 'localName') this.type,
      @JsonKey(name: 'name') this.dbName,
      this.properties = const [],
      this.indices = const []})
      : assert(properties != null),
        assert(indices != null);

  factory _$_ObjectInfo.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectInfoFromJson(json);

  @override
  @JsonKey(name: 'localName')
  final String type;
  @override
  @JsonKey(name: 'name')
  final String dbName;
  @JsonKey(defaultValue: const [])
  @override
  final List<ObjectProperty> properties;
  @JsonKey(defaultValue: const [])
  @override
  final List<ObjectIndex> indices;

  @override
  String toString() {
    return 'ObjectInfo(type: $type, dbName: $dbName, properties: $properties, indices: $indices)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ObjectInfo &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)) &&
            (identical(other.dbName, dbName) ||
                const DeepCollectionEquality().equals(other.dbName, dbName)) &&
            (identical(other.properties, properties) ||
                const DeepCollectionEquality()
                    .equals(other.properties, properties)) &&
            (identical(other.indices, indices) ||
                const DeepCollectionEquality().equals(other.indices, indices)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(type) ^
      const DeepCollectionEquality().hash(dbName) ^
      const DeepCollectionEquality().hash(properties) ^
      const DeepCollectionEquality().hash(indices);

  @override
  _$ObjectInfoCopyWith<_ObjectInfo> get copyWith =>
      __$ObjectInfoCopyWithImpl<_ObjectInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_ObjectInfoToJson(this);
  }
}

abstract class _ObjectInfo implements ObjectInfo {
  const factory _ObjectInfo(
      {@JsonKey(name: 'localName') String type,
      @JsonKey(name: 'name') String dbName,
      List<ObjectProperty> properties,
      List<ObjectIndex> indices}) = _$_ObjectInfo;

  factory _ObjectInfo.fromJson(Map<String, dynamic> json) =
      _$_ObjectInfo.fromJson;

  @override
  @JsonKey(name: 'localName')
  String get type;
  @override
  @JsonKey(name: 'name')
  String get dbName;
  @override
  List<ObjectProperty> get properties;
  @override
  List<ObjectIndex> get indices;
  @override
  _$ObjectInfoCopyWith<_ObjectInfo> get copyWith;
}

ObjectProperty _$ObjectPropertyFromJson(Map<String, dynamic> json) {
  return _ObjectProperty.fromJson(json);
}

/// @nodoc
class _$ObjectPropertyTearOff {
  const _$ObjectPropertyTearOff();

// ignore: unused_element
  _ObjectProperty call(
      {@JsonKey(name: 'localName') String name,
      @JsonKey(name: 'name') String dbName,
      DataType type,
      int staticPadding,
      bool nullable,
      bool elementNullable}) {
    return _ObjectProperty(
      name: name,
      dbName: dbName,
      type: type,
      staticPadding: staticPadding,
      nullable: nullable,
      elementNullable: elementNullable,
    );
  }

// ignore: unused_element
  ObjectProperty fromJson(Map<String, Object> json) {
    return ObjectProperty.fromJson(json);
  }
}

/// @nodoc
// ignore: unused_element
const $ObjectProperty = _$ObjectPropertyTearOff();

/// @nodoc
mixin _$ObjectProperty {
  @JsonKey(name: 'localName')
  String get name;
  @JsonKey(name: 'name')
  String get dbName;
  DataType get type;
  int get staticPadding;
  bool get nullable;
  bool get elementNullable;

  Map<String, dynamic> toJson();
  $ObjectPropertyCopyWith<ObjectProperty> get copyWith;
}

/// @nodoc
abstract class $ObjectPropertyCopyWith<$Res> {
  factory $ObjectPropertyCopyWith(
          ObjectProperty value, $Res Function(ObjectProperty) then) =
      _$ObjectPropertyCopyWithImpl<$Res>;
  $Res call(
      {@JsonKey(name: 'localName') String name,
      @JsonKey(name: 'name') String dbName,
      DataType type,
      int staticPadding,
      bool nullable,
      bool elementNullable});
}

/// @nodoc
class _$ObjectPropertyCopyWithImpl<$Res>
    implements $ObjectPropertyCopyWith<$Res> {
  _$ObjectPropertyCopyWithImpl(this._value, this._then);

  final ObjectProperty _value;
  // ignore: unused_field
  final $Res Function(ObjectProperty) _then;

  @override
  $Res call({
    Object name = freezed,
    Object dbName = freezed,
    Object type = freezed,
    Object staticPadding = freezed,
    Object nullable = freezed,
    Object elementNullable = freezed,
  }) {
    return _then(_value.copyWith(
      name: name == freezed ? _value.name : name as String,
      dbName: dbName == freezed ? _value.dbName : dbName as String,
      type: type == freezed ? _value.type : type as DataType,
      staticPadding: staticPadding == freezed
          ? _value.staticPadding
          : staticPadding as int,
      nullable: nullable == freezed ? _value.nullable : nullable as bool,
      elementNullable: elementNullable == freezed
          ? _value.elementNullable
          : elementNullable as bool,
    ));
  }
}

/// @nodoc
abstract class _$ObjectPropertyCopyWith<$Res>
    implements $ObjectPropertyCopyWith<$Res> {
  factory _$ObjectPropertyCopyWith(
          _ObjectProperty value, $Res Function(_ObjectProperty) then) =
      __$ObjectPropertyCopyWithImpl<$Res>;
  @override
  $Res call(
      {@JsonKey(name: 'localName') String name,
      @JsonKey(name: 'name') String dbName,
      DataType type,
      int staticPadding,
      bool nullable,
      bool elementNullable});
}

/// @nodoc
class __$ObjectPropertyCopyWithImpl<$Res>
    extends _$ObjectPropertyCopyWithImpl<$Res>
    implements _$ObjectPropertyCopyWith<$Res> {
  __$ObjectPropertyCopyWithImpl(
      _ObjectProperty _value, $Res Function(_ObjectProperty) _then)
      : super(_value, (v) => _then(v as _ObjectProperty));

  @override
  _ObjectProperty get _value => super._value as _ObjectProperty;

  @override
  $Res call({
    Object name = freezed,
    Object dbName = freezed,
    Object type = freezed,
    Object staticPadding = freezed,
    Object nullable = freezed,
    Object elementNullable = freezed,
  }) {
    return _then(_ObjectProperty(
      name: name == freezed ? _value.name : name as String,
      dbName: dbName == freezed ? _value.dbName : dbName as String,
      type: type == freezed ? _value.type : type as DataType,
      staticPadding: staticPadding == freezed
          ? _value.staticPadding
          : staticPadding as int,
      nullable: nullable == freezed ? _value.nullable : nullable as bool,
      elementNullable: elementNullable == freezed
          ? _value.elementNullable
          : elementNullable as bool,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectProperty implements _ObjectProperty {
  const _$_ObjectProperty(
      {@JsonKey(name: 'localName') this.name,
      @JsonKey(name: 'name') this.dbName,
      this.type,
      this.staticPadding,
      this.nullable,
      this.elementNullable});

  factory _$_ObjectProperty.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectPropertyFromJson(json);

  @override
  @JsonKey(name: 'localName')
  final String name;
  @override
  @JsonKey(name: 'name')
  final String dbName;
  @override
  final DataType type;
  @override
  final int staticPadding;
  @override
  final bool nullable;
  @override
  final bool elementNullable;

  @override
  String toString() {
    return 'ObjectProperty(name: $name, dbName: $dbName, type: $type, staticPadding: $staticPadding, nullable: $nullable, elementNullable: $elementNullable)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ObjectProperty &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.dbName, dbName) ||
                const DeepCollectionEquality().equals(other.dbName, dbName)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)) &&
            (identical(other.staticPadding, staticPadding) ||
                const DeepCollectionEquality()
                    .equals(other.staticPadding, staticPadding)) &&
            (identical(other.nullable, nullable) ||
                const DeepCollectionEquality()
                    .equals(other.nullable, nullable)) &&
            (identical(other.elementNullable, elementNullable) ||
                const DeepCollectionEquality()
                    .equals(other.elementNullable, elementNullable)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(dbName) ^
      const DeepCollectionEquality().hash(type) ^
      const DeepCollectionEquality().hash(staticPadding) ^
      const DeepCollectionEquality().hash(nullable) ^
      const DeepCollectionEquality().hash(elementNullable);

  @override
  _$ObjectPropertyCopyWith<_ObjectProperty> get copyWith =>
      __$ObjectPropertyCopyWithImpl<_ObjectProperty>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_ObjectPropertyToJson(this);
  }
}

abstract class _ObjectProperty implements ObjectProperty {
  const factory _ObjectProperty(
      {@JsonKey(name: 'localName') String name,
      @JsonKey(name: 'name') String dbName,
      DataType type,
      int staticPadding,
      bool nullable,
      bool elementNullable}) = _$_ObjectProperty;

  factory _ObjectProperty.fromJson(Map<String, dynamic> json) =
      _$_ObjectProperty.fromJson;

  @override
  @JsonKey(name: 'localName')
  String get name;
  @override
  @JsonKey(name: 'name')
  String get dbName;
  @override
  DataType get type;
  @override
  int get staticPadding;
  @override
  bool get nullable;
  @override
  bool get elementNullable;
  @override
  _$ObjectPropertyCopyWith<_ObjectProperty> get copyWith;
}

ObjectIndex _$ObjectIndexFromJson(Map<String, dynamic> json) {
  return _ObjectIndex.fromJson(json);
}

/// @nodoc
class _$ObjectIndexTearOff {
  const _$ObjectIndexTearOff();

// ignore: unused_element
  _ObjectIndex call({List<String> properties, bool unique, bool hashValue}) {
    return _ObjectIndex(
      properties: properties,
      unique: unique,
      hashValue: hashValue,
    );
  }

// ignore: unused_element
  ObjectIndex fromJson(Map<String, Object> json) {
    return ObjectIndex.fromJson(json);
  }
}

/// @nodoc
// ignore: unused_element
const $ObjectIndex = _$ObjectIndexTearOff();

/// @nodoc
mixin _$ObjectIndex {
  List<String> get properties;
  bool get unique;
  bool get hashValue;

  Map<String, dynamic> toJson();
  $ObjectIndexCopyWith<ObjectIndex> get copyWith;
}

/// @nodoc
abstract class $ObjectIndexCopyWith<$Res> {
  factory $ObjectIndexCopyWith(
          ObjectIndex value, $Res Function(ObjectIndex) then) =
      _$ObjectIndexCopyWithImpl<$Res>;
  $Res call({List<String> properties, bool unique, bool hashValue});
}

/// @nodoc
class _$ObjectIndexCopyWithImpl<$Res> implements $ObjectIndexCopyWith<$Res> {
  _$ObjectIndexCopyWithImpl(this._value, this._then);

  final ObjectIndex _value;
  // ignore: unused_field
  final $Res Function(ObjectIndex) _then;

  @override
  $Res call({
    Object properties = freezed,
    Object unique = freezed,
    Object hashValue = freezed,
  }) {
    return _then(_value.copyWith(
      properties: properties == freezed
          ? _value.properties
          : properties as List<String>,
      unique: unique == freezed ? _value.unique : unique as bool,
      hashValue: hashValue == freezed ? _value.hashValue : hashValue as bool,
    ));
  }
}

/// @nodoc
abstract class _$ObjectIndexCopyWith<$Res>
    implements $ObjectIndexCopyWith<$Res> {
  factory _$ObjectIndexCopyWith(
          _ObjectIndex value, $Res Function(_ObjectIndex) then) =
      __$ObjectIndexCopyWithImpl<$Res>;
  @override
  $Res call({List<String> properties, bool unique, bool hashValue});
}

/// @nodoc
class __$ObjectIndexCopyWithImpl<$Res> extends _$ObjectIndexCopyWithImpl<$Res>
    implements _$ObjectIndexCopyWith<$Res> {
  __$ObjectIndexCopyWithImpl(
      _ObjectIndex _value, $Res Function(_ObjectIndex) _then)
      : super(_value, (v) => _then(v as _ObjectIndex));

  @override
  _ObjectIndex get _value => super._value as _ObjectIndex;

  @override
  $Res call({
    Object properties = freezed,
    Object unique = freezed,
    Object hashValue = freezed,
  }) {
    return _then(_ObjectIndex(
      properties: properties == freezed
          ? _value.properties
          : properties as List<String>,
      unique: unique == freezed ? _value.unique : unique as bool,
      hashValue: hashValue == freezed ? _value.hashValue : hashValue as bool,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectIndex implements _ObjectIndex {
  const _$_ObjectIndex({this.properties, this.unique, this.hashValue});

  factory _$_ObjectIndex.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectIndexFromJson(json);

  @override
  final List<String> properties;
  @override
  final bool unique;
  @override
  final bool hashValue;

  @override
  String toString() {
    return 'ObjectIndex(properties: $properties, unique: $unique, hashValue: $hashValue)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ObjectIndex &&
            (identical(other.properties, properties) ||
                const DeepCollectionEquality()
                    .equals(other.properties, properties)) &&
            (identical(other.unique, unique) ||
                const DeepCollectionEquality().equals(other.unique, unique)) &&
            (identical(other.hashValue, hashValue) ||
                const DeepCollectionEquality()
                    .equals(other.hashValue, hashValue)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(properties) ^
      const DeepCollectionEquality().hash(unique) ^
      const DeepCollectionEquality().hash(hashValue);

  @override
  _$ObjectIndexCopyWith<_ObjectIndex> get copyWith =>
      __$ObjectIndexCopyWithImpl<_ObjectIndex>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_ObjectIndexToJson(this);
  }
}

abstract class _ObjectIndex implements ObjectIndex {
  const factory _ObjectIndex(
      {List<String> properties, bool unique, bool hashValue}) = _$_ObjectIndex;

  factory _ObjectIndex.fromJson(Map<String, dynamic> json) =
      _$_ObjectIndex.fromJson;

  @override
  List<String> get properties;
  @override
  bool get unique;
  @override
  bool get hashValue;
  @override
  _$ObjectIndexCopyWith<_ObjectIndex> get copyWith;
}
