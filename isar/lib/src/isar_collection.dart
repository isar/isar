import 'dart:async';

import 'package:isar/internal.dart';
import 'package:isar/src/isar_object.dart';
import 'package:isar/src/query.dart';

abstract class IsarCollection<T extends IsarObject> {
  Future<T> get(int id);

  Future<void> put(T object);

  Future<void> putAll(List<T> objects);

  Future<void> delete(T object);

  Query<T, IsarCollection<T>, QNoWhere, QCanFilter, dynamic, QCanSort,
      QCanExecute> where() {
    return Query();
  }
}
