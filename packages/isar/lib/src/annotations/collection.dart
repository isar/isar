part of isar;

/// Annotation to create an Isar collection.
const collection = Collection();

/// Annotation to create an Isar collection.
@Target({TargetKind.classType})
class Collection {
  /// Annotation to create an Isar collection.
  const Collection({this.inheritance = true, this.accessor});

  /// Should properties and accessors of parent classes and mixins be included?
  final bool inheritance;

  /// Allows you to override the default collection accessor.
  ///
  /// Example:
  /// ```dart
  /// @Collection(accessor: 'col')
  /// class MyCol {
  ///   Id? id;
  /// }
  ///
  /// // access collection using: isar.col
  /// ```
  final String? accessor;
}
