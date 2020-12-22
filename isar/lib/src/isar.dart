import 'dart:async';

abstract class Isar {
  Future<T> txn<T>(Future<T> Function(Isar isar) callback);

  Future<T> writeTxn<T>(Future<T> Function(Isar isar) callback);

  T txnSync<T>(T Function(Isar isar) callback);

  T writeTxnSync<T>(T Function(Isar isar) callback);
}
