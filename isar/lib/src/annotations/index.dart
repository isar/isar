class Index {
  final List<String> composite;

  final bool unique;

  final bool hashValue;

  const Index({
    this.composite = const [],
    this.unique = true,
    this.hashValue,
  });
}
