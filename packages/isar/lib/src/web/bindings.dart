import 'dart:indexed_db';

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('Promise')
class Promise {}

extension PromiseX on Promise {
  Future<T> wait<T>() => promiseToFuture(this);
}

@JS('openIsar')
external Promise openIsarJs(
    String name, List<dynamic> schemas, bool relaxedDurability);

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

@JS('IsarCollection')
class IsarCollectionJs {
  external Promise get(IsarTxnJs txn, int id);

  external Promise getAll(IsarTxnJs txn, List<int> ids);

  external Promise getByIndex(
      IsarTxnJs txn, String indexName, List<dynamic> value);

  external Promise getAllByIndex(
      IsarTxnJs txn, String indexName, List<List<dynamic>> values);

  external Promise put(IsarTxnJs txn, dynamic object, bool replaceOnConflict);

  external Promise putAll(IsarTxnJs txn, List objects, bool replaceOnConflict);

  external Promise delete(IsarTxnJs txn, int id);

  external Promise deleteByIndex(IsarTxnJs txn, dynamic key);

  external Promise deleteAll(IsarTxnJs txn, List<int> ids);

  external Promise deleteAllByIndex(IsarTxnJs txn, List<dynamic> keys);

  external Promise clear(IsarTxnJs txn);
}

@JS('WhereClause')
class WhereClauseJs {
  external WhereClauseJs(String? indexName, KeyRange? range);
}

@JS('Function')
class FilterJs {
  external FilterJs(String obj, String cmp, String method);
}

@JS('Function')
class SortCmpJs {
  external SortCmpJs(String a, String b, String cmp, String method);
}

@JS('Function')
class DistinctValueJs {
  external DistinctValueJs(String obj, String method);
}

@JS('IsarQuery')
class QueryJs {
  external QueryJs(
    IsarCollectionJs collection,
    List<WhereClauseJs> whereClauses,
    bool whereDistinct,
    bool whereAscending,
    FilterJs? filter,
    SortCmpJs? sortCmp,
    DistinctValueJs? distinctValue,
    int? offset,
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
