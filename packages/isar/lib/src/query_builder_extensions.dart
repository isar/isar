part of isar;

extension QueryWhereOr<OBJ> on QueryBuilder<OBJ, QWhereOr> {
  QueryBuilder<OBJ, QWhereClause> or() {
    return copyWith();
  }
}

extension QueryFilter<OBJ> on QueryBuilder<OBJ, QFilter> {
  QueryBuilder<OBJ, QFilterCondition> filter() {
    return copyWith();
  }
}

extension QueryFilterAndOr<OBJ> on QueryBuilder<OBJ, QFilterOperator> {
  QueryBuilder<OBJ, QFilterCondition> and() {
    return andOrInternal(FilterGroupType.And);
  }

  QueryBuilder<OBJ, QFilterCondition> or() {
    return andOrInternal(FilterGroupType.Or);
  }
}

extension QueryFilterNot<OBJ> on QueryBuilder<OBJ, QFilterCondition> {
  QueryBuilder<OBJ, QFilterCondition> not() {
    return notInternal();
  }
}

extension QueryFilterNoGroups<OBJ> on QueryBuilder<OBJ, QFilterCondition> {
  QueryBuilder<OBJ, QAfterFilterCondition> group(FilterQuery<OBJ> q) {
    return groupInternal(q);
  }
}

extension QueryOffset<OBJ> on QueryBuilder<OBJ, QOffset> {
  QueryBuilder<OBJ, QAfterOffset> offset(int offset) {
    return copyWith(offset: offset);
  }
}

extension QueryLimit<OBJ> on QueryBuilder<OBJ, QLimit> {
  QueryBuilder<OBJ, QAfterLimit> limit(int limit) {
    return copyWith(limit: limit);
  }
}

typedef QueryOption<OBJ, T, R> = QueryBuilder<OBJ, R> Function(
    QueryBuilder<OBJ, T> q);

extension QueryOptional<OBJ, T> on QueryBuilder<OBJ, T> {
  QueryBuilder<OBJ, R> optional<R>(
      bool enabled, QueryOption<OBJ, T, R> option) {
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

extension QueryExecute<OBJ> on QueryBuilder<OBJ, QQueryOperations> {
  Query<OBJ> build() {
    return buildInternal();
  }

  Future<OBJ?> findFirst() {
    return build().findFirst();
  }

  OBJ? findFirstSync() {
    return build().findFirstSync();
  }

  Future<List<OBJ>> findAll() {
    return build().findAll();
  }

  List<OBJ> findAllSync() {
    return build().findAllSync();
  }

  Future<int> count() {
    return build().count();
  }

  int countSync() {
    return build().countSync();
  }

  Future<bool> deleteFirst() {
    return build().deleteFirst();
  }

  bool deleteFirstSync() {
    return build().deleteFirstSync();
  }

  Future<int> deleteAll() {
    return build().deleteAll();
  }

  int deleteAllSync() {
    return build().deleteAllSync();
  }

  Stream<List<OBJ>> watch({bool initialReturn = false}) {
    return build().watch(initialReturn: initialReturn);
  }

  Stream<void> watchLazy() {
    return build().watchLazy();
  }
}
