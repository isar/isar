part of isar;

abstract class IsarCollection<ID, OBJECT> {
  Future<OBJECT?> get(ID id);

  OBJECT? getSync(ID id);

  Future<void> put(OBJECT object);

  void putSync(OBJECT object);

  Future<void> putAll(List<OBJECT> objects);

  void putAllSync(List<OBJECT> objects);

  Future<bool> delete(ID id);

  bool deleteSync(ID id);

  Future<void> importJson(Uint8List jsonBytes);

  Future<R> exportJson<R>(bool primitiveNull, R Function(Uint8List) callback);

  QueryBuilder<OBJECT, QNoWhere, QCanFilter, QCanGroupBy, QCanOffsetLimit,
      QCanSort, QCanExecute> where() {
    return newQueryInternal(this);
  }

  Stream<void> watchChanges();
}
