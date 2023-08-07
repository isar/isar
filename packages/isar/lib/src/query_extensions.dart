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
  QueryBuilder<OBJ, R, QAfterFilterCondition> anyOf<E>(
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
  QueryBuilder<OBJ, R, QAfterFilterCondition> allOf<E>(
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

extension QueryNumAggregation<T extends num?> on IsarQuery<T?> {
  T? min() => aggregate(Aggregation.min);

  Future<T?> minAsync() => aggregateAsync(Aggregation.min);

  T? max() => aggregate(Aggregation.max);

  Future<T?> maxAsync() => aggregateAsync(Aggregation.max);

  double average() => aggregate(Aggregation.average) ?? double.nan;

  Future<double> averageAsync() => aggregateAsync<double>(Aggregation.average)
      .then((value) => value ?? double.nan);

  T sum() => aggregate(Aggregation.sum)!;

  Future<T> sumAsync() =>
      aggregateAsync<T>(Aggregation.sum).then((value) => value!);
}

extension QueryDateAggregation<T extends DateTime?> on IsarQuery<T> {
  DateTime? min() => aggregate(Aggregation.min);

  Future<DateTime?> minAsync() => aggregateAsync(Aggregation.min);

  DateTime? max() => aggregate(Aggregation.max);

  Future<DateTime?> maxAsync() => aggregateAsync(Aggregation.max);
}

extension QueryStringAggregation<T extends String?> on IsarQuery<T?> {
  T? min() => aggregate(Aggregation.min);

  Future<T?> minAsync() => aggregateAsync(Aggregation.min);

  T? max() => aggregate(Aggregation.max);

  Future<T?> maxAsync() => aggregateAsync(Aggregation.max);
}

/// Extension for QueryBuilders
extension QueryExecute<OBJ, R> on QueryBuilder<OBJ, R, QOperations> {
  /// Create a query from this query builder.
  IsarQuery<R> build() => _query.build();

  T _withQuery<T>(T Function(IsarQuery<R> q) f) {
    final q = build();
    try {
      return f(q);
    } finally {
      q.close();
    }
  }

  /// {@macro query_find_first}
  R? findFirst({int? offset}) => _withQuery((q) => q.findFirst(offset: offset));

  /// {@macro query_find_all}
  List<R> findAll({int? offset, int? limit}) =>
      _withQuery((q) => q.findAll(offset: offset, limit: limit));

  /// {@macro query_delete_first}
  bool deleteFirst({int? offset}) =>
      _withQuery((q) => q.deleteFirst(offset: offset));

  /// {@macro query_delete_all}
  int deleteAll({int? offset, int? limit}) =>
      _withQuery((q) => q.deleteAll(offset: offset, limit: limit));

  /// {@macro query_find_all}
  List<Map<String, dynamic>> exportJson({int? offset, int? limit}) =>
      _withQuery((q) => q.exportJson(offset: offset, limit: limit));

  Stream<List<R>> watch({
    bool fireImmediately = false,
    int? offset,
    int? limit,
  }) {
    final q = build();
    final controller = StreamController<List<R>>();
    q
        .watch(fireImmediately: fireImmediately, offset: offset, limit: limit)
        .listen(
      controller.add,
      onError: controller.addError,
      onDone: () {
        controller.close();
        q.close();
      },
    );
    return controller.stream;
  }

  Stream<void> watchLazy({bool fireImmediately = false}) =>
      _withQuery((q) => q.watchLazy(fireImmediately: fireImmediately));

  Future<T> _withQueryAsync<T>(Future<T> Function(IsarQuery<R> q) f) async {
    final q = build();
    try {
      return await f(q);
    } finally {
      q.close();
    }
  }

  Future<R?> findFirstAsync({int? offset}) =>
      _withQueryAsync((q) => q.findFirstAsync(offset: offset));

  Future<List<R>> findAllAsync({int? offset, int? limit}) =>
      _withQueryAsync((q) => q.findAllAsync(offset: offset, limit: limit));
}

extension QueryExecuteAggregation<OBJ, T>
    on QueryBuilder<OBJ, T?, QOperations> {
  int count() => _withQuery((q) => q.count());

  bool isEmpty() => _withQuery((q) => q.isEmpty());

  bool isNotEmpty() => _withQuery((q) => q.isNotEmpty());

  Future<int> countAsync() => _withQueryAsync((q) => q.countAsync());

  Future<bool> isEmptyAsync() => _withQueryAsync((q) => q.isEmptyAsync());

  Future<bool> isNotEmptyAsync() => _withQueryAsync((q) => q.isNotEmptyAsync());
}

/// Extension for QueryBuilders
extension QueryExecuteNumAggregation<OBJ, T extends num>
    on QueryBuilder<OBJ, T?, QAfterProperty> {
  /// {@macro aggregation_min}
  T? min() => _withQuery((q) => q.min());

  /// {@macro aggregation_max}
  T? max() => _withQuery((q) => q.max());

  /// {@macro aggregation_average}
  double average() => _withQuery((q) => q.average());

  /// {@macro aggregation_sum}
  T sum() => _withQuery((q) => q.sum());

  Future<T?> minAsync() => _withQueryAsync((q) => q.minAsync());

  Future<T?> maxAsync() => _withQueryAsync((q) => q.maxAsync());

  Future<double> averageAsync() => _withQueryAsync((q) => q.averageAsync());

  Future<T> sumAsync() => _withQueryAsync((q) => q.sumAsync());
}

/// Extension for QueryBuilders
extension QueryExecuteDateAggregation<OBJ>
    on QueryBuilder<OBJ, DateTime?, QAfterProperty> {
  /// {@macro aggregation_min}
  DateTime? min() => _withQuery((q) => q.min());

  /// {@macro aggregation_max}
  DateTime? max() => _withQuery((q) => q.max());

  Future<DateTime?> minAsync() => _withQueryAsync((q) => q.minAsync());

  /// {@macro aggregation_max}
  Future<DateTime?> maxAsync() => _withQueryAsync((q) => q.maxAsync());
}

extension QueryExecuteStringAggregation<OBJ>
    on QueryBuilder<OBJ, String?, QAfterProperty> {
  String? min() => _withQuery((q) => q.min());

  String? max() => _withQuery((q) => q.max());

  Future<String?> minAsync() => _withQueryAsync((q) => q.minAsync());

  Future<String?> maxAsync() => _withQueryAsync((q) => q.maxAsync());
}
