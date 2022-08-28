part of isar;

/// Annotate Isar collections or properties to change their name.
///
/// Can be used to change the name in Dart independently of Isar.
@Target({TargetKind.classType, TargetKind.field, TargetKind.getter})
class Name {
  /// Annotate Isar collections or properties to change their name.
  const Name(this.name);

  /// The name this entity should have in the database.
  final String name;
}
