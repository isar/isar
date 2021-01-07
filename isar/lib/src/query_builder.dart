part of isar;

class QueryBuilder<T extends IsarObject, WHERE, FILTER, GROUPS, GROUPBY,
    OFFSET_LIMIT, SORT, EXECUTE> {
  IsarCollection<T> _collection;
  List<WhereClause> _whereClauses;
  late FilterGroup _filter;

  QueryBuilder._(
    this._collection, [
    this._whereClauses = const [],
    FilterGroup? filter,
  ]) {
    _filter = filter ?? FilterGroup(parent: null, andOr: null, implicit: false);
  }

  QueryBuilder<T, dynamic, QFilter, GROUPS, dynamic, dynamic, dynamic, dynamic>
      _andOr(FilterAndOr andOr) {
    final cloned =
        clone<dynamic, QFilter, GROUPS, dynamic, dynamic, dynamic, dynamic>();
    if (_filter.andOr == null || _filter.andOr == andOr) {
      cloned._filter.andOr = andOr;
    } else {
      var newFilter =
          FilterGroup(parent: cloned._filter, andOr: andOr, implicit: true);
      var last = cloned._filter.conditions.removeLast();
      newFilter.conditions.add(last);
      cloned._filter = newFilter;
    }

    return cloned;
  }

  QueryBuilder<T, dynamic, QFilter, G, dynamic, dynamic, dynamic, dynamic>
      _beginGroup<G>() {
    final cloned =
        clone<dynamic, QFilter, G, dynamic, dynamic, dynamic, dynamic>();
    var newFilter =
        FilterGroup(parent: cloned._filter, andOr: null, implicit: false);
    cloned._filter.conditions.add(newFilter);
    cloned._filter = newFilter;
    return cloned;
  }

  QueryBuilder<T, dynamic, QFilterAfterCond, G, QCanGroupBy, QCanOffsetLimit,
      QCanSort, QCanExecute> _endGroup<G>() {
    final cloned = clone<dynamic, QFilterAfterCond, G, QCanGroupBy,
        QCanOffsetLimit, QCanSort, QCanExecute>();
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

QueryBuilder<T, QNoWhere, QCanFilter, QNoGroups, QCanGroupBy, QCanOffsetLimit,
    QCanSort, QCanExecute> newQueryInternal<
        T extends IsarObject, COLLECTION extends IsarCollection<T>>(
    COLLECTION collection) {
  return QueryBuilder._(collection);
}

extension QueryBuilderX<T extends IsarObject> on QueryBuilder<T, dynamic,
    dynamic, dynamic, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<T, B, C, D, E, F, G, H> clone<B, C, D, E, F, G, H>() {
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

  const QueryCondition(
    this.conditionType,
    this.propertyIndex,
    this.propertyType,
    this.value, {
    this.includeValue = true,
    this.value2,
    this.includeValue2 = true,
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
  IsNull,
  IsNotNull,
  Eq,
  NEq,
  Gt,
  Lt,
  StartsWith,
  Contains,
  Between,
}

enum FilterAndOr {
  And,
  Or,
}

class FilterGroup extends QueryOperation {
  FilterGroup? parent;
  List<QueryOperation> conditions = [];
  FilterAndOr? andOr;
  bool implicit;

  FilterGroup({this.parent, this.andOr, required this.implicit});

  List<FilterGroup?> _clone(FilterGroup caller, FilterGroup? newParent) {
    if (parent != null && newParent == null) {
      return parent!._clone(caller, null);
    } else {
      final cloned = FilterGroup(andOr: andOr, implicit: implicit);
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

typedef QNoGroups = Function();
typedef QOneGroups = Function(bool);
typedef QTwoGroups = Function(bool, bool);

typedef QCanGroupBy = Function();

typedef QCanOffsetLimit = Function();
typedef QHasOffset = Function(bool);
typedef QHasLimit = Function(bool, bool);

typedef QCanSort = Function();
typedef QSorting = Function(bool);

typedef QCanExecute = Function();

extension QueryWhereOr<T extends IsarObject> on QueryBuilder<T, QWhereProperty,
    dynamic, dynamic, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<T, QNoWhere, dynamic, dynamic, dynamic, dynamic, dynamic,
      dynamic> or() {
    return clone();
  }
}

extension QueryFilter<T extends IsarObject> on QueryBuilder<T, dynamic,
    QCanFilter, dynamic, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<T, dynamic, QFilter, QNoGroups, dynamic, dynamic, dynamic,
      dynamic> filter() {
    return clone();
  }
}

extension QueryFilterAddCondition<T extends IsarObject> on QueryBuilder<T,
    dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<T, B, C, D, E, F, G, H> addFilterCondition<B, C, D, E, F, G, H>(
      QueryCondition cond) {
    final cloned = clone<B, C, D, E, F, G, H>();
    cloned._filter.conditions.add(cond);
    return cloned;
  }

  QueryBuilder<T, B, C, D, E, F, G, H> addWhereClause<B, C, D, E, F, G, H>(
      WhereClause where) {
    final cloned = clone<B, C, D, E, F, G, H>();
    cloned._whereClauses.add(where);
    return cloned;
  }
}

extension QueryFilterAndOr<T extends IsarObject, GROUPS> on QueryBuilder<T,
    dynamic, QFilterAfterCond, GROUPS, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<T, dynamic, QFilter, GROUPS, dynamic, dynamic, dynamic, dynamic>
      and() {
    return _andOr(FilterAndOr.And);
  }

  QueryBuilder<T, dynamic, QFilter, GROUPS, dynamic, dynamic, dynamic, dynamic>
      or() {
    return _andOr(FilterAndOr.Or);
  }
}

extension QueryFilterNoGroups<T extends IsarObject> on QueryBuilder<T, dynamic,
    QFilter, QNoGroups, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<T, dynamic, QFilter, QOneGroups, dynamic, dynamic, dynamic,
      dynamic> beginGroup() {
    return _beginGroup();
  }
}

extension QueryFilterOneGroups<T extends IsarObject> on QueryBuilder<T, dynamic,
    QFilter, QOneGroups, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<T, dynamic, QFilter, QTwoGroups, dynamic, dynamic, dynamic,
      dynamic> beginGroup() {
    return _beginGroup();
  }
}

extension QueryFilterOneGroupsEnd<T extends IsarObject> on QueryBuilder<T,
    dynamic, QFilterAfterCond, QOneGroups, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<T, dynamic, QFilterAfterCond, QNoGroups, QCanGroupBy,
      QCanOffsetLimit, QCanSort, QCanExecute> endGroup() {
    return _endGroup();
  }
}

extension QueryFilterTwoGroupsEnd<T extends IsarObject> on QueryBuilder<T,
    dynamic, QFilterAfterCond, QTwoGroups, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<T, dynamic, QFilterAfterCond, QOneGroups, dynamic, dynamic,
      dynamic, dynamic> endGroup() {
    return _endGroup();
  }
}

extension QueryExecute<T extends IsarObject> on QueryBuilder<T, dynamic,
    dynamic, QNoGroups, dynamic, dynamic, dynamic, QCanExecute> {
  Query<T> build() {
    return buildQuery(_collection, _whereClauses, _filter);
  }

  Future<T?> findFirst() {
    return build().findFirst();
  }

  T? findFirstSync() {
    return build().findFirstSync();
  }

  Future<List<T>> findAll() {
    return build().findAll();
  }

  List<T> findAllSync() {
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

  T deleteFirstSync() {
    return build().deleteFirstSync();
  }

  Future<int> deleteAll() {
    return build().deleteAll();
  }

  int deleteAllSync() {
    return build().deleteAllSync();
  }
}
