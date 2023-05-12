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
        var q2 = QueryBuilder<OBJ, OBJ, QAfterFilterCondition>._(q._query);
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
        var q2 = QueryBuilder<OBJ, OBJ, QAfterFilterCondition>._(q._query);
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
      return QueryBuilder._(_query);
    }
  }
}

extension QueryAggregation<T extends num> on Query<T?> {
  T? min() => aggregate<T>(AggregationOp.min);

  T? max() => aggregate<T>(AggregationOp.max);

  double average() => aggregate<double>(AggregationOp.average)!;

  T sum() => aggregate<T>(AggregationOp.sum)!;
}

extension QueryDateAggregation<T extends DateTime?> on Query<T> {
  DateTime? min() => aggregate<DateTime>(AggregationOp.min);

  DateTime? max() => aggregate<DateTime>(AggregationOp.max);
}

/// Extension for QueryBuilders
extension QueryExecute<OBJ, R> on QueryBuilder<OBJ, R, QQueryOperations> {
  /// Create a query from this query builder.
  Query<R> build() => _query.build();

  /// {@macro query_find_first}
  R? findFirst() => build().findFirst();

  /// {@macro query_find_all}
  List<R> findAll({int? offset, int? limit}) => build().findAll(
        offset: offset,
        limit: limit,
      );

  /// {@macro query_count}
  int count() => build().count();

  /// {@macro query_is_empty}
  bool isEmpty() => build().isEmpty();

  /// {@macro query_is_not_empty}
  bool isNotEmpty() => build().isNotEmpty();

  /// {@macro query_delete_first}
  bool deleteFirst() => build().deleteFirst();

  /// {@macro query_delete_all}
  int deleteAll({int? offset, int? limit}) => build().deleteAll(
        offset: offset,
        limit: limit,
      );
}

/// Extension for QueryBuilders
extension QueryExecuteAggregation<OBJ, T extends num>
    on QueryBuilder<OBJ, T?, QQueryOperations> {
  /// {@macro aggregation_min}
  T? min() => build().min();

  /// {@macro aggregation_max}
  T? max() => build().max();

  /// {@macro aggregation_average}
  double average() => build().average();

  /// {@macro aggregation_sum}
  T sum() => build().sum();
}

/// Extension for QueryBuilders
extension QueryExecuteDateAggregation<OBJ>
    on QueryBuilder<OBJ, DateTime?, QQueryOperations> {
  /// {@macro aggregation_min}
  DateTime? min() => build().min();

  /// {@macro aggregation_max}
  DateTime? max() => build().max();
}
