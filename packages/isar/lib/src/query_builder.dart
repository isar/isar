part of isar;

/// @nodoc
@protected
typedef FilterQuery<OBJ> = QueryBuilder<OBJ, OBJ, QAfterFilterCondition>
    Function(QueryBuilder<OBJ, OBJ, QFilterCondition> q);

const _nullFilterGroup = FilterGroup.and([]);

/// Query builders are used to create queries in a safe way.
///
/// Aquire a `QueryBuilder` instance using `collection.where()` or
/// `collection.filter()`.
class QueryBuilder<OBJ, R, S> {
  final IsarCollection<OBJ> _collection;
  final List<WhereClause> _whereClauses;
  final bool _whereDistinct;
  final Sort _whereSort;
  final FilterGroup _filterOr;
  final FilterGroup? _filterAnd;
  final bool _filterNot;
  final List<DistinctProperty> _distinctByProperties;
  final List<SortProperty> _sortByProperties;
  final int? _offset;
  final int? _limit;
  final String? _propertyName;

  @protected
  QueryBuilder(this._collection, this._whereDistinct, this._whereSort)
      : _whereClauses = const [],
        _distinctByProperties = const [],
        _sortByProperties = const [],
        _filterOr = FilterGroup.or([]),
        _filterAnd = null,
        _filterNot = false,
        _offset = null,
        _limit = null,
        _propertyName = null;

  /// @nodoc
  @protected
  QueryBuilder._(
    this._collection,
    this._filterOr,
    this._filterAnd,
    this._filterNot, [
    this._whereClauses = const [],
    this._whereDistinct = false,
    this._whereSort = Sort.asc,
    this._distinctByProperties = const [],
    this._sortByProperties = const [],
    this._offset,
    this._limit,
    this._propertyName,
  ]);

  /// @nodoc
  @protected
  QueryBuilder<OBJ, R, NS> addFilterConditionInternal<NS>(
      FilterOperation cond) {
    if (_filterNot) {
      cond = FilterGroup.not(cond);
    }

    if (_filterAnd != null) {
      return copyWithInternal(
        filterAnd: FilterGroup.and([..._filterAnd!.filters, cond]),
        filterNot: false,
      );
    } else {
      return copyWithInternal(
        filterOr: FilterGroup.or([..._filterOr.filters, cond]),
        filterNot: false,
      );
    }
  }

  /// @nodoc
  @protected
  QueryBuilder<OBJ, R, NS> addWhereClauseInternal<NS>(WhereClause where) {
    return copyWithInternal(whereClauses: [..._whereClauses, where]);
  }

  /// @nodoc
  @protected
  QueryBuilder<OBJ, R, QAfterFilterOperator> andOrInternal(
      FilterGroupType andOr) {
    if (andOr == FilterGroupType.and) {
      if (_filterAnd == null) {
        return copyWithInternal(
          filterOr: FilterGroup.or(
            _filterOr.filters.sublist(0, _filterOr.filters.length - 1),
          ),
          filterAnd: FilterGroup.and([_filterOr.filters.last]),
        );
      }
    } else if (_filterAnd != null) {
      return copyWithInternal(
        filterOr: FilterGroup.or([..._filterOr.filters, _filterAnd!]),
        filterAnd: null,
      );
    }
    return copyWithInternal();
  }

  /// @nodoc
  @protected
  QueryBuilder<OBJ, R, NS> notInternal<NS>() {
    return copyWithInternal(
      filterNot: !_filterNot,
    );
  }

  /// @nodoc
  @protected
  QueryBuilder<OBJ, R, QAfterFilterCondition> groupInternal(
      FilterQuery<OBJ> q) {
    final qb = q(QueryBuilder(_collection, _whereDistinct, _whereSort));
    final qbFinished = qb.andOrInternal(FilterGroupType.or);

    if (qbFinished._filterOr.filters.isEmpty) {
      return copyWithInternal();
    } else if (qbFinished._filterOr.filters.length == 1) {
      return addFilterConditionInternal(qbFinished._filterOr.filters.first);
    } else {
      return addFilterConditionInternal(qbFinished._filterOr);
    }
  }

