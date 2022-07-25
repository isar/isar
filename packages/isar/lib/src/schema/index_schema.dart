part of isar;

class IndexSchema {
  /// @nodoc
  @protected
  IndexSchema({
    required this.name,
    required this.id,
    required this.unique,
    required this.replace,
    required this.properties,
  });

  final String name;
  final int id;
  final bool unique;
  final bool replace;
  final List<IndexProperySchema> properties;

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

class IndexProperySchema {
  /// @nodoc
  @protected
  IndexProperySchema({
    required this.name,
    required this.type,
    required this.caseSensitive,
  });

  final String name;
  final IndexType type;
  final bool caseSensitive;

  /// @nodoc
  Map<String, dynamic> toSchemaJson() {
    return {
      'name': name,
      'type': type.name,
      'caseSensitive': caseSensitive,
    };
  }
}
