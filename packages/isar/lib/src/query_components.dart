part of isar;

/// @nodoc
@protected
abstract class Filter {
  const Filter._();
}

/// The type of dynamic filter conditions.
enum FilterConditionType {
  /// Filter checking for equality.
  equalTo,

  /// Filter matching values greater than the bound.
  greaterThan,

  /// Filter matching values smaller than the bound.
  lessThan,

  /// Filter matching values between the bounds.
  between,

  /// Filter matching String values starting with the prefix.
  startsWith,

  /// Filter matching String values ending with the suffix.
  endsWith,

  /// Filter matching String values containing the String.
  contains,

  /// Filter matching String values matching the wildcard.
  matches,

  /// Filter matching values that are `null`.
  isNull,

  /// Filter matching the length of a list.
  listLength,
}

/// Create a filter condition dynamically.
class FilterCondition extends Filter {
  /// @nodoc
  @protected
  const FilterCondition({
    required this.type,
    required this.property,
    this.value1,
    this.value2,
    required this.include1,
    required this.include2,
    required this.caseSensitive,
  }) : super._();

  /// Filters the results to only include objects where the property equals
  /// [value].
  ///
  /// For lists, at least one of the values in the list has to match.
  const FilterCondition.equalTo({
    required this.property,
    required Object value,
    this.caseSensitive = true,
  })  : type = FilterConditionType.equalTo,
        value1 = value,
        include1 = true,
        value2 = null,
        include2 = false,
        super._();

  /// Filters the results to only include objects where the property is greater
  /// than [value].
  ///
  /// For lists, at least one of the values in the list has to match.
  const FilterCondition.greaterThan({
    required this.property,
    required Object value,
    bool include = false,
    this.caseSensitive = true,
  })  : type = FilterConditionType.greaterThan,
        value1 = value,
        include1 = include,
        value2 = null,
        include2 = false,
        super._();

  /// Filters the results to only include objects where the property is less
  /// than [value].
  ///
  /// For lists, at least one of the values in the list has to match.
  const FilterCondition.lessThan({
    required this.property,
    required Object value,
    bool include = false,
    this.caseSensitive = true,
  })  : type = FilterConditionType.lessThan,
        value1 = value,
        include1 = include,
        value2 = null,
        include2 = false,
        super._();

  /// Filters the results to only include objects where the property is
  /// between [lower] and [upper].
  ///
  /// For lists, at least one of the values in the list has to match.
  const FilterCondition.between({
    required this.property,
    required Object lower,
    bool includeLower = true,
    required Object upper,
    bool includeUpper = true,
    this.caseSensitive = true,
  })  : value1 = lower,
        include1 = includeLower,
        value2 = upper,
        include2 = includeUpper,
        type = FilterConditionType.between,
        super._();

  /// Filters the results to only include objects where the property starts
  /// with [value].
  ///
  /// For String lists, at least one of the values in the list has to match.
  const FilterCondition.startsWith({
    required this.property,
    required String value,
    this.caseSensitive = true,
  })  : type = FilterConditionType.startsWith,
        value1 = value,
        include1 = true,
        value2 = null,
        include2 = false,
        super._();

  /// Filters the results to only include objects where the property ends with
  /// [value].
  ///
  /// For String lists, at least one of the values in the list has to match.
  const FilterCondition.endsWith({
    required this.property,
    required String value,
    this.caseSensitive = true,
  })  : type = FilterConditionType.endsWith,
        value1 = value,
        include1 = true,
        value2 = null,
        include2 = false,
        super._();

  /// Filters the results to only include objects where the String property
  /// contains [value].
  ///
  /// For String lists, at least one of the values in the list has to match.
  const FilterCondition.contains({
    required this.property,
    required String value,
    this.caseSensitive = true,
  })  : type = FilterConditionType.contains,
        value1 = value,
        include1 = true,
        value2 = null,
        include2 = false,
        super._();

  /// Filters the results to only include objects where the property matches
  /// the [wildcard].
  ///
  /// For String lists, at least one of the values in the list has to match.
  const FilterCondition.matches({
    required this.property,
    required String wildcard,
    this.caseSensitive = true,
  })  : type = FilterConditionType.matches,
        value1 = wildcard,
        include1 = true,
        value2 = null,
        include2 = false,
        super._();

  /// Filters the results to only include objects where the property is null.
  const FilterCondition.isNull({
    required this.property,
  })  : type = FilterConditionType.isNull,
        value1 = null,
        include1 = false,
        value2 = null,
        include2 = false,
        caseSensitive = false,
        super._();

  /// Filters the results to only include objects where the length of
  /// [property] is between [lower] (included) and [upper] (included).
  ///
  /// Only list properties are supported.
  const FilterCondition.listLength({
    required this.property,
    required int lower,
    required int upper,
  })  : type = FilterConditionType.listLength,
        value1 = lower,
        include1 = true,
        value2 = upper,
        include2 = true,
        caseSensitive = false,
        assert(lower >= 0 && upper >= 0, 'List length must be positive.'),
        super._();

  static const nullBool = Object();
  static const nullInt = -9223372036854775808;
  static const nullDouble = double.nan;
  static const nullString = Object();

  /// Type of the filter condition.
  final FilterConditionType type;

  /// Index of the property used for comparisons.
  final int property;

  /// Value used for comparisons. Lower bound for `ConditionType.between`.
  final Object? value1;

  /// Should `value1` be part of the results.
  final bool include1;

  /// Upper bound for `ConditionType.between`.
  final Object? value2;

  /// Should `value1` be part of the results.
  final bool include2;

  /// Are string operations case sensitive.
  final bool caseSensitive;
}

/// The type of filter groups.
enum FilterGroupType {
  /// Logical AND.
  and,

  /// Logical OR.
  or,

  /// Logical NOT.
  not,
}

/// Group one or more filter conditions.
class FilterGroup extends Filter {
  /// @nodoc
  @protected
  FilterGroup({
    required this.type,
    required this.filters,
  }) : super._();

  /// Create a logical AND filter group.
  ///
  /// Matches when all [filters] match.
  const FilterGroup.and(this.filters)
      : type = FilterGroupType.and,
        super._();

  /// Create a logical OR filter group.
  ///
  /// Matches when any of the [filters] matches.
  const FilterGroup.or(this.filters)
      : type = FilterGroupType.or,
        super._();

  /// Negate a filter.
  ///
  /// Matches when any of the [filter] doesn't matches.
  FilterGroup.not(Filter filter)
      : filters = [filter],
        type = FilterGroupType.not,
        super._();

  /// Type of this group.
  final FilterGroupType type;

  /// The filter(s) to be grouped.
  final List<Filter> filters;
}

/// Sort order
enum Sort {
  /// Ascending sort order.
  asc,

  /// Descending sort order.
  desc,
}

/// Property used to sort query results.
class SortProperty {
  /// Create a sort property.
  const SortProperty({required this.property, required this.sort});

  /// Index of the property used for sorting.
  final int property;

  /// Sort order.
  final Sort sort;
}

/// Property used to filter duplicate values.
class DistinctProperty {
  /// Create a distinct property.
  const DistinctProperty({required this.property, this.caseSensitive});

  /// Index of the property used to determine distinct values.
  final int property;

  /// Should Strings be case sensitive?
  final bool? caseSensitive;
}

/// Filter condition based on an embedded object.
class ObjectFilter extends Filter {
  /// Create a filter condition based on an embedded object.
  const ObjectFilter({
    required this.property,
    required this.filter,
  }) : super._();

  /// Index of the property containing the embedded object.
  final int property;

  /// Filter condition that should be applied
  final Filter filter;
}
