import 'package:isar/isar.dart';
import 'package:isar/isar_native.dart';

class QueryBuilder<OBJECT, WHERE, FILTER, DISTINCT_BY, OFFSET_LIMIT, SORT,
    EXECUTE> {
  final IsarCollection<dynamic, OBJECT> _collection;
  final List<WhereClause> _whereClauses;
  final bool? _whereDistinct;
  final bool? _whereAscending;
  final FilterGroup _filter;
  final List<FilterGroup> _parentFilters;
  final List<int> _distinctByPropertyIndices;
  final List<SortProperty> _sortByProperties;
  final int? _offset;
  final int? _limit;

  QueryBuilder(this._collection, this._whereDistinct, this._whereAscending)
      : _whereClauses = const [],
        _distinctByPropertyIndices = const [],
        _sortByProperties = const [],
        _filter = FilterGroup(groupType: FilterGroupType.And, implicit: false),
        _parentFilters = [],
        _offset = null,
        _limit = null;

  QueryBuilder._(
    this._collection,
    this._filter,
    this._parentFilters, [
    this._whereClauses = const [],
    this._whereDistinct,
    this._whereAscending,
    this._distinctByPropertyIndices = const [],
    this._sortByProperties = const [],
    this._offset,
    this._limit,
  ]);
}

extension QueryBuilderInternal<OBJECT> on QueryBuilder<OBJECT, dynamic, dynamic,
    dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, B, C, D, E, F, G> addFilterCondition<B, C, D, E, F, G>(
      QueryCondition cond) {
    var cloned = copyWith<B, C, D, E, F, G>(
      filter: _filter.copyWith(conditions: [..._filter.conditions, cond]),
    );
    if (cloned._filter.groupType == FilterGroupType.Not) {
      cloned = cloned.endGroupInternal();
    }
    return cloned;
  }

  QueryBuilder<OBJECT, B, C, D, E, F, G> addWhereClause<B, C, D, E, F, G, H>(
      WhereClause where) {
    return copyWith(whereClauses: [..._whereClauses, where]);
  }

  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      andOrInternal(FilterGroupType andOr) {
    if (_filter.groupType == null || _filter.groupType == andOr) {
      return copyWith(filter: _filter.copyWith(groupType: andOr));
    } else {
      return copyWith(
        parentFilters: [..._parentFilters, _filter],
        filter: FilterGroup(implicit: true, groupType: andOr),
      );
    }
  }

  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      notInternal() {
    return copyWith(
      parentFilters: [..._parentFilters, _filter],
      filter: FilterGroup(groupType: FilterGroupType.Not, implicit: true),
    );
  }

  QueryBuilder<OBJECT, dynamic, QFilter, QCanDistinctBy, QCanOffsetLimit,
      QCanSort, QCanExecute> beginGroupInternal<G>() {
    return copyWith(
      parentFilters: [..._parentFilters, _filter],
      filter: FilterGroup(implicit: false),
    );
  }

  QueryBuilder<OBJECT, B, C, D, E, F, G> endGroupInternal<B, C, D, E, F, G>() {
    QueryBuilder<OBJECT, B, C, D, E, F, G> endGroup(QueryBuilder builder) {
      return copyWith(
        parentFilters: _parentFilters.sublist(0, _parentFilters.length - 1),
        filter: _parentFilters.last.copyWith(conditions: [
          ..._parentFilters.last.conditions,
          if (_filter.conditions.isNotEmpty) _filter,
        ]),
      );
    }

    var builder = this;
    while (builder._filter.implicit) {
      builder = endGroup(builder);
    }
    return endGroup(builder);
  }

  QueryBuilder<OBJECT, B, C, D, E, F, G>
      addDistinctByInternal<B, C, D, E, F, G>(int propertyIndex) {
    return copyWith(distinctByPropertyIndices: [
      ..._distinctByPropertyIndices,
      propertyIndex,
    ]);
  }

  QueryBuilder<OBJECT, B, C, D, E, F, G> copyWith<B, C, D, E, F, G>({
    List<WhereClause>? whereClauses,
    FilterGroup? filter,
    List<FilterGroup>? parentFilters,
    List<int>? distinctByPropertyIndices,
    List<SortProperty>? sortByProperties,
    int? offset,
    int? limit,
  }) {
    assert(offset == null || offset >= 0);
    assert(limit == null || limit > 0);
    return QueryBuilder._(
      _collection,
      filter ?? _filter,
      parentFilters ?? _parentFilters,
      whereClauses ?? List.unmodifiable(_whereClauses),
      _whereDistinct,
      _whereAscending,
      distinctByPropertyIndices ??
          List.unmodifiable(_distinctByPropertyIndices),
      sortByProperties ?? List.unmodifiable(_sortByProperties),
      offset ?? _offset,
      limit ?? _limit,
    );
  }

  Query<OBJECT> buildInternal() {
    var builder = this;
    while (builder._parentFilters.isNotEmpty) {
      builder = builder.endGroupInternal();
    }
    return buildQuery(
      _collection,
      _whereClauses,
      _whereDistinct,
      _whereAscending,
      builder._filter,
      _distinctByPropertyIndices,
      _offset,
      _limit,
    );
  }
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
  final dynamic? value;
  final bool includeValue;
  final dynamic? value2;
  final bool includeValue2;
  final bool caseSensitive;

  const QueryCondition(
    this.conditionType,
    this.propertyIndex,
    this.propertyType,
    this.value, {
    this.includeValue = true,
    this.value2,
    this.includeValue2 = true,
    this.caseSensitive = true,
  });

  @override
  QueryCondition clone() {
    return QueryCondition(
      conditionType,
      propertyIndex,
      propertyType,
      value,
      includeValue: includeValue,
      value2: value2,
      includeValue2: includeValue2,
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
  final bool implicit;

  const FilterGroup({
    this.conditions = const [],
    this.groupType,
    required this.implicit,
  });

  @override
  FilterGroup clone() {
    return FilterGroup(
      conditions: conditions.map((e) => e.clone()).toList(),
      groupType: groupType,
      implicit: implicit,
    );
  }

  FilterGroup copyWith(
      {List<QueryOperation>? conditions, FilterGroupType? groupType}) {
    return FilterGroup(
      conditions: conditions ?? this.conditions.map((e) => e.clone()).toList(),
      groupType: groupType ?? this.groupType,
      implicit: implicit,
    );
  }
}

class SortProperty {
  final int propertyIndex;
  final bool ascending;

  const SortProperty(this.propertyIndex, this.ascending);
}

// When where is in progress. Only property conditions are allowed.
class QWhere {}

// Before where is started
class QNoWhere extends QWhere {}

// Directly after a where property condition.
class QWhereProperty {}

class QCanFilter {}

class QFilter {}

class QFilterAfterCond extends QFilter {}

class QCanDistinctBy {}

class QCanOffsetLimit {}

class QCanOffset {}

class QCanLimit {}

class QCanSort {}

class QSorting {}

class QCanExecute {}
