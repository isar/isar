import 'dart:async';

import 'package:isar/internal.dart';
import 'package:isar/src/isar_object.dart';
import 'package:isar/src/object_id.dart';
import 'package:isar/src/query.dart';

abstract class IsarCollection<T extends IsarObject> {
  Future<T> get(ObjectId id);

  T getSync(ObjectId id);

  Future<void> put(T object);

  void putSync(T object);

  Future<void> putAll(List<T> objects);

  void putAllSync(List<T> objects);

  Future<void> delete(T object);

  void deleteSync(T object);

  Query<T, IsarCollection<T>, QNoWhere, QCanFilter, dynamic, QCanSort,
      QCanExecute> where() {
    return Query();
  }
}
