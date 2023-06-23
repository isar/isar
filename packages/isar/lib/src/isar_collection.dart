part of isar;

@pragma('vm:isolate-unsendable')
abstract class IsarCollection<ID, OBJ> {
  Isar get isar;

  OBJ? get(ID id);

  List<OBJ?> getAll(List<ID> ids);

  void put(OBJ object) => putAll([object]);

  void putAll(List<OBJ> objects);

  @protected
  int updateProperties(List<ID> ids, Map<int, dynamic> changes);

  bool delete(ID id);

  int deleteAll(List<ID> id);

  QueryBuilder<OBJ, OBJ, QStart> where();

  int count();

  int getSize({bool includeIndexes = false});

  int importJson(List<Map<String, dynamic>> json) =>
      importJsonString(jsonEncode(json));

  int importJsonString(String json);

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

  @experimental
  IsarQuery<R> buildQuery<R>({
    Filter? filter,
    List<SortProperty>? sortBy,
    List<DistinctProperty>? distinctBy,
    List<int>? properties,
  });
}
