part of isar;

/// This schema represents a collection.
class CollectionSchema<OBJ> extends Schema<OBJ> {
  /// @nodoc
  @protected
  const CollectionSchema({
    required super.id,
    required super.name,
    required super.properties,
    required super.estimateSize,
    required super.serialize,
    required super.deserialize,
    required super.deserializeProp,
    required this.idName,
    required this.indexes,
    required this.links,
    required this.embeddedSchemas,
    required this.getId,
    required this.getLinks,
    required this.attach,
    required this.version,
  }) : assert(
          Isar.version == version,
          'Outdated generated code. Please re-run code '
          'generation using the latest generator.',
        );

  /// @nodoc
  @protected
  factory CollectionSchema.fromJson(Map<String, dynamic> json) {
    final collection = Schema<dynamic>.fromJson(json);
    return CollectionSchema(
      id: collection.id,
      name: collection.name,
      properties: collection.properties,
      idName: json['idName'] as String,
      indexes: {
        for (final index in json['indexes'] as List<dynamic>)
          (index as Map<String, dynamic>)['name'] as String:
              IndexSchema.fromJson(index),
      },
      links: {
        for (final link in json['links'] as List<dynamic>)
          (link as Map<String, dynamic>)['name'] as String:
              LinkSchema.fromJson(link),
      },
      embeddedSchemas: {
        for (final schema in json['embeddedSchemas'] as List<dynamic>)
          (schema as Map<String, dynamic>)['name'] as String:
              Schema.fromJson(schema),
      },
      estimateSize: (_, __, ___) => throw UnimplementedError(),
      serialize: (_, __, ___, ____) => throw UnimplementedError(),
      deserialize: (_, __, ___, ____) => throw UnimplementedError(),
      deserializeProp: (_, __, ___, ____) => throw UnimplementedError(),
      getId: (_) => throw UnimplementedError(),
      getLinks: (_) => throw UnimplementedError(),
      attach: (_, __, ___) => throw UnimplementedError(),
      version: Isar.version,
    );
  }

  /// Name of the id property
  final String idName;

  @override
  bool get embedded => false;

  /// A map of name -> index pairs
  final Map<String, IndexSchema> indexes;

  /// A map of name -> link pairs
  final Map<String, LinkSchema> links;

  /// A map of name -> embedded schema pairs
  final Map<String, Schema<dynamic>> embeddedSchemas;

  /// @nodoc
  final GetId<OBJ> getId;

  /// @nodoc
  final GetLinks<OBJ> getLinks;

  /// @nodoc
  final Attach<OBJ> attach;

  /// @nodoc
  final String version;

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
  @pragma('vm:prefer-inline')
  LinkSchema link(String linkName) {
    final link = links[linkName];
    if (link != null) {
      return link;
    } else {
      throw IsarError('Unknown link "$linkName"');
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
      'links': [
        for (final link in links.values) link.toJson(),
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

/// @nodoc
@protected
typedef GetLinks<T> = List<IsarLinkBase<dynamic>> Function(T object);

/// @nodoc
@protected
typedef Attach<T> = void Function(IsarCollection<T> col, Id id, T object);
