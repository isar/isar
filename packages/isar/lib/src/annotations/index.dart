part of isar;

/// Annotate properties to build an index.
const index = Index();

/// Annotate properties to build an index.
@Target({TargetKind.field, TargetKind.getter})
class Index {
  /// Annotate properties to build an index.
  const Index({
    this.name,
    this.composite = const [],
    this.unique = false,
    this.hash = true,
  });

  /// Name of the index. By default, the names of the properties are
  /// concatenated using "_"
  final String? name;

  /// Specify up to two other properties to build a composite index.
  final List<String> composite;

  /// A unique index ensures the index does not contain any duplicate values.
  /// If you attempt to insert a value that conflicts with the unique index,
  /// the old object is deleted.
  final bool unique;

  /// Stores the hash of the value(s) in the index. This saves space and
  /// increases performance, but only equality queries are supported. You
  /// should always use this if you only want to guarantee uniqueness.
  ///
  /// SQLite does not support hash indexes so a value index will be used
  /// instead.
  final bool hash;
}
