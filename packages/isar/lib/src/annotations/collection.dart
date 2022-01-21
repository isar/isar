part of isar;

/// Annotation to create an Isar collection.
@Target({TargetKind.classType})
class Collection {
  /// Should properties and accessors of parent classes and mixins be included?
  final bool inheritance;

  /// Allows you to override the default collection accessor.
  ///
  /// Example:
  /// ```dart
  /// @Collection(accessor: 'col')
  /// class MyCol {
  ///   int? id;
  /// }
  ///
  /// // access colection using: isar.col
  /// ```
  final String? accessor;

  /// Annotation to create an Isar collection.
  const Collection({this.inheritance = true, this.accessor});
}
