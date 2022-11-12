part of isar;

/// Normal keys consist of a single object, composite keys multiple.
typedef IndexKey = List<Object?>;

/// Use `IsarCollection` instances to find, query, and create new objects of a
/// given type in Isar.
///
/// You can get an instance of `IsarCollection` by calling `isar.get<OBJ>()` or
/// by using the generated `isar.yourCollections` getter.
abstract class IsarCollection<OBJ> {
  /// The corresponding Isar instance.
  Isar get isar;

  /// Get the schema of the collection.
  CollectionSchema<OBJ> get schema;

  /// The name of the collection.
  String get name => schema.name;

  /// {@template col_get}
  /// Get a single object by its [id] or `null` if the object does not exist.
  /// {@endtemplate}
  Future<OBJ?> get(Id id) {
    return getAll([id]).then((List<OBJ?> objects) => objects[0]);
  }

  /// {@macro col_get}
  OBJ? getSync(Id id) {
    return getAllSync([id])[0];
  }

  /// {@template col_get_all}
  /// Get a list of objects by their [ids] or `null` if an object does not
  /// exist.
  /// {@endtemplate}
  Future<List<OBJ?>> getAll(List<Id> ids);

  /// {@macro col_get_all}
  List<OBJ?> getAllSync(List<Id> ids);

  /// {@template col_get_by_index}
  /// Get a single object by the unique index [indexName] and [key].
  ///
  /// Returns `null` if the object does not exist.
  ///
  /// If possible, you should use the generated type-safe methods instead.
  /// {@endtemplate}
  @experimental
  Future<OBJ?> getByIndex(String indexName, IndexKey key) {
    return getAllByIndex(indexName, [key])
        .then((List<OBJ?> objects) => objects[0]);
  }

  /// {@macro col_get_by_index}
  @experimental
  OBJ? getByIndexSync(String indexName, IndexKey key) {
    return getAllByIndexSync(indexName, [key])[0];
  }

  /// {@template col_get_all_by_index}
  /// Get a list of objects by the unique index [indexName] and [keys].
  ///
  /// Returns `null` if the object does not exist.
  ///
  /// If possible, you should use the generated type-safe methods instead.
  /// {@endtemplate}
  @experimental
  Future<List<OBJ?>> getAllByIndex(String indexName, List<IndexKey> keys);

  /// {@macro col_get_all_by_index}'
  @experimental
  List<OBJ?> getAllByIndexSync(String indexName, List<IndexKey> keys);

  /// {@template col_put}
  /// Insert or update an [object]. Returns the id of the new or updated object.
  ///
  /// If the object has an non-final id property, it will be set to the assigned
  /// id. Otherwise you should use the returned id to update the object.
  /// {@endtemplate}
  Future<Id> put(OBJ object) {
    return putAll([object]).then((List<Id> ids) => ids[0]);
  }

  /// {@macro col_put}
  Id putSync(OBJ object, {bool saveLinks = true}) {
    return putAllSync([object], saveLinks: saveLinks)[0];
  }

  /// {@template col_put_all}
  /// Insert or update a list of [objects]. Returns the list of ids of the new
  /// or updated objects.
  ///
  /// If the objects have an non-final id property, it will be set to the
  /// assigned id. Otherwise you should use the returned ids to update the
  /// objects.
  /// {@endtemplate}
  Future<List<Id>> putAll(List<OBJ> objects);

  /// {@macro col_put_all}
  List<Id> putAllSync(List<OBJ> objects, {bool saveLinks = true});

  /// {@template col_put_by_index}
  /// Insert or update the [object] by the unique index [indexName]. Returns the
  /// id of the new or updated object.
  ///
  /// If there is already an object with the same index key, it will be
  /// updated and all links will be preserved. Otherwise a new object will be
  /// inserted.
  ///
  /// If the object has an non-final id property, it will be set to the assigned
  /// id. Otherwise you should use the returned id to update the object.
  ///
  /// If possible, you should use the generated type-safe methods instead.
  /// {@endtemplate}
  @experimental
  Future<Id> putByIndex(String indexName, OBJ object) {
    return putAllByIndex(indexName, [object]).then((List<Id> ids) => ids[0]);
  }

  /// {@macro col_put_by_index}
  @experimental
  Id putByIndexSync(String indexName, OBJ object, {bool saveLinks = true}) {
    return putAllByIndexSync(indexName, [object])[0];
  }

  /// {@template col_put_all_by_index}
  /// Insert or update a list of [objects] by the unique index [indexName].
  /// Returns the list of ids of the new or updated objects.
  ///
  /// If there is already an object with the same index key, it will be
  /// updated and all links will be preserved. Otherwise a new object will be
  /// inserted.
  ///
  /// If the objects have an non-final id property, it will be set to the
  /// assigned id. Otherwise you should use the returned ids to update the
  /// objects.
  ///
  /// If possible, you should use the generated type-safe methods instead.
  /// {@endtemplate}
  @experimental
  Future<List<Id>> putAllByIndex(String indexName, List<OBJ> objects);

