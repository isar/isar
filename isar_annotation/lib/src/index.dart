part of isar_annotation;

enum IndexType {
  value,
  hash,
  words,
}

class Index {
  final List<CompositeIndex> composite;

  final bool unique;

  final IndexType? indexType;

  final bool? caseSensitive;

  const Index({
    this.composite = const [],
    this.unique = false,
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
