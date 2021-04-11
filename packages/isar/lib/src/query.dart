part of isar;

abstract class Query<T> {
  Future<T?> findFirst();

  T? findFirstSync();

  Future<List<T>> findAll();

  List<T> findAllSync();

  Future<int> count() =>
      aggregateQuery<int>(this, AggregationOp.Count).then((value) => value!);

  int countSync() => aggregateQuerySync(this, AggregationOp.Count);

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
  Future<T?> min() => aggregateQuery(this, AggregationOp.Min);

  T? minSync() => aggregateQuerySync(this, AggregationOp.Min);

  Future<T?> max() => aggregateQuery(this, AggregationOp.Max);

  T? maxSync() => aggregateQuerySync(this, AggregationOp.Max);

  Future<double> average() =>
      aggregateQuery<double>(this, AggregationOp.Average)
          .then((value) => value!);

  double averageSync() =>
      aggregateQuerySync<double>(this, AggregationOp.Average)!;

  Future<T> sum() =>
      aggregateQuery<T>(this, AggregationOp.Sum).then((value) => value!);

  T sumSync() => aggregateQuerySync<T>(this, AggregationOp.Sum)!;
}

extension QueryDateAggregation<T extends DateTime?> on Query<T> {
  Future<DateTime?> min() => aggregateQuery(this, AggregationOp.Min);

  DateTime? minSync() => aggregateQuerySync(this, AggregationOp.Min);

  Future<DateTime?> max() => aggregateQuery(this, AggregationOp.Max);

  DateTime? maxSync() => aggregateQuerySync(this, AggregationOp.Max);
}
