part of isar;

/// Annotate the property or accessor in an Isar collection that should be used
/// as the primary key.
const id = Id();

/// @nodoc
@Target({TargetKind.field, TargetKind.getter})
class Id {
  /// @nodoc
  const Id();
}
