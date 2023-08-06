part of isar;

extension on int {
  @tryInline
  void checkNoError() {
    if (this != 0) {
      throwError();
    }
  }

  Never throwError() {
    switch (this) {
      case ERROR_PATH:
        throw PathError();
      case ERROR_WRITE_TXN_REQUIRED:
        throw WriteTxnRequiredError();
      case ERROR_VERSION:
        throw VersionError();
      case ERROR_OBJECT_LIMIT_REACHED:
        throw ObjectLimitReachedError();
      case ERROR_INSTANCE_MISMATCH:
        throw InstanceMismatchError();
      case ERROR_ENCRYPTION:
        throw EncryptionError();
      case ERROR_DB_FULL:
        throw DatabaseFullError();
      default:
        final length = IsarCore.b.isar_get_error(IsarCore.stringPtrPtr);
        final ptr = IsarCore.stringPtr;
        if (length != 0 && !ptr.isNull) {
          final error = utf8.decode(ptr.asU8List(length));
          throw DatabaseError(error);
        } else {
          throw DatabaseError(
            'There was an error but it could not be loaded from IsarCore.',
          );
        }
    }
  }
}