  /// @nodoc
  @protected
  QueryBuilder<OBJ, R, QAfterFilterCondition> linkInternal<E>(
    IsarCollection<E> targetCollection,
    FilterQuery<E> q,
    String linkName,
  ) {
    final qb = q(QueryBuilder(targetCollection, false, _whereSort));
    final qbFinished = qb.andOrInternal(FilterGroupType.or);

    final conditions = qbFinished._filterOr.filters;
    if (conditions.isEmpty) {
      return copyWithInternal();
    }

    FilterOperation filter;
    if (conditions.length == 1) {
      filter = conditions[0];
    } else {
      filter = qbFinished._filterOr;
    }
    return addFilterConditionInternal(LinkFilter(
      filter: filter,
      linkName: linkName,
      targetCollection: targetCollection.name,
    ));
  }

  /// @nodoc
  @protected
  QueryBuilder<OBJ, R, NS> addSortByInternal<NS>(
      String propertyName, Sort sort) {
    return copyWithInternal(sortByProperties: [
      ..._sortByProperties,
      SortProperty(property: propertyName, sort: sort),
    ]);
  }

  /// @nodoc
  @protected
  QueryBuilder<OBJ, R, QDistinct> addDistinctByInternal(String propertyName,
      {bool? caseSensitive}) {
    return copyWithInternal(distinctByProperties: [
      ..._distinctByProperties,
      DistinctProperty(property: propertyName, caseSensitive: caseSensitive),
    ]);
  }

  /// @nodoc
  @protected
  QueryBuilder<OBJ, E, QQueryOperations> addPropertyNameInternal<E>(
      String propertyName) {
    return copyWithInternal(propertyName: propertyName).castInternal();
  }

  /// @nodoc
  @protected
  QueryBuilder<OBJ, R, NS> copyWithInternal<NS>({
    List<WhereClause>? whereClauses,
    FilterGroup? filterOr,
    FilterGroup? filterAnd = _nullFilterGroup,
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
    return QueryBuilder._(
      _collection,
      filterOr ?? _filterOr,
      identical(filterAnd, _nullFilterGroup) ? _filterAnd : filterAnd,
      filterNot ?? _filterNot,
      whereClauses ?? List.unmodifiable(_whereClauses),
      _whereDistinct,
      _whereSort,
      distinctByProperties ?? List.unmodifiable(_distinctByProperties),
      sortByProperties ?? List.unmodifiable(_sortByProperties),
      offset ?? _offset,
      limit ?? _limit,
      propertyName ?? _propertyName,
    );
  }

  /// @nodoc
  @protected
  QueryBuilder<OBJ, NR, NS> castInternal<NR, NS>() {
    return QueryBuilder._(
      _collection,
      _filterOr,
      _filterAnd,
      _filterNot,
      _whereClauses,
      _whereDistinct,
      _whereSort,
      _distinctByProperties,
      _sortByProperties,
      _offset,
      _limit,
      _propertyName,
    );
  }

  /// @nodoc
  @protected
  Query<R> buildInternal() {
    final builder = andOrInternal(FilterGroupType.or);
    FilterOperation? filter = builder._filterOr;
    while (filter is FilterGroup) {
      if (filter.filters.isEmpty) {
        filter = null;
      } else if (filter.filters.length == 1 &&
          filter.type != FilterGroupType.not) {
        filter = filter.filters.first;
      } else {
        break;
      }
    }

    return _collection.buildQuery(
      whereDistinct: _whereDistinct,
      whereSort: _whereSort,
      whereClauses: _whereClauses,
      filter: filter,
      sortBy: _sortByProperties,
      distinctBy: _distinctByProperties,
      offset: _offset,
      limit: _limit,
      property: _propertyName,
    );
  }

  /// @nodoc
  @protected
  Isar get isar => _collection.isar;

  /// @nodoc
  @protected
  Sort get whereSortInternal => _whereSort;
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
