part of isar;

/// Collections are used to store and receive your objects from Isar.
abstract class IsarCollection<OBJ> {
  /// The corresponding Isar instance.
  Isar get isar;

  /// The name of the collection.
  String get name;

  /// Get a single object by its [id] or `null` if the object does not exist.
  Future<OBJ?> get(int id);

  /// Get a single object by [its] id or `null` if the object does not exist.
  OBJ? getSync(int id);

  /// Get a list of objects by their [ids] or `null` if an object does not
  /// exist.
  Future<List<OBJ?>> getAll(List<int> ids);

  /// Get a list of objects by their [ids] or `null` if an object does not
  /// exist.
  List<OBJ?> getAllSync(List<int> ids);

  /// @nodoc
  @protected
  Future<OBJ?> getByIndex(String indexName, List<Object?> key);

  /// @nodoc
  @protected
  Future<List<OBJ?>> getAllByIndex(String indexName, List<List<Object?>> keys);

  /// @nodoc
  @protected
  OBJ? getByIndexSync(String indexName, List<Object?> key);

  /// @nodoc
  @protected
  List<OBJ?> getAllByIndexSync(String indexName, List<List<Object?>> keys);

  /// Insert or update an [object] and returns the assigned id.
  Future<int> put(
    OBJ object, {
    bool replaceOnConflict = false,
    bool saveLinks = false,
  });

  /// Insert or update an [object] and returns the assigned id.
  int putSync(
    OBJ object, {
    bool replaceOnConflict = false,
    bool saveLinks = false,
  });

  /// Insert or update a list of [objects] and returns the list of assigned ids.
  Future<List<int>> putAll(
    List<OBJ> objects, {
    bool replaceOnConflict = false,
    bool saveLinks = false,
  });

  /// Insert or update a list of [objects] and returns the list of assigned ids.
  List<int> putAllSync(
    List<OBJ> objects, {
    bool replaceOnConflict = false,
    bool saveLinks = false,
  });

  /// Delete a single object by its [id].
  ///
  /// Returns whether the object has been deleted. Isar web always returns
  /// `true`.
  Future<bool> delete(int id) => deleteAll([id]).then((count) => count == 1);

  /// Delete a single object by its [id].
  ///
  /// Returns whether the object has been deleted.
  bool deleteSync(int id) => deleteAllSync([id]) == 1;

  /// Delete a list of objecs by their [ids].
  ///
  /// Returns the number of objects that have been deleted. Isar web always
  /// returns `ids.length`.
  Future<int> deleteAll(List<int> ids);

  /// Delete a list of objecs by their [ids].
  ///
  /// Returns the number of objects that have been deleted.
  int deleteAllSync(List<int> ids);

  /// @nodoc
  @protected
  Future<bool> deleteByIndex(String indexName, List<Object?> key);

  /// @nodoc
  @protected
  Future<int> deleteAllByIndex(String indexName, List<List<Object?>> keys);

  /// @nodoc
  @protected
  bool deleteByIndexSync(String indexName, List<Object?> key);

  /// @nodoc
  @protected
  int deleteAllByIndexSync(String indexName, List<List<Object?>> keys);

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
      {bool replaceOnConflict = false});

  /// Import a list of json objects.
  void importJsonSync(List<Map<String, dynamic>> json,
      {bool replaceOnConflict = false});

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

  /// Returns the total number of objects in this collection
  Future<int> count() => where().count();

  /// Returns the total number of objects in this collection
  int countSync() => where().countSync();

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
