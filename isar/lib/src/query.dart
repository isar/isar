import 'package:isar/internal.dart';

class Query<T extends IsarObject, COLLECTION extends IsarCollection<T>, WHERE,
    FILTER, GROUPS, SORT, EXECUTE> {
  final _whereConditions = <QueryCondition>[];
  FilterGroup? _group = FilterGroup(parent: null, implicit: false, andOr: null);

  Query([this._group]);

  void _newImplicitGroup(FilterAndOr andOr) {
    var last = _group!.conditions.removeLast();
    var newGroup = FilterGroup(parent: _group, implicit: true, andOr: andOr);
    _group!.conditions.add(newGroup);
    newGroup.conditions.add(last);
    _group = newGroup;
  }

  void _beginGroup() {
    var newGroup = FilterGroup(parent: _group, implicit: false, andOr: null);
    _group!.conditions.add(newGroup);
    _group = newGroup;
  }

  void _endGroup() {
    while (_group!.implicit!) {
      _group = _group!.parent;
    }
    if (_group!.conditions.isEmpty) {
      _group!.parent!.conditions.removeLast();
    }
    _group = _group!.parent;
  }

  Query<A, B, C, D, E, F, G>
      copy<A extends IsarObject, B extends IsarCollection<A>, C, D, E, F, G>() {
    return Query(_group);
  }
}

class QueryOperation {}

class QueryCondition<T> extends QueryOperation {
  final ConditionType type;
  final int index;
  final T value;

  QueryCondition(this.type, this.index, this.value);
}

class QueryBetween<T> extends QueryCondition<T> {
  final T value2;
  QueryBetween(int index, T value1, this.value2)
      : super(ConditionType.Between, index, value1);
}

enum ConditionType {
  Eq,
  NEq,
  Gt,
  Lt,
  StartsWith,
  EndsWith,
  Contains,
  Between,
}

enum FilterAndOr {
  And,
  Or,
}

class FilterGroup extends QueryOperation {
  final FilterGroup? parent;
  final List<QueryOperation> conditions = [];
  final bool? implicit;
  FilterAndOr? andOr;

  FilterGroup({this.parent, this.implicit, this.andOr});
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

typedef QCanSort = Function();
typedef QSorting = Function(bool);

typedef QCanExecute = Function();

extension QueryWhereOr<T extends IsarObject, B extends IsarCollection<T>>
    on Query<T, B, QWhereProperty, dynamic, dynamic, dynamic, dynamic> {
  Query<T, B, QNoWhere, dynamic, dynamic, dynamic, dynamic> or() {
    return copy();
  }
}

extension QueryFilter<T extends IsarObject, B extends IsarCollection<T>>
    on Query<T, B, dynamic, QCanFilter, dynamic, dynamic, dynamic> {
  Query<T, B, dynamic, QFilter, QNoGroups, dynamic, dynamic> filter() {
    return copy();
  }
}

extension QueryFilterAddCondition<T extends IsarObject,
        B extends IsarCollection<T>>
    on Query<T, B, dynamic, dynamic, dynamic, dynamic, dynamic> {
  void addFilterCondition(QueryCondition cond) {
    _group!.conditions.add(cond);
  }

  void addWhereCondition(QueryCondition cond) {
    _whereConditions.add(cond);
  }
}

extension QueryFilterAndOr<T extends IsarObject, B extends IsarCollection<T>, F>
    on Query<T, B, dynamic, QFilterAfterCond, F, dynamic, dynamic> {
  Query<T, B, dynamic, QFilter, F, dynamic, dynamic> and() {
    if (_group!.andOr == null || _group!.andOr == FilterAndOr.And) {
      _group!.andOr = FilterAndOr.And;
    } else {
      _newImplicitGroup(FilterAndOr.And);
    }
    return copy();
  }

  Query<T, B, dynamic, QFilter, F, dynamic, dynamic> or() {
    if (_group!.andOr == null || _group!.andOr == FilterAndOr.Or) {
      _group!.andOr = FilterAndOr.Or;
    } else {
      _newImplicitGroup(FilterAndOr.Or);
    }
    return copy();
  }
}

extension QueryFilterNoGroups<T extends IsarObject, B extends IsarCollection<T>>
    on Query<T, B, dynamic, QFilter, QNoGroups, dynamic, dynamic> {
  Query<T, B, dynamic, QFilter, QOneGroups, dynamic, dynamic> beginGroup() {
    _beginGroup();
    return copy();
  }
}

extension QueryFilterOneGroups<T extends IsarObject,
        B extends IsarCollection<T>>
    on Query<T, B, dynamic, QFilter, QOneGroups, dynamic, dynamic> {
  Query<T, B, dynamic, QFilter, QTwoGroups, dynamic, dynamic> beginGroup() {
    _beginGroup();
    return copy();
  }
}

extension QueryFilterOneGroupsEnd<T extends IsarObject,
        B extends IsarCollection<T>>
    on Query<T, B, dynamic, QFilter, QOneGroups, dynamic, dynamic> {
  Query<T, B, dynamic, QFilter, QNoGroups, QCanSort, QCanExecute> endGroup() {
    _endGroup();
    return copy();
  }
}

extension QueryFilterTwoGroupsEnd<T extends IsarObject,
        B extends IsarCollection<T>>
    on Query<T, B, dynamic, QFilterAfterCond, QTwoGroups, dynamic, dynamic> {
  Query<T, B, dynamic, QFilter, QOneGroups, dynamic, dynamic> endGroup() {
    _endGroup();
    return copy();
  }
}

/*extension QueryExecute<T extends IsarObject, B extends IsarCollection<T>>
    on Query<T, B, dynamic, dynamic, QNoGroups, dynamic, QCanExecute> {
  Future<T> findFirst() {}

  T findFirstSync() {}

  Future<List<T>> findAll() {}

  List<T> findAllSync() {}

  Future<int> count() {}

  int countSync() {}
}*/
