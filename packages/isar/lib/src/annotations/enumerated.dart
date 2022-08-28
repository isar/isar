part of isar;

/// Annotation to specify how an enum property should be serialized.
const enumerated = Enumerated(EnumType.ordinal);

/// Annotation to specify how an enum property should be serialized.
@Target({TargetKind.field, TargetKind.getter})
class Enumerated {
  /// Annotation to specify how an enum property should be serialized.
  const Enumerated(this.type, [this.property]);

  /// How the enum property should be serialized.
  final EnumType type;

  /// The property to use for the enum values.
  final String? property;
}

/// Enum type for enum values.
enum EnumType {
  /// Stores the position of the enum value. The first enum value is 1. 0 is
  /// used to represent `null`.
  ordinal,

  /// Uses the name of the enum value.
  name,

  /// Uses a custom enum value.
  value
}
