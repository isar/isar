part of isar;

/// This schema either represents a collection or embedded object.
class Schema<OBJ> {
  /// @nodoc
  @protected
  const Schema({
    required this.id,
    required this.name,
    required this.properties,
    required this.serializeNative,
    required this.estimateSize,
    required this.deserializeNative,
    required this.deserializePropNative,
    required this.serializeWeb,
    required this.deserializeWeb,
    required this.deserializePropWeb,
  });

  /// Internal id of this collection or embedded object.
  final int id;

  /// Name of the collection or embedded object
  final String name;

  /// Whether this is an embedded object
  bool get embedded => true;

  /// A map of name -> property pairs
  final Map<String, PropertySchema> properties;

  /// @nodoc
  @protected
  final EstimateSize<OBJ> estimateSize;

  /// @nodoc
  @protected
  final SerializeNative<OBJ> serializeNative;

  /// @nodoc
  @protected
  final DeserializeNative<OBJ> deserializeNative;

  /// @nodoc
  @protected
  final DeserializePropNative deserializePropNative;

  /// @nodoc
  @protected
  final SerializeWeb<OBJ> serializeWeb;

  /// @nodoc
  @protected
  final DeserializeWeb<OBJ> deserializeWeb;

  /// @nodoc
  @protected
  final DeserializePropWeb deserializePropWeb;

  /// Returns a property by its name or throws an error.
  @pragma('vm:prefer-inline')
  PropertySchema property(String propertyName) {
    final property = properties[propertyName];
    if (property != null) {
      return property;
    } else {
      throw IsarError('Unknown property "$propertyName"');
    }
  }

  /// @nodoc
  @protected
  Map<String, dynamic> toSchemaJson() {
    return {
      'name': name,
      'embedded': embedded,
      'properties': [
        for (final property in properties.values) property.toSchemaJson(),
      ],
    };
  }

  /// @nodoc
  @protected
  Type get type => OBJ;
}

/// @nodoc
@protected
typedef EstimateSize<T> = int Function(
  T object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
);

/// @nodoc
@protected
typedef SerializeNative<T> = int Function(
  T object,
  IsarBinaryWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
);

/// @nodoc
@protected
typedef DeserializeNative<T> = T Function(
  Id id,
  IsarBinaryReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
);

/// @nodoc
@protected
typedef DeserializePropNative = dynamic Function(
  IsarBinaryReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
);

/// @nodoc
@protected
typedef SerializeWeb<T> = Object Function(
  IsarCollection<T> collection,
  T object,
);

/// @nodoc
@protected
typedef DeserializeWeb<T> = T Function(
  IsarCollection<T> collection,
  Object jsObj,
);

/// @nodoc
@protected
typedef DeserializePropWeb = dynamic Function(
  Object jsObj,
  String propertyName,
);
