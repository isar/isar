part of isar;

/// Superclass of all Isar errors.
sealed class IsarError extends Error {
  /// Name of the error.
  String get name;

  /// Error message.
  String get message;

  @override
  String toString() {
    return '$name: $message';
  }
}

/// Invalid or protected path error.
class PathError extends IsarError {
  @override
  final name = 'PathError';

  @override
  final message = 'The specified path does not exist or cannot be used by Isar '
      'for example because it is a file.';
}

/// An active write transaction is required for this operation.
class WriteTxnRequiredError extends IsarError {
  @override
  String get name => 'WriteTxnRequiredError';

  @override
  String get message => 'This operation requires an active write transaction.';
}

/// Database file is incompatible with this version of Isar.
class VersionError extends IsarError {
  @override
  String get name => 'VersionError';

  @override
  String get message => 'The database version is not compatible with this '
      'version of Isar. Please check if you need to migrate the database.';
}

/// The object is too large to be stored in Isar.
class ObjectLimitReachedError extends IsarError {
  @override
  String get name => 'ObjectLimitReachedError';

  @override
  String get message => 'The maximum size of an object was exceeded. All '
      'objects in Isar including all nested lists and objects must be smaller '
      'than 16MB.';
}

/// Invalid Isar instance.
class InstanceMismatchError extends IsarError {
  @override
  String get name => 'InstanceMismatchError';

  @override
  String get message => 'Provided resources do not belong to this Isar '
      'instance. This can happen when you try to use a query or transaction '
      'from a different Isar instance.';
}

/// Something went wrong during encryption/decryption. Most likely the
/// encryption key is wrong.
class EncryptionError extends IsarError {
  @override
  String get name => 'EncryptionError';

  @override
  String get message => 'Could not encrypt/decrypt the database. Make sure '
      'that the encryption key is correct and that the database is not '
      'corrupted.';
}

/// The database is full.
class DatabaseFullError extends IsarError {
  @override
  final name = 'DatabaseFullError';

  @override
  final message =
      'The database is full. Pleas increase the maxSizeMiB parameter '
      'when opening Isar. Alternatively you can compact the database by '
      'specifying a CompactCondition when opening Isar.';
}

/// Isar has not been initialized correctly.
class IsarNotReadyError extends IsarError {
  /// @nodoc
  @protected
  IsarNotReadyError(this.message);

  @override
  String get name => 'IsarNotReadyError';

  @override
  final String message;
}

/// Unknown error returned by the database engine.
class DatabaseError extends IsarError {
  /// @nodoc
  @protected
  DatabaseError(this.message);

  @override
  String get name => 'IsarError';

  @override
  final String message;
}
