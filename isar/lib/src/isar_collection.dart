part of isar;

abstract class IsarCollection<T extends IsarObject> {
  Future<T?> get(ObjectId id);

  T? getSync(ObjectId id);

  Future<void> put(T object);

  void putSync(T object);

  Future<void> putAll(List<T> objects);

  void putAllSync(List<T> objects);

  Future<void> delete(ObjectId id);

  void deleteSync(ObjectId id);

  Future<void> exportJson(bool primitiveNull, Function(Uint8List) callback);

  void exportJsonSync(bool primitiveNull, Function(Uint8List) callback);

  QueryBuilder<T, QNoWhere, QCanFilter, QNoGroups, QCanGroupBy, QCanOffsetLimit,
      QCanSort, QCanExecute> where() {
    return newQueryInternal(this);
  }
}
