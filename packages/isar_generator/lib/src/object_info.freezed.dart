// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'object_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

ObjectInfo _$ObjectInfoFromJson(Map<String, dynamic> json) {
  return _ObjectInfo.fromJson(json);
}

/// @nodoc
class _$ObjectInfoTearOff {
  const _$ObjectInfoTearOff();

  _ObjectInfo call(
      {required String dartName,
      required String isarName,
      required String accessor,
      required List<ObjectProperty> properties,
      required List<ObjectIndex> indexes,
      required List<ObjectLink> links}) {
    return _ObjectInfo(
      dartName: dartName,
      isarName: isarName,
      accessor: accessor,
      properties: properties,
      indexes: indexes,
      links: links,
    );
  }

  ObjectInfo fromJson(Map<String, Object?> json) {
    return ObjectInfo.fromJson(json);
  }
}

/// @nodoc
const $ObjectInfo = _$ObjectInfoTearOff();

/// @nodoc
mixin _$ObjectInfo {
  String get dartName => throw _privateConstructorUsedError;
  String get isarName => throw _privateConstructorUsedError;
  String get accessor => throw _privateConstructorUsedError;
  List<ObjectProperty> get properties => throw _privateConstructorUsedError;
  List<ObjectIndex> get indexes => throw _privateConstructorUsedError;
  List<ObjectLink> get links => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ObjectInfoCopyWith<ObjectInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ObjectInfoCopyWith<$Res> {
  factory $ObjectInfoCopyWith(
          ObjectInfo value, $Res Function(ObjectInfo) then) =
      _$ObjectInfoCopyWithImpl<$Res>;
  $Res call(
      {String dartName,
      String isarName,
      String accessor,
      List<ObjectProperty> properties,
      List<ObjectIndex> indexes,
      List<ObjectLink> links});
}

/// @nodoc
class _$ObjectInfoCopyWithImpl<$Res> implements $ObjectInfoCopyWith<$Res> {
  _$ObjectInfoCopyWithImpl(this._value, this._then);

  final ObjectInfo _value;
  // ignore: unused_field
  final $Res Function(ObjectInfo) _then;

  @override
  $Res call({
    Object? dartName = freezed,
    Object? isarName = freezed,
    Object? accessor = freezed,
    Object? properties = freezed,
    Object? indexes = freezed,
    Object? links = freezed,
  }) {
    return _then(_value.copyWith(
      dartName: dartName == freezed
          ? _value.dartName
          : dartName // ignore: cast_nullable_to_non_nullable
              as String,
      isarName: isarName == freezed
          ? _value.isarName
          : isarName // ignore: cast_nullable_to_non_nullable
              as String,
      accessor: accessor == freezed
          ? _value.accessor
          : accessor // ignore: cast_nullable_to_non_nullable
              as String,
      properties: properties == freezed
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<ObjectProperty>,
      indexes: indexes == freezed
          ? _value.indexes
          : indexes // ignore: cast_nullable_to_non_nullable
              as List<ObjectIndex>,
      links: links == freezed
          ? _value.links
          : links // ignore: cast_nullable_to_non_nullable
              as List<ObjectLink>,
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
      {String dartName,
      String isarName,
      String accessor,
      List<ObjectProperty> properties,
      List<ObjectIndex> indexes,
      List<ObjectLink> links});
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
    Object? dartName = freezed,
    Object? isarName = freezed,
    Object? accessor = freezed,
    Object? properties = freezed,
    Object? indexes = freezed,
    Object? links = freezed,
  }) {
    return _then(_ObjectInfo(
      dartName: dartName == freezed
          ? _value.dartName
          : dartName // ignore: cast_nullable_to_non_nullable
              as String,
      isarName: isarName == freezed
          ? _value.isarName
          : isarName // ignore: cast_nullable_to_non_nullable
              as String,
      accessor: accessor == freezed
          ? _value.accessor
          : accessor // ignore: cast_nullable_to_non_nullable
              as String,
      properties: properties == freezed
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<ObjectProperty>,
      indexes: indexes == freezed
          ? _value.indexes
          : indexes // ignore: cast_nullable_to_non_nullable
              as List<ObjectIndex>,
      links: links == freezed
          ? _value.links
          : links // ignore: cast_nullable_to_non_nullable
              as List<ObjectLink>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ObjectInfo extends _ObjectInfo {
  const _$_ObjectInfo(
      {required this.dartName,
      required this.isarName,
      required this.accessor,
      required this.properties,
      required this.indexes,
      required this.links})
      : super._();

  factory _$_ObjectInfo.fromJson(Map<String, dynamic> json) =>
      _$$_ObjectInfoFromJson(json);

  @override
  final String dartName;
  @override
  final String isarName;
  @override
  final String accessor;
  @override
  final List<ObjectProperty> properties;
  @override
  final List<ObjectIndex> indexes;
  @override
  final List<ObjectLink> links;

  @override
  String toString() {
    return 'ObjectInfo(dartName: $dartName, isarName: $isarName, accessor: $accessor, properties: $properties, indexes: $indexes, links: $links)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ObjectInfo &&
            const DeepCollectionEquality().equals(other.dartName, dartName) &&
            const DeepCollectionEquality().equals(other.isarName, isarName) &&
            const DeepCollectionEquality().equals(other.accessor, accessor) &&
            const DeepCollectionEquality()
                .equals(other.properties, properties) &&
            const DeepCollectionEquality().equals(other.indexes, indexes) &&
            const DeepCollectionEquality().equals(other.links, links));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(dartName),
      const DeepCollectionEquality().hash(isarName),
      const DeepCollectionEquality().hash(accessor),
      const DeepCollectionEquality().hash(properties),
      const DeepCollectionEquality().hash(indexes),
      const DeepCollectionEquality().hash(links));

  @JsonKey(ignore: true)
  @override
  _$ObjectInfoCopyWith<_ObjectInfo> get copyWith =>
      __$ObjectInfoCopyWithImpl<_ObjectInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ObjectInfoToJson(this);
  }
}

abstract class _ObjectInfo extends ObjectInfo {
  const factory _ObjectInfo(
      {required String dartName,
      required String isarName,
      required String accessor,
      required List<ObjectProperty> properties,
      required List<ObjectIndex> indexes,
      required List<ObjectLink> links}) = _$_ObjectInfo;
  const _ObjectInfo._() : super._();

  factory _ObjectInfo.fromJson(Map<String, dynamic> json) =
      _$_ObjectInfo.fromJson;

  @override
  String get dartName;
  @override
  String get isarName;
  @override
  String get accessor;
  @override
  List<ObjectProperty> get properties;
  @override
  List<ObjectIndex> get indexes;
  @override
  List<ObjectLink> get links;
  @override
  @JsonKey(ignore: true)
  _$ObjectInfoCopyWith<_ObjectInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

ObjectProperty _$ObjectPropertyFromJson(Map<String, dynamic> json) {
  return _ObjectProperty.fromJson(json);
}

/// @nodoc
class _$ObjectPropertyTearOff {
  const _$ObjectPropertyTearOff();

  _ObjectProperty call(
      {required String dartName,
      required String isarName,
      required String dartType,
      required IsarType isarType,
      required bool isId,
      String? converter,
      required bool nullable,
      required bool elementNullable,
      required PropertyDeser deserialize,
      int? constructorPosition}) {
    return _ObjectProperty(
      dartName: dartName,
      isarName: isarName,
      dartType: dartType,
      isarType: isarType,
      isId: isId,
      converter: converter,
      nullable: nullable,
      elementNullable: elementNullable,
      deserialize: deserialize,
      constructorPosition: constructorPosition,
    );
  }

  ObjectProperty fromJson(Map<String, Object?> json) {
    return ObjectProperty.fromJson(json);
  }
}

/// @nodoc
const $ObjectProperty = _$ObjectPropertyTearOff();

/// @nodoc
mixin _$ObjectProperty {
  String get dartName => throw _privateConstructorUsedError;
  String get isarName => throw _privateConstructorUsedError;
  String get dartType => throw _privateConstructorUsedError;
  IsarType get isarType => throw _privateConstructorUsedError;
  bool get isId => throw _privateConstructorUsedError;
  String? get converter => throw _privateConstructorUsedError;
  bool get nullable => throw _privateConstructorUsedError;
  bool get elementNullable => throw _privateConstructorUsedError;
  PropertyDeser get deserialize => throw _privateConstructorUsedError;
  int? get constructorPosition => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ObjectPropertyCopyWith<ObjectProperty> get copyWith =>
      throw _privateConstructorUsedError;
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
      bool isId,
      String? converter,
      bool nullable,
      bool elementNullable,
      PropertyDeser deserialize,
      int? constructorPosition});
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
    Object? dartName = freezed,
    Object? isarName = freezed,
    Object? dartType = freezed,
    Object? isarType = freezed,
    Object? isId = freezed,
    Object? converter = freezed,
    Object? nullable = freezed,
    Object? elementNullable = freezed,
    Object? deserialize = freezed,
    Object? constructorPosition = freezed,
  }) {
    return _then(_value.copyWith(
      dartName: dartName == freezed
          ? _value.dartName
          : dartName // ignore: cast_nullable_to_non_nullable
              as String,
      isarName: isarName == freezed
          ? _value.isarName
          : isarName // ignore: cast_nullable_to_non_nullable
              as String,
      dartType: dartType == freezed
          ? _value.dartType
          : dartType // ignore: cast_nullable_to_non_nullable
              as String,
      isarType: isarType == freezed
          ? _value.isarType
          : isarType // ignore: cast_nullable_to_non_nullable
              as IsarType,
      isId: isId == freezed
          ? _value.isId
          : isId // ignore: cast_nullable_to_non_nullable
              as bool,
      converter: converter == freezed
          ? _value.converter
          : converter // ignore: cast_nullable_to_non_nullable
              as String?,
      nullable: nullable == freezed
          ? _value.nullable
          : nullable // ignore: cast_nullable_to_non_nullable
              as bool,
      elementNullable: elementNullable == freezed
          ? _value.elementNullable
          : elementNullable // ignore: cast_nullable_to_non_nullable
              as bool,
      deserialize: deserialize == freezed
          ? _value.deserialize
          : deserialize // ignore: cast_nullable_to_non_nullable
              as PropertyDeser,
      constructorPosition: constructorPosition == freezed
          ? _value.constructorPosition
          : constructorPosition // ignore: cast_nullable_to_non_nullable
              as int?,
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
      bool isId,
      String? converter,
      bool nullable,
      bool elementNullable,
      PropertyDeser deserialize,
      int? constructorPosition});
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
    Object? dartName = freezed,
    Object? isarName = freezed,
    Object? dartType = freezed,
    Object? isarType = freezed,
    Object? isId = freezed,
    Object? converter = freezed,
    Object? nullable = freezed,
    Object? elementNullable = freezed,
    Object? deserialize = freezed,
    Object? constructorPosition = freezed,
  }) {
    return _then(_ObjectProperty(
      dartName: dartName == freezed
          ? _value.dartName
          : dartName // ignore: cast_nullable_to_non_nullable
              as String,
      isarName: isarName == freezed
          ? _value.isarName
          : isarName // ignore: cast_nullable_to_non_nullable
              as String,
      dartType: dartType == freezed
          ? _value.dartType
          : dartType // ignore: cast_nullable_to_non_nullable
              as String,
      isarType: isarType == freezed
          ? _value.isarType
          : isarType // ignore: cast_nullable_to_non_nullable
              as IsarType,
      isId: isId == freezed
          ? _value.isId
          : isId // ignore: cast_nullable_to_non_nullable
              as bool,
      converter: converter == freezed
          ? _value.converter
          : converter // ignore: cast_nullable_to_non_nullable
              as String?,
      nullable: nullable == freezed
          ? _value.nullable
          : nullable // ignore: cast_nullable_to_non_nullable
              as bool,
      elementNullable: elementNullable == freezed
          ? _value.elementNullable
          : elementNullable // ignore: cast_nullable_to_non_nullable
              as bool,
      deserialize: deserialize == freezed
          ? _value.deserialize
          : deserialize // ignore: cast_nullable_to_non_nullable
              as PropertyDeser,
      constructorPosition: constructorPosition == freezed
          ? _value.constructorPosition
          : constructorPosition // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ObjectProperty extends _ObjectProperty {
  const _$_ObjectProperty(
      {required this.dartName,
      required this.isarName,
      required this.dartType,
      required this.isarType,
      required this.isId,
      this.converter,
      required this.nullable,
      required this.elementNullable,
      required this.deserialize,
      this.constructorPosition})
      : super._();

  factory _$_ObjectProperty.fromJson(Map<String, dynamic> json) =>
      _$$_ObjectPropertyFromJson(json);

  @override
  final String dartName;
  @override
  final String isarName;
  @override
  final String dartType;
  @override
  final IsarType isarType;
  @override
  final bool isId;
  @override
  final String? converter;
  @override
  final bool nullable;
  @override
  final bool elementNullable;
  @override
  final PropertyDeser deserialize;
  @override
  final int? constructorPosition;

  @override
  String toString() {
    return 'ObjectProperty(dartName: $dartName, isarName: $isarName, dartType: $dartType, isarType: $isarType, isId: $isId, converter: $converter, nullable: $nullable, elementNullable: $elementNullable, deserialize: $deserialize, constructorPosition: $constructorPosition)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ObjectProperty &&
            const DeepCollectionEquality().equals(other.dartName, dartName) &&
            const DeepCollectionEquality().equals(other.isarName, isarName) &&
            const DeepCollectionEquality().equals(other.dartType, dartType) &&
            const DeepCollectionEquality().equals(other.isarType, isarType) &&
            const DeepCollectionEquality().equals(other.isId, isId) &&
            const DeepCollectionEquality().equals(other.converter, converter) &&
            const DeepCollectionEquality().equals(other.nullable, nullable) &&
            const DeepCollectionEquality()
                .equals(other.elementNullable, elementNullable) &&
            const DeepCollectionEquality()
                .equals(other.deserialize, deserialize) &&
            const DeepCollectionEquality()
                .equals(other.constructorPosition, constructorPosition));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(dartName),
      const DeepCollectionEquality().hash(isarName),
      const DeepCollectionEquality().hash(dartType),
      const DeepCollectionEquality().hash(isarType),
      const DeepCollectionEquality().hash(isId),
      const DeepCollectionEquality().hash(converter),
      const DeepCollectionEquality().hash(nullable),
      const DeepCollectionEquality().hash(elementNullable),
      const DeepCollectionEquality().hash(deserialize),
      const DeepCollectionEquality().hash(constructorPosition));

  @JsonKey(ignore: true)
  @override
  _$ObjectPropertyCopyWith<_ObjectProperty> get copyWith =>
      __$ObjectPropertyCopyWithImpl<_ObjectProperty>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ObjectPropertyToJson(this);
  }
}

