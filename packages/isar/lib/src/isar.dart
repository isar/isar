part of isar;

abstract class Isar {
  Future<T> txn<T>(T Function(Isar isar) callback);

  Future<T> writeTxn<T>(T Function(Isar isar) callback);
}

abstract class IsarInstance extends Isar {
  void clear();
}
