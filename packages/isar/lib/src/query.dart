part of isar;

abstract class Query<T> {
  T? findFirst() => findAll(limit: 1).firstOrNull;

  List<T> findAll({int? offset, int? limit});

  bool deleteFirst() => deleteAll(limit: 1) > 0;

  int deleteAll({int? offset, int? limit});

  int count();

  bool isEmpty() => aggregate(AggregationOp.isEmpty)!;

  bool isNotEmpty() => !isEmpty();

  @protected
  R? aggregate<R>(AggregationOp op);

  void close();
}

/// @nodoc
@protected
enum AggregationOp {
  /// Finds the smallest value.
  min,

  /// Finds the largest value.
  max,

  /// Calculates the sum of all values.
  sum,

  /// Calculates the average of all values.
  average,

  /// Counts all values.
  count,

  /// Returns `true` if the query has no results.
  isEmpty,
}
