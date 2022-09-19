// ignore_for_file: public_member_api_docs, invalid_use_of_protected_member

import 'dart:async';
import 'dart:convert';
import 'dart:js';
import 'dart:js_util';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/web/bindings.dart';
import 'package:isar/src/web/isar_impl.dart';
import 'package:isar/src/web/isar_reader_impl.dart';
import 'package:isar/src/web/isar_web.dart';
import 'package:isar/src/web/isar_writer_impl.dart';
import 'package:isar/src/web/query_build.dart';
import 'package:meta/dart2js.dart';

class IsarCollectionImpl<OBJ> extends IsarCollection<OBJ> {
  IsarCollectionImpl({
    required this.isar,
    required this.native,
    required this.schema,
  });

  @override
  final IsarImpl isar;
  final IsarCollectionJs native;

  @override
  final CollectionSchema<OBJ> schema;

  @override
  String get name => schema.name;

  late final _offsets = isar.offsets[OBJ]!;

  @tryInline
  OBJ deserializeObject(Object object) {
    final id = getProperty<int>(object, idName);
    final reader = IsarReaderImpl(object);
    return schema.deserialize(id, reader, _offsets, isar.offsets);
  }

  @tryInline
  List<OBJ?> deserializeObjects(dynamic objects) {
    final list = objects as List;
    final results = <OBJ?>[];
    for (final object in list) {
      results.add(object is Object ? deserializeObject(object) : null);
    }
    return results;
  }

  @override
  Future<List<OBJ?>> getAll(List<Id> ids) {
    return isar.getTxn(false, (IsarTxnJs txn) async {
      final objects = await native.getAll(txn, ids).wait<List<Object?>>();
      return deserializeObjects(objects);
    });
  }

  @override
  Future<List<OBJ?>> getAllByIndex(String indexName, List<IndexKey> keys) {
    return isar.getTxn(false, (IsarTxnJs txn) async {
      final objects = await native
          .getAllByIndex(txn, indexName, keys)
          .wait<List<Object?>>();
      return deserializeObjects(objects);
    });
  }

  @override
  List<OBJ?> getAllSync(List<Id> ids) => unsupportedOnWeb();

  @override
  List<OBJ?> getAllByIndexSync(String indexName, List<IndexKey> keys) =>
      unsupportedOnWeb();

  @override
  Future<List<Id>> putAll(List<OBJ> objects) {
    return putAllByIndex(null, objects);
  }

  @override
  List<int> putAllSync(List<OBJ> objects, {bool saveLinks = true}) =>
      unsupportedOnWeb();

  @override
  Future<List<Id>> putAllByIndex(String? indexName, List<OBJ> objects) {
    return isar.getTxn(true, (IsarTxnJs txn) async {
      final serialized = <Object>[];
      for (final object in objects) {
        final jsObj = newObject<Object>();
        final writer = IsarWriterImpl(jsObj);
        schema.serialize(object, writer, _offsets, isar.offsets);
        setProperty(jsObj, idName, schema.getId(object));
        serialized.add(jsObj);
      }
      final ids = await native.putAll(txn, serialized).wait<List<dynamic>>();
      for (var i = 0; i < objects.length; i++) {
        final object = objects[i];
        final id = ids[i] as Id;
        schema.attach(this, id, object);
      }

      return ids.cast<Id>().toList();
    });
  }

  @override
  List<Id> putAllByIndexSync(
    String indexName,
    List<OBJ> objects, {
    bool saveLinks = true,
  }) =>
      unsupportedOnWeb();

  @override
  Future<int> deleteAll(List<Id> ids) async {
    await isar.getTxn(true, (IsarTxnJs txn) {
      return native.deleteAll(txn, ids).wait<void>();
    });
    return ids.length;
  }

  @override
  Future<int> deleteAllByIndex(String indexName, List<IndexKey> keys) {
    return isar.getTxn(true, (IsarTxnJs txn) {
      return native.deleteAllByIndex(txn, indexName, keys).wait();
    });
  }

  @override
  int deleteAllSync(List<Id> ids) => unsupportedOnWeb();

  @override
  int deleteAllByIndexSync(String indexName, List<IndexKey> keys) =>
      unsupportedOnWeb();

  @override
  Future<void> clear() {
    return isar.getTxn(true, (IsarTxnJs txn) {
      return native.clear(txn).wait();
    });
  }

  @override
  void clearSync() => unsupportedOnWeb();

  @override
  Future<void> importJson(List<Map<String, dynamic>> json) {
    return isar.getTxn(true, (IsarTxnJs txn) async {
      await native.putAll(txn, json.map(jsify).toList()).wait<dynamic>();
    });
  }

  @override
  Future<void> importJsonRaw(Uint8List jsonBytes) {
    final json = jsonDecode(const Utf8Decoder().convert(jsonBytes)) as List;
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
  Stream<void> watchLazy({bool fireImmediately = false}) {
    JsFunction? stop;
    final controller = StreamController<void>(
      onCancel: () {
        stop?.apply([]);
      },
    );

    final void Function() callback = allowInterop(() => controller.add(null));
    stop = native.watchLazy(callback);

    return controller.stream;
  }

  @override
  Stream<OBJ?> watchObject(
    Id id, {
    bool fireImmediately = false,
    bool deserialize = true,
  }) {
    JsFunction? stop;
    final controller = StreamController<OBJ?>(
      onCancel: () {
        stop?.apply([]);
      },
    );

    final Null Function(Object? obj) callback = allowInterop((Object? obj) {
      final object = deserialize && obj != null ? deserializeObject(obj) : null;
      controller.add(object);
    });
    stop = native.watchObject(id, callback);

    return controller.stream;
  }

  @override
  Stream<void> watchObjectLazy(Id id, {bool fireImmediately = false}) =>
      watchObject(id, deserialize: false);

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

  @override
  Future<void> verify(List<OBJ> objects) => unsupportedOnWeb();

  @override
  Future<void> verifyLink(
    String linkName,
    List<int> sourceIds,
    List<int> targetIds,
  ) =>
      unsupportedOnWeb();
}
