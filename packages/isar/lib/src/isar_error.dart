part of isar;

sealed class IsarError extends Error {
  String get name;

  String get message;

  @override
  String toString() {
    return '$name: $message';
  }
}

class PathError extends IsarError {
  @override
  final name = 'PathError';

  @override
  final message = 'The specified path does not exist or cannot be used by Isar '
      'for example because it is a file.';
}

class WriteTxnRequiredError extends IsarError {
  @override
  String get name => 'WriteTxnRequiredError';

  @override
  String get message => 'This operation requires an active write transaction.';
}

class VersionError extends IsarError {
  @override
  String get name => 'VersionError';

  @override
  String get message => 'The database version is not compatible with this '
      'version of Isar. Please check if you need to migrate the database.';
}

class ObjectLimitReachedError extends IsarError {
  @override
  String get name => 'ObjectLimitReachedError';

  @override
  String get message => 'The maximum size of an object was exceeded. All '
      'objects in Isar including all nested lists and objects must be smaller '
      'than 16MB.';
}

class InstanceMismatchError extends IsarError {
  @override
  String get name => 'InstanceMismatchError';

  @override
  String get message => 'Provided resources do not belong to this Isar '
      'instance. This can happen when you try to use a query or transaction '
      'from a different Isar instance.';
}

class EncryptionError extends IsarError {
  @override
  String get name => 'EncryptionError';

  @override
  String get message => 'Could not encrypt/decrypt the database. Make sure '
      'that the encryption key is correct and that the database is not '
      'corrupted.';
}

class DatabaseFullError extends IsarError {
  @override
  final name = 'DatabaseFullError';

  @override
  final message =
      'The database is full. Pleas increase the maxSizeMiB parameter '
      'when opening Isar. Alternatively you can compact the database by '
      'specifying a CompactCondition when opening Isar.';
}

class IsarNotReadyError extends IsarError {
  /// @nodoc
  @protected
  IsarNotReadyError(this.message);

  @override
  String get name => 'IsarNotReadyError';

  @override
  final String message;
}

class QueryError extends IsarError {
  /// @nodoc
  @protected
  QueryError(this.message);

  @override
  String get name => 'QueryError';

  @override
  final String message;
}

class DatabaseError extends IsarError {
  /// @nodoc
  @protected
  DatabaseError(this.message);

  @override
  String get name => 'IsarError';

  @override
  final String message;
}