  /// {@macro col_put_all_by_index}
  @experimental
  List<Id> putAllByIndexSync(
    String indexName,
    List<OBJ> objects, {
    bool saveLinks = true,
  });

  /// {@template col_delete}
  /// Delete a single object by its [id].
  ///
  /// Returns whether the object has been deleted. Isar web always returns
  /// `true`.
  /// {@endtemplate}
  Future<bool> delete(Id id) {
    return deleteAll([id]).then((int count) => count == 1);
  }

  /// {@macro col_delete}
  bool deleteSync(Id id) {
    return deleteAllSync([id]) == 1;
  }

  /// {@template col_delete_all}
  /// Delete a list of objects by their [ids].
  ///
  /// Returns the number of objects that have been deleted. Isar web always
  /// returns `ids.length`.
  /// {@endtemplate}
  Future<int> deleteAll(List<Id> ids);

  /// {@macro col_delete_all}
  int deleteAllSync(List<Id> ids);

  /// {@template col_delete_by_index}
  /// Delete a single object by the unique index [indexName] and [key].
  ///
  /// Returns whether the object has been deleted. Isar web always returns
  /// `true`.
  /// {@endtemplate}
  @experimental
  Future<bool> deleteByIndex(String indexName, IndexKey key) {
    return deleteAllByIndex(indexName, [key]).then((int count) => count == 1);
  }

  /// {@macro col_delete_by_index}
  @experimental
  bool deleteByIndexSync(String indexName, IndexKey key) {
    return deleteAllByIndexSync(indexName, [key]) == 1;
  }

  /// {@template col_delete_all_by_index}
  /// Delete a list of objects by the unique index [indexName] and [keys].
  ///
  /// Returns the number of objects that have been deleted. Isar web always
  /// returns `keys.length`.
  /// {@endtemplate}
  @experimental
  Future<int> deleteAllByIndex(String indexName, List<IndexKey> keys);

  /// {@macro col_delete_all_by_index}
  @experimental
  int deleteAllByIndexSync(String indexName, List<IndexKey> keys);

  /// {@template col_clear}
  /// Remove all data in this collection and reset the auto increment value.
  /// {@endtemplate}
  Future<void> clear();

  /// {@macro col_clear}
  void clearSync();

  /// {@template col_import_json_raw}
  /// Import a list of json objects encoded as a byte array.
  ///
  /// The json objects must have the same structure as the objects in this
  /// collection. Otherwise an exception will be thrown.
  /// {@endtemplate}
  Future<void> importJsonRaw(Uint8List jsonBytes);

  /// {@macro col_import_json_raw}
  void importJsonRawSync(Uint8List jsonBytes);

  /// {@template col_import_json}
  /// Import a list of json objects.
  ///
  /// The json objects must have the same structure as the objects in this
  /// collection. Otherwise an exception will be thrown.
  /// {@endtemplate}
  Future<void> importJson(List<Map<String, dynamic>> json);

  /// {@macro col_import_json}
  void importJsonSync(List<Map<String, dynamic>> json);

  /// Start building a query using the [QueryBuilder].
  ///
  /// You can use where clauses to only return [distinct] results. If you want
  /// to reverse the order, set [sort] to [Sort.desc].
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
  /// Shortcut if you don't want to use where clauses.
  QueryBuilder<OBJ, OBJ, QFilterCondition> filter() => where().filter();

  /// Build a query dynamically for example to build a custom query language.
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

  /// {@template col_count}
  /// Returns the total number of objects in this collection.
  ///
  /// For non-web apps, this method is extremely fast and independent of the
  /// number of objects in the collection.
  /// {@endtemplate}
  Future<int> count();

  /// {@macro col_count}
  int countSync();

  /// {@template col_size}
  /// Returns the size of the collection in bytes. Not supported on web.
  ///
  /// For non-web apps, this method is extremely fast and independent of the
  /// number of objects in the collection.
  /// {@endtemplate}
  Future<int> getSize({bool includeIndexes = false, bool includeLinks = false});

  /// {@macro col_size}
  int getSizeSync({bool includeIndexes = false, bool includeLinks = false});

  /// Watch the collection for changes.
  ///
  /// If [fireImmediately] is `true`, an event will be fired immediately.
  Stream<void> watchLazy({bool fireImmediately = false});

  /// Watch the object with [id] for changes. If a change occurs, the new object
  /// will be returned in the stream.
  ///
  /// Objects that don't exist (yet) can also be watched. If [fireImmediately]
  /// is `true`, the object will be sent to the consumer immediately.
  Stream<OBJ?> watchObject(Id id, {bool fireImmediately = false});

  /// Watch the object with [id] for changes.
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
