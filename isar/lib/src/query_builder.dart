part of isar;

class QueryBuilder<OBJECT, WHERE, FILTER, GROUPBY, OFFSET_LIMIT, SORT,
    EXECUTE> {
  final IsarCollection<dynamic, OBJECT> _collection;
  final List<WhereClause> _whereClauses;
  late FilterGroup _filter;

  QueryBuilder._(
    this._collection, [
    this._whereClauses = const [],
    FilterGroup? filter,
  ]) {
    _filter =
        filter ?? FilterGroup(parent: null, groupType: null, implicit: false);
  }

  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      _andOr(FilterGroupType andOr) {
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
      _not() {
    final cloned = clone<dynamic, QFilter, QCanGroupBy, QCanOffsetLimit,
        QCanSort, QCanExecute>();
    var newFilter = FilterGroup(
        parent: cloned._filter, groupType: FilterGroupType.Not, implicit: true);
    cloned._filter.conditions.add(newFilter);
    cloned._filter = newFilter;
    return cloned;
  }

  QueryBuilder<OBJECT, dynamic, QFilter, QCanGroupBy, QCanOffsetLimit, QCanSort,
      QCanExecute> _beginGroup<G>() {
    final cloned = clone<dynamic, QFilter, QCanGroupBy, QCanOffsetLimit,
        QCanSort, QCanExecute>();
    var newFilter =
        FilterGroup(parent: cloned._filter, groupType: null, implicit: false);
    cloned._filter.conditions.add(newFilter);
    cloned._filter = newFilter;
    return cloned;
  }

  QueryBuilder<OBJECT, B, C, D, E, F, G> _endGroup<B, C, D, E, F, G>() {
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
}

QueryBuilder<OBJECT, QNoWhere, QCanFilter, QCanGroupBy, QCanOffsetLimit,
    QCanSort, QCanExecute> newQueryInternal<
        OBJECT, COLLECTION extends IsarCollection<dynamic, OBJECT>>(
    COLLECTION collection) {
  return QueryBuilder._(collection);
}

extension QueryBuilderX<OBJECT> on QueryBuilder<OBJECT, dynamic, dynamic,
    dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, B, C, D, E, F, G> clone<B, C, D, E, F, G>() {
    final newWhereClauses = <WhereClause>[];
    for (var cond in _whereClauses) {
      newWhereClauses.add(cond.clone());
    }
    return QueryBuilder._(
      _collection,
      newWhereClauses,
      _filter.clone(),
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

// When where is in progress. Only property conditions are allowed.
class QWhere {}

// Before where is started
class QNoWhere extends QWhere {}

// Directly after a where property condition.
typedef QWhereProperty = Function();

typedef QCanFilter = Function();

class QFilter {}

class QFilterAfterCond extends QFilter {}

typedef QCanGroupBy = Function();

typedef QCanOffsetLimit = Function();
typedef QHasOffset = Function(bool);
typedef QHasLimit = Function(bool, bool);

typedef QCanSort = Function();
typedef QSorting = Function(bool);

typedef QCanExecute = Function();

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

extension QueryFilterAddCondition<OBJECT> on QueryBuilder<OBJECT, dynamic,
    dynamic, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, B, C, D, E, F, G> addFilterCondition<B, C, D, E, F, G>(
      QueryCondition cond) {
    var cloned = clone<B, C, D, E, F, G>();
    cloned._filter.conditions.add(cond);
    if (cloned._filter.groupType == FilterGroupType.Not) {
      cloned = cloned._endGroup();
    }
    return cloned;
  }

  QueryBuilder<OBJECT, B, C, D, E, F, G> addWhereClause<B, C, D, E, F, G, H>(
      WhereClause where) {
    final cloned = clone<B, C, D, E, F, G>();
    cloned._whereClauses.add(where);
    return cloned;
  }
}

extension QueryFilterAndOr<OBJECT, GROUPS> on QueryBuilder<OBJECT, dynamic,
    QFilterAfterCond, GROUPS, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      and() {
    return _andOr(FilterGroupType.And);
  }

  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      or() {
    return _andOr(FilterGroupType.Or);
  }
}

extension QueryFilterNot<OBJECT> on QueryBuilder<OBJECT, dynamic, QFilter,
    dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      not() {
    return _not();
  }
}

extension QueryFilterNoGroups<OBJECT> on QueryBuilder<OBJECT, dynamic, QFilter,
    dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, dynamic, QFilter, dynamic, dynamic, dynamic, dynamic>
      beginGroup() {
    return _beginGroup();
  }
}

extension QueryFilterOneGroupsEnd<OBJECT> on QueryBuilder<OBJECT, dynamic,
    QFilterAfterCond, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<OBJECT, dynamic, QFilterAfterCond, QCanGroupBy, QCanOffsetLimit,
      QCanSort, QCanExecute> endGroup() {
    return _endGroup();
  }
}

extension QueryExecute<OBJECT> on QueryBuilder<OBJECT, dynamic, dynamic,
    dynamic, dynamic, dynamic, QCanExecute> {
  Query<OBJECT> build() {
    return buildQuery(_collection, _whereClauses, _filter);
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

  Stream<void> watchChanges() {
    return build().watchChanges();
  }

  Stream<List<OBJECT>> watch() {
    return build().watch();
  }
}
