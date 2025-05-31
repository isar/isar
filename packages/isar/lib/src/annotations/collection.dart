part of '../../isar.dart';

/// {@template isar_collection}
/// Annotation to create an Isar collection.
/// {@endtemplate}
const collection = Collection();

/// {@macro isar_collection}
@Target({TargetKind.classType})
class Collection {
  /// {@macro isar_collection}
  const Collection({
    this.inheritance = true,
    this.accessor,
    this.ignore = const {'copyWith'},
  });

  /// Should properties and accessors of parent classes and mixins be included?
  final bool inheritance;

  /// Allows you to override the default collection accessor.
  ///
  /// Example:
  /// ```dart
  /// @Collection(accessor: 'col')
  /// class MyCol {
  ///   late int id;
  /// }
  ///
  /// // access collection:
  /// isar.col.where().findAll();
  /// ```
  final String? accessor;

  /// A list of properties or getter names that Isar should ignore.
  final Set<String> ignore;
}
