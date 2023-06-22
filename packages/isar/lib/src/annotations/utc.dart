part of isar;

/// By default Isar returns [DateTime] values in the local timezone. If you want
/// to receive UTC [DateTime] values instead, annotate the property or accessor
/// with `@utc`.
const utc = Utc();

/// @nodoc
@Target({TargetKind.field, TargetKind.getter})
class Utc {
  /// @nodoc
  const Utc();
}
