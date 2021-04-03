part of isar;

extension QueryWhereOr<OBJ, T> on QueryBuilder<T, QWhereOr> {
  QueryBuilder<T, QWhereClause> or() {
    return copyWith();
  }
}

extension QueryFilter<OBJ, T> on QueryBuilder<T, QFilter> {
  QueryBuilder<T, QFilterCondition> filter() {
    return copyWith();
  }
}

extension QueryFilterAndOr<OBJ, T> on QueryBuilder<T, QFilterOperator> {
  QueryBuilder<T, QFilterCondition> and() {
    return andOrInternal(FilterGroupType.And);
  }

  QueryBuilder<T, QFilterCondition> or() {
    return andOrInternal(FilterGroupType.Or);
  }
}

extension QueryFilterNot<OBJ, T> on QueryBuilder<T, QFilterCondition> {
  QueryBuilder<T, QFilterCondition> not() {
    return notInternal();
  }
}

extension QueryFilterNoGroups<OBJ, T> on QueryBuilder<T, QFilterCondition> {
  QueryBuilder<T, QAfterFilterCondition> group(FilterQuery<T> q) {
    return groupInternal(q);
  }
}

extension QueryOffset<OBJ, T> on QueryBuilder<T, QOffset> {
  QueryBuilder<T, QAfterOffset> offset(int offset) {
    return copyWith(offset: offset);
  }
}

extension QueryLimit<OBJ, T> on QueryBuilder<T, QLimit> {
  QueryBuilder<T, QAfterLimit> limit(int limit) {
    return copyWith(limit: limit);
  }
}

typedef QueryOption<T, S, R> = QueryBuilder<T, R> Function(
    QueryBuilder<T, S> q);

extension QueryOptional<T, S> on QueryBuilder<T, S> {
  QueryBuilder<T, R> optional<R>(bool enabled, QueryOption<T, S, R> option) {
    if (enabled) {
      return option(this);
    } else {
      return cast();
    }
  }
}

typedef QueryRepeatModifier<OBJ, T, R, E> = QueryBuilder<OBJ, R> Function(
    QueryBuilder<OBJ, T> q, E element);

extension QueryRepeat<OBJ, T> on QueryBuilder<OBJ, T> {
  QueryBuilder<OBJ, R> repeat<E, R>(
      Iterable<E> items, QueryRepeatModifier<OBJ, T, R, E> modifier) {
    QueryBuilder<OBJ, R>? q;
    for (var e in items) {
      q = modifier((q ?? this).cast(), e);
    }
    return q ?? cast();
  }
}

extension QueryExecute<T> on QueryBuilder<T, QQueryOperations> {
  Query<T> build() => buildInternal();

  Future<T?> findFirst() => build().findFirst();

  T? findFirstSync() => build().findFirstSync();

  Future<List<T>> findAll() => build().findAll();

  List<T> findAllSync() => build().findAllSync();

  Future<int> count() => build().count();

  int countSync() => build().countSync();

  Future<bool> deleteFirst() => build().deleteFirst();

  bool deleteFirstSync() => build().deleteFirstSync();

  Future<int> deleteAll() => build().deleteAll();

  int deleteAllSync() => build().deleteAllSync();

  Stream<List<T>> watch({bool initialReturn = false}) =>
      build().watch(initialReturn: initialReturn);

  Stream<void> watchLazy() => build().watchLazy();
}

extension QueryExecuteAggregation<T extends num?>
    on QueryBuilder<T, QQueryOperations> {
  Future<T> min() => build().min();

  T minSync() => build().minSync();

  Future<T> max() => build().max();

  T maxSync() => build().maxSync();

  Future<T> average() => build().average();

  T averageSync() => build().averageSync();

  Future<T> sum() => build().sum();

  T sumSync() => build().sumSync();
}
