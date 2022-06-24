part of isar;

/// An error raised by Isar.
class IsarError extends Error {
  /// @nodoc
  @protected
  IsarError(this.message);

  /// The message
  final String message;

  @override
  String toString() {
    return 'IsarError: $message';
  }
}

/// This error is returned when a unique index constraint is violated.
class IsarUniqueViolationError extends IsarError {
  /// @nodoc
  @protected
  IsarUniqueViolationError() : super('Unique index violated');
}
