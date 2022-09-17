part of isar;

/// Normal keys consist of a single object, composite keys multiple.
typedef IndexKey = List<Object?>;

/// Collections are used to store and retrieve your objects from Isar.
abstract class IsarCollection<OBJ> {
  /// The corresponding Isar instance.
  Isar get isar;

  /// Get the schema of the collection.
  CollectionSchema<OBJ> get schema;

  /// The name of the collection.
  String get name => schema.name;

  /// Get a single object by its [id] or `null` if the object does not exist.
  Future<OBJ?> get(Id id) {
    return getAll([id]).then((List<OBJ?> objects) => objects[0]);
  }

  /// Get a single object by its [id] or `null` if the object does not exist.
  OBJ? getSync(Id id) {
    return getAllSync([id])[0];
  }

  /// Get a list of objects by their [ids] or `null` if an object does not
  /// exist.
  Future<List<OBJ?>> getAll(List<Id> ids);

  /// Get a list of objects by their [ids] or `null` if an object does not
  /// exist.
  List<OBJ?> getAllSync(List<Id> ids);

  /// @nodoc
  @protected
  Future<OBJ?> getByIndex(String indexName, IndexKey key) {
    return getAllByIndex(indexName, [key])
        .then((List<OBJ?> objects) => objects[0]);
  }

  /// @nodoc
  @protected
  OBJ? getByIndexSync(String indexName, IndexKey key) {
    return getAllByIndexSync(indexName, [key])[0];
  }

  /// @nodoc
  @protected
  Future<List<OBJ?>> getAllByIndex(String indexName, List<IndexKey> keys);

  /// @nodoc
  @protected
  List<OBJ?> getAllByIndexSync(String indexName, List<IndexKey> keys);

  /// Insert or update an [object] and returns the assigned id.
  Future<Id> put(OBJ object) {
    return putAll([object]).then((List<Id> ids) => ids[0]);
  }

  /// Insert or update an [object] and returns the assigned id.
  Id putSync(OBJ object, {bool saveLinks = true}) {
    return putAllSync([object], saveLinks: saveLinks)[0];
  }

  /// Insert or update a list of [objects] and returns the list of assigned ids.
  Future<List<Id>> putAll(List<OBJ> objects);

  /// Insert or update a list of [objects] and returns the list of assigned ids.
  List<Id> putAllSync(List<OBJ> objects, {bool saveLinks = true});

  /// @nodoc
  @protected
  Future<Id> putByIndex(String indexName, OBJ object) {
    return putAllByIndex(indexName, [object]).then((List<Id> ids) => ids[0]);
  }

  /// @nodoc
  @protected
  Id putByIndexSync(String indexName, OBJ object, {bool saveLinks = true}) {
    return putAllByIndexSync(indexName, [object])[0];
  }

  /// @nodoc
  @protected
  Future<List<Id>> putAllByIndex(String indexName, List<OBJ> objects);

  /// @nodoc
  @protected
  List<Id> putAllByIndexSync(
    String indexName,
    List<OBJ> objects, {
    bool saveLinks = true,
  });

  /// Delete a single object by its [id].
  ///
  /// Returns whether the object has been deleted. Isar web always returns
  /// `true`.
  Future<bool> delete(Id id) {
    return deleteAll([id]).then((int count) => count == 1);
  }

  /// Delete a single object by its [id].
  ///
  /// Returns whether the object has been deleted.
  bool deleteSync(Id id) {
    return deleteAllSync([id]) == 1;
  }

  /// Delete a list of objects by their [ids].
  ///
  /// Returns the number of objects that have been deleted. Isar web always
  /// returns `ids.length`.
  Future<int> deleteAll(List<Id> ids);

  /// Delete a list of objects by their [ids].
  ///
  /// Returns the number of objects that have been deleted.
  int deleteAllSync(List<Id> ids);

  /// @nodoc
  @protected
  Future<bool> deleteByIndex(String indexName, IndexKey key) {
    return deleteAllByIndex(indexName, [key]).then((int count) => count == 1);
  }

