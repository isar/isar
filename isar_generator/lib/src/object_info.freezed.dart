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
      {String dartName,
      String isarName,
      ObjectProperty oidProperty,
      List<ObjectProperty> properties = const [],
      List<ObjectIndex> indices = const [],
      List<String> converterImports = const []}) {
    return _ObjectInfo(
      dartName: dartName,
      isarName: isarName,
      oidProperty: oidProperty,
      properties: properties,
      indices: indices,
      converterImports: converterImports,
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
  String get dartName;
  String get isarName;
  ObjectProperty get oidProperty;
  List<ObjectProperty> get properties;
  List<ObjectIndex> get indices;
  List<String> get converterImports;

  Map<String, dynamic> toJson();
  $ObjectInfoCopyWith<ObjectInfo> get copyWith;
}

/// @nodoc
abstract class $ObjectInfoCopyWith<$Res> {
  factory $ObjectInfoCopyWith(
          ObjectInfo value, $Res Function(ObjectInfo) then) =
      _$ObjectInfoCopyWithImpl<$Res>;
  $Res call(
      {String dartName,
      String isarName,
      ObjectProperty oidProperty,
      List<ObjectProperty> properties,
      List<ObjectIndex> indices,
      List<String> converterImports});

  $ObjectPropertyCopyWith<$Res> get oidProperty;
}

/// @nodoc
class _$ObjectInfoCopyWithImpl<$Res> implements $ObjectInfoCopyWith<$Res> {
  _$ObjectInfoCopyWithImpl(this._value, this._then);

  final ObjectInfo _value;
  // ignore: unused_field
  final $Res Function(ObjectInfo) _then;

  @override
  $Res call({
    Object dartName = freezed,
    Object isarName = freezed,
    Object oidProperty = freezed,
    Object properties = freezed,
    Object indices = freezed,
    Object converterImports = freezed,
  }) {
    return _then(_value.copyWith(
      dartName: dartName == freezed ? _value.dartName : dartName as String,
      isarName: isarName == freezed ? _value.isarName : isarName as String,
      oidProperty: oidProperty == freezed
          ? _value.oidProperty
          : oidProperty as ObjectProperty,
      properties: properties == freezed
          ? _value.properties
          : properties as List<ObjectProperty>,
      indices:
          indices == freezed ? _value.indices : indices as List<ObjectIndex>,
      converterImports: converterImports == freezed
          ? _value.converterImports
          : converterImports as List<String>,
    ));
  }

  @override
  $ObjectPropertyCopyWith<$Res> get oidProperty {
    if (_value.oidProperty == null) {
      return null;
    }
    return $ObjectPropertyCopyWith<$Res>(_value.oidProperty, (value) {
      return _then(_value.copyWith(oidProperty: value));
    });
  }
}

/// @nodoc
abstract class _$ObjectInfoCopyWith<$Res> implements $ObjectInfoCopyWith<$Res> {
  factory _$ObjectInfoCopyWith(
          _ObjectInfo value, $Res Function(_ObjectInfo) then) =
      __$ObjectInfoCopyWithImpl<$Res>;
  @override
  $Res call(
      {String dartName,
      String isarName,
      ObjectProperty oidProperty,
      List<ObjectProperty> properties,
      List<ObjectIndex> indices,
      List<String> converterImports});

  @override
  $ObjectPropertyCopyWith<$Res> get oidProperty;
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
    Object dartName = freezed,
    Object isarName = freezed,
    Object oidProperty = freezed,
    Object properties = freezed,
    Object indices = freezed,
    Object converterImports = freezed,
  }) {
    return _then(_ObjectInfo(
      dartName: dartName == freezed ? _value.dartName : dartName as String,
      isarName: isarName == freezed ? _value.isarName : isarName as String,
      oidProperty: oidProperty == freezed
          ? _value.oidProperty
          : oidProperty as ObjectProperty,
      properties: properties == freezed
          ? _value.properties
          : properties as List<ObjectProperty>,
      indices:
          indices == freezed ? _value.indices : indices as List<ObjectIndex>,
      converterImports: converterImports == freezed
          ? _value.converterImports
          : converterImports as List<String>,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectInfo implements _ObjectInfo {
  const _$_ObjectInfo(
      {this.dartName,
      this.isarName,
      this.oidProperty,
      this.properties = const [],
      this.indices = const [],
      this.converterImports = const []})
      : assert(properties != null),
        assert(indices != null),
        assert(converterImports != null);

  factory _$_ObjectInfo.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectInfoFromJson(json);

  @override
  final String dartName;
  @override
  final String isarName;
  @override
  final ObjectProperty oidProperty;
  @JsonKey(defaultValue: const [])
  @override
  final List<ObjectProperty> properties;
  @JsonKey(defaultValue: const [])
  @override
  final List<ObjectIndex> indices;
  @JsonKey(defaultValue: const [])
  @override
  final List<String> converterImports;

  @override
  String toString() {
    return 'ObjectInfo(dartName: $dartName, isarName: $isarName, oidProperty: $oidProperty, properties: $properties, indices: $indices, converterImports: $converterImports)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ObjectInfo &&
            (identical(other.dartName, dartName) ||
                const DeepCollectionEquality()
                    .equals(other.dartName, dartName)) &&
            (identical(other.isarName, isarName) ||
                const DeepCollectionEquality()
                    .equals(other.isarName, isarName)) &&
            (identical(other.oidProperty, oidProperty) ||
                const DeepCollectionEquality()
                    .equals(other.oidProperty, oidProperty)) &&
            (identical(other.properties, properties) ||
                const DeepCollectionEquality()
                    .equals(other.properties, properties)) &&
            (identical(other.indices, indices) ||
                const DeepCollectionEquality()
                    .equals(other.indices, indices)) &&
            (identical(other.converterImports, converterImports) ||
                const DeepCollectionEquality()
                    .equals(other.converterImports, converterImports)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(dartName) ^
      const DeepCollectionEquality().hash(isarName) ^
      const DeepCollectionEquality().hash(oidProperty) ^
      const DeepCollectionEquality().hash(properties) ^
      const DeepCollectionEquality().hash(indices) ^
      const DeepCollectionEquality().hash(converterImports);

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
      {String dartName,
      String isarName,
      ObjectProperty oidProperty,
      List<ObjectProperty> properties,
      List<ObjectIndex> indices,
      List<String> converterImports}) = _$_ObjectInfo;

  factory _ObjectInfo.fromJson(Map<String, dynamic> json) =
      _$_ObjectInfo.fromJson;

  @override
  String get dartName;
  @override
  String get isarName;
  @override
  ObjectProperty get oidProperty;
  @override
  List<ObjectProperty> get properties;
  @override
  List<ObjectIndex> get indices;
  @override
  List<String> get converterImports;
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
      {String dartName,
      String isarName,
      String dartType,
      IsarType isarType,
      String converter,
      bool nullable,
      bool elementNullable}) {
    return _ObjectProperty(
      dartName: dartName,
      isarName: isarName,
      dartType: dartType,
      isarType: isarType,
      converter: converter,
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
  String get dartName;
  String get isarName;
  String get dartType;
  IsarType get isarType;
  String get converter;
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
      {String dartName,
      String isarName,
      String dartType,
      IsarType isarType,
      String converter,
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
    Object dartName = freezed,
    Object isarName = freezed,
    Object dartType = freezed,
    Object isarType = freezed,
    Object converter = freezed,
    Object nullable = freezed,
    Object elementNullable = freezed,
  }) {
    return _then(_value.copyWith(
      dartName: dartName == freezed ? _value.dartName : dartName as String,
      isarName: isarName == freezed ? _value.isarName : isarName as String,
      dartType: dartType == freezed ? _value.dartType : dartType as String,
      isarType: isarType == freezed ? _value.isarType : isarType as IsarType,
      converter: converter == freezed ? _value.converter : converter as String,
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
      {String dartName,
      String isarName,
      String dartType,
      IsarType isarType,
      String converter,
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
    Object dartName = freezed,
    Object isarName = freezed,
    Object dartType = freezed,
    Object isarType = freezed,
    Object converter = freezed,
    Object nullable = freezed,
    Object elementNullable = freezed,
  }) {
    return _then(_ObjectProperty(
      dartName: dartName == freezed ? _value.dartName : dartName as String,
      isarName: isarName == freezed ? _value.isarName : isarName as String,
      dartType: dartType == freezed ? _value.dartType : dartType as String,
      isarType: isarType == freezed ? _value.isarType : isarType as IsarType,
      converter: converter == freezed ? _value.converter : converter as String,
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
      {this.dartName,
      this.isarName,
      this.dartType,
      this.isarType,
      this.converter,
      this.nullable,
      this.elementNullable});

  factory _$_ObjectProperty.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectPropertyFromJson(json);

  @override
  final String dartName;
  @override
  final String isarName;
  @override
  final String dartType;
  @override
  final IsarType isarType;
  @override
  final String converter;
  @override
  final bool nullable;
  @override
  final bool elementNullable;

  @override
  String toString() {
    return 'ObjectProperty(dartName: $dartName, isarName: $isarName, dartType: $dartType, isarType: $isarType, converter: $converter, nullable: $nullable, elementNullable: $elementNullable)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ObjectProperty &&
            (identical(other.dartName, dartName) ||
                const DeepCollectionEquality()
                    .equals(other.dartName, dartName)) &&
            (identical(other.isarName, isarName) ||
                const DeepCollectionEquality()
                    .equals(other.isarName, isarName)) &&
            (identical(other.dartType, dartType) ||
                const DeepCollectionEquality()
                    .equals(other.dartType, dartType)) &&
            (identical(other.isarType, isarType) ||
                const DeepCollectionEquality()
                    .equals(other.isarType, isarType)) &&
            (identical(other.converter, converter) ||
                const DeepCollectionEquality()
                    .equals(other.converter, converter)) &&
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
      const DeepCollectionEquality().hash(dartName) ^
      const DeepCollectionEquality().hash(isarName) ^
      const DeepCollectionEquality().hash(dartType) ^
      const DeepCollectionEquality().hash(isarType) ^
      const DeepCollectionEquality().hash(converter) ^
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
      {String dartName,
      String isarName,
      String dartType,
      IsarType isarType,
      String converter,
      bool nullable,
      bool elementNullable}) = _$_ObjectProperty;

  factory _ObjectProperty.fromJson(Map<String, dynamic> json) =
      _$_ObjectProperty.fromJson;

  @override
  String get dartName;
  @override
  String get isarName;
  @override
  String get dartType;
  @override
  IsarType get isarType;
  @override
  String get converter;
  @override
  bool get nullable;
  @override
  bool get elementNullable;
  @override
  _$ObjectPropertyCopyWith<_ObjectProperty> get copyWith;
}

ObjectIndexProperty _$ObjectIndexPropertyFromJson(Map<String, dynamic> json) {
  return _ObjectIndexProperty.fromJson(json);
}

/// @nodoc
class _$ObjectIndexPropertyTearOff {
  const _$ObjectIndexPropertyTearOff();

// ignore: unused_element
  _ObjectIndexProperty call(
      {String isarName, StringIndexType stringType, bool caseSensitive}) {
    return _ObjectIndexProperty(
      isarName: isarName,
      stringType: stringType,
      caseSensitive: caseSensitive,
    );
  }

// ignore: unused_element
  ObjectIndexProperty fromJson(Map<String, Object> json) {
    return ObjectIndexProperty.fromJson(json);
  }
}

/// @nodoc
// ignore: unused_element
const $ObjectIndexProperty = _$ObjectIndexPropertyTearOff();

/// @nodoc
mixin _$ObjectIndexProperty {
  String get isarName;
  StringIndexType get stringType;
  bool get caseSensitive;

  Map<String, dynamic> toJson();
  $ObjectIndexPropertyCopyWith<ObjectIndexProperty> get copyWith;
}

/// @nodoc
abstract class $ObjectIndexPropertyCopyWith<$Res> {
  factory $ObjectIndexPropertyCopyWith(
          ObjectIndexProperty value, $Res Function(ObjectIndexProperty) then) =
      _$ObjectIndexPropertyCopyWithImpl<$Res>;
  $Res call({String isarName, StringIndexType stringType, bool caseSensitive});
}

/// @nodoc
class _$ObjectIndexPropertyCopyWithImpl<$Res>
    implements $ObjectIndexPropertyCopyWith<$Res> {
  _$ObjectIndexPropertyCopyWithImpl(this._value, this._then);

  final ObjectIndexProperty _value;
  // ignore: unused_field
  final $Res Function(ObjectIndexProperty) _then;

  @override
  $Res call({
    Object isarName = freezed,
    Object stringType = freezed,
    Object caseSensitive = freezed,
  }) {
    return _then(_value.copyWith(
      isarName: isarName == freezed ? _value.isarName : isarName as String,
      stringType: stringType == freezed
          ? _value.stringType
          : stringType as StringIndexType,
      caseSensitive: caseSensitive == freezed
          ? _value.caseSensitive
          : caseSensitive as bool,
    ));
  }
}

/// @nodoc
abstract class _$ObjectIndexPropertyCopyWith<$Res>
    implements $ObjectIndexPropertyCopyWith<$Res> {
  factory _$ObjectIndexPropertyCopyWith(_ObjectIndexProperty value,
          $Res Function(_ObjectIndexProperty) then) =
      __$ObjectIndexPropertyCopyWithImpl<$Res>;
  @override
  $Res call({String isarName, StringIndexType stringType, bool caseSensitive});
}

/// @nodoc
class __$ObjectIndexPropertyCopyWithImpl<$Res>
    extends _$ObjectIndexPropertyCopyWithImpl<$Res>
    implements _$ObjectIndexPropertyCopyWith<$Res> {
  __$ObjectIndexPropertyCopyWithImpl(
      _ObjectIndexProperty _value, $Res Function(_ObjectIndexProperty) _then)
      : super(_value, (v) => _then(v as _ObjectIndexProperty));

  @override
  _ObjectIndexProperty get _value => super._value as _ObjectIndexProperty;

  @override
  $Res call({
    Object isarName = freezed,
    Object stringType = freezed,
    Object caseSensitive = freezed,
  }) {
    return _then(_ObjectIndexProperty(
      isarName: isarName == freezed ? _value.isarName : isarName as String,
      stringType: stringType == freezed
          ? _value.stringType
          : stringType as StringIndexType,
      caseSensitive: caseSensitive == freezed
          ? _value.caseSensitive
          : caseSensitive as bool,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectIndexProperty implements _ObjectIndexProperty {
  const _$_ObjectIndexProperty(
      {this.isarName, this.stringType, this.caseSensitive});

  factory _$_ObjectIndexProperty.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectIndexPropertyFromJson(json);

  @override
  final String isarName;
  @override
  final StringIndexType stringType;
  @override
  final bool caseSensitive;

  @override
  String toString() {
    return 'ObjectIndexProperty(isarName: $isarName, stringType: $stringType, caseSensitive: $caseSensitive)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ObjectIndexProperty &&
            (identical(other.isarName, isarName) ||
                const DeepCollectionEquality()
                    .equals(other.isarName, isarName)) &&
            (identical(other.stringType, stringType) ||
                const DeepCollectionEquality()
                    .equals(other.stringType, stringType)) &&
            (identical(other.caseSensitive, caseSensitive) ||
                const DeepCollectionEquality()
                    .equals(other.caseSensitive, caseSensitive)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(isarName) ^
      const DeepCollectionEquality().hash(stringType) ^
      const DeepCollectionEquality().hash(caseSensitive);

  @override
  _$ObjectIndexPropertyCopyWith<_ObjectIndexProperty> get copyWith =>
      __$ObjectIndexPropertyCopyWithImpl<_ObjectIndexProperty>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_ObjectIndexPropertyToJson(this);
  }
}

abstract class _ObjectIndexProperty implements ObjectIndexProperty {
  const factory _ObjectIndexProperty(
      {String isarName,
      StringIndexType stringType,
      bool caseSensitive}) = _$_ObjectIndexProperty;

  factory _ObjectIndexProperty.fromJson(Map<String, dynamic> json) =
      _$_ObjectIndexProperty.fromJson;

  @override
  String get isarName;
  @override
  StringIndexType get stringType;
  @override
  bool get caseSensitive;
  @override
  _$ObjectIndexPropertyCopyWith<_ObjectIndexProperty> get copyWith;
}

ObjectIndex _$ObjectIndexFromJson(Map<String, dynamic> json) {
  return _ObjectIndex.fromJson(json);
}

/// @nodoc
class _$ObjectIndexTearOff {
  const _$ObjectIndexTearOff();

// ignore: unused_element
  _ObjectIndex call({List<ObjectIndexProperty> properties, bool unique}) {
    return _ObjectIndex(
      properties: properties,
      unique: unique,
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
  List<ObjectIndexProperty> get properties;
  bool get unique;

  Map<String, dynamic> toJson();
  $ObjectIndexCopyWith<ObjectIndex> get copyWith;
}

/// @nodoc
abstract class $ObjectIndexCopyWith<$Res> {
  factory $ObjectIndexCopyWith(
          ObjectIndex value, $Res Function(ObjectIndex) then) =
      _$ObjectIndexCopyWithImpl<$Res>;
  $Res call({List<ObjectIndexProperty> properties, bool unique});
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
  }) {
    return _then(_value.copyWith(
      properties: properties == freezed
          ? _value.properties
          : properties as List<ObjectIndexProperty>,
      unique: unique == freezed ? _value.unique : unique as bool,
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
  $Res call({List<ObjectIndexProperty> properties, bool unique});
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
  }) {
    return _then(_ObjectIndex(
      properties: properties == freezed
          ? _value.properties
          : properties as List<ObjectIndexProperty>,
      unique: unique == freezed ? _value.unique : unique as bool,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectIndex implements _ObjectIndex {
  const _$_ObjectIndex({this.properties, this.unique});

  factory _$_ObjectIndex.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectIndexFromJson(json);

  @override
  final List<ObjectIndexProperty> properties;
  @override
  final bool unique;

  @override
  String toString() {
    return 'ObjectIndex(properties: $properties, unique: $unique)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ObjectIndex &&
            (identical(other.properties, properties) ||
                const DeepCollectionEquality()
                    .equals(other.properties, properties)) &&
            (identical(other.unique, unique) ||
                const DeepCollectionEquality().equals(other.unique, unique)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(properties) ^
      const DeepCollectionEquality().hash(unique);

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
      {List<ObjectIndexProperty> properties, bool unique}) = _$_ObjectIndex;

  factory _ObjectIndex.fromJson(Map<String, dynamic> json) =
      _$_ObjectIndex.fromJson;

  @override
  List<ObjectIndexProperty> get properties;
  @override
  bool get unique;
  @override
  _$ObjectIndexCopyWith<_ObjectIndex> get copyWith;
}
