part of isar;

/// Querying is how you find records that match certain conditions.
///
/// It is important to call `close()` when you are done with a query, otherwise
/// you will leak resources.
abstract class IsarQuery<T> {
  /// The corresponding Isar instance.
  Isar get isar;

  /// Find the first object that matches this query or `null` if no object
  /// matches.
  T? findFirst({int? offset}) => findAll(offset: offset, limit: 1).firstOrNull;

  /// Find all objects that match this query.
  List<T> findAll({int? offset, int? limit});

  /// This is a low level method to update objects.
  ///
  /// It is not recommended to use this method directly, instead use the
  /// generated `updateFirst()` and `updateAll()` method.
  @protected
  int updateProperties(Map<int, dynamic> changes, {int? offset, int? limit});

  /// Delete the first object that matches this query. Returns whether an object
  /// has been deleted.
  bool deleteFirst({int? offset}) => deleteAll(offset: offset, limit: 1) > 0;

  /// Delete all objects that match this query. Returns the number of deleted
  /// objects.
  int deleteAll({int? offset, int? limit});

  /// Count how many objects match this query.
  ///
  /// This operation is much faster than using `findAll().length`.
  int count() => aggregate(Aggregation.count) ?? 0;

  /// Returns `true` if there are no objects that match this query.
  ///
  /// This operation is faster than using `count() == 0`.
  bool isEmpty() => aggregate(Aggregation.isEmpty) ?? true;

  /// Returns `true` if there are objects that match this query.
  ///
  /// This operation is faster than using `count() > 0`.
  bool isNotEmpty() => !isEmpty();

  /// @nodoc
  @protected
  R? aggregate<R>(Aggregation op);

  /// Export the results of this query as json.
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
