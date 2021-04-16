part of isar;

/// There are multiple different type for indexes
enum IndexType {
  /// This is the default type and also the only allowed type for all properties
  /// that don't hold Strings. Property values are used to build the index.
  value,

  /// Strings are hashed to reduce the storage required by the index. The
  /// disadvantage of hash indexes is that they can't be used for prefix scans
  /// (`startsWith()` where clauses).
  hash,

  /// Strings are splitted on Grapheme Clusters or word boundaries, according to
  /// the Unicode Standard Annex #29 rules and stored individually. Can be used
  /// for full-text search.
  words,
}

/// Annotate properties to build an index for the annotated property.
class Index {
  ///
  final List<CompositeIndex> composite;

  /// A unique index ensures the index does not contain any duplicate values.
  /// Any attempt to insert or update data into the unique index that causes a
  /// duplicate will result in an error.
  final bool unique;

  /// Rather than throwing an exception the replace index will replace existing
  /// objects with the same value.
  final bool replace;

  final IndexType? indexType;

  final bool? caseSensitive;

  const Index({
    this.composite = const [],
    this.unique = false,
    this.replace = false,
    this.indexType,
    this.caseSensitive,
  });
}

class CompositeIndex {
  final String property;

  final IndexType? indexType;

  final bool? caseSensitive;

  const CompositeIndex(
    this.property, {
    this.indexType,
    this.caseSensitive,
  });
}
