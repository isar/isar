part of isar;

abstract class Query<T> {
  T? findFirst();

  List<T> findAll();

  bool deleteFirst();

  int deleteAll();
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
