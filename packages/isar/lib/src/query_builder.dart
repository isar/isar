part of isar;

/// @nodoc
@protected
typedef FilterQuery<OBJ> = QueryBuilder<OBJ, OBJ, QAfterFilterCondition>
    Function(QueryBuilder<OBJ, OBJ, QFilterCondition> q);

/// Query builders are used to create queries in a safe way.
///
/// Aquire a `QueryBuilder` instance using `collection.where()` or
/// `collection.filter()`.
class QueryBuilder<OBJ, R, S> {
  final QueryBuilderInternal<OBJ> _query;

  /// @nodoc
  @protected
  QueryBuilder(this._query);

  /// @nodoc
  @protected
  static QueryBuilder<OBJ, R, S> apply<OBJ, R, S>(
      QueryBuilder<OBJ, dynamic, dynamic> qb,
      QueryBuilderInternal<OBJ> Function(QueryBuilderInternal<OBJ> query)
          transform) {
    return QueryBuilder(transform(qb._query));
  }
}

/// @nodoc
@protected
class QueryBuilderInternal<OBJ> {
  final IsarCollection<OBJ> collection;
  final List<WhereClause> whereClauses;
  final bool whereDistinct;
  final Sort whereSort;
  final FilterGroup filter;
  final FilterGroupType filterGroupType;
  final bool filterNot;
  final List<DistinctProperty> distinctByProperties;
  final List<SortProperty> sortByProperties;
  final int? offset;
  final int? limit;
  final String? propertyName;

  const QueryBuilderInternal({
    required this.collection,
    this.whereClauses = const [],
    this.whereDistinct = false,
    this.whereSort = Sort.asc,
    this.filter = const FilterGroup.and([]),
    this.filterGroupType = FilterGroupType.and,
    this.filterNot = false,
    this.distinctByProperties = const [],
    this.sortByProperties = const [],
    this.offset,
    this.limit,
    this.propertyName,
  });

  QueryBuilderInternal<OBJ> addFilterCondition(FilterOperation cond) {
    if (filterNot) {
      cond = FilterGroup.not(cond);
    }

    late FilterGroup filterGroup;

    if (filter.type == filterGroupType || filter.filters.length <= 1) {
      filterGroup = FilterGroup(
        type: filterGroupType,
        filters: [...filter.filters, cond],
      );
    } else if (filterGroupType == FilterGroupType.and) {
      filterGroup = FilterGroup(
        type: filter.type,
        filters: [
          ...filter.filters.sublist(0, filter.filters.length - 1),
          FilterGroup(
            type: filterGroupType,
            filters: [filter.filters.last, cond],
          ),
        ],
      );
    } else {
      filterGroup = FilterGroup(
        type: filterGroupType,
        filters: [filter, cond],
      );
    }

    return copyWith(
      filter: filterGroup,
      filterGroupType: FilterGroupType.and,
      filterNot: false,
    );
  }

  QueryBuilderInternal<OBJ> addWhereClause(WhereClause where) {
    return copyWith(whereClauses: [...whereClauses, where]);
  }

  QueryBuilderInternal<OBJ> group(FilterQuery<OBJ> q) {
    final internalQb = QueryBuilderInternal(collection: collection);
    final qb = q(QueryBuilder(internalQb));
    return addFilterCondition(qb._query.filter);
  }

  QueryBuilderInternal<OBJ> link<E>(
    IsarCollection<E> targetCollection,
    FilterQuery<E> q,
    String linkName,
  ) {
    final internalQb = QueryBuilderInternal(collection: targetCollection);
    final qb = q(QueryBuilder(internalQb));
    return addFilterCondition(
      LinkFilter(
        filter: qb._query.filter,
        linkName: linkName,
        targetCollection: targetCollection.name,
      ),
    );
  }

  QueryBuilderInternal<OBJ> addSortBy(String propertyName, Sort sort) {
    return copyWith(
      sortByProperties: [
        ...sortByProperties,
        SortProperty(property: propertyName, sort: sort),
      ],
    );
  }

