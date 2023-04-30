import 'dart:ffi';

import 'package:isar/isar.dart';
import 'package:isar/src/impl/bindings.dart';

class IsarImpl implements Isar {
  const IsarImpl._(this.ptr);

  final Pointer<CIsarInstance> ptr;

  @override
  Future<T> txn<T>(T Function(Isar isar) callback) {
    // TODO: implement txn
    throw UnimplementedError();
  }

  @override
  Future<T> writeTxn<T>(T Function(Isar isar) callback) {
    // TODO: implement writeTxn
    throw UnimplementedError();
  }
}
