import 'package:isar/isar.dart';

class QueryBuilder<T extends IsarObject, BANK extends IsarBank<T>, WHERE,
    FILTER, SORT, EXECUTE> {
  IsarBank _bank;
}

typedef NoWhere = Function();
typedef WhereField = Function(bool);

typedef CanFilter = Function();
typedef Filter = Function(bool);
typedef FilterNoAndOr = Function(bool, bool);

class FilterT {}

class FilterAndOrT extends FilterT {}

typedef CanSort = Function();
typedef Sorting = Function(bool);

typedef CanExecute = Function();

extension WhereOrExtension<T extends IsarObject, B extends IsarBank<T>>
    on QueryBuilder<T, B, WhereField, dynamic, dynamic, dynamic> {
  QueryBuilder<T, B, NoWhere, dynamic, dynamic, dynamic> or() {
    return QueryBuilder();
  }
}

extension WhereFilterExtension<T extends IsarObject, B extends IsarBank<T>>
    on QueryBuilder<T, B, dynamic, CanFilter, dynamic, dynamic> {
  QueryBuilder<T, B, dynamic, FilterT, dynamic, dynamic> filter() {
    return QueryBuilder();
  }
}

extension FilterAndOrExtension<T extends IsarObject, B extends IsarBank<T>>
    on QueryBuilder<T, B, dynamic, FilterAndOrT, dynamic, dynamic> {
  QueryBuilder<T, B, dynamic, FilterT, dynamic, dynamic> and() {
    return QueryBuilder();
  }

  QueryBuilder<T, B, dynamic, FilterT, dynamic, dynamic> or() {
    return QueryBuilder();
  }
}

extension SortExtension<T extends IsarObject, B extends IsarBank<T>>
    on QueryBuilder<T, B, dynamic, Filter, dynamic, dynamic> {
  Future<T> and() {}

  Future<List<T>> or() {}

  Future<int> count() {}
}

extension ExecuteExtension<T extends IsarObject, B extends IsarBank<T>>
    on QueryBuilder<T, B, dynamic, dynamic, dynamic, CanExecute> {
  Future<T> findFirst() {}

  Future<List<T>> findAll() {}

  Future<int> count() {}
}

extension TestWhereField<T extends IsarObject, B extends IsarBank<T>>
    on QueryBuilder<T, B, NoWhere, dynamic, dynamic, dynamic> {
  QueryBuilder<T, B, WhereField, CanFilter, CanSort, CanExecute> nameEqualTo(
      String name) {
    return QueryBuilder();
  }
}

/*class EqualTo<T> {
  final int property;
  final T value;

  const EqualTo(this.property, this.value);
}

class LessThan<T> {
  final int property;
  final T value;

  const LessThan(this.property, this.value);
}

class GreaterThan<T> {
  final int property;
  final T value;

  const GreaterThan(this.property, this.value);
}

class Cond {
  const Cond();
}

class Eq<T> extends Cond {
  final int property;
  final T value;

  const Eq(this.property, this.value);
}

enum AndOr {
  And,
  Or,
}

class Group extends Cond {
  final Group parent;
  final List<Cond> conditions = [];
  final bool implicit;
  AndOr andOr;

  Group(this.parent, this.implicit, this.andOr);
}

class Q {
  var group = Group(null, false, null);
  AndOr pending;

  Q and() {
    if (pending != null) {
      throw ".and() must not follow .and() or .or()";
    }
    if (group.conditions.isEmpty) {
      throw "Invalid .and() at the beginning of a group";
    }
    pending = AndOr.And;
    return this;
  }

  Q or() {
    if (pending != null) {
      throw ".or() must not follow .and() or .or()";
    }
    if (group.conditions.isEmpty) {
      throw "Invalid .or() at the beginning of a group";
    }
    pending = AndOr.Or;
    return this;
  }

  void execAndOr() {
    if (pending == null) {
      if (group.conditions.isEmpty) {
        return;
      } else {
        pending = AndOr.And;
      }
    }
    if (group.andOr == null) {
      group.andOr = pending;
    } else if (group.andOr != pending) {
      var last = group.conditions.removeLast();
      var newGroup = Group(group, true, pending);
      group.conditions.add(newGroup);
      newGroup.conditions.add(last);
      group = newGroup;
    }
    pending = null;
  }

  Q begin() {
    if (pending != null) {
      throw ".begin() must not follow .and() or .or()";
    }
    var newGroup = Group(group, false, null);
    group.conditions.add(newGroup);
    group = newGroup;
    return this;
  }

  Q newGroup(void Function(Q q)) {}

  Q end() {
    if (pending != null) {
      throw ".end() must not follow .and() or .or()";
    }
    while (group.implicit) {
      group = group.parent;
    }
    group = group.parent;
    return this;
  }

  Q eq<T>(int property, T value) {
    execAndOr();
    group.conditions.add(Eq(property, value));
    return this;
  }

  Q finish() {
    if (pending != null) {
      throw "Query must not end with .and() or .or()";
    }
    while (group.parent != null) {
      if (!group.implicit) {
        throw "Please close all open groups";
      }
      group = group.parent;
    }
    return this;
  }
}
*/
