part of isar;

class IsarError extends Error {
  final String message;

  IsarError(this.message);

  @override
  String toString() {
    return 'IsarError: $message';
  }
}
