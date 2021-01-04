class Collection {
  const Collection();
}

class Ignore {
  const Ignore();
}

class Index {
  final List<String> composite;

  final bool unique;

  final bool hashValue;

  const Index({
    this.composite = const [],
    this.unique = false,
    this.hashValue = false,
  });
}

class Name {
  final String name;

  const Name(this.name);
}

class Size32 {
  const Size32();
}
