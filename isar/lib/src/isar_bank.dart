import 'dart:async';

import 'package:isar/internal.dart';
import 'package:isar/src/isar_object.dart';

abstract class IsarBank<T extends IsarObject> {
  Future<T> get(int id);

  Future<void> put(T object);

  Future<void> putAll(List<T> objects);

  Future<void> delete(T object);

  QueryBuilder<T, IsarBank<T>, NoWhere, CanFilter, CanSort, CanExecute>
      where() {
    return QueryBuilder();
  }
}
