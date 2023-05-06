part of isar;

/// Annotate the property or accessor in an Isar collection that should be used
/// as the primary key.
const id = Id();

/// Annotate the property or accessor in an Isar collection that should be used
/// as the primary key.
@Target({TargetKind.field, TargetKind.getter})
class Id {
  /// Annotate the property or accessor in an Isar collection that should be used
  /// as the primary key.
  const Id();
}
