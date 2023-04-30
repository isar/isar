part of isar;

abstract class IsarCollection<OBJ> {
  CollectionSchema<OBJ> get schema;

  Object? get(int id);

  int put(OBJ object);

  bool delete(int id);

  QueryBuilder<OBJ, OBJ, QFilter> where();

  int count();

  void clear();

  Query<R> buildQuery<R>({
    Filter? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? offset,
    int? limit,
    String? property,
  });
}
