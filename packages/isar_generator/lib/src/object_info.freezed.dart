// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

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
      List<ObjectProperty> properties = const [],
      List<ObjectIndex> indexes = const [],
      List<ObjectLink> links = const [],
      List<String> imports = const []}) {
    return _ObjectInfo(
      dartName: dartName,
      isarName: isarName,
      properties: properties,
      indexes: indexes,
      links: links,
      imports: imports,
    );
  }

  ObjectInfo fromJson(Map<String, Object> json) {
    return ObjectInfo.fromJson(json);
  }
}

/// @nodoc
const $ObjectInfo = _$ObjectInfoTearOff();

/// @nodoc
mixin _$ObjectInfo {
  String get dartName => throw _privateConstructorUsedError;
  String get isarName => throw _privateConstructorUsedError;
  List<ObjectProperty> get properties => throw _privateConstructorUsedError;
  List<ObjectIndex> get indexes => throw _privateConstructorUsedError;
  List<ObjectLink> get links => throw _privateConstructorUsedError;
  List<String> get imports => throw _privateConstructorUsedError;

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
      List<ObjectProperty> properties,
      List<ObjectIndex> indexes,
      List<ObjectLink> links,
      List<String> imports});
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
    Object? properties = freezed,
    Object? indexes = freezed,
    Object? links = freezed,
    Object? imports = freezed,
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
      imports: imports == freezed
          ? _value.imports
          : imports // ignore: cast_nullable_to_non_nullable
              as List<String>,
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
      List<String> imports});
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
    Object? properties = freezed,
    Object? indexes = freezed,
    Object? links = freezed,
    Object? imports = freezed,
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
      imports: imports == freezed
          ? _value.imports
          : imports // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectInfo implements _ObjectInfo {
  const _$_ObjectInfo(
      {required this.dartName,
      required this.isarName,
      this.properties = const [],
      this.indexes = const [],
      this.links = const [],
      this.imports = const []});

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
  final List<String> imports;

  @override
  String toString() {
    return 'ObjectInfo(dartName: $dartName, isarName: $isarName, properties: $properties, indexes: $indexes, links: $links, imports: $imports)';
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
            (identical(other.imports, imports) ||
                const DeepCollectionEquality().equals(other.imports, imports)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(dartName) ^
      const DeepCollectionEquality().hash(isarName) ^
      const DeepCollectionEquality().hash(properties) ^
      const DeepCollectionEquality().hash(indexes) ^
      const DeepCollectionEquality().hash(links) ^
      const DeepCollectionEquality().hash(imports);

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
      {required String dartName,
      required String isarName,
      List<ObjectProperty> properties,
      List<ObjectIndex> indexes,
      List<ObjectLink> links,
      List<String> imports}) = _$_ObjectInfo;

  factory _ObjectInfo.fromJson(Map<String, dynamic> json) =
      _$_ObjectInfo.fromJson;

  @override
  String get dartName => throw _privateConstructorUsedError;
  @override
  String get isarName => throw _privateConstructorUsedError;
  @override
  List<ObjectProperty> get properties => throw _privateConstructorUsedError;
  @override
  List<ObjectIndex> get indexes => throw _privateConstructorUsedError;
  @override
  List<ObjectLink> get links => throw _privateConstructorUsedError;
  @override
  List<String> get imports => throw _privateConstructorUsedError;
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
      required bool elementNullable}) {
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

  ObjectProperty fromJson(Map<String, Object> json) {
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
    Object? dartName = freezed,
    Object? isarName = freezed,
    Object? dartType = freezed,
    Object? isarType = freezed,
    Object? isId = freezed,
    Object? converter = freezed,
    Object? nullable = freezed,
    Object? elementNullable = freezed,
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
    Object? dartName = freezed,
    Object? isarName = freezed,
    Object? dartType = freezed,
    Object? isarType = freezed,
    Object? isId = freezed,
    Object? converter = freezed,
    Object? nullable = freezed,
    Object? elementNullable = freezed,
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
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectProperty implements _ObjectProperty {
  const _$_ObjectProperty(
      {required this.dartName,
      required this.isarName,
      required this.dartType,
      required this.isarType,
      required this.isId,
      this.converter,
      required this.nullable,
      required this.elementNullable});

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
  final String? converter;
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
      {required String dartName,
      required String isarName,
      required String dartType,
      required IsarType isarType,
      required bool isId,
      String? converter,
      required bool nullable,
      required bool elementNullable}) = _$_ObjectProperty;

  factory _ObjectProperty.fromJson(Map<String, dynamic> json) =
      _$_ObjectProperty.fromJson;

  @override
  String get dartName => throw _privateConstructorUsedError;
  @override
  String get isarName => throw _privateConstructorUsedError;
  @override
  String get dartType => throw _privateConstructorUsedError;
  @override
  IsarType get isarType => throw _privateConstructorUsedError;
  @override
  bool get isId => throw _privateConstructorUsedError;
  @override
  String? get converter => throw _privateConstructorUsedError;
  @override
  bool get nullable => throw _privateConstructorUsedError;
  @override
  bool get elementNullable => throw _privateConstructorUsedError;
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
      required IndexType indexType,
      required bool? caseSensitive}) {
    return _ObjectIndexProperty(
      property: property,
      indexType: indexType,
      caseSensitive: caseSensitive,
    );
  }

  ObjectIndexProperty fromJson(Map<String, Object> json) {
    return ObjectIndexProperty.fromJson(json);
  }
}

