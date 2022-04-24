import 'dart:async';
import 'dart:convert';
import 'dart:js';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/web/bindings.dart';

import 'isar_collection_impl.dart';
import 'isar_web.dart';

typedef QueryDeserialize<T> = T Function(dynamic);

class QueryImpl<T> extends Query<T> {
  final IsarCollectionImpl col;
  final QueryJs queryJs;
  final QueryDeserialize<T> deserialize;
  final String? propertyName;

  QueryImpl(this.col, this.queryJs, this.deserialize, this.propertyName);

  @override
  Future<T?> findFirst() {
    return col.isar.getTxn(false, (txn) async {
      final result = await queryJs.findFirst(txn).wait();
      if (result == null) {
        return null;
      }
      return deserialize(result);
    });
  }

  @override
  T? findFirstSync() => unsupportedOnWeb();

  @override
  Future<List<T>> findAll() {
    return col.isar.getTxn(false, (txn) async {
      final result = await queryJs.findAll(txn).wait();
      return (result as List).map(deserialize).toList();
    });
  }

  @override
  List<T> findAllSync() => unsupportedOnWeb();

  @override
  Future<R?> aggregate<R>(AggregationOp op) {
    return col.isar.getTxn(false, (txn) async {
      final property = propertyName ?? col.schema.idName;

      num? result;
      switch (op) {
        case AggregationOp.min:
          result = await queryJs.min(txn, property).wait();
          break;
        case AggregationOp.max:
          result = await queryJs.max(txn, property).wait();
          break;
        case AggregationOp.sum:
          result = await queryJs.sum(txn, property).wait();
          break;
        case AggregationOp.average:
          result = await queryJs.average(txn, property).wait();
          break;
        case AggregationOp.count:
          result = await queryJs.count(txn).wait();
          break;
      }

      if (result == null) {
        return null;
      }

      if (R == DateTime) {
        return DateTime.fromMillisecondsSinceEpoch(result.toInt()).toLocal()
            as R;
      } else if (R == int) {
        return result.toInt() as R;
      } else if (R == double) {
        return result.toDouble() as R;
      } else {
        return null;
      }
    });
  }

  @override
  R? aggregateSync<R>(AggregationOp op) => unsupportedOnWeb();

  @override
  Future<bool> deleteFirst() {
    return col.isar.getTxn(true, (txn) {
      return queryJs.deleteFirst(txn).wait();
    });
  }

  @override
  bool deleteFirstSync() => unsupportedOnWeb();

  @override
  Future<int> deleteAll() {
    return col.isar.getTxn(true, (txn) {
      return queryJs.deleteAll(txn).wait();
    });
  }

  @override
  int deleteAllSync() => unsupportedOnWeb();

  @override
  Stream<List<T>> watch({bool initialReturn = false}) {
    JsFunction? stop;
    final controller = StreamController<List<T>>(onCancel: () {
      stop?.apply([]);
    });

    if (initialReturn) {
      findAll().then((results) {
        controller.add(results);
      });
    }

    final callback = allowInterop((List results) {
      controller.add(results.map(deserialize).toList());
    });
    stop = col.native.watchQuery(queryJs, callback);

    return controller.stream;
  }

  @override
  Stream<void> watchLazy() {
    JsFunction? stop;
    final controller = StreamController<void>(onCancel: () {
      stop?.apply([]);
    });

    final callback = allowInterop(() {
      controller.add(null);
    });
    stop = col.native.watchQueryLazy(queryJs, callback);

    return controller.stream;
  }

  @override
  Future<R> exportJsonRaw<R>(R Function(Uint8List) callback) async {
    return col.isar.getTxn(false, (txn) async {
      final result = await queryJs.findAll(txn).wait();
      final jsonStr = stringify(result);
      return callback(Utf8Encoder().convert(jsonStr));
    });
  }

  @override
  Future<List<Map<String, dynamic>>> exportJson() {
    return col.isar.getTxn(false, (txn) async {
      final result = await queryJs.findAll(txn).wait();
      return (result as List).map(jsMapToDart).toList();
    });
  }

  @override
  R exportJsonRawSync<R>(R Function(Uint8List) callback) => unsupportedOnWeb();

  @override
  List<Map<String, dynamic>> exportJsonSync({bool primitiveNull = true}) =>
      unsupportedOnWeb();
}
