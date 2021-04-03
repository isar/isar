import 'package:isar/isar.dart';
import 'package:isar/src/isar_platform.dart';

typedef FilterQuery<T> = QueryBuilder<T, QAfterFilterCondition> Function(
    QueryBuilder<T, QFilterCondition> q);

const _NullFilterGroup = FilterGroup();

class QueryBuilder<T, S> {
  final IsarCollection _collection;
  final List<WhereClause> _whereClauses;
  final bool? _whereDistinct;
  final bool? _whereAscending;
  final FilterGroup _filterOr;
  final FilterGroup? _filterAnd;
  final bool _filterNot;
  final List<DistinctProperty> _distinctByPropertyIndices;
  final List<SortProperty> _sortByProperties;
  final int? _offset;
  final int? _limit;
  final int? _propertyIndex;

  QueryBuilder(this._collection, this._whereDistinct, this._whereAscending)
      : _whereClauses = const [],
        _distinctByPropertyIndices = const [],
        _sortByProperties = const [],
        _filterOr = FilterGroup(groupType: FilterGroupType.Or),
        _filterAnd = null,
        _filterNot = false,
        _offset = null,
        _limit = null,
        _propertyIndex = null;

  QueryBuilder._(
    this._collection,
    this._filterOr,
    this._filterAnd,
    this._filterNot, [
    this._whereClauses = const [],
    this._whereDistinct,
    this._whereAscending,
    this._distinctByPropertyIndices = const [],
    this._sortByProperties = const [],
    this._offset,
    this._limit,
    this._propertyIndex,
  ]);
}

