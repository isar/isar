part of isar;

abstract class IsarCollection<ID, OBJ> {
  Isar get isar;

  OBJ? get(ID id);

  List<OBJ?> getAll(List<ID> ids);

  void put(OBJ object) => putAll([object]);

  void putAll(List<OBJ> objects);

  bool delete(ID id);

  int deleteAll(List<ID> id);

  QueryBuilder<OBJ, OBJ, QStart> where();

  int count();

  int getSize({bool includeIndexes = false});

  void importJson(List<Map<String, dynamic>> json) {
    importJsonBytes(const Utf8Encoder().convert(jsonEncode(json)));
  }

  void importJsonBytes(Uint8List jsonBytes);

  void importJsonFile(String path);

  void clear();

  @experimental
  IsarQuery<R> buildQuery<R>({
    Filter? filter,
    List<SortProperty>? sortBy,
    List<DistinctProperty>? distinctBy,
    List<int>? properties,
  });
}
