part of isar;

/// @nodoc
@protected
typedef FilterRepeatModifier<OBJ, R, E>
    = QueryBuilder<OBJ, R, QAfterFilterCondition> Function(
  QueryBuilder<OBJ, R, QFilterCondition> q,
  E element,
);

/// Extension for QueryBuilders.
extension QueryFilterAndOr<OBJ, R> on QueryBuilder<OBJ, R, QFilterOperator> {
  /// Intersection of two filter conditions.
  QueryBuilder<OBJ, R, QFilterCondition> and() {
    return QueryBuilder.apply(
      this,
      (q) => q.copyWith(filterGroupAnd: true),
    );
  }

  /// Union of two filter conditions.
  QueryBuilder<OBJ, R, QFilterCondition> or() {
    return QueryBuilder.apply(
      this,
      (q) => q.copyWith(filterGroupAnd: false),
    );
  }
}

/// Extension for QueryBuilders.
extension QueryFilterNot<OBJ, R> on QueryBuilder<OBJ, R, QFilterCondition> {
  /// Complement the next filter condition or group.
  QueryBuilder<OBJ, R, QFilterCondition> not() {
    return QueryBuilder.apply(
      this,
      (q) => q.copyWith(filterNot: !q.filterNot),
    );
  }

  /// Joins the results of the [modifier] for each item in [items] using logical
  /// OR. So an object will be included if it matches at least one of the
  /// resulting filters.
  ///
  /// If [items] is empty, this is a no-op.
  QueryBuilder<OBJ, R, QAfterFilterCondition> anyOf<E, RS>(
    Iterable<E> items,
    FilterRepeatModifier<OBJ, OBJ, E> modifier,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.group((q) {
        var q2 = QueryBuilder<OBJ, OBJ, QAfterFilterCondition>(q._query);
        for (final e in items) {
          q2 = modifier(q2.or(), e);
        }
        return q2;
      });
    });
  }

  /// Joins the results of the [modifier] for each item in [items] using logical
  /// AND. So an object will be included if it matches all of the resulting
  /// filters.
  ///
  /// If [items] is empty, this is a no-op.
  QueryBuilder<OBJ, R, QAfterFilterCondition> allOf<E, RS>(
    Iterable<E> items,
    FilterRepeatModifier<OBJ, OBJ, E> modifier,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.group((q) {
        var q2 = QueryBuilder<OBJ, OBJ, QAfterFilterCondition>(q._query);
        for (final e in items) {
          q2 = modifier(q2.and(), e);
        }
        return q2;
      });
    });
  }
}

/// Extension for QueryBuilders.
extension QueryFilterNoGroups<OBJ, R>
    on QueryBuilder<OBJ, R, QFilterCondition> {
  /// Group filter conditions.
  QueryBuilder<OBJ, R, QAfterFilterCondition> group(FilterQuery<OBJ> q) {
    return QueryBuilder.apply(this, (query) => query.group(q));
  }
}

/// @nodoc
@protected
typedef QueryOption<OBJ, S, RS> = QueryBuilder<OBJ, OBJ, RS> Function(
  QueryBuilder<OBJ, OBJ, S> q,
);

/// Extension for QueryBuilders.
extension QueryModifier<OBJ, S> on QueryBuilder<OBJ, OBJ, S> {
  /// Only apply a part of the query if `enabled` is true.
  QueryBuilder<OBJ, OBJ, RS> optional<RS>(
    bool enabled,
    QueryOption<OBJ, S, RS> option,
  ) {
    if (enabled) {
      return option(this);
    } else {
      return QueryBuilder(_query);
    }
  }
}

/// Extension for QueryBuilders
/*extension QueryExecute<OBJ, R> on QueryBuilder<OBJ, R, QQueryOperations> {
  /// Create a query from this query builder.
  Query<R> build() => _query.build();

  /// {@macro query_find_first}
  Future<R?> findFirst() => build().findFirst();

  /// {@macro query_find_first}
  R? findFirstSync() => build().findFirstSync();

  /// {@macro query_find_all}
  Future<List<R>> findAll() => build().findAll();

  /// {@macro query_find_all}
  List<R> findAllSync() => build().findAllSync();

  /// {@macro query_count}
  Future<int> count() => build().count();

  /// {@macro query_count}
  int countSync() => build().countSync();

  /// {@macro query_is_empty}
  Future<bool> isEmpty() => build().isEmpty();

  /// {@macro query_is_empty}
  bool isEmptySync() => build().isEmptySync();

  /// {@macro query_is_not_empty}
  Future<bool> isNotEmpty() => build().isNotEmpty();

  /// {@macro query_is_not_empty}
  bool isNotEmptySync() => build().isNotEmptySync();

  /// {@macro query_delete_first}
  Future<bool> deleteFirst() => build().deleteFirst();

  /// {@macro query_delete_first}
  bool deleteFirstSync() => build().deleteFirstSync();

  /// {@macro query_delete_all}
  Future<int> deleteAll() => build().deleteAll();

  /// {@macro query_delete_all}
  int deleteAllSync() => build().deleteAllSync();

  /// {@macro query_watch}
  Stream<List<R>> watch({bool fireImmediately = false}) =>
      build().watch(fireImmediately: fireImmediately);

  /// {@macro query_watch_lazy}
  Stream<void> watchLazy({bool fireImmediately = false}) =>
      build().watchLazy(fireImmediately: fireImmediately);

  /// {@macro query_export_json_raw}
  Future<T> exportJsonRaw<T>(T Function(Uint8List) callback) =>
      build().exportJsonRaw(callback);

  /// {@macro query_export_json_raw}
  T exportJsonRawSync<T>(T Function(Uint8List) callback) =>
      build().exportJsonRawSync(callback);

  /// {@macro query_export_json}
  Future<List<Map<String, dynamic>>> exportJson() => build().exportJson();

  /// {@macro query_export_json}
  List<Map<String, dynamic>> exportJsonSync() => build().exportJsonSync();
}

/// Extension for QueryBuilders
extension QueryExecuteAggregation<OBJ, T extends num>
    on QueryBuilder<OBJ, T?, QQueryOperations> {
  /// {@macro aggregation_min}
  Future<T?> min() => build().min();

  /// {@macro aggregation_min}
  T? minSync() => build().minSync();

  /// {@macro aggregation_max}
  Future<T?> max() => build().max();

  /// {@macro aggregation_max}
  T? maxSync() => build().maxSync();

  /// {@macro aggregation_average}
  Future<double> average() => build().average();

  /// {@macro aggregation_average}
  double averageSync() => build().averageSync();

  /// {@macro aggregation_sum}
  Future<T> sum() => build().sum();

  /// {@macro aggregation_sum}
  T sumSync() => build().sumSync();
}

/// Extension for QueryBuilders
extension QueryExecuteDateAggregation<OBJ>
    on QueryBuilder<OBJ, DateTime?, QQueryOperations> {
  /// {@macro aggregation_min}
  Future<DateTime?> min() => build().min();

  /// {@macro aggregation_min}
  DateTime? minSync() => build().minSync();

  /// {@macro aggregation_max}
  Future<DateTime?> max() => build().max();

  /// {@macro aggregation_max}
  DateTime? maxSync() => build().maxSync();
}
*/