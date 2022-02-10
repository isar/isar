import 'dart:convert';
import 'dart:js_util';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/web/query_build.dart';
import 'package:meta/dart2js.dart';

import 'bindings.dart';
import 'isar_impl.dart';
import 'isar_web.dart';

class IsarCollectionImpl<OBJ> extends IsarCollection<OBJ> {
  @override
  final IsarImpl isar;
  final IsarCollectionJs col;

  final IsarWebTypeAdapter<OBJ> adapter;
  final Set<String> listProperties;
  final Map<String, bool> isCompositeIndex;
  final String idName;
  final int? Function(OBJ) getId;
  final void Function(OBJ, int)? setId;
  final List<IsarLinkBase> Function(OBJ)? getLinks;

  IsarCollectionImpl({
    required this.isar,
    required this.col,
    required this.adapter,
    required this.listProperties,
    required this.isCompositeIndex,
    required this.idName,
    required this.getId,
    required this.setId,
    required this.getLinks,
  });

  @tryInline
  OBJ? deserializeObject(dynamic object) {
    return object != null ? adapter.deserialize(this, object) : null;
  }

  @tryInline
  List<OBJ?> deserializeObjects(dynamic objects) {
    final list = objects as List;
    final results = <OBJ?>[];
    for (var object in list) {
      results.add(deserializeObject(object));
    }
    return results;
  }

  @override
  Future<OBJ?> get(int id) {
    return isar.getTxn(false, (txn) async {
      final object = await col.get(txn, id).wait();
      return deserializeObject(object);
    });
  }

  @override
  Future<List<OBJ?>> getAll(List<int> ids) {
    return isar.getTxn(false, (txn) async {
      final objects = await col.getAll(txn, ids).wait();
      return deserializeObjects(objects);
    });
  }

  @override
  Future<OBJ?> getByIndex(String indexName, List<Object?> key) {
    return isar.getTxn(false, (txn) async {
      final object = await col.getByIndex(txn, indexName, key).wait();
      return deserializeObject(object);
    });
  }

  @override
  Future<List<OBJ?>> getAllByIndex(String indexName, List<List<Object?>> keys) {
    return isar.getTxn(false, (txn) async {
      final objects = await col.getAllByIndex(txn, indexName, keys).wait();
      return deserializeObjects(objects);
    });
  }

  @override
  OBJ? getSync(int id) => unsupportedOnWeb();

  @override
  List<OBJ?> getAllSync(List<int> ids) => unsupportedOnWeb();

  @override
  OBJ? getByIndexSync(String indexName, List<Object?> key) =>
      unsupportedOnWeb();

  @override
  List<OBJ?> getAllByIndexSync(String indexName, List<List<Object?>> keys) =>
      unsupportedOnWeb();

  @override
  Future<int> put(
    OBJ object, {
    bool replaceOnConflict = false,
    bool saveLinks = false,
  }) {
    return isar.getTxn(true, (txn) async {
      final serialized = adapter.serialize(this, object);
      final id = await col.put(txn, serialized, replaceOnConflict).wait();
      setId?.call(object, id);

      final linkFutures = <Future>[];
      if (saveLinks && getLinks != null) {
        for (var link in getLinks!(object)) {
          if (link.isChanged) {
            linkFutures.add(link.save());
          }
        }
      }
      if (linkFutures.isNotEmpty) {
        await Future.wait(linkFutures);
      }
      return id;
    });
  }

  @override
  Future<List<int>> putAll(
    List<OBJ> objects, {
    bool replaceOnConflict = false,
    bool saveLinks = false,
  }) {
    return isar.getTxn(true, (txn) async {
      final serialized = [];
      for (var object in objects) {
        serialized.add(adapter.serialize(this, object));
      }
      final ids = await col.putAll(txn, serialized, replaceOnConflict).wait();
      final linkFutures = <Future>[];
      if (setId != null || (getLinks != null && saveLinks)) {
        for (var i = 0; i < objects.length; i++) {
          final object = objects[i];
          setId?.call(object, ids[i]);
          if (getLinks != null && saveLinks) {
            for (var link in getLinks!(object)) {
              if (link.isChanged) {
                linkFutures.add(link.save());
              }
            }
          }
        }
      }
      if (linkFutures.isNotEmpty) {
        await Future.wait(linkFutures);
      }

      return ids.cast<int>().toList();
    });
  }

  @override
  int putSync(
    OBJ object, {
    bool replaceOnConflict = false,
    bool saveLinks = false,
  }) =>
      unsupportedOnWeb();

  @override
  List<int> putAllSync(
    List<OBJ> objects, {
    bool replaceOnConflict = false,
    bool saveLinks = false,
  }) =>
      unsupportedOnWeb();

  @override
  Future<bool> delete(int id) async {
    await isar.getTxn(true, (txn) {
      return col.delete(txn, id).wait();
    });
    return true;
  }

  @override
  Future<int> deleteAll(List<int> ids) async {
    await isar.getTxn(true, (txn) {
      return col.deleteAll(txn, ids).wait();
    });
    return ids.length;
  }

  @override
  Future<bool> deleteByIndex(String indexName, List<Object?> key) {
    return isar.getTxn(true, (txn) {
      return col.deleteByIndex(txn, indexName, key).wait();
    });
  }

  @override
  Future<int> deleteAllByIndex(String indexName, List<List<Object?>> keys) {
    return isar.getTxn(true, (txn) {
      return col.deleteAllByIndex(txn, indexName, keys).wait();
    });
  }

  @override
  int deleteAllSync(List<int> ids) => unsupportedOnWeb();

  @override
  bool deleteByIndexSync(String indexName, List<Object?> key) =>
      unsupportedOnWeb();

  @override
  int deleteAllByIndexSync(String indexName, List<List<Object?>> keys) =>
      unsupportedOnWeb();

  @override
  Future<void> clear() {
    return isar.getTxn(true, (txn) {
      return col.clear(txn).wait();
    });
  }

  @override
  void clearSync() => unsupportedOnWeb();

  @override
  Future<void> importJson(List<Map<String, dynamic>> json,
      {bool replaceOnConflict = false}) {
    return isar.getTxn(true, (txn) async {
      await col.putAll(txn, json.map(jsify).toList(), replaceOnConflict).wait();
    });
  }

  @override
  Future<void> importJsonRaw(Uint8List jsonBytes,
      {bool replaceOnConflict = false}) {
    final json = jsonDecode(Utf8Decoder().convert(jsonBytes)) as List;
    return importJson(json.cast(), replaceOnConflict: replaceOnConflict);
  }

  @override
  void importJsonSync(List<Map<String, dynamic>> json,
          {bool replaceOnConflict = false}) =>
      unsupportedOnWeb();

  @override
  void importJsonRawSync(Uint8List jsonBytes,
          {bool replaceOnConflict = false}) =>
      unsupportedOnWeb();

  @override
  Stream<void> watchLazy() => unsupportedOnWeb();

  @override
  Stream<OBJ?> watchObject(int id, {bool initialReturn = false}) {
    return watchObjectLazy(id, initialReturn: initialReturn)
        .asyncMap((event) => get(id));
  }

  @override
  Stream<void> watchObjectLazy(int id, {bool initialReturn = false}) =>
      unsupportedOnWeb();

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
