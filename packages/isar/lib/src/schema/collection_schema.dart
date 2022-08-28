part of isar;

/// This schema represents a collection.
class CollectionSchema<OBJ> extends Schema<OBJ> {
  /// @nodoc
  @protected
  const CollectionSchema({
    required super.id,
    required super.name,
    required super.properties,
    required super.serializeNative,
    required super.estimateSize,
    required super.deserializeNative,
    required super.deserializePropNative,
    required super.serializeWeb,
    required super.deserializeWeb,
    required super.deserializePropWeb,
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

  /// Whether this collection has links
  bool get hasLinks => links.isNotEmpty;

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
  Map<String, dynamic> toSchemaJson() {
    return {
      ...super.toSchemaJson(),
      'indexes': [
        for (final index in indexes.values) index.toSchemaJson(),
      ],
      'links': [
        for (final link in links.values) link.toSchemaJson(),
      ],
    };
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
