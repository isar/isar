import 'dart:async';
import 'dart:convert';
import 'dart:js';
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
  final IsarCollectionJs native;

  final CollectionSchema<OBJ> schema;

  IsarCollectionImpl({
    required this.isar,
    required this.native,
    required this.schema,
  });

  @override
  String get name => schema.name;

  @tryInline
  OBJ? deserializeObject(Object? object) {
    return object != null ? schema.deserializeWeb(this, object) : null;
  }

  @tryInline
  List<OBJ?> deserializeObjects(List<Object?> objects) {
    final results = <OBJ?>[];
    for (var object in objects) {
      results.add(deserializeObject(object));
    }
    return results;
  }

  @override
  Future<List<OBJ?>> getAll(List<int> ids) {
    return isar.getTxn(false, (txn) async {
      final objects = await native.getAll(txn, ids).wait<List<Object?>>();
      return deserializeObjects(objects);
    });
  }

  @override
  Future<List<OBJ?>> getAllByIndex(String indexName, List<List<Object?>> keys) {
    return isar.getTxn(false, (txn) async {
      final objects = await native
          .getAllByIndex(txn, indexName, keys)
          .wait<List<Object?>>();
      return deserializeObjects(objects);
    });
  }

  @override
  List<OBJ?> getAllSync(List<int> ids) => unsupportedOnWeb();

  @override
  List<OBJ?> getAllByIndexSync(String indexName, List<List<Object?>> keys) =>
      unsupportedOnWeb();

  @override
  Future<List<int>> putAll(List<OBJ> objects) {
    return isar.getTxn(true, (txn) async {
      final serialized = <Object>[];
      for (var object in objects) {
        serialized.add(schema.serializeWeb(this, object));
      }
      final ids = await native.putAll(txn, serialized).wait<List<int>>();
      final linkFutures = <Future<void>>[];
      for (var i = 0; i < objects.length; i++) {
        final object = objects[i];
        final id = ids[i];
        schema.setId?.call(object, id);

        if (schema.hasLinks) {
          schema.attachLinks(this, id, object);
          if (saveLinks) {
            for (var link in schema.getLinks(object)) {
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
  List<int> putAllSync(List<OBJ> objects) => unsupportedOnWeb();

  @override
  Future<int> deleteAll(List<int> ids) async {
    await isar.getTxn(true, (txn) {
      return native.deleteAll(txn, ids).wait<void>();
    });
    return ids.length;
  }

  @override
  Future<int> deleteAllByIndex(String indexName, List<List<Object?>> keys) {
    return isar.getTxn(true, (txn) {
      return native.deleteAllByIndex(txn, indexName, keys).wait();
    });
  }

  @override
  int deleteAllSync(List<int> ids) => unsupportedOnWeb();

  @override
  int deleteAllByIndexSync(String indexName, List<List<Object?>> keys) =>
      unsupportedOnWeb();

  @override
  Future<void> clear() {
    return isar.getTxn(true, (txn) {
      return native.clear(txn).wait();
    });
  }

  @override
  void clearSync() => unsupportedOnWeb();

  @override
  Future<void> importJson(List<Map<String, dynamic>> json) {
    return isar.getTxn(true, (txn) async {
      // for performance reasons
      // ignore: argument_type_not_assignable
      await native.putAll(txn, json.map(jsify).toList()).wait<dynamic>();
    });
  }

  @override
  Future<void> importJsonRaw(Uint8List jsonBytes) {
    final json = jsonDecode(Utf8Decoder().convert(jsonBytes)) as List;
    return importJson(json.cast());
  }

  @override
  void importJsonSync(List<Map<String, dynamic>> json) => unsupportedOnWeb();

  @override
  void importJsonRawSync(Uint8List jsonBytes) => unsupportedOnWeb();

  @override
  Future<int> count() => where().count();

  @override
  int countSync() => unsupportedOnWeb();

  @override
  Future<int> getSize({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) =>
      unsupportedOnWeb();

  @override
  int getSizeSync({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) =>
      unsupportedOnWeb();

  @override
  Stream<void> watchLazy() {
    JsFunction? stop;
    final controller = StreamController<void>(onCancel: () {
      stop?.apply([]);
    });

    final callback = allowInterop(() => controller.add(null));
    stop = native.watchLazy(callback);

    return controller.stream;
  }

  @override
  Stream<OBJ?> watchObject(
    int id, {
    bool initialReturn = false,
    bool deserialize = true,
  }) {
    JsFunction? stop;
    final controller = StreamController<OBJ?>(onCancel: () {
      stop?.apply([]);
    });

    final callback = allowInterop((Object obj) {
      final object = deserialize ? deserializeObject(obj) : null;
      controller.add(object);
    });
    stop = native.watchObject(id, callback);

    return controller.stream;
  }

  @override
  Stream<void> watchObjectLazy(int id) => watchObject(id, deserialize: false);

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
