part of isar;

extension QueryWhereOr<OBJECT> on QueryBuilder<OBJECT, QWhereProperty, dynamic,
    dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, QNoWhere, dynamic, dynamic, dynamic, dynamic, dynamic>
      or() {
    return clone();
  }
}

extension QueryFilter<OBJECT> on QueryBuilder<OBJECT, dynamic, QCanFilter,
    dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      filter() {
    return clone();
  }
}

extension QueryFilterAndOr<OBJECT, GROUPS> on QueryBuilder<OBJECT, dynamic,
    QFilterAfterCond, GROUPS, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      and() {
    return andOrInternal(FilterGroupType.And);
  }

  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      or() {
    return andOrInternal(FilterGroupType.Or);
  }
}

extension QueryFilterNot<OBJECT> on QueryBuilder<OBJECT, dynamic, QFilter,
    dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      not() {
    return notInternal();
  }
}

extension QueryFilterNoGroups<OBJECT> on QueryBuilder<OBJECT, dynamic, QFilter,
    dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      beginGroup() {
    return beginGroupInternal();
  }
}

extension QueryFilterOneGroupsEnd<OBJECT> on QueryBuilder<OBJECT, dynamic,
    QFilterAfterCond, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, dynamic, QFilterAfterCond, QCanGroupBy, QCanOffsetLimit,
      QCanSort, QCanExecute> endGroup() {
    return endGroupInternal();
  }
}

extension QueryExecute<OBJECT> on QueryBuilder<OBJECT, dynamic, dynamic,
    dynamic, dynamic, dynamic, QCanExecute> {
  Query<OBJECT> build() {
    return buildInternal();
  }

  Future<OBJECT?> findFirst() {
    return build().findFirst();
  }

  OBJECT? findFirstSync() {
    return build().findFirstSync();
  }

  Future<List<OBJECT>> findAll() {
    return build().findAll();
  }

  List<OBJECT> findAllSync() {
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

  Stream<List<OBJECT>?> watch({bool lazy = true}) {
    return build().watch(lazy: lazy);
  }
}
