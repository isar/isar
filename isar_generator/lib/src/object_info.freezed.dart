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
      List<ObjectProperty> properties = const [],
      List<ObjectIndex> indexes = const [],
      List<ObjectLink> links = const [],
      List<String> converterImports = const []}) {
    return _ObjectInfo(
      dartName: dartName,
      isarName: isarName,
      properties: properties,
      indexes: indexes,
      links: links,
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
  List<ObjectProperty> get properties;
  List<ObjectIndex> get indexes;
  List<ObjectLink> get links;
  List<String> get converterImports;

  Map<String, dynamic> toJson();
  @JsonKey(ignore: true)
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
      List<ObjectProperty> properties,
      List<ObjectIndex> indexes,
      List<ObjectLink> links,
      List<String> converterImports});
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
    Object properties = freezed,
    Object indexes = freezed,
    Object links = freezed,
    Object converterImports = freezed,
  }) {
    return _then(_value.copyWith(
      dartName: dartName == freezed ? _value.dartName : dartName as String,
      isarName: isarName == freezed ? _value.isarName : isarName as String,
      properties: properties == freezed
          ? _value.properties
          : properties as List<ObjectProperty>,
      indexes:
          indexes == freezed ? _value.indexes : indexes as List<ObjectIndex>,
      links: links == freezed ? _value.links : links as List<ObjectLink>,
      converterImports: converterImports == freezed
          ? _value.converterImports
          : converterImports as List<String>,
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
      List<ObjectProperty> properties,
      List<ObjectIndex> indexes,
      List<ObjectLink> links,
      List<String> converterImports});
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
    Object properties = freezed,
    Object indexes = freezed,
    Object links = freezed,
    Object converterImports = freezed,
  }) {
    return _then(_ObjectInfo(
      dartName: dartName == freezed ? _value.dartName : dartName as String,
      isarName: isarName == freezed ? _value.isarName : isarName as String,
      properties: properties == freezed
          ? _value.properties
          : properties as List<ObjectProperty>,
      indexes:
          indexes == freezed ? _value.indexes : indexes as List<ObjectIndex>,
      links: links == freezed ? _value.links : links as List<ObjectLink>,
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
      this.properties = const [],
      this.indexes = const [],
      this.links = const [],
      this.converterImports = const []})
      : assert(properties != null),
        assert(indexes != null),
        assert(links != null),
        assert(converterImports != null);

  factory _$_ObjectInfo.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectInfoFromJson(json);

  @override
  final String dartName;
  @override
  final String isarName;
  @JsonKey(defaultValue: const [])
  @override
  final List<ObjectProperty> properties;
  @JsonKey(defaultValue: const [])
  @override
  final List<ObjectIndex> indexes;
  @JsonKey(defaultValue: const [])
  @override
  final List<ObjectLink> links;
  @JsonKey(defaultValue: const [])
  @override
  final List<String> converterImports;

  @override
  String toString() {
    return 'ObjectInfo(dartName: $dartName, isarName: $isarName, properties: $properties, indexes: $indexes, links: $links, converterImports: $converterImports)';
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
            (identical(other.properties, properties) ||
                const DeepCollectionEquality()
                    .equals(other.properties, properties)) &&
            (identical(other.indexes, indexes) ||
                const DeepCollectionEquality()
                    .equals(other.indexes, indexes)) &&
            (identical(other.links, links) ||
                const DeepCollectionEquality().equals(other.links, links)) &&
            (identical(other.converterImports, converterImports) ||
                const DeepCollectionEquality()
                    .equals(other.converterImports, converterImports)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(dartName) ^
      const DeepCollectionEquality().hash(isarName) ^
      const DeepCollectionEquality().hash(properties) ^
      const DeepCollectionEquality().hash(indexes) ^
      const DeepCollectionEquality().hash(links) ^
      const DeepCollectionEquality().hash(converterImports);

  @JsonKey(ignore: true)
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
      List<ObjectProperty> properties,
      List<ObjectIndex> indexes,
      List<ObjectLink> links,
      List<String> converterImports}) = _$_ObjectInfo;

  factory _ObjectInfo.fromJson(Map<String, dynamic> json) =
      _$_ObjectInfo.fromJson;

  @override
  String get dartName;
  @override
  String get isarName;
  @override
  List<ObjectProperty> get properties;
  @override
  List<ObjectIndex> get indexes;
  @override
  List<ObjectLink> get links;
  @override
  List<String> get converterImports;
  @override
  @JsonKey(ignore: true)
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
      bool isId,
      String converter,
      bool nullable,
      bool elementNullable}) {
    return _ObjectProperty(
      dartName: dartName,
      isarName: isarName,
      dartType: dartType,
      isarType: isarType,
      isId: isId,
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
  bool get isId;
  String get converter;
  bool get nullable;
  bool get elementNullable;

  Map<String, dynamic> toJson();
  @JsonKey(ignore: true)
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
      bool isId,
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
    Object isId = freezed,
    Object converter = freezed,
    Object nullable = freezed,
    Object elementNullable = freezed,
  }) {
    return _then(_value.copyWith(
      dartName: dartName == freezed ? _value.dartName : dartName as String,
      isarName: isarName == freezed ? _value.isarName : isarName as String,
      dartType: dartType == freezed ? _value.dartType : dartType as String,
      isarType: isarType == freezed ? _value.isarType : isarType as IsarType,
      isId: isId == freezed ? _value.isId : isId as bool,
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
      bool isId,
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
    Object isId = freezed,
    Object converter = freezed,
    Object nullable = freezed,
    Object elementNullable = freezed,
  }) {
    return _then(_ObjectProperty(
      dartName: dartName == freezed ? _value.dartName : dartName as String,
      isarName: isarName == freezed ? _value.isarName : isarName as String,
      dartType: dartType == freezed ? _value.dartType : dartType as String,
      isarType: isarType == freezed ? _value.isarType : isarType as IsarType,
      isId: isId == freezed ? _value.isId : isId as bool,
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
      this.isId,
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
  final bool isId;
  @override
  final String converter;
  @override
  final bool nullable;
  @override
  final bool elementNullable;

  @override
  String toString() {
    return 'ObjectProperty(dartName: $dartName, isarName: $isarName, dartType: $dartType, isarType: $isarType, isId: $isId, converter: $converter, nullable: $nullable, elementNullable: $elementNullable)';
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
            (identical(other.isId, isId) ||
                const DeepCollectionEquality().equals(other.isId, isId)) &&
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
      const DeepCollectionEquality().hash(isId) ^
      const DeepCollectionEquality().hash(converter) ^
      const DeepCollectionEquality().hash(nullable) ^
      const DeepCollectionEquality().hash(elementNullable);

  @JsonKey(ignore: true)
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
      bool isId,
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
  bool get isId;
  @override
  String get converter;
  @override
  bool get nullable;
  @override
  bool get elementNullable;
  @override
  @JsonKey(ignore: true)
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
      {ObjectProperty property, IndexType indexType, bool caseSensitive}) {
    return _ObjectIndexProperty(
      property: property,
      indexType: indexType,
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
  ObjectProperty get property;
  IndexType get indexType;
  bool get caseSensitive;

  Map<String, dynamic> toJson();
  @JsonKey(ignore: true)
  $ObjectIndexPropertyCopyWith<ObjectIndexProperty> get copyWith;
}

/// @nodoc
abstract class $ObjectIndexPropertyCopyWith<$Res> {
  factory $ObjectIndexPropertyCopyWith(
          ObjectIndexProperty value, $Res Function(ObjectIndexProperty) then) =
      _$ObjectIndexPropertyCopyWithImpl<$Res>;
  $Res call({ObjectProperty property, IndexType indexType, bool caseSensitive});

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
    Object property = freezed,
    Object indexType = freezed,
    Object caseSensitive = freezed,
  }) {
    return _then(_value.copyWith(
      property:
          property == freezed ? _value.property : property as ObjectProperty,
      indexType:
          indexType == freezed ? _value.indexType : indexType as IndexType,
      caseSensitive: caseSensitive == freezed
          ? _value.caseSensitive
          : caseSensitive as bool,
    ));
  }

  @override
  $ObjectPropertyCopyWith<$Res> get property {
    if (_value.property == null) {
      return null;
    }
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
  $Res call({ObjectProperty property, IndexType indexType, bool caseSensitive});

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
    Object property = freezed,
    Object indexType = freezed,
    Object caseSensitive = freezed,
  }) {
    return _then(_ObjectIndexProperty(
      property:
          property == freezed ? _value.property : property as ObjectProperty,
      indexType:
          indexType == freezed ? _value.indexType : indexType as IndexType,
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
      {this.property, this.indexType, this.caseSensitive});

  factory _$_ObjectIndexProperty.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectIndexPropertyFromJson(json);

  @override
  final ObjectProperty property;
  @override
  final IndexType indexType;
  @override
  final bool caseSensitive;

  @override
  String toString() {
    return 'ObjectIndexProperty(property: $property, indexType: $indexType, caseSensitive: $caseSensitive)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ObjectIndexProperty &&
            (identical(other.property, property) ||
                const DeepCollectionEquality()
                    .equals(other.property, property)) &&
            (identical(other.indexType, indexType) ||
                const DeepCollectionEquality()
                    .equals(other.indexType, indexType)) &&
            (identical(other.caseSensitive, caseSensitive) ||
                const DeepCollectionEquality()
                    .equals(other.caseSensitive, caseSensitive)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(property) ^
      const DeepCollectionEquality().hash(indexType) ^
      const DeepCollectionEquality().hash(caseSensitive);

  @JsonKey(ignore: true)
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
      {ObjectProperty property,
      IndexType indexType,
      bool caseSensitive}) = _$_ObjectIndexProperty;

  factory _ObjectIndexProperty.fromJson(Map<String, dynamic> json) =
      _$_ObjectIndexProperty.fromJson;

  @override
  ObjectProperty get property;
  @override
  IndexType get indexType;
  @override
  bool get caseSensitive;
  @override
  @JsonKey(ignore: true)
  _$ObjectIndexPropertyCopyWith<_ObjectIndexProperty> get copyWith;
}

ObjectIndex _$ObjectIndexFromJson(Map<String, dynamic> json) {
  return _ObjectIndex.fromJson(json);
}

/// @nodoc
class _$ObjectIndexTearOff {
  const _$ObjectIndexTearOff();

// ignore: unused_element
  _ObjectIndex call(
      {List<ObjectIndexProperty> properties, bool unique, bool replace}) {
    return _ObjectIndex(
      properties: properties,
      unique: unique,
      replace: replace,
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
  bool get replace;

  Map<String, dynamic> toJson();
  @JsonKey(ignore: true)
  $ObjectIndexCopyWith<ObjectIndex> get copyWith;
}

/// @nodoc
abstract class $ObjectIndexCopyWith<$Res> {
  factory $ObjectIndexCopyWith(
          ObjectIndex value, $Res Function(ObjectIndex) then) =
      _$ObjectIndexCopyWithImpl<$Res>;
  $Res call({List<ObjectIndexProperty> properties, bool unique, bool replace});
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
    Object replace = freezed,
  }) {
    return _then(_value.copyWith(
      properties: properties == freezed
          ? _value.properties
          : properties as List<ObjectIndexProperty>,
      unique: unique == freezed ? _value.unique : unique as bool,
      replace: replace == freezed ? _value.replace : replace as bool,
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
  $Res call({List<ObjectIndexProperty> properties, bool unique, bool replace});
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
    Object replace = freezed,
  }) {
    return _then(_ObjectIndex(
      properties: properties == freezed
          ? _value.properties
          : properties as List<ObjectIndexProperty>,
      unique: unique == freezed ? _value.unique : unique as bool,
      replace: replace == freezed ? _value.replace : replace as bool,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectIndex implements _ObjectIndex {
  const _$_ObjectIndex({this.properties, this.unique, this.replace});

  factory _$_ObjectIndex.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectIndexFromJson(json);

  @override
  final List<ObjectIndexProperty> properties;
  @override
  final bool unique;
  @override
  final bool replace;

  @override
  String toString() {
    return 'ObjectIndex(properties: $properties, unique: $unique, replace: $replace)';
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
            (identical(other.replace, replace) ||
                const DeepCollectionEquality().equals(other.replace, replace)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(properties) ^
      const DeepCollectionEquality().hash(unique) ^
      const DeepCollectionEquality().hash(replace);

  @JsonKey(ignore: true)
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
      {List<ObjectIndexProperty> properties,
      bool unique,
      bool replace}) = _$_ObjectIndex;

  factory _ObjectIndex.fromJson(Map<String, dynamic> json) =
      _$_ObjectIndex.fromJson;

  @override
  List<ObjectIndexProperty> get properties;
  @override
  bool get unique;
  @override
  bool get replace;
  @override
  @JsonKey(ignore: true)
  _$ObjectIndexCopyWith<_ObjectIndex> get copyWith;
}

ObjectLink _$ObjectLinkFromJson(Map<String, dynamic> json) {
  return _ObjectLink.fromJson(json);
}

/// @nodoc
class _$ObjectLinkTearOff {
  const _$ObjectLinkTearOff();

// ignore: unused_element
  _ObjectLink call(
      {String dartName,
      String isarName,
      String targetDartName,
      String targetCollectionDartName,
      bool links,
      bool backlink,
      int linkIndex}) {
    return _ObjectLink(
      dartName: dartName,
      isarName: isarName,
      targetDartName: targetDartName,
      targetCollectionDartName: targetCollectionDartName,
      links: links,
      backlink: backlink,
      linkIndex: linkIndex,
    );
  }

// ignore: unused_element
  ObjectLink fromJson(Map<String, Object> json) {
    return ObjectLink.fromJson(json);
  }
}

/// @nodoc
// ignore: unused_element
const $ObjectLink = _$ObjectLinkTearOff();

/// @nodoc
mixin _$ObjectLink {
  String get dartName;
  String get isarName;
  String get targetDartName;
  String get targetCollectionDartName;
  bool get links;
  bool get backlink;
  int get linkIndex;

  Map<String, dynamic> toJson();
  @JsonKey(ignore: true)
  $ObjectLinkCopyWith<ObjectLink> get copyWith;
}

/// @nodoc
abstract class $ObjectLinkCopyWith<$Res> {
  factory $ObjectLinkCopyWith(
          ObjectLink value, $Res Function(ObjectLink) then) =
      _$ObjectLinkCopyWithImpl<$Res>;
  $Res call(
      {String dartName,
      String isarName,
      String targetDartName,
      String targetCollectionDartName,
      bool links,
      bool backlink,
      int linkIndex});
}

/// @nodoc
class _$ObjectLinkCopyWithImpl<$Res> implements $ObjectLinkCopyWith<$Res> {
  _$ObjectLinkCopyWithImpl(this._value, this._then);

  final ObjectLink _value;
  // ignore: unused_field
  final $Res Function(ObjectLink) _then;

  @override
  $Res call({
    Object dartName = freezed,
    Object isarName = freezed,
    Object targetDartName = freezed,
    Object targetCollectionDartName = freezed,
    Object links = freezed,
    Object backlink = freezed,
    Object linkIndex = freezed,
  }) {
    return _then(_value.copyWith(
      dartName: dartName == freezed ? _value.dartName : dartName as String,
      isarName: isarName == freezed ? _value.isarName : isarName as String,
      targetDartName: targetDartName == freezed
          ? _value.targetDartName
          : targetDartName as String,
      targetCollectionDartName: targetCollectionDartName == freezed
          ? _value.targetCollectionDartName
          : targetCollectionDartName as String,
      links: links == freezed ? _value.links : links as bool,
      backlink: backlink == freezed ? _value.backlink : backlink as bool,
      linkIndex: linkIndex == freezed ? _value.linkIndex : linkIndex as int,
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
      String targetDartName,
      String targetCollectionDartName,
      bool links,
      bool backlink,
      int linkIndex});
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
    Object dartName = freezed,
    Object isarName = freezed,
    Object targetDartName = freezed,
    Object targetCollectionDartName = freezed,
    Object links = freezed,
    Object backlink = freezed,
    Object linkIndex = freezed,
  }) {
    return _then(_ObjectLink(
      dartName: dartName == freezed ? _value.dartName : dartName as String,
      isarName: isarName == freezed ? _value.isarName : isarName as String,
      targetDartName: targetDartName == freezed
          ? _value.targetDartName
          : targetDartName as String,
      targetCollectionDartName: targetCollectionDartName == freezed
          ? _value.targetCollectionDartName
          : targetCollectionDartName as String,
      links: links == freezed ? _value.links : links as bool,
      backlink: backlink == freezed ? _value.backlink : backlink as bool,
      linkIndex: linkIndex == freezed ? _value.linkIndex : linkIndex as int,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectLink implements _ObjectLink {
  const _$_ObjectLink(
      {this.dartName,
      this.isarName,
      this.targetDartName,
      this.targetCollectionDartName,
      this.links,
      this.backlink,
      this.linkIndex});

  factory _$_ObjectLink.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectLinkFromJson(json);

  @override
  final String dartName;
  @override
  final String isarName;
  @override
  final String targetDartName;
  @override
  final String targetCollectionDartName;
  @override
  final bool links;
  @override
  final bool backlink;
  @override
  final int linkIndex;

  @override
  String toString() {
    return 'ObjectLink(dartName: $dartName, isarName: $isarName, targetDartName: $targetDartName, targetCollectionDartName: $targetCollectionDartName, links: $links, backlink: $backlink, linkIndex: $linkIndex)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _ObjectLink &&
            (identical(other.dartName, dartName) ||
                const DeepCollectionEquality()
                    .equals(other.dartName, dartName)) &&
            (identical(other.isarName, isarName) ||
                const DeepCollectionEquality()
                    .equals(other.isarName, isarName)) &&
            (identical(other.targetDartName, targetDartName) ||
                const DeepCollectionEquality()
                    .equals(other.targetDartName, targetDartName)) &&
            (identical(
                    other.targetCollectionDartName, targetCollectionDartName) ||
                const DeepCollectionEquality().equals(
                    other.targetCollectionDartName,
                    targetCollectionDartName)) &&
            (identical(other.links, links) ||
                const DeepCollectionEquality().equals(other.links, links)) &&
            (identical(other.backlink, backlink) ||
                const DeepCollectionEquality()
                    .equals(other.backlink, backlink)) &&
            (identical(other.linkIndex, linkIndex) ||
                const DeepCollectionEquality()
                    .equals(other.linkIndex, linkIndex)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(dartName) ^
      const DeepCollectionEquality().hash(isarName) ^
      const DeepCollectionEquality().hash(targetDartName) ^
      const DeepCollectionEquality().hash(targetCollectionDartName) ^
      const DeepCollectionEquality().hash(links) ^
      const DeepCollectionEquality().hash(backlink) ^
      const DeepCollectionEquality().hash(linkIndex);

  @JsonKey(ignore: true)
  @override
  _$ObjectLinkCopyWith<_ObjectLink> get copyWith =>
      __$ObjectLinkCopyWithImpl<_ObjectLink>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_ObjectLinkToJson(this);
  }
}

abstract class _ObjectLink implements ObjectLink {
  const factory _ObjectLink(
      {String dartName,
      String isarName,
      String targetDartName,
      String targetCollectionDartName,
      bool links,
      bool backlink,
      int linkIndex}) = _$_ObjectLink;

  factory _ObjectLink.fromJson(Map<String, dynamic> json) =
      _$_ObjectLink.fromJson;

  @override
  String get dartName;
  @override
  String get isarName;
  @override
  String get targetDartName;
  @override
  String get targetCollectionDartName;
  @override
  bool get links;
  @override
  bool get backlink;
  @override
  int get linkIndex;
  @override
  @JsonKey(ignore: true)
  _$ObjectLinkCopyWith<_ObjectLink> get copyWith;
}
