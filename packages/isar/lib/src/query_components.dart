part of isar;

/// @nodoc
@protected
sealed class Filter {
  const Filter();

  static const nullBool = #nullBool;
  static const nullInt = -9223372036854775808;
  static const nullDate = -9223372036854775808;
  static const nullDouble = double.nan;
  static const nullString = #nullString;

  static const epsilon = 0.00001;
}

/// Filter checking for equality.
final class EqualToCondition extends Filter {
  /// Filters the results to only include objects where the property equals
  /// [value].
  ///
  /// For lists, at least one of the values in the list has to match.
  const EqualToCondition({
    required this.property,
    required this.value,
    this.epsilon = Filter.epsilon,
    this.caseSensitive = true,
  });

  final int property;
  final Object value;
  final double epsilon;
  final bool caseSensitive;
}

/// Filter matching values greater than the bound.
final class GreaterThanCondition extends Filter {
  /// Filters the results to only include objects where the property is greater
  /// than [value].
  ///
  /// For lists, at least one of the values in the list has to match.
  const GreaterThanCondition({
    required this.property,
    required this.value,
    this.include = false,
    this.epsilon = Filter.epsilon,
    this.caseSensitive = true,
  });

  final int property;
  final Object value;
  final bool include;
  final double epsilon;
  final bool caseSensitive;
}

/// Filter matching values smaller than the bound.
final class LessThanCondition extends Filter {
  /// Filters the results to only include objects where the property is less
  /// than [value].
  ///
  /// For lists, at least one of the values in the list has to match.
  const LessThanCondition({
    required this.property,
    required this.value,
    this.include = false,
    this.epsilon = Filter.epsilon,
    this.caseSensitive = true,
  });

  final int property;
  final Object value;
  final bool include;
  final double epsilon;
  final bool caseSensitive;
}

/// Filter matching values between the bounds.

final class BetweenCondition extends Filter {
  /// Filters the results to only include objects where the property is
  /// between [lower] and [upper].
  ///
  /// For lists, at least one of the values in the list has to match.
  const BetweenCondition({
    required this.property,
    required this.lower,
    this.includeLower = true,
    required this.upper,
    this.includeUpper = true,
    this.epsilon = Filter.epsilon,
    this.caseSensitive = true,
  });

  final int property;
  final Object lower;
  final bool includeLower;
  final Object upper;
  final bool includeUpper;
  final double epsilon;
  final bool caseSensitive;
}

/// Filter matching String values starting with the prefix.

final class StartsWithCondition extends Filter {
  /// Filters the results to only include objects where the property starts
  /// with [value].
  ///
  /// For String lists, at least one of the values in the list has to match.
  const StartsWithCondition({
    required this.property,
    required this.value,
    this.caseSensitive = true,
  });

  final int property;
  final String value;
  final bool caseSensitive;
}

/// Filter matching String values ending with the suffix.

final class EndsWithCondition extends Filter {
  /// Filters the results to only include objects where the property ends with
  /// [value].
  ///
  /// For String lists, at least one of the values in the list has to match.
  const EndsWithCondition({
    required this.property,
    required this.value,
    this.caseSensitive = true,
  });

  final int property;
  final String value;
  final bool caseSensitive;
}

/// Filter matching String values containing the String.
final class ContainsCondition extends Filter {
  /// Filters the results to only include objects where the String property
  /// contains [value].
  ///
  /// For String lists, at least one of the values in the list has to match.
  const ContainsCondition({
    required this.property,
    required this.value,
    this.caseSensitive = true,
  });

  final int property;
  final String value;
  final bool caseSensitive;
}

/// Filter matching String values matching the wildcard.
final class MatchesCondition extends Filter {
  /// Filters the results to only include objects where the property matches
  /// the [wildcard].
  ///
  /// For String lists, at least one of the values in the list has to match.
  const MatchesCondition({
    required this.property,
    required this.wildcard,
    this.caseSensitive = true,
  });

  final int property;
  final String wildcard;
  final bool caseSensitive;
}

/// Filter matching values that are `null`.
final class IsNullCondition extends Filter {
  /// Filters the results to only include objects where the property is null.
  const IsNullCondition({required this.property});

  final int property;
}

/// Filter matching empty lists.
final class ListIsEmptyCondition extends Filter {
  /// Filters the results to only include objects where the length of
  /// [property] is 0.
  ///
  /// Only list properties are supported.
  const ListIsEmptyCondition({
    required this.property,
  });

  final int property;
}

/// Logical AND.
class AndGroup extends Filter {
  /// Create a logical AND filter group.
  ///
  /// Matches when all [filters] match.
  const AndGroup(this.filters) : assert(filters.length > 0);

  /// The filters of this group.
  final List<Filter> filters;
}

/// Logical OR.
class OrGroup extends Filter {
  /// Create a logical OR filter group.
  ///
  /// Matches when any of the [filters] matches.
  const OrGroup(this.filters) : assert(filters.length > 0);

  /// The filters of this group.
  final List<Filter> filters;
}

/// Logical NOT.
class NotGroup extends Filter {
  /// Negate a filter.
  ///
  /// Matches when any of the [filter] doesn't matches.
  const NotGroup(this.filter);

  /// The filter to be negated.
  final Filter filter;
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
  const SortProperty({
    required this.property,
    required this.sort,
    this.caseSensitive = true,
  });

  /// Index of the property used for sorting.
  final int property;

  /// Sort order.
  final Sort sort;

  /// Should Strings be case sensitive?
  final bool caseSensitive;
}

/// Property used to filter duplicate values.
class DistinctProperty {
  /// Create a distinct property.
  const DistinctProperty({required this.property, this.caseSensitive = true});

  /// Index of the property used to determine distinct values.
  final int property;

  /// Should Strings be case sensitive?
  final bool caseSensitive;
}

/// Filter condition based on an embedded object.
class ObjectFilter extends Filter {
  /// Create a filter condition based on an embedded object.
  const ObjectFilter({
    required this.property,
    required this.filter,
  });

  /// Index of the property containing the embedded object.
  final int property;

  /// Filter condition that should be applied
  final Filter filter;
}
