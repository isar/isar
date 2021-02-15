part of isar;

abstract class IsarCollection<ID, OBJECT> {
  Future<OBJECT?> get(ID id) => getAll([id]).then((objects) => objects[0]);

  OBJECT? getSync(ID id) => getAllSync([id])[0];

  Future<List<OBJECT?>> getAll(List<ID> ids);

  List<OBJECT?> getAllSync(List<ID> ids);

  Future<void> put(OBJECT object) => putAll([object]);

  void putSync(OBJECT object) => putAllSync([object]);

  Future<void> putAll(List<OBJECT> objects);

  void putAllSync(List<OBJECT> objects);

  Future<bool> delete(ID id) => deleteAll([id]).then((count) => count == 1);

  bool deleteSync(ID id) => deleteAllSync([id]) == 1;

  Future<int> deleteAll(List<ID> ids);

  int deleteAllSync(List<ID> ids);

  Future<void> importJson(Uint8List jsonBytes);

  Future<R> exportJson<R>(bool primitiveNull, R Function(Uint8List) callback);

  QueryBuilder<OBJECT, QNoWhere, QCanFilter, QCanDistinctBy, QCanOffsetLimit,
      QCanSort, QCanExecute> where() {
    return QueryBuilder(this);
  }

  Stream<OBJECT?> watch({ID? id, bool lazy = true});
}