  /// @nodoc
  @protected
  bool deleteByIndexSync(String indexName, IndexKey key) {
    return deleteAllByIndexSync(indexName, [key]) == 1;
  }

  /// @nodoc
  @protected
  Future<int> deleteAllByIndex(String indexName, List<IndexKey> keys);

  /// @nodoc
  @protected
  int deleteAllByIndexSync(String indexName, List<IndexKey> keys);

  /// Remove all data in this collection and reset the auto increment value.
  Future<void> clear();

  /// Remove all data in this collection and reset the auto increment value.
  void clearSync();

  /// Import a list of json objects.
  Future<void> importJsonRaw(Uint8List jsonBytes);

  /// Import a list of json objects.
  void importJsonRawSync(Uint8List jsonBytes);

  /// Import a list of json objects.
  Future<void> importJson(List<Map<String, dynamic>> json);

  /// Import a list of json objects.
  void importJsonSync(List<Map<String, dynamic>> json);

  /// Start building a query using the [QueryBuilder].
  QueryBuilder<OBJ, OBJ, QWhere> where({
    bool distinct = false,
    Sort sort = Sort.asc,
  }) {
    final qb = QueryBuilderInternal(
      collection: this,
      whereDistinct: distinct,
      whereSort: sort,
    );
    return QueryBuilder(qb);
  }

  /// Start building a query using the [QueryBuilder].
  ///
  /// Shortcut if you don't want to use indexes
  QueryBuilder<OBJ, OBJ, QFilterCondition> filter() => where().filter();

  /// Build a query dynamically. Can be used to build a custom query language.
  ///
  /// It is highly discouraged to use this method. Only in very special cases
  /// should it be used. If you open an issue please always mention that you
  /// used this method.
  ///
  /// The type argument [R] needs to be equal to [OBJ] if no [property] is
  /// specified. Otherwise it should be the type of the property.
  @experimental
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

  /// Returns the total number of objects in this collection.
  ///
  /// For non-web apps, this method is extremely fast and independent of the
  /// number of objects in the collection.
  Future<int> count();

  /// Returns the total number of objects in this collection.
  ///
  /// For non-web apps, this method is extremely fast and independent of the
  /// number of objects in the collection.
  int countSync();

  /// Returns the size of the collection in bytes. Not supported on web.
  ///
  /// This method is extremely fast and independent of the number of objects in
  /// the collection.
  Future<int> getSize({bool includeIndexes = false, bool includeLinks = false});

  /// Returns the size of the collection in bytes. Not supported on web.
  ///
  /// This method is extremely fast and independent of the number of objects in
  /// the collection.
  int getSizeSync({bool includeIndexes = false, bool includeLinks = false});

  /// Watch the collection for changes.
  ///
  /// If [fireImmediately] is `true`, an event will be fired immediately.
  Stream<void> watchLazy({bool fireImmediately = false});

  /// Watch an object with [id] for changes.
  ///
  /// Objects that don't exist (yet) can also be watched. If [fireImmediately]
  /// is `true`, the object will be sent to the consumer immediately.
  Stream<OBJ?> watchObject(Id id, {bool fireImmediately = false});

  /// Watch an object with [id] for changes.
  ///
  /// If [fireImmediately] is `true`, an event will be fired immediately.
  Stream<void> watchObjectLazy(Id id, {bool fireImmediately = false});

  /// Verifies the integrity of the collection and its indexes.
  ///
  /// Throws an exception if the collection does not contain exactly the
  /// provided [objects].
  ///
  /// Do not use this method in production apps.
  @visibleForTesting
  @experimental
  Future<void> verify(List<OBJ> objects);

  /// Verifies the integrity of a link.
  ///
  /// Throws an exception if not exactly [sourceIds] as linked to the
  /// [targetIds].
  ///
  /// Do not use this method in production apps.
  @visibleForTesting
  @experimental
  Future<void> verifyLink(
    String linkName,
    List<int> sourceIds,
    List<int> targetIds,
  );
}
