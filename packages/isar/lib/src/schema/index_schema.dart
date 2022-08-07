part of isar;

/// This schema represents an index.
class IndexSchema {
  /// @nodoc
  @protected
  const IndexSchema({
    required this.id,
    required this.name,
    required this.unique,
    required this.replace,
    required this.properties,
  });

  /// Internal id of this index.
  final int id;

  /// Name of this index.
  final String name;

  /// Whether duplicates are disallowed in this index.
  final bool unique;

  /// Whether duplocates will be replaced or throw an error.
  final bool replace;

  /// Composite properties.
  final List<IndexPropertySchema> properties;

  /// @nodoc
  Map<String, dynamic> toSchemaJson() {
    return {
      'name': name,
      'unique': unique,
      'replace': replace,
      'properties': [
        for (final property in properties) property.toSchemaJson(),
      ],
    };
  }
}

/// This schema represents a composite index property.
class IndexPropertySchema {
  /// @nodoc
  @protected
  const IndexPropertySchema({
    required this.name,
    required this.type,
    required this.caseSensitive,
  });

  /// Isar name of the property.
  final String name;

  /// Type of index.
  final IndexType type;

  /// Whether String properties should be stored with casing.
  final bool caseSensitive;

  /// @nodoc
  Map<String, dynamic> toSchemaJson() {
    return {
      'name': name,
      'type': _typeName[type],
      'caseSensitive': caseSensitive,
    };
  }

  static const _typeName = {
    IndexType.value: 'Value',
    IndexType.hash: 'Hash',
    IndexType.hashElements: 'HashElements',
  };
}
