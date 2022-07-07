part of isar;

/// Annotate an [int] property to mark it as 8-bit sized.
///
/// You may only store values between 0 and 255 in such a property. This type is
/// very useful for enum [TypeConverter]s.
const byte = _Byte();

/// Annotate a [int] property to mark it as 32-bit sized.
///
/// You may only store values between -2147483648 and 2147483647 in such a
/// property.
const short = _Short();

/// Annotate a [double] property to mark it as 32-bit precision.
const float = _Float();

// @nodoc
class _Byte {
  // @nodoc
  const _Byte();
}

// @nodoc
class _Short {
  // @nodoc
  const _Short();
}

// @nodoc
class _Float {
  // @nodoc
  const _Float();
}
