part of isar;

/// Create a where clause dynamically.
class WhereClause {
  /// THe Isar name of the index to be used.
  final String? indexName;

  /// The lower bound of the where clause.
  final List? lower;

  /// Whether the lower bound should be included in the results. Double values
  /// are never included.
  final bool includeLower;

  /// The upper bound of the where clause.
  final List? upper;

  /// Whether the upper bound should be included in the results. Double values
  /// are never included.
  final bool includeUpper;

  const WhereClause({
    this.indexName,
    this.lower,
    this.includeLower = true,
    this.upper,
    this.includeUpper = true,
  });
}

/// @nodoc
@protected
abstract class FilterOperation {
  const FilterOperation();
}

/// The type of dynamic filter conditions.
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

  const FilterGroup.and(this.filters) : type = FilterGroupType.and;

  const FilterGroup.or(this.filters) : type = FilterGroupType.or;

  FilterGroup.not(FilterOperation filter)
      : filters = [filter],
        type = FilterGroupType.or;
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
  /// Isar name of the target collection of the link.
  final IsarCollection targetCollection;

  /// Filter condition that should be applied
  final FilterOperation filter;

  /// Isar name of the link.
  final String linkName;

  const LinkFilter({
    required this.targetCollection,
    required this.filter,
    required this.linkName,
  });
}
