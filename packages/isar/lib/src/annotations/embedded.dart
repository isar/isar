part of isar;

/// Annotation to nest objects of this type in collections.
const embedded = Embedded();

/// Annotation to nest objects of this type in collections.
@Target({TargetKind.classType})
class Embedded {
  /// Annotation to nest objects of this type in collections.
  const Embedded({this.inheritance = true});

  /// Should properties and accessors of parent classes and mixins be included?
  final bool inheritance;
}
