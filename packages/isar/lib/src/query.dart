part of isar;

abstract class Query<T> {
  Future<T?> findFirst();

  T? findFirstSync();

  Future<List<T>> findAll();

  List<T> findAllSync();

  @protected
  Future<R?> aggregate<R>(AggregationOp op);

  @protected
  R? aggregateSync<R>(AggregationOp op);

  Future<int> count() =>
      aggregate<int>(AggregationOp.count).then((value) => value!);

  int? countSync() => aggregateSync<int>(AggregationOp.count);

  Future<bool> deleteFirst();

  bool deleteFirstSync();

  Future<int> deleteAll();

  int deleteAllSync();

  Stream<List<T>> watch({bool initialReturn = false});

  Stream<void> watchLazy();

  Future<R> exportJsonRaw<R>(R Function(Uint8List) callback,
      {bool primitiveNull = true});

  Future<List<Map<String, dynamic>>> exportJson({bool primitiveNull = true}) {
    return exportJsonRaw(
      (bytes) {
        final json = jsonDecode(Utf8Decoder().convert(bytes)) as List;
        return json.cast<Map<String, dynamic>>();
      },
      primitiveNull: primitiveNull,
    );
  }
}

extension QueryAggregation<T extends num> on Query<T?> {
  Future<T?> min() => aggregate<T>(AggregationOp.min);

  T? minSync() => aggregateSync<T>(AggregationOp.min);

  Future<T?> max() => aggregate<T>(AggregationOp.max);

  T? maxSync() => aggregateSync<T>(AggregationOp.max);

  Future<double> average() =>
      aggregate<double>(AggregationOp.average).then((value) => value!);

  double averageSync() => aggregateSync<double>(AggregationOp.average)!;

  Future<T> sum() => aggregate<T>(AggregationOp.sum).then((value) => value!);

  T sumSync() => aggregateSync<T>(AggregationOp.sum)!;
}

extension QueryDateAggregation<T extends DateTime?> on Query<T> {
  Future<DateTime?> min() => aggregate<DateTime>(AggregationOp.min);

  DateTime? minSync() => aggregateSync<DateTime>(AggregationOp.min);

  Future<DateTime?> max() => aggregate<DateTime>(AggregationOp.max);

  DateTime? maxSync() => aggregateSync<DateTime>(AggregationOp.max);
}
