part of isar;

/// Annotate a property or accessor in an Isar collection to ignore it.
const ignore = Ignore();

/// @nodoc
@Target({TargetKind.field, TargetKind.getter})
class Ignore {
  /// @nodoc
  const Ignore();
}
