part of isar;

abstract class IsarCollection<ID, OBJ> {
  OBJ? get(ID id);

  List<OBJ> getAll(List<ID> ids);

  void put(OBJ object);

  void putAll(List<OBJ> objects);

  bool delete(ID id);

  int deleteAll(List<ID> id);

  QueryBuilder<OBJ, OBJ, QFilter> where();

  int count();

  void clear();

  Query<R> buildQuery<R>({
    Filter? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? property,
  });
}
