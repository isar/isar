part of isar;

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

  final int id;
  final String name;
  final bool unique;
  final bool replace;
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

class IndexPropertySchema {
  /// @nodoc
  @protected
  const IndexPropertySchema({
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
