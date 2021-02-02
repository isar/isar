part of isar_annotation;

enum StringIndexType {
  value,
  hash,
  words,
}

class Index {
  final List<CompositeIndex> composite;

  final bool unique;

  final bool caseSensitive;

  final StringIndexType? stringType;

  const Index({
    this.composite = const [],
    this.unique = false,
    this.caseSensitive = true,
    this.stringType,
  });
}

class CompositeIndex {
  final String property;

  final bool caseSensitive;

  final StringIndexType? stringType;

  const CompositeIndex(
    this.property, {
    this.caseSensitive = false,
    this.stringType,
  });
}
