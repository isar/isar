part of isar;

/// @nodoc
@protected
typedef FilterQuery<OBJ> = QueryBuilder<OBJ, OBJ, QAfterFilterCondition>
    Function(QueryBuilder<OBJ, OBJ, QFilterCondition> q);

/// Query builders are used to create queries in a safe way.
///
/// Acquire a `QueryBuilder` instance using `collection.where()` or
/// `collection.filter()`.
class QueryBuilder<OBJ, R, S> {
  /// @nodoc
  @protected
  const QueryBuilder._(this._query);

  final _QueryBuilder<OBJ> _query;

  /// @nodoc
  @protected
  static QueryBuilder<OBJ, R, S> apply<OBJ, R, S>(
    QueryBuilder<OBJ, dynamic, dynamic> qb,
    _QueryBuilder<OBJ> Function(_QueryBuilder<OBJ> query) transform,
  ) {
    return QueryBuilder._(transform(qb._query));
  }
}

class _QueryBuilder<OBJ> {
  /// @nodoc
  const _QueryBuilder({
    this.collection,
    this.filter = const AndGroup([]),
    this.filterGroupAnd = true,
    this.filterNot = false,
    this.distinctByProperties = const [],
    this.sortByProperties = const [],
    this.property,
  });

  /// @nodoc
  final IsarCollection<dynamic, OBJ>? collection;

  /// @nodoc
  final Filter filter;

  /// @nodoc
  final bool filterGroupAnd;

  /// @nodoc
  final bool filterNot;

  /// @nodoc
  final List<DistinctProperty> distinctByProperties;

  /// @nodoc
  final List<SortProperty> sortByProperties;

  /// @nodoc
  final int? property;

  /// @nodoc
  _QueryBuilder<OBJ> addFilterCondition(Filter cond) {
    if (filterNot) {
      cond = NotGroup(cond);
    }

    late Filter newFilter;

    final filter = this.filter;
    if (filterGroupAnd) {
      if (filter is AndGroup) {
        newFilter = AndGroup([...filter.filters, cond]);
      } else if (filter is OrGroup) {
        newFilter = OrGroup([
          ...filter.filters.sublist(0, filter.filters.length - 1),
          AndGroup([
            filter.filters.last,
            cond,
          ]),
        ]);
      } else {
        newFilter = AndGroup([filter, cond]);
      }
    } else {
      if (filter is OrGroup) {
        newFilter = OrGroup([...filter.filters, cond]);
      } else {
        newFilter = OrGroup([filter, cond]);
      }
    }

    return copyWith(
      filter: newFilter,
      filterGroupAnd: true,
      filterNot: false,
    );
  }

  /// @nodoc
  _QueryBuilder<OBJ> group(FilterQuery<OBJ> q) {
    // ignore: prefer_const_constructors
    final qb = q(QueryBuilder._(_QueryBuilder()));
    return addFilterCondition(qb._query.filter);
  }

  /// @nodoc
  _QueryBuilder<OBJ> listLength<E>(
    int property,
    int lower,
    bool includeLower,
    int upper,
    bool includeUpper,
  ) {
    if (!includeLower) {
      lower += 1;
    }
    if (!includeUpper) {
      if (upper == 0) {
        lower = 1;
      } else {
        upper -= 1;
      }
    }
    return addFilterCondition(
      ListLengthCondition(
        property: property,
        lower: lower,
        upper: upper,
      ),
    );
  }

  /// @nodoc
  /*_QueryBuilder<OBJ> object<E>(
    FilterQuery<E> q,
    int property,
  ) {
    // ignore: prefer_const_constructors
    final qb = q(QueryBuilder(_QueryBuilder()));
    return addFilterCondition(
      ObjectFilter(filter: qb._query.filter, property: property),
    );
  }*/

  ///

  /// @nodoc
  _QueryBuilder<OBJ> addSortBy(
    int property, {
    Sort sort = Sort.asc,
    bool caseSensitive = true,
  }) {
    return copyWith(
      sortByProperties: [
        ...sortByProperties,
        SortProperty(
          property: property,
          sort: sort,
          caseSensitive: caseSensitive,
        ),
      ],
    );
  }

  /// @nodoc
  _QueryBuilder<OBJ> addDistinctBy(
    int property, {
    bool caseSensitive = true,
  }) {
    return copyWith(
      distinctByProperties: [
        ...distinctByProperties,
        DistinctProperty(
          property: property,
          caseSensitive: caseSensitive,
        ),
      ],
    );
  }

  /// @nodoc
  _QueryBuilder<OBJ> addProperty<E>(int property) {
    return copyWith(property: property);
  }

  /// @nodoc
  _QueryBuilder<OBJ> copyWith({
    Filter? filter,
    bool? filterIsGrouped,
    bool? filterGroupAnd,
    bool? filterNot,
    List<DistinctProperty>? distinctByProperties,
    List<SortProperty>? sortByProperties,
    int? property,
  }) {
    return _QueryBuilder(
      collection: collection,
      filter: filter ?? this.filter,
      filterGroupAnd: filterGroupAnd ?? this.filterGroupAnd,
      filterNot: filterNot ?? this.filterNot,
      distinctByProperties:
          distinctByProperties ?? List.unmodifiable(this.distinctByProperties),
      sortByProperties:
          sortByProperties ?? List.unmodifiable(this.sortByProperties),
      property: property ?? this.property,
    );
  }

  /// @nodoc
  @protected
  Query<R> build<R>() {
    return collection!.buildQuery(
      filter: filter,
      sortBy: sortByProperties,
      distinctBy: distinctByProperties,
      property: property,
    );
  }
}

/// @nodoc
///
/// Right after query starts
@protected
interface class QStart
    implements QFilterCondition, QSortBy, QDistinct, QQueryProperty {}

/// @nodoc
@protected
sealed class QFilterCondition {}

/// @nodoc
@protected
interface class QAfterFilterCondition
    implements
        QFilterCondition,
        QFilterOperator,
        QSortBy,
        QDistinct,
        QQueryProperty {}

/// @nodoc
@protected
interface class QFilterOperator {}

/// @nodoc
@protected
interface class QAfterFilterOperator implements QFilterCondition {}

/// @nodoc
@protected
interface class QSortBy {}

/// @nodoc
@protected
interface class QAfterSortBy
    implements QSortThenBy, QDistinct, QQueryProperty {}

/// @nodoc
@protected
interface class QSortThenBy {}

/// @nodoc
@protected
interface class QDistinct implements QQueryProperty {}

/// @nodoc
@protected
interface class QQueryProperty implements QQueryOperations {}

/// @nodoc
@protected
interface class QQueryOperations {}
