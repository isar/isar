part of isar;

/// Use `IsarCollection` instances to find, query, and create new objects of a
/// given type in Isar.
///
/// You can get an instance of `IsarCollection` by calling `isar.get<OBJ>()` or
/// by using the generated `isar.yourCollections` getter.
@pragma('vm:isolate-unsendable')
abstract class IsarCollection<ID, OBJ> {
  /// The corresponding Isar instance.
  Isar get isar;

  /// The schema of this collection.
  IsarSchema get schema;

  /// Fetch the next auto increment id for this collection.
  ///
  /// After an app restart the auto increment counter will be set to the largest
  /// id in the collection. If the collection is empty, the counter will be set
  /// to 1.
  int autoIncrement();

  /// {@template collection_get}
  /// Get a single object by its [id]. Returns `null` if the object does not
  /// exist.
  /// {@endtemplate}
  OBJ? get(ID id) => getAll([id]).firstOrNull;

  /// {@template collection_get_all}
  /// Get a list of objects by their [ids]. Objects in the list are `null`
  /// if they don't exist.
  /// {@endtemplate}
  List<OBJ?> getAll(List<ID> ids);

  /// Insert or update the [object].
  void put(OBJ object) => putAll([object]);

  /// Insert or update a list of [objects].
  void putAll(List<OBJ> objects);

  /// This is a low level method to update objects.
  ///
  /// It is not recommended to use this method directly, instead use the
  /// generated `update()` method.
  @protected
  int updateProperties(List<ID> ids, Map<int, dynamic> changes);

  /// Delete a single object by its [id].
  ///
  /// Returns whether the object has been deleted.
  bool delete(ID id);

  /// Delete a list of objects by their [ids].
  ///
  /// Returns the number of deleted objects.
  int deleteAll(List<ID> ids);

  /// Start building a query using the [QueryBuilder].
  QueryBuilder<OBJ, OBJ, QStart> where();

  /// Returns the total number of objects in this collection.
  ///
  /// This method is extremely fast and independent of the
  /// number of objects in the collection.
  int count();

  /// Calculates the size of the collection in bytes.
  int getSize({bool includeIndexes = false});

  /// Import a list of json objects.
  ///
  /// The json objects must have the same structure as the objects in this
  /// collection. Otherwise an exception will be thrown.
  int importJson(List<Map<String, dynamic>> json) =>
      importJsonString(jsonEncode(json));

  /// Import a list of json objects.
  ///
  /// The json objects must have the same structure as the objects in this
  /// collection. Otherwise an exception will be thrown.
  int importJsonString(String json);

  /// Remove all data in this collection and reset the auto increment value.
  void clear();

  /// Watch the collection for changes.
  ///
  /// If [fireImmediately] is `true`, an event will be fired immediately.
  Stream<void> watchLazy({bool fireImmediately = false});

  /// Watch the object with [id] for changes. If a change occurs, the new object
  /// will be returned in the stream.
  ///
  /// Objects that don't exist (yet) can also be watched. If [fireImmediately]
  /// is `true`, the object will be sent to the consumer immediately.
  Stream<OBJ?> watchObject(ID id, {bool fireImmediately = false});

  /// Watch the object with [id] for changes.
  ///
  /// If [fireImmediately] is `true`, an event will be fired immediately.
  Stream<void> watchObjectLazy(ID id, {bool fireImmediately = false});

  /// Build a query dynamically for example to build a custom query language.
  ///
  /// It is highly discouraged to use this method. Only in very special cases
  /// should it be used. If you open an issue please always mention that you
  /// used this method.
  ///
  /// The type argument [R] needs to be equal to [OBJ] if no [properties] are
  /// specified. Otherwise it should be the type of the property.
  @experimental
  IsarQuery<R> buildQuery<R>({
    Filter? filter,
    List<SortProperty>? sortBy,
    List<DistinctProperty>? distinctBy,
    List<int>? properties,
  });
}

/// Asychronous extensions for [IsarCollection].
extension CollectionAsync<ID, OBJ> on IsarCollection<ID, OBJ> {
  /// {@macro collection_get}
  Future<OBJ?> getAsync(ID id) {
    return isar.readAsync((isar) => isar.collection<ID, OBJ>().get(id));
  }

  /// {@macro collection_get_all}
  Future<List<OBJ?>> getAllAsync(List<ID> ids) {
    return isar.readAsync((isar) => isar.collection<ID, OBJ>().getAll(ids));
  }
}
