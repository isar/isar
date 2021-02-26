part of isar;

abstract class Isar {
  final String path;

  const Isar(this.path);

  Future<T> txn<T>(Future<T> Function(Isar isar) callback);

  Future<T> writeTxn<T>(Future<T> Function(Isar isar) callback,
      {bool silent = false});

  T txnSync<T>(T Function(Isar isar) callback);

  T writeTxnSync<T>(T Function(Isar isar) callback, {bool silent = false});
}
