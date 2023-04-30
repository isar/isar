part of isar;

/// This schema represents a collection.
class CollectionSchema<OBJ> extends Schema<OBJ> {
  /// @nodoc
  @protected
  const CollectionSchema({
    required super.name,
    required super.properties,
    required super.serialize,
    required super.deserialize,
    required super.deserializeProp,
    required this.idName,
    required this.indexes,
    required this.embeddedSchemas,
    required this.getId,
  });

  /// @nodoc
  @protected
  factory CollectionSchema.fromJson(Map<String, dynamic> json) {
    final collection = Schema<dynamic>.fromJson(json);
    return CollectionSchema(
      name: collection.name,
      properties: collection.properties,
      idName: json['idName'] as String,
      indexes: {
        for (final index in json['indexes'] as List<dynamic>)
          (index as Map<String, dynamic>)['name'] as String:
              IndexSchema.fromJson(index),
      },
      embeddedSchemas: {
        for (final schema in json['embeddedSchemas'] as List<dynamic>)
          (schema as Map<String, dynamic>)['name'] as String:
              Schema.fromJson(schema),
      },
      serialize: (_, __, ___, ____) => throw UnimplementedError(),
      deserialize: (_, __, ___, ____) => throw UnimplementedError(),
      deserializeProp: (_, __, ___, ____) => throw UnimplementedError(),
      getId: (_) => throw UnimplementedError(),
    );
  }

  /// Name of the id property
  final String idName;

  @override
  bool get embedded => false;

  /// A map of name -> index pairs
  final Map<String, IndexSchema> indexes;

  /// A map of name -> embedded schema pairs
  final Map<String, Schema<dynamic>> embeddedSchemas;

  /// @nodoc
  final GetId<OBJ> getId;

  /// @nodoc
  void toCollection(void Function<OBJ>() callback) => callback<OBJ>();

  /// @nodoc
  @pragma('vm:prefer-inline')
  IndexSchema index(String indexName) {
    final index = indexes[indexName];
    if (index != null) {
      return index;
    } else {
      throw IsarError('Unknown index "$indexName"');
    }
  }

  /// @nodoc
  @protected
  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'idName': idName,
      'indexes': [
        for (final index in indexes.values) index.toJson(),
      ],
    };

    assert(() {
      json['embeddedSchemas'] = [
        for (final schema in embeddedSchemas.values) schema.toJson(),
      ];
      return true;
    }());

    return json;
  }
}

/// @nodoc
@protected
typedef GetId<T> = Id Function(T object);
