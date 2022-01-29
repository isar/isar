part of isar;

/// Collections are used to store and receive your objects from Isar.
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

  /// @nodoc
  @protected
  Future<OBJ?> getByIndex(
    String indexName,
    List<dynamic> value,
  ) =>
      getAllByIndex(indexName, [value]).then((objects) => objects[0]);

  /// @nodoc
  @protected
  Future<List<OBJ?>> getAllByIndex(
    String indexName,
    List<List<dynamic>> values,
  );

  /// @nodoc
  @protected
  OBJ? getByIndexSync(String indexName, List<dynamic> value) =>
      getAllByIndexSync(indexName, [value])[0];

  /// @nodoc
  @protected
  List<OBJ?> getAllByIndexSync(String indexName, List<List<dynamic>> values);

  /// Insert or update an [object] and returns the assigned id.
  Future<int> put(OBJ object, {bool replaceOnConflict = false}) {
    return putAll(
      [object],
      replaceOnConflict: replaceOnConflict,
    ).then((ids) => ids[0]);
  }

  /// Insert or update an [object] and returns the assigned id.
  int putSync(OBJ object, {bool replaceOnConflict = false}) {
    return putAllSync(
      [object],
      replaceOnConflict: replaceOnConflict,
    )[0];
  }

  /// Insert or update a list of [objects] and returns the list of assigned ids.
  Future<List<int>> putAll(List<OBJ> objects, {bool replaceOnConflict = false});

  /// Insert or update a list of [objects] and returns the list of assigned ids.
  List<int> putAllSync(List<OBJ> objects, {bool replaceOnConflict = false});

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

  /// @nodoc
  @protected
  Future<bool> deleteByIndex(String indexName, List<dynamic> value) =>
      deleteAllByIndex(indexName, [value]).then((count) => count == 1);

  /// @nodoc
  @protected
  Future<int> deleteAllByIndex(String indexName, List<List<dynamic>> values);

  /// @nodoc
  @protected
  bool deleteByIndexSync(String indexName, List<dynamic> value) =>
      deleteAllByIndexSync(indexName, [value]) == 1;

  /// @nodoc
  @protected
  int deleteAllByIndexSync(String indexName, List<List<dynamic>> values);

  /// Remove all data in this collection and reset the auto increment value.
  Future<void> clear();

  /// Remove all data in this collection and reset the auto increment value.
  void clearSync();

  /// Import a list of json objects.
  Future<void> importJsonRaw(Uint8List jsonBytes,
      {bool replaceOnConflict = false});

  /// Import a list of json objects.
  void importJsonRawSync(Uint8List jsonBytes, {bool replaceOnConflict = false});

  /// Import a list of json objects.
  Future<void> importJson(List<Map<String, dynamic>> json,
      {bool replaceOnConflict = false}) {
    final bytes = Utf8Encoder().convert(jsonEncode(json));
    return importJsonRaw(bytes, replaceOnConflict: replaceOnConflict);
  }

  /// Import a list of json objects.
  void importJsonSync(List<Map<String, dynamic>> json,
      {bool replaceOnConflict = false}) {
    final bytes = Utf8Encoder().convert(jsonEncode(json));
    importJsonRawSync(bytes, replaceOnConflict: replaceOnConflict);
  }

  /// Start building a query using the [QueryBuilder].
  QueryBuilder<OBJ, OBJ, QWhere> where(
      {bool distinct = false, Sort sort = Sort.asc}) {
    return QueryBuilder(this, distinct, sort);
  }

  /// Start building a query using the [QueryBuilder].
  ///
  /// Shortcut if you don't want to use indexes
  QueryBuilder<OBJ, OBJ, QFilterCondition> filter() => where().filter();

  /// Build a query dynamically. Can be used to build a custom query language.
  Query<R> buildQuery<R>({
    List<WhereClause> whereClauses = const [],
    bool whereDistinct = false,
    Sort whereSort = Sort.asc,
    FilterOperation? filter,
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