abstract class _ObjectProperty extends ObjectProperty {
  const factory _ObjectProperty(
      {required String dartName,
      required String isarName,
      required String dartType,
      required IsarType isarType,
      required bool isId,
      String? converter,
      required bool nullable,
      required bool elementNullable,
      required PropertyDeser deserialize,
      int? constructorPosition}) = _$_ObjectProperty;
  const _ObjectProperty._() : super._();

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
  bool get isId;
  @override
  String? get converter;
  @override
  bool get nullable;
  @override
  bool get elementNullable;
  @override
  PropertyDeser get deserialize;
  @override
  int? get constructorPosition;
  @override
  @JsonKey(ignore: true)
  _$ObjectPropertyCopyWith<_ObjectProperty> get copyWith =>
      throw _privateConstructorUsedError;
}

ObjectIndexProperty _$ObjectIndexPropertyFromJson(Map<String, dynamic> json) {
  return _ObjectIndexProperty.fromJson(json);
}

/// @nodoc
class _$ObjectIndexPropertyTearOff {
  const _$ObjectIndexPropertyTearOff();

  _ObjectIndexProperty call(
      {required ObjectProperty property,
      required IndexType type,
      required bool caseSensitive}) {
    return _ObjectIndexProperty(
      property: property,
      type: type,
      caseSensitive: caseSensitive,
    );
  }

