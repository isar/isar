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
      aggregate<int>(AggregationOp.Count).then((value) => value!);

  int? countSync() => aggregateSync<int>(AggregationOp.Count);

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
  Future<T?> min() => aggregate<T>(AggregationOp.Min);

  T? minSync() => aggregateSync<T>(AggregationOp.Min);

  Future<T?> max() => aggregate<T>(AggregationOp.Max);

  T? maxSync() => aggregateSync<T>(AggregationOp.Max);

  Future<double> average() =>
      aggregate<double>(AggregationOp.Average).then((value) => value!);

  double averageSync() => aggregateSync<double>(AggregationOp.Average)!;

  Future<T> sum() => aggregate<T>(AggregationOp.Sum).then((value) => value!);

  T sumSync() => aggregateSync<T>(AggregationOp.Sum)!;
}

extension QueryDateAggregation<T extends DateTime?> on Query<T> {
  Future<DateTime?> min() => aggregate<DateTime>(AggregationOp.Min);

  DateTime? minSync() => aggregateSync<DateTime>(AggregationOp.Min);

  Future<DateTime?> max() => aggregate<DateTime>(AggregationOp.Max);

  DateTime? maxSync() => aggregateSync<DateTime>(AggregationOp.Max);
}
