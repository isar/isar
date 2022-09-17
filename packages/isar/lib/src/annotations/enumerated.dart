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
  /// Stores the index of the enum as a byte value.
  ordinal,

  /// Stores the index of the enum as a 4-byte value. Use this type if your enum
  /// has more than 256 values or needs to be nullable.
  ordinal32,

  /// Uses the name of the enum value.
  name,

  /// Uses a custom enum value.
  value
}
