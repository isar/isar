import 'dart:async';

abstract class Isar {
  Future<T> txn<T>(bool write, Future<T> Function(Isar isar) callback);

  T txnSync<T>(bool write, T Function(Isar isar) callback);
}
