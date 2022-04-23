// ignore_for_file: prefer_initializing_formals

part of isar;

abstract class WhereClause {
  const WhereClause._();
}

/// A where clause traversing the primary index (ids).
class IdWhereClause extends WhereClause {
  /// The lower bound id or `null` for unbounded.
  final int? lower;

  /// Whether the lower bound should be included in the results.
  final bool includeLower;

  /// The upper bound id or `null` for unbounded.
  final int? upper;

  /// Whether the upper bound should be included in the results.
  final bool includeUpper;

  const IdWhereClause.any()
      : lower = null,
        upper = null,
        includeLower = true,
        includeUpper = true,
        super._();

  const IdWhereClause.greaterThan({
    required int lower,
    this.includeLower = true,
  })  : lower = lower,
        upper = null,
        includeUpper = true,
        super._();

  const IdWhereClause.lessThan({
    required int upper,
    this.includeUpper = true,
  })  : upper = upper,
        lower = null,
        includeLower = true,
        super._();

  const IdWhereClause.equalTo({
    required int value,
  })  : lower = value,
        upper = value,
        includeLower = true,
        includeUpper = true,
        super._();

  const IdWhereClause.between({
    this.lower,
    this.includeLower = true,
    this.upper,
    this.includeUpper = true,
  }) : super._();
}

/// A where clause traversing an index.
class IndexWhereClause extends WhereClause {
  /// The Isar name of the index to be used.
  final String indexName;

  /// The lower bound of the where clause.
  final List<Object?>? lower;

  /// Whether the lower bound should be included in the results. Double values
  /// are never included.
  final bool includeLower;

  /// The upper bound of the where clause.
  final List<Object?>? upper;

  /// Whether the upper bound should be included in the results. Double values
  /// are never included.
  final bool includeUpper;

  const IndexWhereClause.any({required this.indexName})
      : lower = null,
        upper = null,
        includeLower = true,
        includeUpper = true,
        super._();

  const IndexWhereClause.greaterThan({
    required this.indexName,
    required List<Object?> lower,
    this.includeLower = true,
  })  : lower = lower,
        upper = null,
        includeUpper = true,
        super._();

  const IndexWhereClause.lessThan({
    required this.indexName,
    required List<Object?> upper,
    this.includeUpper = true,
  })  : upper = upper,
        lower = null,
        includeLower = true,
        super._();

  const IndexWhereClause.equalTo({
    required this.indexName,
    required List<Object?> value,
  })  : lower = value,
        upper = value,
        includeLower = true,
        includeUpper = true,
        super._();

  const IndexWhereClause.between({
    required this.indexName,
    this.lower,
    this.includeLower = true,
    this.upper,
    this.includeUpper = true,
  }) : super._();
}

/// A where clause traversing objects linked to the specified object.
class LinkWhereClause extends WhereClause {
  /// The name of the collection the link originates from.
  final String linkCollection;

  /// The isar name of the link to be used.
  final String linkName;

  /// The id of the source object.
  final int id;

  const LinkWhereClause({
    required this.linkCollection,
    required this.linkName,
    required this.id,
  }) : super._();
}

/// @nodoc
@protected
abstract class FilterOperation {
  const FilterOperation();
}

/// The type of dynamic filter conditions.
///
/// For lists, at least one of the values in the list has to match. For
/// `isNull`, the entire list hast to be null.
enum ConditionType {
  eq,
  gt,
  lt,
  between,
  startsWith,
  endsWith,
  contains,
  matches,
  isNull,
}

/// Create a filter condition dynamically.
class FilterCondition<T> extends FilterOperation {
  /// Type of the filter condition.
  final ConditionType type;

  /// Property used for comparisons.
  final String property;

  /// Value used for comparisons. Lower bound for `ConditionType.between`.
  final T? value1;

  /// Should `value1` be part of the results.
  final bool include1;

  /// Upper bound for `ConditionType.between`.
  final T? value2;

  /// Should `value1` be part of the results.
  final bool include2;

  /// Are string operations case sensitive.
  final bool caseSensitive;

  const FilterCondition({
    required this.type,
    required this.property,
    T? value,
    bool include = false,
    this.caseSensitive = true,
  })  : value1 = value,
        include1 = include,
        value2 = null,
        include2 = false,
        assert(type != ConditionType.between);

  const FilterCondition.between({
    required this.property,
    T? lower,
    bool includeLower = true,
    T? upper,
    bool includeUpper = true,
    this.caseSensitive = true,
  })  : value1 = lower,
        include1 = includeLower,
        value2 = upper,
        include2 = includeUpper,
        type = ConditionType.between;
}

/// Thw type of filter groups.
enum FilterGroupType {
  and,
  or,
  not,
}

/// Group one or more filter conditions.
class FilterGroup extends FilterOperation {
  /// The filter(s) to be grouped.
  final List<FilterOperation> filters;

  /// Type of this group.
  final FilterGroupType type;

  /// Create a logical AND filter group.
  const FilterGroup.and(this.filters) : type = FilterGroupType.and;

  /// Create a logical OR filter group.
  const FilterGroup.or(this.filters) : type = FilterGroupType.or;

  /// Negate a filter.
  FilterGroup.not(FilterOperation filter)
      : filters = [filter],
        type = FilterGroupType.not;
}

/// Sort order
enum Sort {
  asc,
  desc,
}

/// Property used to sort query results.
class SortProperty {
  /// Isar name of the property used for sorting.
  final String property;

  /// Sort order.
  final Sort sort;

  const SortProperty({required this.property, required this.sort});
}

/// Property used to filter duplicate values.
class DistinctProperty {
  /// Isar name of the property used for sorting.
  final String property;

  /// Should Strings be case sensitive?
  final bool? caseSensitive;

  const DistinctProperty({required this.property, this.caseSensitive});
}

/// Filter condition based on a link.
class LinkFilter extends FilterOperation {
  /// Filter condition that should be applied
  final FilterOperation filter;

  /// Isar name of the link.
  final String linkName;

  /// The name of the collection the link points to.
  final String targetCollection;

  const LinkFilter({
    required this.filter,
    required this.linkName,
    required this.targetCollection,
  });
}
