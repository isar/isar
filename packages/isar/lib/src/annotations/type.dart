// ignore_for_file: camel_case_types

part of isar;

/// Type to mark an [int] property or List as 8-bit sized.
///
/// You may only store values between 0 and 255 in such a property.
typedef byte = int;

/// Type to mark an [int] property or List as 32-bit sized.
///
/// You may only store values between -2147483648 and 2147483647 in such a
/// property.
typedef short = int;

/// Type to mark a [double] property or List to have 32-bit precision.
typedef float = double;