/// @nodoc
const $ObjectIndexProperty = _$ObjectIndexPropertyTearOff();

/// @nodoc
mixin _$ObjectIndexProperty {
  ObjectProperty get property => throw _privateConstructorUsedError;
  IndexType get indexType => throw _privateConstructorUsedError;
  bool? get caseSensitive => throw _privateConstructorUsedError;

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
  $Res call(
      {ObjectProperty property, IndexType indexType, bool? caseSensitive});

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
    Object? indexType = freezed,
    Object? caseSensitive = freezed,
  }) {
    return _then(_value.copyWith(
      property: property == freezed
          ? _value.property
          : property // ignore: cast_nullable_to_non_nullable
              as ObjectProperty,
      indexType: indexType == freezed
          ? _value.indexType
          : indexType // ignore: cast_nullable_to_non_nullable
              as IndexType,
      caseSensitive: caseSensitive == freezed
          ? _value.caseSensitive
          : caseSensitive // ignore: cast_nullable_to_non_nullable
              as bool?,
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
  $Res call(
      {ObjectProperty property, IndexType indexType, bool? caseSensitive});

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
    Object? indexType = freezed,
    Object? caseSensitive = freezed,
  }) {
    return _then(_ObjectIndexProperty(
      property: property == freezed
          ? _value.property
          : property // ignore: cast_nullable_to_non_nullable
              as ObjectProperty,
      indexType: indexType == freezed
          ? _value.indexType
          : indexType // ignore: cast_nullable_to_non_nullable
              as IndexType,
      caseSensitive: caseSensitive == freezed
          ? _value.caseSensitive
          : caseSensitive // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectIndexProperty implements _ObjectIndexProperty {
  const _$_ObjectIndexProperty(
      {required this.property,
      required this.indexType,
      required this.caseSensitive});

  factory _$_ObjectIndexProperty.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectIndexPropertyFromJson(json);

  @override
  final ObjectProperty property;
  @override
  final IndexType indexType;
  @override
  final bool? caseSensitive;

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
      {required ObjectProperty property,
      required IndexType indexType,
      required bool? caseSensitive}) = _$_ObjectIndexProperty;

  factory _ObjectIndexProperty.fromJson(Map<String, dynamic> json) =
      _$_ObjectIndexProperty.fromJson;

  @override
  ObjectProperty get property => throw _privateConstructorUsedError;
  @override
  IndexType get indexType => throw _privateConstructorUsedError;
  @override
  bool? get caseSensitive => throw _privateConstructorUsedError;
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
      {required List<ObjectIndexProperty> properties,
      required bool unique,
      required bool replace}) {
    return _ObjectIndex(
      properties: properties,
      unique: unique,
      replace: replace,
    );
  }

  ObjectIndex fromJson(Map<String, Object> json) {
    return ObjectIndex.fromJson(json);
  }
}

/// @nodoc
const $ObjectIndex = _$ObjectIndexTearOff();

/// @nodoc
mixin _$ObjectIndex {
  List<ObjectIndexProperty> get properties =>
      throw _privateConstructorUsedError;
  bool get unique => throw _privateConstructorUsedError;
  bool get replace => throw _privateConstructorUsedError;

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
    Object? properties = freezed,
    Object? unique = freezed,
    Object? replace = freezed,
  }) {
    return _then(_value.copyWith(
      properties: properties == freezed
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<ObjectIndexProperty>,
      unique: unique == freezed
          ? _value.unique
          : unique // ignore: cast_nullable_to_non_nullable
              as bool,
      replace: replace == freezed
          ? _value.replace
          : replace // ignore: cast_nullable_to_non_nullable
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
    Object? properties = freezed,
    Object? unique = freezed,
    Object? replace = freezed,
  }) {
    return _then(_ObjectIndex(
      properties: properties == freezed
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<ObjectIndexProperty>,
      unique: unique == freezed
          ? _value.unique
          : unique // ignore: cast_nullable_to_non_nullable
              as bool,
      replace: replace == freezed
          ? _value.replace
          : replace // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectIndex implements _ObjectIndex {
  const _$_ObjectIndex(
      {required this.properties, required this.unique, required this.replace});

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
      {required List<ObjectIndexProperty> properties,
      required bool unique,
      required bool replace}) = _$_ObjectIndex;

  factory _ObjectIndex.fromJson(Map<String, dynamic> json) =
      _$_ObjectIndex.fromJson;

  @override
  List<ObjectIndexProperty> get properties =>
      throw _privateConstructorUsedError;
  @override
  bool get unique => throw _privateConstructorUsedError;
  @override
  bool get replace => throw _privateConstructorUsedError;
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
      required String? targetDartName,
      required String targetCollectionDartName,
      required bool links,
      required bool backlink,
      int linkIndex = -1}) {
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

  ObjectLink fromJson(Map<String, Object> json) {
    return ObjectLink.fromJson(json);
  }
}

/// @nodoc
const $ObjectLink = _$ObjectLinkTearOff();

/// @nodoc
mixin _$ObjectLink {
  String get dartName => throw _privateConstructorUsedError;
  String get isarName => throw _privateConstructorUsedError;
  String? get targetDartName => throw _privateConstructorUsedError;
  String get targetCollectionDartName => throw _privateConstructorUsedError;
  bool get links => throw _privateConstructorUsedError;
  bool get backlink => throw _privateConstructorUsedError;
  int get linkIndex => throw _privateConstructorUsedError;

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
      String? targetDartName,
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
    Object? dartName = freezed,
    Object? isarName = freezed,
    Object? targetDartName = freezed,
    Object? targetCollectionDartName = freezed,
    Object? links = freezed,
    Object? backlink = freezed,
    Object? linkIndex = freezed,
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
      targetDartName: targetDartName == freezed
          ? _value.targetDartName
          : targetDartName // ignore: cast_nullable_to_non_nullable
              as String?,
      targetCollectionDartName: targetCollectionDartName == freezed
          ? _value.targetCollectionDartName
          : targetCollectionDartName // ignore: cast_nullable_to_non_nullable
              as String,
      links: links == freezed
          ? _value.links
          : links // ignore: cast_nullable_to_non_nullable
              as bool,
      backlink: backlink == freezed
          ? _value.backlink
          : backlink // ignore: cast_nullable_to_non_nullable
              as bool,
      linkIndex: linkIndex == freezed
          ? _value.linkIndex
          : linkIndex // ignore: cast_nullable_to_non_nullable
              as int,
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
      String? targetDartName,
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
    Object? dartName = freezed,
    Object? isarName = freezed,
    Object? targetDartName = freezed,
    Object? targetCollectionDartName = freezed,
    Object? links = freezed,
    Object? backlink = freezed,
    Object? linkIndex = freezed,
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
      targetDartName: targetDartName == freezed
          ? _value.targetDartName
          : targetDartName // ignore: cast_nullable_to_non_nullable
              as String?,
      targetCollectionDartName: targetCollectionDartName == freezed
          ? _value.targetCollectionDartName
          : targetCollectionDartName // ignore: cast_nullable_to_non_nullable
              as String,
      links: links == freezed
          ? _value.links
          : links // ignore: cast_nullable_to_non_nullable
              as bool,
      backlink: backlink == freezed
          ? _value.backlink
          : backlink // ignore: cast_nullable_to_non_nullable
              as bool,
      linkIndex: linkIndex == freezed
          ? _value.linkIndex
          : linkIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_ObjectLink implements _ObjectLink {
  const _$_ObjectLink(
      {required this.dartName,
      required this.isarName,
      required this.targetDartName,
      required this.targetCollectionDartName,
      required this.links,
      required this.backlink,
      this.linkIndex = -1});

  factory _$_ObjectLink.fromJson(Map<String, dynamic> json) =>
      _$_$_ObjectLinkFromJson(json);

  @override
  final String dartName;
  @override
  final String isarName;
  @override
  final String? targetDartName;
  @override
  final String targetCollectionDartName;
  @override
  final bool links;
  @override
  final bool backlink;
  @JsonKey(defaultValue: -1)
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
      {required String dartName,
      required String isarName,
      required String? targetDartName,
      required String targetCollectionDartName,
      required bool links,
      required bool backlink,
      int linkIndex}) = _$_ObjectLink;

  factory _ObjectLink.fromJson(Map<String, dynamic> json) =
      _$_ObjectLink.fromJson;

  @override
  String get dartName => throw _privateConstructorUsedError;
  @override
  String get isarName => throw _privateConstructorUsedError;
  @override
  String? get targetDartName => throw _privateConstructorUsedError;
  @override
  String get targetCollectionDartName => throw _privateConstructorUsedError;
  @override
  bool get links => throw _privateConstructorUsedError;
  @override
  bool get backlink => throw _privateConstructorUsedError;
  @override
  int get linkIndex => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$ObjectLinkCopyWith<_ObjectLink> get copyWith =>
      throw _privateConstructorUsedError;
}
