part of isar;

/// Querying is how you find records that match certain conditions.
///
/// It is important to call `close()` when you are done with a query, otherwise
/// you will leak resources.
abstract class IsarQuery<T> {
  /// The corresponding Isar instance.
  Isar get isar;

  /// {@template query_find_first}
  /// Find the first object that matches this query or `null` if no object
  /// matches.
  /// {@endtemplate}
  T? findFirst({int? offset}) => findAll(offset: offset, limit: 1).firstOrNull;

  /// {@template query_find_all}
  /// Find all objects that match this query.
  /// {@endtemplate}
  List<T> findAll({int? offset, int? limit});

  /// This is a low level method to update objects.
  ///
  /// It is not recommended to use this method directly, instead use the
  /// generated `updateFirst()` and `updateAll()` method.
  @protected
  int updateProperties(Map<int, dynamic> changes, {int? offset, int? limit});

  /// {@template query_delete_first}
  /// Delete the first object that matches this query. Returns whether an object
  /// has been deleted.
  /// {@endtemplate}
  bool deleteFirst({int? offset}) => deleteAll(offset: offset, limit: 1) > 0;

  /// {@template query_delete_all}
  /// Delete all objects that match this query. Returns the number of deleted
  /// objects.
  /// {@endtemplate}
  int deleteAll({int? offset, int? limit});

  /// {@macro aggregation_min}
  int count() => aggregate(Aggregation.count) ?? 0;

  /// {@macro aggregation_is_empty}
  bool isEmpty() => aggregate(Aggregation.isEmpty) ?? true;

  /// @nodoc
  @protected
  R? aggregate<R>(Aggregation op);

  /// {@template query_export_json}
  /// Export the results of this query as json.
  /// {@endtemplate}
  List<Map<String, dynamic>> exportJson({int? offset, int? limit});

  /// {@template query_watch}
  /// Create a watcher that yields the results of this query whenever its
  /// results have (potentially) changed.
  ///
  /// If you don't always use the results, consider using `watchLazy` and rerun
  /// the query manually. If [fireImmediately] is `true`, the results will be
  /// sent to the consumer immediately.
  /// {@endtemplate}
  Stream<List<T>> watch({
    bool fireImmediately = false,
    int? offset,
    int? limit,
  });

  /// {@template query_watch_lazy}
  /// Watch the query for changes. If [fireImmediately] is `true`, an event will
  /// be fired immediately.
  /// {@endtemplate}
  Stream<void> watchLazy({bool fireImmediately = false});

  /// Release all resources associated with this query.
  void close();
}

/// @nodoc
@protected
enum Aggregation {
  /// {@template aggregation_count}
  /// Count how many objects match the query.
  ///
  /// This operation is much faster than using `findAll().length`.
  /// {@endtemplate}
  count,

  /// {@template aggregation_is_empty}
  /// Yields `true` if there are no objects that match the query.
  ///
  /// This operation is faster than using `count() == 0`.
  /// {@endtemplate}
  isEmpty,

  /// {@template aggregation_min}
  /// Finds the smallest value matching the query. Null values are considered
  /// smaller than all other values.
  ///
  /// Yields null if there are no objects that match the query.
  /// {@endtemplate}
  min,

  /// {@template aggregation_max}
  /// Finds the largest value matching the query.
  ///
  /// Yields null if there are no objects that match the query.
  /// {@endtemplate}
  max,

  /// {@template aggregation_sum}
  /// Calculates the sum of all values. This only works for numeric values.
  /// {@endtemplate}
  sum,

  /// {@template aggregation_average}
  /// Calculates the average of all values. This only works for numeric values.
  /// {@endtemplate}
  average,
}