  ObjectIndexProperty fromJson(Map<String, Object?> json) {
    return ObjectIndexProperty.fromJson(json);
  }
}

/// @nodoc
const $ObjectIndexProperty = _$ObjectIndexPropertyTearOff();

/// @nodoc
mixin _$ObjectIndexProperty {
  ObjectProperty get property => throw _privateConstructorUsedError;
  IndexType get type => throw _privateConstructorUsedError;
  bool get caseSensitive => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ObjectIndexPropertyCopyWith<ObjectIndexProperty> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ObjectIndexPropertyCopyWith<$Res> {
  factory $ObjectIndexPropertyCopyWith(
          ObjectIndexProperty value, $Res Function(ObjectIndexProperty) then) =
      _$ObjectIndexPropertyCopyWithImpl<$Res>;
  $Res call({ObjectProperty property, IndexType type, bool caseSensitive});

  $ObjectPropertyCopyWith<$Res> get property;
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
    Object? property = freezed,
    Object? type = freezed,
    Object? caseSensitive = freezed,
  }) {
    return _then(_value.copyWith(
      property: property == freezed
          ? _value.property
          : property // ignore: cast_nullable_to_non_nullable
              as ObjectProperty,
      type: type == freezed
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IndexType,
      caseSensitive: caseSensitive == freezed
          ? _value.caseSensitive
          : caseSensitive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  @override
  $ObjectPropertyCopyWith<$Res> get property {
    return $ObjectPropertyCopyWith<$Res>(_value.property, (value) {
      return _then(_value.copyWith(property: value));
    });
  }
}

/// @nodoc
abstract class _$ObjectIndexPropertyCopyWith<$Res>
    implements $ObjectIndexPropertyCopyWith<$Res> {
  factory _$ObjectIndexPropertyCopyWith(_ObjectIndexProperty value,
          $Res Function(_ObjectIndexProperty) then) =
      __$ObjectIndexPropertyCopyWithImpl<$Res>;
  @override
  $Res call({ObjectProperty property, IndexType type, bool caseSensitive});

  @override
  $ObjectPropertyCopyWith<$Res> get property;
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
    Object? property = freezed,
    Object? type = freezed,
    Object? caseSensitive = freezed,
  }) {
    return _then(_ObjectIndexProperty(
      property: property == freezed
          ? _value.property
          : property // ignore: cast_nullable_to_non_nullable
              as ObjectProperty,
      type: type == freezed
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IndexType,
      caseSensitive: caseSensitive == freezed
          ? _value.caseSensitive
          : caseSensitive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ObjectIndexProperty extends _ObjectIndexProperty {
  const _$_ObjectIndexProperty(
      {required this.property, required this.type, required this.caseSensitive})
      : super._();

  factory _$_ObjectIndexProperty.fromJson(Map<String, dynamic> json) =>
      _$$_ObjectIndexPropertyFromJson(json);

  @override
  final ObjectProperty property;
  @override
  final IndexType type;
  @override
  final bool caseSensitive;

  @override
  String toString() {
    return 'ObjectIndexProperty(property: $property, type: $type, caseSensitive: $caseSensitive)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ObjectIndexProperty &&
            const DeepCollectionEquality().equals(other.property, property) &&
            const DeepCollectionEquality().equals(other.type, type) &&
            const DeepCollectionEquality()
                .equals(other.caseSensitive, caseSensitive));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(property),
      const DeepCollectionEquality().hash(type),
      const DeepCollectionEquality().hash(caseSensitive));

  @JsonKey(ignore: true)
  @override
  _$ObjectIndexPropertyCopyWith<_ObjectIndexProperty> get copyWith =>
      __$ObjectIndexPropertyCopyWithImpl<_ObjectIndexProperty>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ObjectIndexPropertyToJson(this);
  }
}

abstract class _ObjectIndexProperty extends ObjectIndexProperty {
  const factory _ObjectIndexProperty(
      {required ObjectProperty property,
      required IndexType type,
      required bool caseSensitive}) = _$_ObjectIndexProperty;
  const _ObjectIndexProperty._() : super._();

  factory _ObjectIndexProperty.fromJson(Map<String, dynamic> json) =
      _$_ObjectIndexProperty.fromJson;

  @override
  ObjectProperty get property;
  @override
  IndexType get type;
  @override
  bool get caseSensitive;
  @override
  @JsonKey(ignore: true)
  _$ObjectIndexPropertyCopyWith<_ObjectIndexProperty> get copyWith =>
      throw _privateConstructorUsedError;
}

ObjectIndex _$ObjectIndexFromJson(Map<String, dynamic> json) {
  return _ObjectIndex.fromJson(json);
}

/// @nodoc
class _$ObjectIndexTearOff {
  const _$ObjectIndexTearOff();

  _ObjectIndex call(
      {required String name,
      required List<ObjectIndexProperty> properties,
      required bool unique}) {
    return _ObjectIndex(
      name: name,
      properties: properties,
      unique: unique,
    );
  }

  ObjectIndex fromJson(Map<String, Object?> json) {
    return ObjectIndex.fromJson(json);
  }
}

/// @nodoc
const $ObjectIndex = _$ObjectIndexTearOff();

/// @nodoc
mixin _$ObjectIndex {
  String get name => throw _privateConstructorUsedError;
  List<ObjectIndexProperty> get properties =>
      throw _privateConstructorUsedError;
  bool get unique => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ObjectIndexCopyWith<ObjectIndex> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ObjectIndexCopyWith<$Res> {
  factory $ObjectIndexCopyWith(
          ObjectIndex value, $Res Function(ObjectIndex) then) =
      _$ObjectIndexCopyWithImpl<$Res>;
  $Res call({String name, List<ObjectIndexProperty> properties, bool unique});
}

/// @nodoc
class _$ObjectIndexCopyWithImpl<$Res> implements $ObjectIndexCopyWith<$Res> {
  _$ObjectIndexCopyWithImpl(this._value, this._then);

  final ObjectIndex _value;
  // ignore: unused_field
  final $Res Function(ObjectIndex) _then;

  @override
  $Res call({
    Object? name = freezed,
    Object? properties = freezed,
    Object? unique = freezed,
  }) {
    return _then(_value.copyWith(
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      properties: properties == freezed
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<ObjectIndexProperty>,
      unique: unique == freezed
          ? _value.unique
          : unique // ignore: cast_nullable_to_non_nullable
              as bool,
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
  $Res call({String name, List<ObjectIndexProperty> properties, bool unique});
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
    Object? name = freezed,
    Object? properties = freezed,
    Object? unique = freezed,
  }) {
    return _then(_ObjectIndex(
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      properties: properties == freezed
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<ObjectIndexProperty>,
      unique: unique == freezed
          ? _value.unique
          : unique // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ObjectIndex extends _ObjectIndex {
  const _$_ObjectIndex(
      {required this.name, required this.properties, required this.unique})
      : super._();

  factory _$_ObjectIndex.fromJson(Map<String, dynamic> json) =>
      _$$_ObjectIndexFromJson(json);

  @override
  final String name;
  @override
  final List<ObjectIndexProperty> properties;
  @override
  final bool unique;

  @override
  String toString() {
    return 'ObjectIndex(name: $name, properties: $properties, unique: $unique)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ObjectIndex &&
            const DeepCollectionEquality().equals(other.name, name) &&
            const DeepCollectionEquality()
                .equals(other.properties, properties) &&
            const DeepCollectionEquality().equals(other.unique, unique));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(name),
      const DeepCollectionEquality().hash(properties),
      const DeepCollectionEquality().hash(unique));

  @JsonKey(ignore: true)
  @override
  _$ObjectIndexCopyWith<_ObjectIndex> get copyWith =>
      __$ObjectIndexCopyWithImpl<_ObjectIndex>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ObjectIndexToJson(this);
  }
}

abstract class _ObjectIndex extends ObjectIndex {
  const factory _ObjectIndex(
      {required String name,
      required List<ObjectIndexProperty> properties,
      required bool unique}) = _$_ObjectIndex;
  const _ObjectIndex._() : super._();

  factory _ObjectIndex.fromJson(Map<String, dynamic> json) =
      _$_ObjectIndex.fromJson;

  @override
  String get name;
  @override
  List<ObjectIndexProperty> get properties;
  @override
  bool get unique;
  @override
  @JsonKey(ignore: true)
  _$ObjectIndexCopyWith<_ObjectIndex> get copyWith =>
      throw _privateConstructorUsedError;
}

ObjectLink _$ObjectLinkFromJson(Map<String, dynamic> json) {
  return _ObjectLink.fromJson(json);
}

/// @nodoc
class _$ObjectLinkTearOff {
  const _$ObjectLinkTearOff();

  _ObjectLink call(
      {required String dartName,
      required String isarName,
      required String? targetIsarName,
      required String targetCollectionDartName,
      required String targetCollectionIsarName,
      required bool links,
      required bool backlink}) {
    return _ObjectLink(
      dartName: dartName,
      isarName: isarName,
      targetIsarName: targetIsarName,
      targetCollectionDartName: targetCollectionDartName,
      targetCollectionIsarName: targetCollectionIsarName,
      links: links,
      backlink: backlink,
    );
  }

  ObjectLink fromJson(Map<String, Object?> json) {
    return ObjectLink.fromJson(json);
  }
}

/// @nodoc
const $ObjectLink = _$ObjectLinkTearOff();

/// @nodoc
mixin _$ObjectLink {
  String get dartName => throw _privateConstructorUsedError;
  String get isarName => throw _privateConstructorUsedError;
  String? get targetIsarName => throw _privateConstructorUsedError;
  String get targetCollectionDartName => throw _privateConstructorUsedError;
  String get targetCollectionIsarName => throw _privateConstructorUsedError;
  bool get links => throw _privateConstructorUsedError;
  bool get backlink => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ObjectLinkCopyWith<ObjectLink> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ObjectLinkCopyWith<$Res> {
  factory $ObjectLinkCopyWith(
          ObjectLink value, $Res Function(ObjectLink) then) =
      _$ObjectLinkCopyWithImpl<$Res>;
  $Res call(
      {String dartName,
      String isarName,
      String? targetIsarName,
      String targetCollectionDartName,
      String targetCollectionIsarName,
      bool links,
      bool backlink});
}

/// @nodoc
class _$ObjectLinkCopyWithImpl<$Res> implements $ObjectLinkCopyWith<$Res> {
  _$ObjectLinkCopyWithImpl(this._value, this._then);

  final ObjectLink _value;
  // ignore: unused_field
  final $Res Function(ObjectLink) _then;

  @override
  $Res call({
    Object? dartName = freezed,
    Object? isarName = freezed,
    Object? targetIsarName = freezed,
    Object? targetCollectionDartName = freezed,
    Object? targetCollectionIsarName = freezed,
    Object? links = freezed,
    Object? backlink = freezed,
  }) {
    return _then(_value.copyWith(
      dartName: dartName == freezed
          ? _value.dartName
          : dartName // ignore: cast_nullable_to_non_nullable
              as String,
      isarName: isarName == freezed
          ? _value.isarName
          : isarName // ignore: cast_nullable_to_non_nullable
              as String,
      targetIsarName: targetIsarName == freezed
          ? _value.targetIsarName
          : targetIsarName // ignore: cast_nullable_to_non_nullable
              as String?,
      targetCollectionDartName: targetCollectionDartName == freezed
          ? _value.targetCollectionDartName
          : targetCollectionDartName // ignore: cast_nullable_to_non_nullable
              as String,
      targetCollectionIsarName: targetCollectionIsarName == freezed
          ? _value.targetCollectionIsarName
          : targetCollectionIsarName // ignore: cast_nullable_to_non_nullable
              as String,
      links: links == freezed
          ? _value.links
          : links // ignore: cast_nullable_to_non_nullable
              as bool,
      backlink: backlink == freezed
          ? _value.backlink
          : backlink // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
abstract class _$ObjectLinkCopyWith<$Res> implements $ObjectLinkCopyWith<$Res> {
  factory _$ObjectLinkCopyWith(
          _ObjectLink value, $Res Function(_ObjectLink) then) =
      __$ObjectLinkCopyWithImpl<$Res>;
  @override
  $Res call(
      {String dartName,
      String isarName,
      String? targetIsarName,
      String targetCollectionDartName,
      String targetCollectionIsarName,
      bool links,
      bool backlink});
}

/// @nodoc
class __$ObjectLinkCopyWithImpl<$Res> extends _$ObjectLinkCopyWithImpl<$Res>
    implements _$ObjectLinkCopyWith<$Res> {
  __$ObjectLinkCopyWithImpl(
      _ObjectLink _value, $Res Function(_ObjectLink) _then)
      : super(_value, (v) => _then(v as _ObjectLink));

  @override
  _ObjectLink get _value => super._value as _ObjectLink;

  @override
  $Res call({
    Object? dartName = freezed,
    Object? isarName = freezed,
    Object? targetIsarName = freezed,
    Object? targetCollectionDartName = freezed,
    Object? targetCollectionIsarName = freezed,
    Object? links = freezed,
    Object? backlink = freezed,
  }) {
    return _then(_ObjectLink(
      dartName: dartName == freezed
          ? _value.dartName
          : dartName // ignore: cast_nullable_to_non_nullable
              as String,
      isarName: isarName == freezed
          ? _value.isarName
          : isarName // ignore: cast_nullable_to_non_nullable
              as String,
      targetIsarName: targetIsarName == freezed
          ? _value.targetIsarName
          : targetIsarName // ignore: cast_nullable_to_non_nullable
              as String?,
      targetCollectionDartName: targetCollectionDartName == freezed
          ? _value.targetCollectionDartName
          : targetCollectionDartName // ignore: cast_nullable_to_non_nullable
              as String,
      targetCollectionIsarName: targetCollectionIsarName == freezed
          ? _value.targetCollectionIsarName
          : targetCollectionIsarName // ignore: cast_nullable_to_non_nullable
              as String,
      links: links == freezed
          ? _value.links
          : links // ignore: cast_nullable_to_non_nullable
              as bool,
      backlink: backlink == freezed
          ? _value.backlink
          : backlink // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ObjectLink implements _ObjectLink {
  const _$_ObjectLink(
      {required this.dartName,
      required this.isarName,
      required this.targetIsarName,
      required this.targetCollectionDartName,
      required this.targetCollectionIsarName,
      required this.links,
      required this.backlink});

  factory _$_ObjectLink.fromJson(Map<String, dynamic> json) =>
      _$$_ObjectLinkFromJson(json);

  @override
  final String dartName;
  @override
  final String isarName;
  @override
  final String? targetIsarName;
  @override
  final String targetCollectionDartName;
  @override
  final String targetCollectionIsarName;
  @override
  final bool links;
  @override
  final bool backlink;

  @override
  String toString() {
    return 'ObjectLink(dartName: $dartName, isarName: $isarName, targetIsarName: $targetIsarName, targetCollectionDartName: $targetCollectionDartName, targetCollectionIsarName: $targetCollectionIsarName, links: $links, backlink: $backlink)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ObjectLink &&
            const DeepCollectionEquality().equals(other.dartName, dartName) &&
            const DeepCollectionEquality().equals(other.isarName, isarName) &&
            const DeepCollectionEquality()
                .equals(other.targetIsarName, targetIsarName) &&
            const DeepCollectionEquality().equals(
                other.targetCollectionDartName, targetCollectionDartName) &&
            const DeepCollectionEquality().equals(
                other.targetCollectionIsarName, targetCollectionIsarName) &&
            const DeepCollectionEquality().equals(other.links, links) &&
            const DeepCollectionEquality().equals(other.backlink, backlink));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(dartName),
      const DeepCollectionEquality().hash(isarName),
      const DeepCollectionEquality().hash(targetIsarName),
      const DeepCollectionEquality().hash(targetCollectionDartName),
      const DeepCollectionEquality().hash(targetCollectionIsarName),
      const DeepCollectionEquality().hash(links),
      const DeepCollectionEquality().hash(backlink));

  @JsonKey(ignore: true)
  @override
  _$ObjectLinkCopyWith<_ObjectLink> get copyWith =>
      __$ObjectLinkCopyWithImpl<_ObjectLink>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ObjectLinkToJson(this);
  }
}

abstract class _ObjectLink implements ObjectLink {
  const factory _ObjectLink(
      {required String dartName,
      required String isarName,
      required String? targetIsarName,
      required String targetCollectionDartName,
      required String targetCollectionIsarName,
      required bool links,
      required bool backlink}) = _$_ObjectLink;

  factory _ObjectLink.fromJson(Map<String, dynamic> json) =
      _$_ObjectLink.fromJson;

  @override
  String get dartName;
  @override
  String get isarName;
  @override
  String? get targetIsarName;
  @override
  String get targetCollectionDartName;
  @override
  String get targetCollectionIsarName;
  @override
  bool get links;
  @override
  bool get backlink;
  @override
  @JsonKey(ignore: true)
  _$ObjectLinkCopyWith<_ObjectLink> get copyWith =>
      throw _privateConstructorUsedError;
}
