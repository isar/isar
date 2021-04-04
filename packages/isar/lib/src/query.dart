part of isar;

abstract class Query<T> {
  Future<T?> findFirst();

  T? findFirstSync();

  Future<List<T>> findAll();

  List<T> findAllSync();

  Future<int> count() => aggregateQuery(this, AggregationOp.Count);

  int countSync() => aggregateQuerySync(this, AggregationOp.Count);

  Future<bool> deleteFirst();

  bool deleteFirstSync();

  Future<int> deleteAll();

  int deleteAllSync();

  Stream<List<T>> watch({bool initialReturn = false});

  Stream<void> watchLazy();
}

extension QueryAggregation<T extends num?> on Query<T> {
  Future<T> min() => aggregateQuery(this, AggregationOp.Min);

  T minSync() => aggregateQuerySync(this, AggregationOp.Min);

  Future<T> max() => aggregateQuery(this, AggregationOp.Max);

  T maxSync() => aggregateQuerySync(this, AggregationOp.Max);

  Future<T> average() => aggregateQuery(this, AggregationOp.Average);

  T averageSync() => aggregateQuerySync(this, AggregationOp.Average);

  Future<T> sum() => aggregateQuery(this, AggregationOp.Sum);

  T sumSync() => aggregateQuerySync(this, AggregationOp.Sum);
}
