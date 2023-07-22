part of isar;

abstract class IsarQuery<T> {
  Isar get isar;

  T? findFirst() => findAll(limit: 1).firstOrNull;

  List<T> findAll({int? offset, int? limit});

  bool deleteFirst() => deleteAll(limit: 1) > 0;

  int deleteAll({int? offset, int? limit});

  int count() => aggregate(Aggregation.count) ?? 0;

  bool isEmpty() => aggregate(Aggregation.isEmpty) ?? true;

  bool isNotEmpty() => !isEmpty();

  @protected
  R? aggregate<R>(Aggregation op);

  List<Map<String, dynamic>> exportJson({int? offset, int? limit});

  /// {@template query_watch}
  /// Create a watcher that yields the results of this query whenever its
  /// results have (potentially) changed.
  ///
  /// If you don't always use the results, consider using `watchLazy` and rerun
  /// the query manually. If [fireImmediately] is `true`, the results will be
  /// sent to the consumer immediately.
  /// {@endtemplate}
  Stream<List<T>> watch({bool fireImmediately = false});

  /// {@template query_watch_lazy}
  /// Watch the query for changes. If [fireImmediately] is `true`, an event will
  /// be fired immediately.
  /// {@endtemplate}
  Stream<void> watchLazy({bool fireImmediately = false});

  void close();
}

/// @nodoc
@protected
enum Aggregation {
  /// Counts all values.
  count,

  /// Returns `true` if the query has no results.
  isEmpty,

  /// Finds the smallest value.
  min,

  /// Finds the largest value.
  max,

  /// Calculates the sum of all values.
  sum,

  /// Calculates the average of all values.
  average,
}