  QueryBuilderInternal<OBJ> addDistinctBy(String propertyName,
      {bool? caseSensitive}) {
    return copyWith(
      distinctByProperties: [
        ...distinctByProperties,
        DistinctProperty(
          property: propertyName,
          caseSensitive: caseSensitive,
        ),
      ],
    );
  }

  QueryBuilderInternal<OBJ> addPropertyName<E>(String propertyName) {
    return copyWith(propertyName: propertyName);
  }

  QueryBuilderInternal<OBJ> copyWith({
    List<WhereClause>? whereClauses,
    FilterGroup? filter,
    bool? filterIsGrouped,
    FilterGroupType? filterGroupType,
    bool? filterNot,
    List<FilterGroup>? parentFilters,
    List<DistinctProperty>? distinctByProperties,
    List<SortProperty>? sortByProperties,
    int? offset,
    int? limit,
    String? propertyName,
  }) {
    assert(offset == null || offset >= 0);
    assert(limit == null || limit >= 0);
    return QueryBuilderInternal(
      collection: collection,
      whereClauses: whereClauses ?? List.unmodifiable(this.whereClauses),
      whereDistinct: whereDistinct,
      whereSort: whereSort,
      filter: filter ?? this.filter,
      filterGroupType: filterGroupType ?? this.filterGroupType,
      filterNot: filterNot ?? this.filterNot,
      distinctByProperties:
          distinctByProperties ?? List.unmodifiable(this.distinctByProperties),
      sortByProperties:
          sortByProperties ?? List.unmodifiable(this.sortByProperties),
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      propertyName: propertyName ?? this.propertyName,
    );
  }

  /// @nodoc
  @protected
  Query<R> build<R>() {
    return collection.buildQuery(
      whereDistinct: whereDistinct,
      whereSort: whereSort,
      whereClauses: whereClauses,
      filter: filter,
      sortBy: sortByProperties,
      distinctBy: distinctByProperties,
      offset: offset,
      limit: limit,
      property: propertyName,
    );
  }
}

/// @nodoc
///
/// Right after query starts
@protected
class QWhere
    implements
        QWhereClause,
        QFilter,
        QSortBy,
        QDistinct,
        QOffset,
        QLimit,
        QQueryProperty {}

/// @nodoc
///
/// No more where conditions are allowed
@protected
class QAfterWhere
    implements QFilter, QSortBy, QDistinct, QOffset, QLimit, QQueryProperty {}

/// @nodoc
@protected
class QWhereClause {}

/// @nodoc
@protected
class QAfterWhereClause
    implements
        QWhereOr,
        QFilter,
        QSortBy,
        QDistinct,
        QOffset,
        QLimit,
        QQueryProperty {}

/// @nodoc
@protected
class QWhereOr {}

/// @nodoc
@protected
class QFilter {}

/// @nodoc
@protected
class QFilterCondition {}

/// @nodoc
@protected
class QAfterFilterCondition
    implements
        QFilterCondition,
        QFilterOperator,
        QSortBy,
        QDistinct,
        QOffset,
        QLimit,
        QQueryProperty {}

/// @nodoc
@protected
class QFilterOperator {}

/// @nodoc
@protected
class QAfterFilterOperator implements QFilterCondition {}

/// @nodoc
@protected
class QSortBy {}

/// @nodoc
@protected
class QAfterSortBy
    implements QSortThenBy, QDistinct, QOffset, QLimit, QQueryProperty {}

/// @nodoc
@protected
class QSortThenBy {}

/// @nodoc
@protected
class QDistinct implements QOffset, QLimit, QQueryProperty {}

/// @nodoc
@protected
class QOffset {}

/// @nodoc
@protected
class QAfterOffset implements QLimit, QQueryProperty {}

/// @nodoc
@protected
class QLimit {}

/// @nodoc
@protected
class QAfterLimit implements QQueryProperty {}

/// @nodoc
@protected
class QQueryProperty implements QQueryOperations {}

/// @nodoc
@protected
class QQueryOperations {}
