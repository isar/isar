class Index {
  final List<String> compound;

  final bool unique;

  final bool hashValue;

  const Index({
    this.compound = const [],
    this.unique = false,
    this.hashValue,
  });
}