extension QueryBuilderInternal<T> on QueryBuilder<T, dynamic> {
  QueryBuilder<T, S> addFilterCondition<S>(QueryOperation cond) {
    if (_filterNot) {
      cond = FilterGroup(groupType: FilterGroupType.Not, conditions: [cond]);
    }

    if (_filterAnd != null) {
      return copyWith(
        filterAnd: _filterAnd!.copyWith(
          conditions: [..._filterAnd!.conditions, cond],
        ),
        filterNot: false,
      );
    } else {
      return copyWith(
        filterOr: _filterOr.copyWith(
          conditions: [..._filterOr.conditions, cond],
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
          filterOr: _filterOr.copyWith(
            conditions: _filterOr.conditions
                .sublist(0, _filterOr.conditions.length - 1),
          ),
          filterAnd: FilterGroup(
            groupType: FilterGroupType.And,
            conditions: [_filterOr.conditions.last],
          ),
        );
      }
    } else if (_filterAnd != null) {
      return copyWith(
        filterOr: _filterOr
            .copyWith(conditions: [..._filterOr.conditions, _filterAnd!]),
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
    final qb = q(QueryBuilder(_collection, _whereDistinct, _whereAscending));
    final qbFinished = qb.andOrInternal(FilterGroupType.Or);

    if (qbFinished._filterOr.conditions.isEmpty) {
      return copyWith();
    } else if (qbFinished._filterOr.conditions.length == 1) {
      return addFilterCondition(qbFinished._filterOr.conditions.first);
    } else {
      return addFilterCondition(qbFinished._filterOr);
    }
  }

  QueryBuilder<T, QAfterFilterCondition> linkInternal<E>(
      IsarCollection<E> targetCollection,
      FilterQuery<E> q,
      int linkIndex,
      bool backlink) {
    final qb = q(QueryBuilder(targetCollection, false, true));
    final qbFinished = qb.andOrInternal(FilterGroupType.Or);

    final conditions = qbFinished._filterOr.conditions;
    if (conditions.isEmpty) {
      return copyWith();
    }

    QueryOperation filter;
    if (conditions.length == 1) {
      filter = conditions[0];
    } else {
      filter = qbFinished._filterOr;
    }
    return addFilterCondition(LinkOperation(
      targetCollection,
      filter,
      linkIndex,
      backlink,
    ));
  }

  QueryBuilder<T, QDistinct> addDistinctByInternal(int propertyIndex,
      {bool? caseSensitive}) {
    return copyWith(distinctByPropertyIndices: [
      ..._distinctByPropertyIndices,
      DistinctProperty(propertyIndex, caseSensitive),
    ]);
  }

  QueryBuilder<E, QQueryOperations> addPropertyIndex<E>(int propertyIndex) {
    return copyWith(propertyIndex: propertyIndex);
  }

  QueryBuilder<E, S> copyWith<E, S>({
    List<WhereClause>? whereClauses,
    FilterGroup? filterOr,
    FilterGroup? filterAnd = _NullFilterGroup,
    bool? filterNot,
    List<FilterGroup>? parentFilters,
    List<DistinctProperty>? distinctByPropertyIndices,
    List<SortProperty>? sortByProperties,
    int? offset,
    int? limit,
    int? propertyIndex,
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
      _whereAscending,
      distinctByPropertyIndices ??
          List.unmodifiable(_distinctByPropertyIndices),
      sortByProperties ?? List.unmodifiable(_sortByProperties),
      offset ?? _offset,
      limit ?? _limit,
      propertyIndex ?? _propertyIndex,
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
      _whereAscending,
      _distinctByPropertyIndices,
      _sortByProperties,
      _offset,
      _limit,
      _propertyIndex,
    );
  }

  Query<T> buildInternal() {
    final builder = andOrInternal(FilterGroupType.Or);
    FilterGroup? filter;
    if (builder._filterOr.conditions.length == 1) {
      final group = builder._filterOr.conditions.first;
      if (group is FilterGroup) {
        filter = group;
      }
    }
    filter ??= builder._filterOr;
    return buildQuery(
      _collection,
      _whereClauses,
      _whereDistinct,
      _whereAscending,
      filter,
      _sortByProperties,
      _distinctByPropertyIndices,
      _offset,
      _limit,
      _propertyIndex,
    );
  }

  Isar get isar => _collection.isar;
}

class WhereClause {
  final int? index;
  final List<String> types;
  final List? lower;
  final bool includeLower;
  final List? upper;
  final bool includeUpper;

  const WhereClause(
    this.index,
    this.types, {
    this.lower,
    this.includeLower = true,
    this.upper,
    this.includeUpper = true,
  });

  WhereClause clone() {
    return WhereClause(
      index,
      types,
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
    );
  }
}

abstract class QueryOperation {
  const QueryOperation();

  QueryOperation clone();
}

class QueryCondition extends QueryOperation {
  final ConditionType conditionType;
  final int propertyIndex;
  final String propertyType;
  final dynamic? lower;
  final bool includeLower;
  final dynamic? upper;
  final bool includeUpper;
  final bool caseSensitive;

  const QueryCondition(
    this.conditionType,
    this.propertyIndex,
    this.propertyType, {
    this.lower,
    this.includeLower = true,
    this.upper,
    this.includeUpper = true,
    this.caseSensitive = true,
  });

  @override
  QueryCondition clone() {
    return QueryCondition(
      conditionType,
      propertyIndex,
      propertyType,
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
    );
  }
}

enum ConditionType {
  Eq,
  Gt,
  Lt,
  StartsWith,
  EndsWith,
  Contains,
  Between,
  Matches
}

enum FilterGroupType {
  And,
  Or,
  Not,
}

class FilterGroup extends QueryOperation {
  final List<QueryOperation> conditions;
  final FilterGroupType? groupType;

  const FilterGroup({
    this.conditions = const [],
    this.groupType,
  });

  @override
  FilterGroup clone() {
    return FilterGroup(
      conditions: conditions.map((e) => e.clone()).toList(),
      groupType: groupType,
    );
  }

  FilterGroup copyWith(
      {List<QueryOperation>? conditions, FilterGroupType? groupType}) {
    return FilterGroup(
      conditions: conditions ?? this.conditions.map((e) => e.clone()).toList(),
      groupType: groupType ?? this.groupType,
    );
  }
}

class SortProperty {
  final int propertyIndex;
  final bool ascending;

  const SortProperty(this.propertyIndex, this.ascending);
}

class DistinctProperty {
  final int propertyIndex;
  final bool? caseSensitive;

  const DistinctProperty(this.propertyIndex, this.caseSensitive);
}

class LinkOperation extends QueryOperation {
  final IsarCollection targetCollection;
  final QueryOperation filter;
  final int linkIndex;
  final bool backlink;

  const LinkOperation(
      this.targetCollection, this.filter, this.linkIndex, this.backlink);

  @override
  QueryOperation clone() {
    return LinkOperation(targetCollection, filter, linkIndex, backlink);
  }
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
