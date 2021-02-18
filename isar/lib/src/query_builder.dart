import 'package:isar/isar.dart';
import 'package:isar/isar_native.dart';

class QueryBuilder<OBJECT, WHERE, FILTER, DISTINCT_BY, OFFSET_LIMIT, SORT,
    EXECUTE> {
  final IsarCollection<dynamic, OBJECT> _collection;
  final List<WhereClause> _whereClauses;
  late FilterGroup _filter;
  final List<int> _distinctByPropertyIndices;
  final List<SortProperty> _sortByProperties;
  int? _offset;
  int? _limit;

  QueryBuilder(this._collection)
      : _whereClauses = const [],
        _distinctByPropertyIndices = const [],
        _sortByProperties = const [] {
    _filter = FilterGroup(parent: null, groupType: null, implicit: false);
  }

  QueryBuilder._(
    this._collection,
    this._filter, [
    this._whereClauses = const [],
    this._distinctByPropertyIndices = const [],
    this._sortByProperties = const [],
    this._offset,
    this._limit,
  ]);

  QueryBuilder<OBJECT, B, C, D, E, F, G> addFilterCondition<B, C, D, E, F, G>(
      QueryCondition cond) {
    var cloned = clone<B, C, D, E, F, G>();
    cloned._filter.conditions.add(cond);
    if (cloned._filter.groupType == FilterGroupType.Not) {
      cloned = cloned.endGroupInternal();
    }
    return cloned;
  }

  QueryBuilder<OBJECT, B, C, D, E, F, G> addWhereClause<B, C, D, E, F, G, H>(
      WhereClause where) {
    final cloned = clone<B, C, D, E, F, G>();
    cloned._whereClauses.add(where);
    return cloned;
  }

  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      andOrInternal(FilterGroupType andOr) {
    final cloned =
        clone<dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>();
    if (_filter.groupType == null || _filter.groupType == andOr) {
      cloned._filter.groupType = andOr;
    } else {
      var newFilter =
          FilterGroup(parent: cloned._filter, groupType: andOr, implicit: true);
      var last = cloned._filter.conditions.removeLast();
      newFilter.conditions.add(last);
      cloned._filter = newFilter;
    }

    return cloned;
  }

  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      notInternal() {
    final cloned = clone<dynamic, QFilter, QCanDistinctBy, QCanOffsetLimit,
        QCanSort, QCanExecute>();
    var newFilter = FilterGroup(
        parent: cloned._filter, groupType: FilterGroupType.Not, implicit: true);
    cloned._filter.conditions.add(newFilter);
    cloned._filter = newFilter;
    return cloned;
  }

  QueryBuilder<OBJECT, dynamic, QFilter, QCanDistinctBy, QCanOffsetLimit,
      QCanSort, QCanExecute> beginGroupInternal<G>() {
    final cloned = clone<dynamic, QFilter, QCanDistinctBy, QCanOffsetLimit,
        QCanSort, QCanExecute>();
    var newFilter =
        FilterGroup(parent: cloned._filter, groupType: null, implicit: false);
    cloned._filter.conditions.add(newFilter);
    cloned._filter = newFilter;
    return cloned;
  }

  QueryBuilder<OBJECT, B, C, D, E, F, G> endGroupInternal<B, C, D, E, F, G>() {
    final cloned = clone<B, C, D, E, F, G>();
    while (cloned._filter.implicit) {
      cloned._filter = cloned._filter.parent!;
    }
    if (cloned._filter.conditions.isEmpty) {
      cloned._filter.parent!.conditions.removeLast();
    }
    cloned._filter = cloned._filter.parent!;
    return cloned;
  }

  QueryBuilder<OBJECT, B, C, D, E, F, G>
      addDistinctByInternal<B, C, D, E, F, G>(int propertyIndex) {
    final cloned = clone<B, C, D, E, F, G>();
    cloned._distinctByPropertyIndices.add(propertyIndex);
    return cloned;
  }

  QueryBuilder<OBJECT, B, C, D, E, F, G> offsetInternal<B, C, D, E, F, G>(
      int offset) {
    assert(offset >= 0);
    if (offset == 0) return clone();

    final cloned = clone<B, C, D, E, F, G>();
    cloned._offset = offset;
    return cloned;
  }

  QueryBuilder<OBJECT, B, C, D, E, F, G> limitInternal<B, C, D, E, F, G>(
      int limit) {
    assert(limit > 0);
    final cloned = clone<B, C, D, E, F, G>();
    cloned._limit = limit;
    return cloned;
  }

  QueryBuilder<OBJECT, B, C, D, E, F, G> clone<B, C, D, E, F, G>() {
    final newWhereClauses = <WhereClause>[];
    for (var cond in _whereClauses) {
      newWhereClauses.add(cond.clone());
    }
    return QueryBuilder._(
      _collection,
      _filter.clone(),
      newWhereClauses,
      _distinctByPropertyIndices,
      _sortByProperties,
    );
  }

  Query<OBJECT> buildInternal() {
    return buildQuery(_collection, _whereClauses, _filter,
        _distinctByPropertyIndices, _offset, _limit);
  }
}

class WhereClause {
  final int? index;
  final List<String> types;
  final List? lower;
  final bool includeLower;
  final List? upper;
  final bool includeUpper;
  final bool skipDuplicates;

  const WhereClause(
    this.index,
    this.types, {
    this.lower,
    this.includeLower = true,
    this.upper,
    this.includeUpper = true,
    this.skipDuplicates = false,
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
  FilterGroup? parent;
  List<QueryOperation> conditions = [];
  FilterGroupType? groupType;
  bool implicit;

  FilterGroup({this.parent, this.groupType, required this.implicit});

  List<FilterGroup?> _clone(FilterGroup caller, FilterGroup? newParent) {
    if (parent != null && newParent == null) {
      return parent!._clone(caller, null);
    } else {
      final cloned = FilterGroup(groupType: groupType, implicit: implicit);
      FilterGroup? newCaller;
      for (var condition in conditions) {
        if (condition is FilterGroup) {
          final result = condition._clone(caller, cloned);
          cloned.conditions.add(result[0]!);
          if (condition == caller) {
            newCaller = result[0];
          } else if (result[1] != null) {
            newCaller = result[1];
          }
        } else {
          cloned.conditions.add(condition.clone());
        }
      }
      if (caller == this) {
        newCaller = cloned;
      }
      return [cloned, newCaller];
    }
  }

  @override
  FilterGroup clone() {
    final result = _clone(this, null);
    return result[1]!;
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
