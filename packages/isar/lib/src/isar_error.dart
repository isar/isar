part of isar;

/// An error raised by Isar.
class IsarError {
  /// The message
  final String message;

  @protected
  IsarError(this.message);

  @override
  String toString() {
    return 'IsarError: $message';
  }
}
