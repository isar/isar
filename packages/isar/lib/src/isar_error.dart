part of isar;

/// An error raised by Isar.
class IsarError {

  @protected
  IsarError(this.message);
  /// The message
  final String message;

  @override
  String toString() {
    return 'IsarError: $message';
  }
}

class IsarUniqueViolationError extends IsarError {
  IsarUniqueViolationError() : super('Unique index violated');
}
