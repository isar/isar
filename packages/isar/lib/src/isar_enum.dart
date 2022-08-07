part of isar;

/// Use this mixin on any enum to allow storing it in an Isar collection or
/// embedded object.
///
/// [T] must be a scalar Isar type.
mixin IsarEnum<T> on Enum {
  /// Value that should be stored in the database for this enum variant.
  T get isarValue;
}
