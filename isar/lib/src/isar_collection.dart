part of isar;

abstract class IsarCollection<T extends IsarObjectMixin> {
  Future<T?> get(ObjectId id);

  T? getSync(ObjectId id);

  Future<void> put(T object);

  void putSync(T object);

  Future<void> putAll(List<T> objects);

  void putAllSync(List<T> objects);

  Future<void> delete(ObjectId id);

  void deleteSync(ObjectId id);

  QueryBuilder<T, QNoWhere, QCanFilter, QNoGroups, QCanGroupBy, QCanOffsetLimit,
      QCanSort, QCanExecute> where() {
    return newQueryInternal(this);
  }
}
