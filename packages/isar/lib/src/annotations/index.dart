part of isar;

enum IndexType {
  // Store the value directly in the index
  value,

  /// Strings or Lists can be hashed to reduce the storage required by the
  /// index. The disadvantage of hash indexes is that they can't be used for
  /// prefix scans (`startsWith()` where clauses). String and list indexes are
  /// hashed by default.
  hash,

  // `List<String>` can hash its elements.
  hashElements,
}

/// Annotate properties to build an index for the annotated property.
class Index {
  /// Name of the index. By default, the names of the properties are
  /// concatenated using "_"
  final String? name;

  ///
  final List<CompositeIndex> composite;

  /// A unique index ensures the index does not contain any duplicate values.
  /// Any attempt to insert or update data into the unique index that causes a
  /// duplicate will result in an error.
  final bool unique;

  final IndexType? type;

  // String or `List<String>` indexes can be case sensitive (default) or case
  // insensitive.
  final bool? caseSensitive;

  const Index({
    this.name,
    this.composite = const [],
    this.unique = false,
    this.type,
    this.caseSensitive,
  });
}

class CompositeIndex {
  final String property;

  final IndexType? type;

  final bool? caseSensitive;

  const CompositeIndex(
    this.property, {
    this.type,
    this.caseSensitive,
  });
}
