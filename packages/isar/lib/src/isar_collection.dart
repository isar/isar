part of isar;

abstract class IsarCollection<OBJ> {
  /// The corresponding Isar instance.
  Isar get isar;

  /// Get a single object by its [id] or `null` if the object does not exist.
  Future<OBJ?> get(int id) => getAll([id]).then((objects) => objects[0]);

  /// Get a single object by [its] id or `null` if the object does not exist.
  OBJ? getSync(int id) => getAllSync([id])[0];

  /// Get a list of objects by their [ids] or `null` if an object does not
  /// exist.
  Future<List<OBJ?>> getAll(List<int> ids);

  /// Get a list of objects by their [ids] or `null` if an object does not
  /// exist.
  List<OBJ?> getAllSync(List<int> ids);

  /// Get a list of objects by the [indexName] index or `null` if an object
  /// does not exist. Don't use this method directly.
  @protected
  Future<List<OBJ?>> getAllByIndex(
      String indexName, List<List<dynamic>> values);

  /// Get a list of objects by the [indexName] index or `null` if an object
  /// does not exist. Don't use this method directly.
  @protected
  List<OBJ?> getAllByIndexSync(String indexName, List<List<dynamic>> values);

  /// Insert or update an [object] and returns the assigned id.
  Future<int> put(OBJ object) => putAll([object]).then((ids) => ids[0]);

  /// Insert or update an [object] and returns the assigned id.
  int putSync(OBJ object) => putAllSync([object])[0];

  /// Insert or update a list of [objects] and returns the list of assigned ids.
  Future<List<int>> putAll(List<OBJ> objects);

  /// Insert or update a list of [objects] and returns the list of assigned ids.
  List<int> putAllSync(List<OBJ> objects);

  /// Delete a single object by its [id]. Returns whether the object has been
  /// deleted.
  Future<bool> delete(int id) => deleteAll([id]).then((count) => count == 1);

  /// Delete a single object by its [id]. Returns whether the object has been
  /// deleted.
  bool deleteSync(int id) => deleteAllSync([id]) == 1;

  /// Delete a list of objecs by their [ids]. Returns the number of objects that
  /// have been deleted.
  Future<int> deleteAll(List<int> ids);

  /// Delete a list of objecs by their [ids]. Returns the number of objects that
  /// have been deleted.
  int deleteAllSync(List<int> ids);

  /// Delete a list of objecs by the [indexName] index. Returns the number
  /// of objects that have been deleted. Don't use this method directly.
  @protected
  Future<int> deleteAllByIndex(String indexName, List<List<dynamic>> values);

  /// Delete a list of objecs by the [indexName] index. Returns the number
  /// of objects that have been deleted. Don't use this method directly.
  @protected
  int deleteAllByIndexSync(String indexName, List<List<dynamic>> values);

  /// Import a list of json objects.
  Future<void> importJsonRaw(Uint8List jsonBytes);

  /// Import a list of json objects.
  Future<void> importJson(List<Map<String, dynamic>> json) {
    final bytes = Utf8Encoder().convert(jsonEncode(json));
    return importJsonRaw(bytes);
  }

  /// Start building a query using the [QueryBuilder].
  QueryBuilder<OBJ, OBJ, QWhere> where(
      {bool distinct = false, Sort sort = Sort.asc}) {
    return QueryBuilder(this, distinct, sort);
  }

  /// Build a query dynamically. Can be used to build a custom query language.
  Query<R> buildQuery<R>({
    List<WhereClause> whereClauses = const [],
    bool whereDistinct = false,
    Sort whereSort = Sort.asc,
    FilterGroup? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? offset,
    int? limit,
    String? property,
  });

  /// Watch the collection for changes.
  Stream<void> watchLazy();

  /// Watch an object with [id] for changes.
  ///
  /// Objects that don't exist (yet) can also be called. If [initialReturn]
  /// is `true`, the object will be sent to the consumer immediately.
  Stream<OBJ?> watchObject(int id, {bool initialReturn = false});

  /// Watch an object with [id] for changes.
  Stream<void> watchObjectLazy(int id);
}
