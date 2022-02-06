import 'dart:convert';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/web/query_build.dart';

import 'bindings.dart';
import 'isar_impl.dart';

class IsarCollectionImpl<OBJ> extends IsarCollection<OBJ> {
  @override
  final IsarImpl isar;
  final IsarCollectionJs col;

  final IsarWebTypeAdapter<OBJ> adapter;
  final Map<String, bool> isCompositeIndex;
  final void Function(OBJ, int)? setId;

  IsarCollectionImpl({
    required this.isar,
    required this.col,
    required this.adapter,
    required this.isCompositeIndex,
    required this.setId,
  });

  @override
  Future<OBJ?> get(int id) {
    return isar.getTxn(false, (txn) async {
      final object = await col.get(txn, id).wait();
      return object != null ? adapter.deserialize(this, object) : null;
    });
  }

  @override
  Future<List<OBJ?>> getAll(List<int> ids) {
    return isar.getTxn(false, (txn) async {
      final objects = await col.getAll(txn, ids).wait();
      return (objects as List)
          .map((e) => e != null ? adapter.deserialize(this, e) : null)
          .toList();
    });
  }

  @override
  Future<OBJ?> getByIndex(String indexName, List key) {
    return isar.getTxn(false, (txn) async {
      final object = await col.getByIndex(txn, indexName, key).wait();
      return object != null ? adapter.deserialize(this, object) : null;
    });
  }

  @override
  Future<List<OBJ?>> getAllByIndex(String indexName, List<List> keys) {
    return isar.getTxn(false, (txn) async {
      final objects = await col.getAllByIndex(txn, indexName, keys).wait();
      return (objects as List)
          .map((e) => e != null ? adapter.deserialize(this, e) : null)
          .toList();
    });
  }

  @override
  OBJ? getSync(int id) => throw UnimplementedError();

  @override
  List<OBJ?> getAllSync(List<int> ids) => throw UnimplementedError();

  @override
  OBJ? getByIndexSync(String indexName, List key) => throw UnimplementedError();

  @override
  List<OBJ?> getAllByIndexSync(String indexName, List<List> keys) =>
      throw UnimplementedError();

  @override
  Future<int> put(
    OBJ object, {
    bool replaceOnConflict = false,
  }) {
    return isar.getTxn(true, (txn) async {
      final serialized = adapter.serialize(this, object);
      final id = await col.put(txn, serialized, replaceOnConflict).wait();
      setId?.call(object, id);
      return id;
    });
  }

  @override
  Future<List<int>> putAll(
    List<OBJ> objects, {
    bool replaceOnConflict = false,
  }) {
    return isar.getTxn(true, (txn) async {
      final serialized =
          objects.map((e) => adapter.serialize(this, e)).toList();
      final ids = await col.putAll(txn, serialized, replaceOnConflict).wait();
      if (setId != null) {
        for (var i = 0; i < objects.length; i++) {
          setId?.call(objects[i], ids[i]);
        }
      }
      return ids.cast<int>().toList();
    });
  }

  @override
  int putSync(
    OBJ object, {
    bool replaceOnConflict = false,
  }) =>
      throw UnimplementedError();

  @override
  List<int> putAllSync(
    List<OBJ> objects, {
    bool replaceOnConflict = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> delete(int id) {
    return isar.getTxn(true, (txn) {
      return col.delete(txn, id).wait();
    });
  }

  @override
  Future<int> deleteAll(List<int> ids) {
    return isar.getTxn(true, (txn) {
      return col.deleteAll(txn, ids).wait();
    });
  }

  @override
  Future<bool> deleteByIndex(String indexName, List key) {
    return isar.getTxn(true, (txn) {
      return col.deleteByIndex(txn, key).wait();
    });
  }

  @override
  Future<int> deleteAllByIndex(String indexName, List<List> keys) {
    return isar.getTxn(true, (txn) {
      return col.deleteAllByIndex(txn, keys).wait();
    });
  }

  @override
  int deleteAllSync(List<int> ids) => throw UnimplementedError();

  @override
  bool deleteByIndexSync(String indexName, List<dynamic> key) =>
      throw UnimplementedError();

  @override
  int deleteAllByIndexSync(String indexName, List<List> keys) =>
      throw UnimplementedError();

  @override
  Future<void> clear() {
    return isar.getTxn(true, (txn) {
      return col.clear(txn).wait();
    });
  }

  @override
  void clearSync() => throw UnimplementedError();

  @override
  Future<void> importJson(List<Map<String, dynamic>> json,
      {bool replaceOnConflict = false}) {
    return isar.getTxn(true, (txn) async {
      await col.putAll(txn, json, replaceOnConflict).wait();
    });
  }

  @override
  Future<void> importJsonRaw(Uint8List jsonBytes,
      {bool replaceOnConflict = false}) {
    final json = jsonDecode(Utf8Decoder().convert(jsonBytes));
    return importJson(json, replaceOnConflict: replaceOnConflict);
  }

  @override
  void importJsonSync(List<Map<String, dynamic>> json,
      {bool replaceOnConflict = false}) {
    throw UnimplementedError();
  }

  @override
  void importJsonRawSync(Uint8List jsonBytes,
      {bool replaceOnConflict = false}) {
    throw UnimplementedError();
  }

  @override
  Stream<void> watchLazy() => throw UnimplementedError();

  @override
  Stream<OBJ?> watchObject(int id, {bool initialReturn = false}) {
    return watchObjectLazy(id, initialReturn: initialReturn)
        .asyncMap((event) => get(id));
  }

  @override
  Stream<void> watchObjectLazy(int id, {bool initialReturn = false}) =>
      throw UnimplementedError();

  @override
  Query<T> buildQuery<T>({
    List<WhereClause> whereClauses = const [],
    bool whereDistinct = false,
    Sort whereSort = Sort.asc,
    FilterOperation? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? offset,
    int? limit,
    String? property,
  }) {
    return buildWebQuery(
      this,
      whereClauses,
      whereDistinct,
      whereSort,
      filter,
      sortBy,
      distinctBy,
      offset,
      limit,
      property,
    );
  }
}
