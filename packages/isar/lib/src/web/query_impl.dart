import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/web/bindings.dart';

import 'isar_collection_impl.dart';

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
  T? findFirstSync() => throw UnimplementedError();

  @override
  Future<List<T>> findAll() {
    return col.isar.getTxn(false, (txn) async {
      final result = await queryJs.findAll(txn).wait();
      return result.map((e) => deserialize(e)).toList();
    });
  }

  @override
  List<T> findAllSync() => throw UnimplementedError();

  @override
  Future<R?> aggregate<R>(AggregationOp op) {
    return col.isar.getTxn(false, (txn) async {
      final property = propertyName ?? col.idName;

      num result;
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

      if (R == DateTime) {
        return DateTime.fromMillisecondsSinceEpoch(result.toInt()).toLocal()
            as R;
      } else if (R == int) {
        return result.toInt() as R;
      } else if (R == double) {
        return result.toDouble() as R;
      }
    });
  }

  @override
  R? aggregateSync<R>(AggregationOp op) => throw UnimplementedError();

  @override
  Future<bool> deleteFirst() {
    return col.isar.getTxn(true, (txn) {
      return queryJs.deleteFirst(txn).wait();
    });
  }

  @override
  bool deleteFirstSync() => throw UnimplementedError();

  @override
  Future<int> deleteAll() {
    return col.isar.getTxn(true, (txn) {
      return queryJs.deleteAll(txn).wait();
    });
  }

  @override
  int deleteAllSync() => throw UnimplementedError();

  @override
  Stream<List<T>> watch({bool initialReturn = false}) =>
      throw UnimplementedError();

  @override
  Stream<void> watchLazy() => throw UnimplementedError();

  @override
  Future<R> exportJsonRaw<R>(R Function(Uint8List) callback,
      {bool primitiveNull = true}) {}

  @override
  Future<List<Map<String, dynamic>>> exportJson({bool primitiveNull = true}) {
    return col.isar.getTxn(false, (txn) async {
      final results = await queryJs.findAll(txn).wait();
      return results;
    });
  }

  @override
  R exportJsonRawSync<R>(R Function(Uint8List) callback,
          {bool primitiveNull = true}) =>
      throw UnimplementedError();

  @override
  List<Map<String, dynamic>> exportJsonSync({bool primitiveNull = true}) =>
      throw UnimplementedError();
}
