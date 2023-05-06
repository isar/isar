part of isar;

/// @nodoc
@protected
final class Schema {
  /// @nodoc
  const Schema({
    required this.schema,
    required this.converter,
  });

  /// @nodoc
  final String schema;

  /// @nodoc
  final ObjectConverter<dynamic, dynamic> converter;
}

/// @nodoc
@protected
final class CollectionSchema extends Schema {
  /// @nodoc
  const CollectionSchema({
    required super.schema,
    required super.converter,
    required this.embeddedSchemas,
    required this.hash,
  });

  /// @nodoc
  final List<Schema> embeddedSchemas;

  /// @nodoc
  final int hash;
}

/// @nodoc
@protected
final class ObjectConverter<ID, OBJ> {
  /// @nodoc
  const ObjectConverter({
    required this.getId,
    required this.serialize,
    required this.deserialize,
    required this.deserializeProp,
  });

  /// @nodoc
  final GetId<OBJ> getId;

  /// @nodoc
  final Serialize<OBJ> serialize;

  /// @nodoc
  final Deserialize<OBJ> deserialize;

  /// @nodoc
  final DeserializeProp deserializeProp;

  /// @nodoc
  Type get type => OBJ;

  /// @nodoc
  T withType<T>(T Function<ID, OBJ>(ObjectConverter<ID, OBJ> converter) f) =>
      f(this);
}

/// @nodoc
typedef GetId<OBJ> = int Function(OBJ);

/// @nodoc
typedef IsarWriter = Pointer<CIsarWriter>;

/// @nodoc
typedef IsarReader = Pointer<CIsarReader>;

/// @nodoc
typedef Serialize<T> = int Function(T object, IsarWriter writer);

/// @nodoc
typedef Deserialize<T> = T Function(IsarReader reader);

/// @nodoc
typedef DeserializeProp = dynamic Function(IsarReader reader, int property);
