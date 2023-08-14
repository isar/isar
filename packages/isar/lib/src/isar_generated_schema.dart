part of isar;

/// @nodoc
@protected
final class IsarGeneratedSchema {
  /// @nodoc
  const IsarGeneratedSchema({
    required this.schema,
    required this.converter,
    this.embeddedSchemas,
  });

  /// @nodoc
  @protected
  final IsarSchema schema;

  /// @nodoc
  @protected
  final List<IsarGeneratedSchema>? embeddedSchemas;

  /// @nodoc
  @protected
  bool get isEmbedded => embeddedSchemas == null;

  /// @nodoc
  @protected
  final IsarObjectConverter<dynamic, dynamic> converter;
}

/// @nodoc
@protected
final class IsarObjectConverter<ID, OBJ> {
  /// @nodoc
  const IsarObjectConverter({
    required this.serialize,
    required this.deserialize,
    this.deserializeProperty,
  });

  /// @nodoc
  final Serialize<OBJ> serialize;

  /// @nodoc
  final Deserialize<OBJ> deserialize;

  /// @nodoc
  final DeserializeProp? deserializeProperty;

  /// @nodoc
  Type get type => OBJ;

  /// @nodoc
  T withType<T>(
    T Function<ID, OBJ>(IsarObjectConverter<ID, OBJ> converter) f,
  ) =>
      f(this);
}

/// @nodoc
typedef GetId<OBJ> = int Function(OBJ);

/// @nodoc
typedef IsarWriter = Pointer<CIsarWriter>;

/// @nodoc
typedef IsarReader = Pointer<CIsarReader>;

/// @nodoc
typedef Serialize<T> = int Function(IsarWriter writer, T object);

/// @nodoc
typedef Deserialize<T> = T Function(IsarReader reader);

/// @nodoc
typedef DeserializeProp = dynamic Function(IsarReader reader, int property);
