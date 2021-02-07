part of isar;

abstract class IsarCollection<ID, OBJECT> {
  Future<OBJECT?> get(ID id);

  OBJECT? getSync(ID id);

  Future<List<OBJECT?>> getAll(List<ID> ids);

  List<OBJECT?> getAllSync(List<ID> ids);

  Future<void> put(OBJECT object);

  void putSync(OBJECT object);

  Future<void> putAll(List<OBJECT> objects);

  void putAllSync(List<OBJECT> objects);

  Future<bool> delete(ID id);

  bool deleteSync(ID id);

  Future<int> deleteAll(List<ID> ids);

  int deleteAllSync(List<ID> ids);

  Future<void> importJson(Uint8List jsonBytes);

  Future<R> exportJson<R>(bool primitiveNull, R Function(Uint8List) callback);

  QueryBuilder<OBJECT, QNoWhere, QCanFilter, QCanGroupBy, QCanOffsetLimit,
      QCanSort, QCanExecute> where() {
    return newQueryInternal(this);
  }

  Stream<OBJECT?> watch({ID? id, bool lazy = true});
}
