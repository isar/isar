// ignore_for_file: public_member_api_docs

import 'dart:indexed_db';
import 'dart:js';

import 'package:isar/isar.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('JSON.stringify')
external String stringify(dynamic value);

@JS('indexedDB.cmp')
external int idbCmp(dynamic value1, dynamic value2);

@JS('Object.keys')
external List<String> objectKeys(dynamic obj);

Map<String, dynamic> jsMapToDart(Object obj) {
  final keys = objectKeys(obj);
  final map = <String, dynamic>{};
  for (final key in keys) {
    map[key] = getProperty<dynamic>(obj, key);
  }
  return map;
}

@JS('Promise')
class Promise {}

extension PromiseX on Promise {
  Future<T> wait<T>() => promiseToFuture(this);
}

@JS('openIsar')
external Promise openIsarJs(
  String name,
  List<dynamic> schemas,
  bool relaxedDurability,
);

@JS('IsarTxn')
class IsarTxnJs {
  external Promise commit();

  external void abort();

  external bool get write;
}

@JS('IsarInstance')
class IsarInstanceJs {
  external IsarTxnJs beginTxn(bool write);

  external IsarCollectionJs getCollection(String name);

  external Promise close(bool deleteFromDisk);
}

typedef ChangeCallbackJs = void Function();

typedef ObjectChangeCallbackJs = void Function(Object? object);

typedef QueryChangeCallbackJs = void Function(List<dynamic> results);

typedef StopWatchingJs = JsFunction;

@JS('IsarCollection')
class IsarCollectionJs {
  external IsarLinkJs getLink(String name);

  external Promise getAll(IsarTxnJs txn, List<Id> ids);

  external Promise getAllByIndex(
    IsarTxnJs txn,
    String indexName,
    List<List<dynamic>> values,
  );

  external Promise putAll(IsarTxnJs txn, List<dynamic> objects);

  external Promise deleteAll(IsarTxnJs txn, List<Id> ids);

  external Promise deleteAllByIndex(
    IsarTxnJs txn,
    String indexName,
    List<dynamic> keys,
  );

  external Promise clear(IsarTxnJs txn);

  external StopWatchingJs watchLazy(ChangeCallbackJs callback);

  external StopWatchingJs watchObject(Id id, ObjectChangeCallbackJs callback);

  external StopWatchingJs watchQuery(
    QueryJs query,
    QueryChangeCallbackJs callback,
  );

  external StopWatchingJs watchQueryLazy(
    QueryJs query,
    ChangeCallbackJs callback,
  );
}

@JS('IsarLink')
class IsarLinkJs {
  external Promise update(
    IsarTxnJs txn,
    bool backlink,
    Id id,
    List<Id> addedTargets,
    List<Id> deletedTargets,
  );

  external Promise clear(IsarTxnJs txn, Id id, bool backlink);
}

@JS('IdWhereClause')
@anonymous
class IdWhereClauseJs {
  external KeyRange? range;
}

@JS('IndexWhereClause')
@anonymous
class IndexWhereClauseJs {
  external String indexName;
  external KeyRange? range;
}

@JS('LinkWhereClause')
@anonymous
class LinkWhereClauseJs {
  external String linkCollection;
  external String linkName;
  external bool backlink;
  external Id id;
}

@JS('Function')
class FilterJs {
  external FilterJs(String id, String obj, String method);
}

@JS('Function')
class SortCmpJs {
  external SortCmpJs(String a, String b, String method);
}

@JS('Function')
class DistinctValueJs {
  external DistinctValueJs(String obj, String method);
}

@JS('IsarQuery')
class QueryJs {
  external QueryJs(
    IsarCollectionJs collection,
    List<dynamic> whereClauses,
    bool whereDistinct,
    bool whereAscending,
    FilterJs? filter,
    SortCmpJs? sortCmp,
    DistinctValueJs? distinctValue,
    int? offset,
    int? limit,
  );

  external Promise findFirst(IsarTxnJs txn);

  external Promise findAll(IsarTxnJs txn);

  external Promise deleteFirst(IsarTxnJs txn);

  external Promise deleteAll(IsarTxnJs txn);

  external Promise min(IsarTxnJs txn, String propertyName);

  external Promise max(IsarTxnJs txn, String propertyName);

  external Promise sum(IsarTxnJs txn, String propertyName);

  external Promise average(IsarTxnJs txn, String propertyName);

  external Promise count(IsarTxnJs txn);
}
