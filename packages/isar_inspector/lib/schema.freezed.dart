// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

part of 'schema.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

Collection _$CollectionFromJson(Map<String, dynamic> json) {
  return _Collection.fromJson(json);
}

/// @nodoc
class _$CollectionTearOff {
  const _$CollectionTearOff();

  _Collection call(String name, List<Property> properties, List<Index> indexes,
      List<Link> links) {
    return _Collection(
      name,
      properties,
      indexes,
      links,
    );
  }

  Collection fromJson(Map<String, Object> json) {
    return Collection.fromJson(json);
  }
}

/// @nodoc
const $Collection = _$CollectionTearOff();

/// @nodoc
mixin _$Collection {
  String get name => throw _privateConstructorUsedError;
  List<Property> get properties => throw _privateConstructorUsedError;
  List<Index> get indexes => throw _privateConstructorUsedError;
  List<Link> get links => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CollectionCopyWith<Collection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollectionCopyWith<$Res> {
  factory $CollectionCopyWith(
          Collection value, $Res Function(Collection) then) =
      _$CollectionCopyWithImpl<$Res>;
  $Res call(
      {String name,
      List<Property> properties,
      List<Index> indexes,
      List<Link> links});
}

/// @nodoc
class _$CollectionCopyWithImpl<$Res> implements $CollectionCopyWith<$Res> {
  _$CollectionCopyWithImpl(this._value, this._then);

  final Collection _value;
  // ignore: unused_field
  final $Res Function(Collection) _then;

  @override
  $Res call({
    Object? name = freezed,
    Object? properties = freezed,
    Object? indexes = freezed,
    Object? links = freezed,
  }) {
    return _then(_value.copyWith(
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      properties: properties == freezed
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<Property>,
      indexes: indexes == freezed
          ? _value.indexes
          : indexes // ignore: cast_nullable_to_non_nullable
              as List<Index>,
      links: links == freezed
          ? _value.links
          : links // ignore: cast_nullable_to_non_nullable
              as List<Link>,
    ));
  }
}

/// @nodoc
abstract class _$CollectionCopyWith<$Res> implements $CollectionCopyWith<$Res> {
  factory _$CollectionCopyWith(
          _Collection value, $Res Function(_Collection) then) =
      __$CollectionCopyWithImpl<$Res>;
  @override
  $Res call(
      {String name,
      List<Property> properties,
      List<Index> indexes,
      List<Link> links});
}

/// @nodoc
class __$CollectionCopyWithImpl<$Res> extends _$CollectionCopyWithImpl<$Res>
    implements _$CollectionCopyWith<$Res> {
  __$CollectionCopyWithImpl(
      _Collection _value, $Res Function(_Collection) _then)
      : super(_value, (v) => _then(v as _Collection));

  @override
  _Collection get _value => super._value as _Collection;

  @override
  $Res call({
    Object? name = freezed,
    Object? properties = freezed,
    Object? indexes = freezed,
    Object? links = freezed,
  }) {
    return _then(_Collection(
      name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      properties == freezed
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<Property>,
      indexes == freezed
          ? _value.indexes
          : indexes // ignore: cast_nullable_to_non_nullable
              as List<Index>,
      links == freezed
          ? _value.links
          : links // ignore: cast_nullable_to_non_nullable
              as List<Link>,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_Collection implements _Collection {
  const _$_Collection(this.name, this.properties, this.indexes, this.links);

  factory _$_Collection.fromJson(Map<String, dynamic> json) =>
      _$_$_CollectionFromJson(json);

  @override
  final String name;
  @override
  final List<Property> properties;
  @override
  final List<Index> indexes;
  @override
  final List<Link> links;

  @override
  String toString() {
    return 'Collection(name: $name, properties: $properties, indexes: $indexes, links: $links)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Collection &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.properties, properties) ||
                const DeepCollectionEquality()
                    .equals(other.properties, properties)) &&
            (identical(other.indexes, indexes) ||
                const DeepCollectionEquality()
                    .equals(other.indexes, indexes)) &&
            (identical(other.links, links) ||
                const DeepCollectionEquality().equals(other.links, links)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(properties) ^
      const DeepCollectionEquality().hash(indexes) ^
      const DeepCollectionEquality().hash(links);

  @JsonKey(ignore: true)
  @override
  _$CollectionCopyWith<_Collection> get copyWith =>
      __$CollectionCopyWithImpl<_Collection>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_CollectionToJson(this);
  }
}

abstract class _Collection implements Collection {
  const factory _Collection(String name, List<Property> properties,
      List<Index> indexes, List<Link> links) = _$_Collection;

  factory _Collection.fromJson(Map<String, dynamic> json) =
      _$_Collection.fromJson;

  @override
  String get name => throw _privateConstructorUsedError;
  @override
  List<Property> get properties => throw _privateConstructorUsedError;
  @override
  List<Index> get indexes => throw _privateConstructorUsedError;
  @override
  List<Link> get links => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$CollectionCopyWith<_Collection> get copyWith =>
      throw _privateConstructorUsedError;
}

Property _$PropertyFromJson(Map<String, dynamic> json) {
  return _Property.fromJson(json);
}

/// @nodoc
class _$PropertyTearOff {
  const _$PropertyTearOff();

  _Property call(String name, int type) {
    return _Property(
      name,
      type,
    );
  }

  Property fromJson(Map<String, Object> json) {
    return Property.fromJson(json);
  }
}

/// @nodoc
const $Property = _$PropertyTearOff();

/// @nodoc
mixin _$Property {
  String get name => throw _privateConstructorUsedError;
  int get type => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PropertyCopyWith<Property> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PropertyCopyWith<$Res> {
  factory $PropertyCopyWith(Property value, $Res Function(Property) then) =
      _$PropertyCopyWithImpl<$Res>;
  $Res call({String name, int type});
}

/// @nodoc
class _$PropertyCopyWithImpl<$Res> implements $PropertyCopyWith<$Res> {
  _$PropertyCopyWithImpl(this._value, this._then);

  final Property _value;
  // ignore: unused_field
  final $Res Function(Property) _then;

  @override
  $Res call({
    Object? name = freezed,
    Object? type = freezed,
  }) {
    return _then(_value.copyWith(
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: type == freezed
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
abstract class _$PropertyCopyWith<$Res> implements $PropertyCopyWith<$Res> {
  factory _$PropertyCopyWith(_Property value, $Res Function(_Property) then) =
      __$PropertyCopyWithImpl<$Res>;
  @override
  $Res call({String name, int type});
}

/// @nodoc
class __$PropertyCopyWithImpl<$Res> extends _$PropertyCopyWithImpl<$Res>
    implements _$PropertyCopyWith<$Res> {
  __$PropertyCopyWithImpl(_Property _value, $Res Function(_Property) _then)
      : super(_value, (v) => _then(v as _Property));

  @override
  _Property get _value => super._value as _Property;

  @override
  $Res call({
    Object? name = freezed,
    Object? type = freezed,
  }) {
    return _then(_Property(
      name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type == freezed
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_Property implements _Property {
  const _$_Property(this.name, this.type);

  factory _$_Property.fromJson(Map<String, dynamic> json) =>
      _$_$_PropertyFromJson(json);

  @override
  final String name;
  @override
  final int type;

  @override
  String toString() {
    return 'Property(name: $name, type: $type)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Property &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(type);

  @JsonKey(ignore: true)
  @override
  _$PropertyCopyWith<_Property> get copyWith =>
      __$PropertyCopyWithImpl<_Property>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_PropertyToJson(this);
  }
}

abstract class _Property implements Property {
  const factory _Property(String name, int type) = _$_Property;

  factory _Property.fromJson(Map<String, dynamic> json) = _$_Property.fromJson;

  @override
  String get name => throw _privateConstructorUsedError;
  @override
  int get type => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$PropertyCopyWith<_Property> get copyWith =>
      throw _privateConstructorUsedError;
}

Index _$IndexFromJson(Map<String, dynamic> json) {
  return _Index.fromJson(json);
}

/// @nodoc
class _$IndexTearOff {
  const _$IndexTearOff();

  _Index call(bool unique, bool replace, List<ObjectIndexProperty> properties) {
    return _Index(
      unique,
      replace,
      properties,
    );
  }

  Index fromJson(Map<String, Object> json) {
    return Index.fromJson(json);
  }
}

/// @nodoc
const $Index = _$IndexTearOff();

/// @nodoc
mixin _$Index {
  bool get unique => throw _privateConstructorUsedError;
  bool get replace => throw _privateConstructorUsedError;
  List<ObjectIndexProperty> get properties =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $IndexCopyWith<Index> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IndexCopyWith<$Res> {
  factory $IndexCopyWith(Index value, $Res Function(Index) then) =
      _$IndexCopyWithImpl<$Res>;
  $Res call({bool unique, bool replace, List<ObjectIndexProperty> properties});
}

/// @nodoc
class _$IndexCopyWithImpl<$Res> implements $IndexCopyWith<$Res> {
  _$IndexCopyWithImpl(this._value, this._then);

  final Index _value;
  // ignore: unused_field
  final $Res Function(Index) _then;

  @override
  $Res call({
    Object? unique = freezed,
    Object? replace = freezed,
    Object? properties = freezed,
  }) {
    return _then(_value.copyWith(
      unique: unique == freezed
          ? _value.unique
          : unique // ignore: cast_nullable_to_non_nullable
              as bool,
      replace: replace == freezed
          ? _value.replace
          : replace // ignore: cast_nullable_to_non_nullable
              as bool,
      properties: properties == freezed
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<ObjectIndexProperty>,
    ));
  }
}

/// @nodoc
abstract class _$IndexCopyWith<$Res> implements $IndexCopyWith<$Res> {
  factory _$IndexCopyWith(_Index value, $Res Function(_Index) then) =
      __$IndexCopyWithImpl<$Res>;
  @override
  $Res call({bool unique, bool replace, List<ObjectIndexProperty> properties});
}

/// @nodoc
class __$IndexCopyWithImpl<$Res> extends _$IndexCopyWithImpl<$Res>
    implements _$IndexCopyWith<$Res> {
  __$IndexCopyWithImpl(_Index _value, $Res Function(_Index) _then)
      : super(_value, (v) => _then(v as _Index));

  @override
  _Index get _value => super._value as _Index;

  @override
  $Res call({
    Object? unique = freezed,
    Object? replace = freezed,
    Object? properties = freezed,
  }) {
    return _then(_Index(
      unique == freezed
          ? _value.unique
          : unique // ignore: cast_nullable_to_non_nullable
              as bool,
      replace == freezed
          ? _value.replace
          : replace // ignore: cast_nullable_to_non_nullable
              as bool,
      properties == freezed
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<ObjectIndexProperty>,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_Index implements _Index {
  const _$_Index(this.unique, this.replace, this.properties);

  factory _$_Index.fromJson(Map<String, dynamic> json) =>
      _$_$_IndexFromJson(json);

  @override
  final bool unique;
  @override
  final bool replace;
  @override
  final List<ObjectIndexProperty> properties;

  @override
  String toString() {
    return 'Index(unique: $unique, replace: $replace, properties: $properties)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Index &&
            (identical(other.unique, unique) ||
                const DeepCollectionEquality().equals(other.unique, unique)) &&
            (identical(other.replace, replace) ||
                const DeepCollectionEquality()
                    .equals(other.replace, replace)) &&
            (identical(other.properties, properties) ||
                const DeepCollectionEquality()
                    .equals(other.properties, properties)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(unique) ^
      const DeepCollectionEquality().hash(replace) ^
      const DeepCollectionEquality().hash(properties);

  @JsonKey(ignore: true)
  @override
  _$IndexCopyWith<_Index> get copyWith =>
      __$IndexCopyWithImpl<_Index>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_IndexToJson(this);
  }
}

abstract class _Index implements Index {
  const factory _Index(
          bool unique, bool replace, List<ObjectIndexProperty> properties) =
      _$_Index;

  factory _Index.fromJson(Map<String, dynamic> json) = _$_Index.fromJson;

  @override
  bool get unique => throw _privateConstructorUsedError;
  @override
  bool get replace => throw _privateConstructorUsedError;
  @override
  List<ObjectIndexProperty> get properties =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$IndexCopyWith<_Index> get copyWith => throw _privateConstructorUsedError;
}

ObjectIndexProperty _$IndexPropertyFromJson(Map<String, dynamic> json) {
  return _IndexProperty.fromJson(json);
}

/// @nodoc
class _$IndexPropertyTearOff {
  const _$IndexPropertyTearOff();

  _IndexProperty call(String name, int indexType, bool caseSensitive) {
    return _IndexProperty(
      name,
      indexType,
      caseSensitive,
    );
  }

  ObjectIndexProperty fromJson(Map<String, Object> json) {
    return ObjectIndexProperty.fromJson(json);
  }
}

/// @nodoc
const $ObjectIndexProperty = _$IndexPropertyTearOff();

/// @nodoc
mixin _$ObjectIndexProperty {
  String get name => throw _privateConstructorUsedError;
  int get indexType => throw _privateConstructorUsedError;
  bool get caseSensitive => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $IndexPropertyCopyWith<ObjectIndexProperty> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IndexPropertyCopyWith<$Res> {
  factory $IndexPropertyCopyWith(
          ObjectIndexProperty value, $Res Function(ObjectIndexProperty) then) =
      _$IndexPropertyCopyWithImpl<$Res>;
  $Res call({String name, int indexType, bool caseSensitive});
}

/// @nodoc
class _$IndexPropertyCopyWithImpl<$Res>
    implements $IndexPropertyCopyWith<$Res> {
  _$IndexPropertyCopyWithImpl(this._value, this._then);

  final ObjectIndexProperty _value;
  // ignore: unused_field
  final $Res Function(ObjectIndexProperty) _then;

  @override
  $Res call({
    Object? name = freezed,
    Object? indexType = freezed,
    Object? caseSensitive = freezed,
  }) {
    return _then(_value.copyWith(
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      indexType: indexType == freezed
          ? _value.indexType
          : indexType // ignore: cast_nullable_to_non_nullable
              as int,
      caseSensitive: caseSensitive == freezed
          ? _value.caseSensitive
          : caseSensitive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
abstract class _$IndexPropertyCopyWith<$Res>
    implements $IndexPropertyCopyWith<$Res> {
  factory _$IndexPropertyCopyWith(
          _IndexProperty value, $Res Function(_IndexProperty) then) =
      __$IndexPropertyCopyWithImpl<$Res>;
  @override
  $Res call({String name, int indexType, bool caseSensitive});
}

/// @nodoc
class __$IndexPropertyCopyWithImpl<$Res>
    extends _$IndexPropertyCopyWithImpl<$Res>
    implements _$IndexPropertyCopyWith<$Res> {
  __$IndexPropertyCopyWithImpl(
      _IndexProperty _value, $Res Function(_IndexProperty) _then)
      : super(_value, (v) => _then(v as _IndexProperty));

  @override
  _IndexProperty get _value => super._value as _IndexProperty;

  @override
  $Res call({
    Object? name = freezed,
    Object? indexType = freezed,
    Object? caseSensitive = freezed,
  }) {
    return _then(_IndexProperty(
      name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      indexType == freezed
          ? _value.indexType
          : indexType // ignore: cast_nullable_to_non_nullable
              as int,
      caseSensitive == freezed
          ? _value.caseSensitive
          : caseSensitive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_IndexProperty implements _IndexProperty {
  const _$_IndexProperty(this.name, this.indexType, this.caseSensitive);

  factory _$_IndexProperty.fromJson(Map<String, dynamic> json) =>
      _$_$_IndexPropertyFromJson(json);

  @override
  final String name;
  @override
  final int indexType;
  @override
  final bool caseSensitive;

  @override
  String toString() {
    return 'ObjectIndexProperty(name: $name, indexType: $indexType, caseSensitive: $caseSensitive)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _IndexProperty &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
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
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(indexType) ^
      const DeepCollectionEquality().hash(caseSensitive);

  @JsonKey(ignore: true)
  @override
  _$IndexPropertyCopyWith<_IndexProperty> get copyWith =>
      __$IndexPropertyCopyWithImpl<_IndexProperty>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_IndexPropertyToJson(this);
  }
}

abstract class _IndexProperty implements ObjectIndexProperty {
  const factory _IndexProperty(String name, int indexType, bool caseSensitive) =
      _$_IndexProperty;

  factory _IndexProperty.fromJson(Map<String, dynamic> json) =
      _$_IndexProperty.fromJson;

  @override
  String get name => throw _privateConstructorUsedError;
  @override
  int get indexType => throw _privateConstructorUsedError;
  @override
  bool get caseSensitive => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$IndexPropertyCopyWith<_IndexProperty> get copyWith =>
      throw _privateConstructorUsedError;
}

Link _$LinkFromJson(Map<String, dynamic> json) {
  return _Link.fromJson(json);
}

/// @nodoc
class _$LinkTearOff {
  const _$LinkTearOff();

  _Link call(String name, String collection) {
    return _Link(
      name,
      collection,
    );
  }

  Link fromJson(Map<String, Object> json) {
    return Link.fromJson(json);
  }
}

/// @nodoc
const $Link = _$LinkTearOff();

/// @nodoc
mixin _$Link {
  String get name => throw _privateConstructorUsedError;
  String get collection => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LinkCopyWith<Link> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LinkCopyWith<$Res> {
  factory $LinkCopyWith(Link value, $Res Function(Link) then) =
      _$LinkCopyWithImpl<$Res>;
  $Res call({String name, String collection});
}

/// @nodoc
class _$LinkCopyWithImpl<$Res> implements $LinkCopyWith<$Res> {
  _$LinkCopyWithImpl(this._value, this._then);

  final Link _value;
  // ignore: unused_field
  final $Res Function(Link) _then;

  @override
  $Res call({
    Object? name = freezed,
    Object? collection = freezed,
  }) {
    return _then(_value.copyWith(
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      collection: collection == freezed
          ? _value.collection
          : collection // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
abstract class _$LinkCopyWith<$Res> implements $LinkCopyWith<$Res> {
  factory _$LinkCopyWith(_Link value, $Res Function(_Link) then) =
      __$LinkCopyWithImpl<$Res>;
  @override
  $Res call({String name, String collection});
}

/// @nodoc
class __$LinkCopyWithImpl<$Res> extends _$LinkCopyWithImpl<$Res>
    implements _$LinkCopyWith<$Res> {
  __$LinkCopyWithImpl(_Link _value, $Res Function(_Link) _then)
      : super(_value, (v) => _then(v as _Link));

  @override
  _Link get _value => super._value as _Link;

  @override
  $Res call({
    Object? name = freezed,
    Object? collection = freezed,
  }) {
    return _then(_Link(
      name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      collection == freezed
          ? _value.collection
          : collection // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_Link implements _Link {
  const _$_Link(this.name, this.collection);

  factory _$_Link.fromJson(Map<String, dynamic> json) =>
      _$_$_LinkFromJson(json);

  @override
  final String name;
  @override
  final String collection;

  @override
  String toString() {
    return 'Link(name: $name, collection: $collection)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Link &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.collection, collection) ||
                const DeepCollectionEquality()
                    .equals(other.collection, collection)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(collection);

  @JsonKey(ignore: true)
  @override
  _$LinkCopyWith<_Link> get copyWith =>
      __$LinkCopyWithImpl<_Link>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_LinkToJson(this);
  }
}

abstract class _Link implements Link {
  const factory _Link(String name, String collection) = _$_Link;

  factory _Link.fromJson(Map<String, dynamic> json) = _$_Link.fromJson;

  @override
  String get name => throw _privateConstructorUsedError;
  @override
  String get collection => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$LinkCopyWith<_Link> get copyWith => throw _privateConstructorUsedError;
}
