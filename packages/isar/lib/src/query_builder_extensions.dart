part of isar;

extension QueryWhereOr<OBJ, R> on QueryBuilder<OBJ, R, QWhereOr> {
  QueryBuilder<OBJ, R, QWhereClause> or() {
    return copyWith();
  }
}

extension QueryFilter<OBJ, R> on QueryBuilder<OBJ, R, QFilter> {
  QueryBuilder<OBJ, R, QFilterCondition> filter() {
    return copyWith();
  }
}

extension QueryFilterAndOr<OBJ, R> on QueryBuilder<OBJ, R, QFilterOperator> {
  QueryBuilder<OBJ, R, QFilterCondition> and() {
    return andOrInternal(FilterGroupType.And);
  }

  QueryBuilder<OBJ, R, QFilterCondition> or() {
    return andOrInternal(FilterGroupType.Or);
  }
}

extension QueryFilterNot<OBJ, R> on QueryBuilder<OBJ, R, QFilterCondition> {
  QueryBuilder<OBJ, R, QFilterCondition> not() {
    return notInternal();
  }
}

extension QueryFilterNoGroups<OBJ, R>
    on QueryBuilder<OBJ, R, QFilterCondition> {
  QueryBuilder<OBJ, R, QAfterFilterCondition> group(FilterQuery<OBJ> q) {
    return groupInternal(q);
  }
}

extension QueryOffset<OBJ, R> on QueryBuilder<OBJ, R, QOffset> {
  QueryBuilder<OBJ, R, QAfterOffset> offset(int offset) {
    return copyWith(offset: offset);
  }
}

extension QueryLimit<OBJ, R> on QueryBuilder<OBJ, R, QLimit> {
  QueryBuilder<OBJ, R, QAfterLimit> limit(int limit) {
    return copyWith(limit: limit);
  }
}

typedef QueryOption<OBJ, S, RS> = QueryBuilder<OBJ, OBJ, RS> Function(
    QueryBuilder<OBJ, OBJ, S> q);

extension QueryOptional<OBJ, S> on QueryBuilder<OBJ, OBJ, S> {
  QueryBuilder<OBJ, OBJ, RS> optional<RS>(
      bool enabled, QueryOption<OBJ, S, RS> option) {
    if (enabled) {
      return option(this);
    } else {
      return cast();
    }
  }
}

typedef QueryRepeatModifier<OBJ, S, RS, E> = QueryBuilder<OBJ, OBJ, RS>
    Function(QueryBuilder<OBJ, OBJ, S> q, E element);

extension QueryRepeat<OBJ, S> on QueryBuilder<OBJ, OBJ, S> {
  QueryBuilder<OBJ, OBJ, RS> repeat<E, RS>(
      Iterable<E> items, QueryRepeatModifier<OBJ, S, RS, E> modifier) {
    QueryBuilder<OBJ, OBJ, RS>? q;
    for (var e in items) {
      q = modifier((q ?? this).cast(), e);
    }
    return q ?? cast();
  }
}

extension QueryExecute<OBJ, R> on QueryBuilder<OBJ, R, QQueryOperations> {
  Query<R> build() => buildInternal();

  Future<R?> findFirst() => build().findFirst();

  R? findFirstSync() => build().findFirstSync();

  Future<List<R>> findAll() => build().findAll();

  List<R> findAllSync() => build().findAllSync();

  Future<int> count() => build().count();

  int? countSync() => build().countSync();

  Future<bool> deleteFirst() => build().deleteFirst();

  bool deleteFirstSync() => build().deleteFirstSync();

  Future<int> deleteAll() => build().deleteAll();

  int deleteAllSync() => build().deleteAllSync();

  Stream<List<R>> watch({bool initialReturn = false}) =>
      build().watch(initialReturn: initialReturn);

  Stream<void> watchLazy() => build().watchLazy();

  Future<R> exportJsonRaw<R>(R Function(Uint8List) callback,
          {bool primitiveNull = true}) =>
      build().exportJsonRaw(callback, primitiveNull: primitiveNull);

  Future<List<Map<String, dynamic>>> exportJson({bool primitiveNull = true}) =>
      build().exportJson(primitiveNull: primitiveNull);
}

extension QueryExecuteAggregation<OBJ, T extends num>
    on QueryBuilder<OBJ, T?, QQueryOperations> {
  Future<T?> min() => build().min();

  T? minSync() => build().minSync();

  Future<T?> max() => build().max();

  T? maxSync() => build().maxSync();

  Future<double> average() => build().average();

  double averageSync() => build().averageSync();

  Future<T> sum() => build().sum();

  T sumSync() => build().sumSync();
}

extension QueryExecuteDateAggregation<OBJ>
    on QueryBuilder<OBJ, DateTime?, QQueryOperations> {
  Future<DateTime?> min() => build().min();

  DateTime? minSync() => build().minSync();

  Future<DateTime?> max() => build().max();

  DateTime? maxSync() => build().maxSync();
}
