import 'package:isar/internal.dart';

class Query<T extends IsarObject, BANK extends IsarBank<T>, WHERE, FILTER,
    SORT> {
  IsarBank _bank;

  Future<T> findFirst() {}

  Future<List<T>> findAll() {}

  Future<int> count() {}
}
