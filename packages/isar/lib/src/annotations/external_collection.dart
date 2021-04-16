part of isar;

/// Annotate any class in the root package with `@ExternalCollection()` to
/// register collections from child packages.
class ExternalCollection {
  /// The collection from a child package that should be registered in the root
  /// package.
  final Type collection;

  const ExternalCollection(this.collection);
}
