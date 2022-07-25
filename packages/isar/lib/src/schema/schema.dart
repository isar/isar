part of isar;

/// This schema either represents a collection or embedded object.
class Schema<OBJ> {
  /// @nodoc
  @protected
  const Schema({
    required this.name,
    required this.id,
    required this.properties,
    required this.serializeNative,
    required this.estimateSize,
    required this.deserializeNative,
    required this.deserializePropNative,
    required this.serializeWeb,
    required this.deserializeWeb,
    required this.deserializePropWeb,
  });

  /// The hashed name of this schema.
  final int id;

  /// Name of the collection or embedded object
  final String name;

  /// Whether this is an embedded object
  // ignore: avoid_field_initializers_in_const_classes
  final bool embedded = true;

  /// A map of name -> property pairs
  final Map<String, PropertySchema> properties;

  /// @nodoc
  final EstimateSize<OBJ> estimateSize;

  /// @nodoc
  final SerializeNative<OBJ> serializeNative;

  /// @nodoc
  final DeserializeNative<OBJ> deserializeNative;

  /// @nodoc
  final DeserializePropNative deserializePropNative;

  /// @nodoc
  final SerializeWeb<OBJ> serializeWeb;

  /// @nodoc
  final DeserializeWeb<OBJ> deserializeWeb;

  /// @nodoc
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
        for (final property in properties.values)
          if (property.type != IsarType.id) property.toSchemaJson(),
      ],
    };
  }
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
  IsarCollection<T> collection,
  int id,
  IsarBinaryReader reader,
  List<int> offsets,
);

/// @nodoc
@protected
typedef DeserializePropNative = dynamic Function(
  int id,
  IsarBinaryReader reader,
  int propertyIndex,
  int offset,
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
