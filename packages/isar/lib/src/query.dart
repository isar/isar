part of isar;

/// Querying is how you find records that match certain conditions.
abstract class Query<T> {
  /// {@template query_find_first}
  /// Find the first object that matches this query or `null` if no object
  /// matches.
  /// {@endtemplate}
  Future<T?> findFirst();

  /// {@macro query_find_first}
  T? findFirstSync();

  /// {@template query_find_all}
  /// Find all objects that match this query.
  /// {@endtemplate}
  Future<List<T>> findAll();

  /// {@macro query_find_all}
  List<T> findAllSync();

  /// @nodoc
  @protected
  Future<R?> aggregate<R>(AggregationOp op);

  /// @nodoc
  @protected
  R? aggregateSync<R>(AggregationOp op);

  /// {@template query_count}
  /// Count how many objects match this query.
  ///
  /// This operation is much faster than using `findAll().length`.
  /// {@endtemplate}
  Future<int> count() =>
      aggregate<int>(AggregationOp.count).then((value) => value!);

  /// {@macro query_count}
  int countSync() => aggregateSync<int>(AggregationOp.count)!;

  /// {@template query_delete_first}
  /// Delete the first object that matches this query. Returns whether a object
  /// has been deleted.
  /// {@endtemplate}
  Future<bool> deleteFirst();

  /// {@macro query_delete_first}
  bool deleteFirstSync();

  /// {@template query_delete_all}
  /// Delete all objects that match this query. Returns the number of deleted
  /// objects.
  /// {@endtemplate}
  Future<int> deleteAll();

  /// {@macro query_delete_all}
  int deleteAllSync();

  /// {@template query_watch}
  /// Create a watcher that yiels the results of this query whenever its
  /// results have (potentially) changed.
  ///
  /// If you don't always use the results, consider using `watchLazy` and rerun
  /// the query manually. If [initialReturn] is `true`, the results will be
  /// sent to the consumer immediately.
  /// {@endtemplate}
  Stream<List<T>> watch({bool initialReturn = false});

  /// {@template query_watch_lazy}
  /// Watch the query for changes.
  /// {@endtemplate}
  Stream<void> watchLazy();

  /// {@template query_export_json_raw}
  /// Export the results of this query as json bytes.
  ///
  /// **IMPORTANT:** Do not leak the bytes outside the callback. If you need to
  /// use the bytes outside, create a copy of the `Uint8List`.
  /// {@endtemplate}
  Future<R> exportJsonRaw<R>(R Function(Uint8List) callback);

  /// {@macro query_export_json_raw}
  R exportJsonRawSync<R>(R Function(Uint8List) callback);

  /// {@template query_export_json}
  /// Export the results of this query as json.
  /// {@endtemplate}
  Future<List<Map<String, dynamic>>> exportJson() {
    return exportJsonRaw((bytes) {
      final json = jsonDecode(Utf8Decoder().convert(bytes)) as List;
      return json.cast<Map<String, dynamic>>();
    });
  }

  /// {@macro query_export_json}
  List<Map<String, dynamic>> exportJsonSync() {
    return exportJsonRawSync((bytes) {
      final json = jsonDecode(Utf8Decoder().convert(bytes)) as List;
      return json.cast<Map<String, dynamic>>();
    });
  }
}

/// @nodoc
@protected
enum AggregationOp {
  min,
  max,
  sum,
  average,
  count,
}

/// Extension for Queries
extension QueryAggregation<T extends num> on Query<T?> {
  /// {@template aggregation_min}
  /// Returns the minimum value of this query.
  /// {@endtemplate}
  Future<T?> min() => aggregate<T>(AggregationOp.min);

  /// {@macro aggregation_min}
  T? minSync() => aggregateSync<T>(AggregationOp.min);

  /// {@template aggregation_max}
  /// Returns the maximum value of this query.
  /// {@endtemplate}
  Future<T?> max() => aggregate<T>(AggregationOp.max);

  /// {@macro aggregation_max}
  T? maxSync() => aggregateSync<T>(AggregationOp.max);

  /// {@template aggregation_average}
  /// Returns the average value of this query.
  /// {@endtemplate}
  Future<double> average() =>
      aggregate<double>(AggregationOp.average).then((value) => value!);

  /// {@macro aggregation_average}
  double averageSync() => aggregateSync<double>(AggregationOp.average)!;

  /// {@template aggregation_sum}
  /// Returns the sum of all values of this query.
  /// {@endtemplate}
  Future<T> sum() => aggregate<T>(AggregationOp.sum).then((value) => value!);

  /// {@macro aggregation_sum}
  T sumSync() => aggregateSync<T>(AggregationOp.sum)!;
}

/// Extension for Queries
extension QueryDateAggregation<T extends DateTime?> on Query<T> {
  /// {@macro aggregation_min}
  Future<DateTime?> min() => aggregate<DateTime>(AggregationOp.min);

  /// {@macro aggregation_min}
  DateTime? minSync() => aggregateSync<DateTime>(AggregationOp.min);

  /// {@macro aggregation_max}
  Future<DateTime?> max() => aggregate<DateTime>(AggregationOp.max);

  /// {@macro aggregation_max}
  DateTime? maxSync() => aggregateSync<DateTime>(AggregationOp.max);
}
