part of isar;

abstract class Query<T> {
  Isar get isar;

  T? findFirst() => findAll(limit: 1).firstOrNull;

  List<T> findAll({int? offset, int? limit});

  bool deleteFirst() => deleteAll(limit: 1) > 0;

  int deleteAll({int? offset, int? limit});

  List<Map<String, dynamic>> exportJson({int? offset, int? limit}) {
    return exportJsonBytes(offset: offset, limit: limit, (jsonBytes) {
      final list = jsonDecode(utf8.decode(jsonBytes)) as List<dynamic>;
      return list.cast();
    });
  }

  R exportJsonBytes<R>(
    R Function(Uint8List jsonBytes) callback, {
    int? offset,
    int? limit,
  });

  void exportJsonFile(String path, {int? offset, int? limit});

  int count() => aggregate(Aggregation.count) ?? 0;

  bool isEmpty() => aggregate(Aggregation.isEmpty) ?? true;

  bool isNotEmpty() => !isEmpty();

  @protected
  R? aggregate<R>(Aggregation op);

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
