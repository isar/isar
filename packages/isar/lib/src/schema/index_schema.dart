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

  /// @nodoc
  @protected
  factory IndexSchema.fromJson(Map<String, dynamic> json) {
    return IndexSchema(
      id: -1,
      name: json['name'] as String,
      unique: json['unique'] as bool,
      replace: json['replace'] as bool,
      properties: (json['properties'] as List<dynamic>)
          .map((e) => IndexPropertySchema.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

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
  @protected
  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'unique': unique,
      'replace': replace,
      'properties': [
        for (final property in properties) property.toJson(),
      ],
    };

    return json;
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

  /// @nodoc
  @protected
  factory IndexPropertySchema.fromJson(Map<String, dynamic> json) {
    return IndexPropertySchema(
      name: json['name'] as String,
      type: IndexType.values.firstWhere((e) => _typeName[e] == json['type']),
      caseSensitive: json['caseSensitive'] as bool,
    );
  }

  /// Isar name of the property.
  final String name;

  /// Type of index.
  final IndexType type;

  /// Whether String properties should be stored with casing.
  final bool caseSensitive;

  /// @nodoc
  @protected
  Map<String, dynamic> toJson() {
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
