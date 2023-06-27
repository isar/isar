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
  QueryBuilder(IsarCollection<dynamic, OBJ>? collection)
      : _query = _QueryBuilder<OBJ>(collection: collection);

  @protected
  const QueryBuilder._(this._query);

  final _QueryBuilder<OBJ> _query;

  /// @nodoc
  @protected
  static QueryBuilder<OBJ, R, S> apply<OBJ, R, S>(
    QueryBuilder<OBJ, dynamic, dynamic> qb,
    // ignore: library_private_types_in_public_api
    _QueryBuilder<OBJ> Function(_QueryBuilder<OBJ> query) transform,
  ) {
    return QueryBuilder._(transform(qb._query));
  }
}

class _QueryBuilder<OBJ> {
  /// @nodoc
  const _QueryBuilder({
    this.collection,
    this.filter,
    this.filterGroupAnd = true,
    this.filterNot = false,
    this.distinctByProperties = const [],
    this.sortByProperties = const [],
    this.properties = const [],
  });

  /// @nodoc
  final IsarCollection<dynamic, OBJ>? collection;

  /// @nodoc
  final Filter? filter;

  /// @nodoc
  final bool filterGroupAnd;

  /// @nodoc
  final bool filterNot;

  /// @nodoc
  final List<DistinctProperty> distinctByProperties;

  /// @nodoc
  final List<SortProperty> sortByProperties;

  /// @nodoc
  final List<int> properties;

  /// @nodoc
  _QueryBuilder<OBJ> addFilterCondition(Filter cond) {
    if (filterNot) {
      cond = NotGroup(cond);
    }

    late Filter newFilter;

    final filter = this.filter;
    if (filter == null) {
      newFilter = cond;
    } else if (filterGroupAnd) {
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
    final filter = qb._query.filter;
    if (filter != null) {
      return addFilterCondition(filter);
    } else {
      // ignore: avoid_returning_this
      return this;
    }
  }

  /// @nodoc
  _QueryBuilder<OBJ> object<E>(
    FilterQuery<E> q,
    int property,
  ) {
    // ignore: prefer_const_constructors
    final qb = q(QueryBuilder._(_QueryBuilder()));
    final filter = qb._query.filter;
    if (filter != null) {
      return addFilterCondition(
        ObjectFilter(property: property, filter: filter),
      );
    } else {
      // ignore: avoid_returning_this
      return this;
    }
  }

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
  _QueryBuilder<OBJ> addDistinctBy(int property, {bool caseSensitive = true}) {
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
  _QueryBuilder<OBJ> addProperty(int property) {
    return copyWith(properties: [...properties, property]);
  }

  /// @nodoc
  _QueryBuilder<OBJ> copyWith({
    Filter? filter,
    bool? filterIsGrouped,
    bool? filterGroupAnd,
    bool? filterNot,
    List<DistinctProperty>? distinctByProperties,
    List<SortProperty>? sortByProperties,
    List<int>? properties,
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
      properties: properties ?? this.properties,
    );
  }

  /// @nodoc
  @protected
  IsarQuery<R> build<R>() {
    return collection!.buildQuery(
      filter: filter,
      sortBy: sortByProperties,
      distinctBy: distinctByProperties,
      properties: properties,
    );
  }
}

/// @nodoc
///
/// Right after query starts
@protected
interface class QStart
    implements QFilterCondition, QSortBy, QDistinct, QProperty, QOperations {}

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
        QProperty,
        QOperations {}

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
    implements QSortThenBy, QDistinct, QProperty, QOperations {}

/// @nodoc
@protected
interface class QSortThenBy {}

/// @nodoc
@protected
interface class QDistinct {}

/// @nodoc
@protected
interface class QAfterDistinct implements QProperty, QOperations {}

/// @nodoc
@protected
interface class QProperty {}

/// @nodoc
@protected
interface class QAfterProperty implements QOperations {}

/// @nodoc
@protected
interface class QOperations {}
