part of '../../isar.dart';

/// {@template isar_embedded}
/// Annotation to nest objects of this type in collections.
/// {@endtemplate}
const embedded = Embedded();

/// {@macro isar_embedded}
@Target({TargetKind.classType})
class Embedded {
  /// {@macro isar_embedded}
  const Embedded({this.inheritance = true, this.ignore = const {}});

  /// Should properties and accessors of parent classes and mixins be included?
  final bool inheritance;

  /// A list of properties or getter names that Isar should ignore.
  final Set<String> ignore;
}
