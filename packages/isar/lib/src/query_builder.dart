import 'package:isar/isar.dart';

typedef FilterQuery<T> = QueryBuilder<T, QAfterFilterCondition> Function(
    QueryBuilder<T, QFilterCondition> q);

const _NullFilterGroup = FilterGroup(
  type: FilterGroupType.And,
  filters: [],
);

class QueryBuilder<T, S> {
  final IsarCollection _collection;
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

  QueryBuilder(this._collection, this._whereDistinct, this._whereSort)
      : _whereClauses = const [],
        _distinctByProperties = const [],
        _sortByProperties = const [],
        _filterOr = FilterGroup(filters: [], type: FilterGroupType.Or),
        _filterAnd = null,
        _filterNot = false,
        _offset = null,
        _limit = null,
        _propertyName = null;

  QueryBuilder._(
    this._collection,
    this._filterOr,
    this._filterAnd,
    this._filterNot, [
    this._whereClauses = const [],
    this._whereDistinct = false,
    this._whereSort = Sort.Asc,
    this._distinctByProperties = const [],
    this._sortByProperties = const [],
    this._offset,
    this._limit,
    this._propertyName,
  ]);
}

extension QueryBuilderInternal<T> on QueryBuilder<T, dynamic> {
  QueryBuilder<T, S> addFilterCondition<S>(FilterOperation cond) {
    if (_filterNot) {
      cond = FilterNot(filter: cond);
    }

    if (_filterAnd != null) {
      return copyWith(
        filterAnd: FilterGroup(
          filters: [..._filterAnd!.filters, cond],
          type: FilterGroupType.And,
        ),
        filterNot: false,
      );
    } else {
      return copyWith(
        filterOr: FilterGroup(
          filters: [..._filterOr.filters, cond],
          type: FilterGroupType.Or,
        ),
        filterNot: false,
      );
    }
  }

  QueryBuilder<T, S> addWhereClause<S>(WhereClause where) {
    return copyWith(whereClauses: [..._whereClauses, where]);
  }

  QueryBuilder<T, QAfterFilterOperator> andOrInternal(FilterGroupType andOr) {
    if (andOr == FilterGroupType.And) {
      if (_filterAnd == null) {
        return copyWith(
          filterOr: FilterGroup(
            type: FilterGroupType.Or,
            filters: _filterOr.filters.sublist(0, _filterOr.filters.length - 1),
          ),
          filterAnd: FilterGroup(
            type: FilterGroupType.And,
            filters: [_filterOr.filters.last],
          ),
        );
      }
    } else if (_filterAnd != null) {
      return copyWith(
        filterOr: FilterGroup(
          filters: [..._filterOr.filters, _filterAnd!],
          type: FilterGroupType.Or,
        ),
        filterAnd: null,
      );
    }
    return copyWith();
  }

  QueryBuilder<T, S> notInternal<S>() {
    return copyWith(
      filterNot: !_filterNot,
    );
  }

  QueryBuilder<T, QAfterFilterCondition> groupInternal(FilterQuery<T> q) {
    final qb = q(QueryBuilder(_collection, _whereDistinct, _whereSort));
    final qbFinished = qb.andOrInternal(FilterGroupType.Or);

    if (qbFinished._filterOr.filters.isEmpty) {
      return copyWith();
    } else if (qbFinished._filterOr.filters.length == 1) {
      return addFilterCondition(qbFinished._filterOr.filters.first);
    } else {
      return addFilterCondition(qbFinished._filterOr);
    }
  }

  QueryBuilder<T, QAfterFilterCondition> linkInternal<E>(
    IsarCollection<E> targetCollection,
    FilterQuery<E> q,
    String linkName,
  ) {
    final qb = q(QueryBuilder(targetCollection, false, _whereSort));
    final qbFinished = qb.andOrInternal(FilterGroupType.Or);

    final conditions = qbFinished._filterOr.filters;
    if (conditions.isEmpty) {
      return copyWith();
    }

    FilterOperation filter;
    if (conditions.length == 1) {
      filter = conditions[0];
    } else {
      filter = qbFinished._filterOr;
    }
    return addFilterCondition(LinkFilter(
      targetCollection: targetCollection,
      filter: filter,
      linkName: linkName,
    ));
  }

  QueryBuilder<T, S> addSortByInternal<S>(String propertyName, Sort sort) {
    return copyWith(sortByProperties: [
      ..._sortByProperties,
      SortProperty(property: propertyName, sort: sort),
    ]);
  }

  QueryBuilder<T, QDistinct> addDistinctByInternal(String propertyName,
      {bool? caseSensitive}) {
    return copyWith(distinctByProperties: [
      ..._distinctByProperties,
      DistinctProperty(property: propertyName, caseSensitive: caseSensitive),
    ]);
  }

  QueryBuilder<E, QQueryOperations> addPropertyName<E>(String propertyName) {
    return copyWith(propertyName: propertyName);
  }

  QueryBuilder<E, S> copyWith<E, S>({
    List<WhereClause>? whereClauses,
    FilterGroup? filterOr,
    FilterGroup? filterAnd = _NullFilterGroup,
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
      identical(filterAnd, _NullFilterGroup) ? _filterAnd : filterAnd,
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

  QueryBuilder<T, S> cast<S>() {
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

  Query<T> buildInternal() {
    final builder = andOrInternal(FilterGroupType.Or);
    FilterGroup? filter;
    if (builder._filterOr.filters.length == 1) {
      final group = builder._filterOr.filters.first;
      if (group is FilterGroup) {
        filter = group;
      }
    }
    filter ??= builder._filterOr;

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

  Isar get isar => _collection.isar;
}

// Right after query starts
class QWhere
    implements
        QWhereClause,
        QFilter,
        QSortBy,
        QDistinct,
        QOffset,
        QLimit,
        QQueryProperty {}

// No more where conditions are allowed
class QAfterWhere
    implements QFilter, QSortBy, QDistinct, QOffset, QLimit, QQueryProperty {}

class QWhereClause {}

class QAfterWhereClause
    implements
        QWhereOr,
        QFilter,
        QSortBy,
        QDistinct,
        QOffset,
        QLimit,
        QQueryProperty {}

class QWhereOr {}

class QFilter {}

class QFilterCondition {}

class QAfterFilterCondition
    implements
        QFilterCondition,
        QFilterOperator,
        QSortBy,
        QDistinct,
        QOffset,
        QLimit,
        QQueryProperty {}

class QFilterOperator {}

class QAfterFilterOperator implements QFilterCondition {}

class QSortBy {}

class QAfterSortBy
    implements QSortThenBy, QDistinct, QOffset, QLimit, QQueryProperty {}

class QSortThenBy {}

class QDistinct implements QOffset, QLimit, QQueryProperty {}

class QOffset {}

class QAfterOffset implements QLimit, QQueryProperty {}

class QLimit {}

class QAfterLimit implements QQueryProperty {}

class QQueryProperty implements QQueryOperations {}

class QQueryOperations {}

enum AggregationOp {
  Min,
  Max,
  Sum,
  Average,
  Count,
}
