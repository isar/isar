// ignore_for_file: prefer_initializing_formals

part of isar;

/// A where clause to traverse an Isar index.
abstract class WhereClause {
  const WhereClause._();
}

/// A where clause traversing the primary index (ids).
class IdWhereClause extends WhereClause {
  /// Where clause that matches all ids. Useful to get sorted results.
  const IdWhereClause.any()
      : lower = null,
        upper = null,
        includeLower = true,
        includeUpper = true,
        super._();

  /// Where clause that matches all id values greater than the given [lower]
  /// bound.
  const IdWhereClause.greaterThan({
    required int lower,
    this.includeLower = true,
  })  : lower = lower,
        upper = null,
        includeUpper = true,
        super._();

  /// Where clause that matches all id values less than the given [upper]
  /// bound.
  const IdWhereClause.lessThan({
    required int upper,
    this.includeUpper = true,
  })  : upper = upper,
        lower = null,
        includeLower = true,
        super._();

  /// Where clause that matches the id value equal to the given [value].
  const IdWhereClause.equalTo({
    required int value,
  })  : lower = value,
        upper = value,
        includeLower = true,
        includeUpper = true,
        super._();

  /// Where clause that matches all id values between the given [lower] and
  /// [upper] bounds.
  const IdWhereClause.between({
    this.lower,
    this.includeLower = true,
    this.upper,
    this.includeUpper = true,
  }) : super._();

  /// The lower bound id or `null` for unbounded.
  final int? lower;

  /// Whether the lower bound should be included in the results.
  final bool includeLower;

  /// The upper bound id or `null` for unbounded.
  final int? upper;

  /// Whether the upper bound should be included in the results.
  final bool includeUpper;
}

/// A where clause traversing an index.
class IndexWhereClause extends WhereClause {
  /// Where clause that matches all index values. Useful to get sorted results.
  const IndexWhereClause.any({required this.indexName})
      : lower = null,
        upper = null,
        includeLower = true,
        includeUpper = true,
        super._();

  /// Where clause that matches all index values greater than the given [lower]
  /// bound.
  ///
  /// For composite indexes, the first elements of the [lower] list are checked
  /// for equality.
  const IndexWhereClause.greaterThan({
    required this.indexName,
    required IndexKey lower,
    this.includeLower = true,
  })  : lower = lower,
        upper = null,
        includeUpper = true,
        super._();

  /// Where clause that matches all index values less than the given [upper]
  /// bound.
  ///
  /// For composite indexes, the first elements of the [upper] list are checked
  /// for equality.
  const IndexWhereClause.lessThan({
    required this.indexName,
    required IndexKey upper,
    this.includeUpper = true,
  })  : upper = upper,
        lower = null,
        includeLower = true,
        super._();

  /// Where clause that matches all index values equal to the given [value].
  const IndexWhereClause.equalTo({
    required this.indexName,
    required IndexKey value,
  })  : lower = value,
        upper = value,
        includeLower = true,
        includeUpper = true,
        super._();

  /// Where clause that matches all index values between the given [lower] and
  /// [upper] bounds.
  ///
  /// For composite indexes, the first elements of the [lower] and [upper] lists
  /// are checked for equality.
  const IndexWhereClause.between({
    required this.indexName,
    required IndexKey lower,
    this.includeLower = true,
    required IndexKey upper,
    this.includeUpper = true,
  })  : lower = lower,
        upper = upper,
        super._();

  /// The Isar name of the index to be used.
  final String indexName;

  /// The lower bound of the where clause.
  final IndexKey? lower;

  /// Whether the lower bound should be included in the results. Double values
  /// are never included.
  final bool includeLower;

  /// The upper bound of the where clause.
  final IndexKey? upper;

  /// Whether the upper bound should be included in the results. Double values
  /// are never included.
  final bool includeUpper;
}

/// A where clause traversing objects linked to the specified object.
class LinkWhereClause extends WhereClause {
  /// Create a where clause for the specified link.
  const LinkWhereClause({
    required this.linkName,
    required this.id,
  }) : super._();

  /// The isar name of the link to be used.
  final String linkName;

  /// The id of the source object.
  final int id;
}

/// @nodoc
@protected
abstract class FilterOperation {
  const FilterOperation._();
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
class FilterCondition extends FilterOperation {
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
    required String property,
    required Object? value,
    this.caseSensitive = true,
  })  : type = FilterConditionType.equalTo,
        property = property,
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
    required Object? value,
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
    required Object? value,
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
    Object? lower,
    bool includeLower = true,
    Object? upper,
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
  /// For lists, at least one of the values in the list has to match.
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
  /// For lists, at least one of the values in the list has to match.
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

  /// Filters the results to only include objects where the property contains
  /// [value].
  ///
  /// For lists, at least one of the values in the list has to match.
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
  /// For lists, at least one of the values in the list has to match.
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
  ///
  /// Lists match if they are null.
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
  /// [property] is between [lower] and [upper].
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
        super._();

  /// Type of the filter condition.
  final FilterConditionType type;

  /// Property used for comparisons.
  final String property;

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

  /// Logical XOR.
  xor,

  /// Logical NOT.
  not,
}

/// Group one or more filter conditions.
class FilterGroup extends FilterOperation {
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

  /// Create a logical XOR filter group.
  ///
  /// Matches when exactly one of the [filters] matches.
  const FilterGroup.xor(this.filters)
      : type = FilterGroupType.xor,
        super._();

  /// Negate a filter.
  ///
  /// Matches when any of the [filter] doesn't matches.
  FilterGroup.not(FilterOperation filter)
      : filters = [filter],
        type = FilterGroupType.not,
        super._();

  /// Type of this group.
  final FilterGroupType type;

  /// The filter(s) to be grouped.
  final List<FilterOperation> filters;
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

  /// Isar name of the property used for sorting.
  final String property;

  /// Sort order.
  final Sort sort;
}

/// Property used to filter duplicate values.
class DistinctProperty {
  /// Create a distinct property.
  const DistinctProperty({required this.property, this.caseSensitive});

  /// Isar name of the property used for sorting.
  final String property;

  /// Should Strings be case sensitive?
  final bool? caseSensitive;
}

/// Filter condition based on an embedded object.
class ObjectFilter extends FilterOperation {
  /// Create a filter condition based on an embedded object.
  const ObjectFilter({
    required this.property,
    required this.filter,
  }) : super._();

  /// Property containing the embedded object(s).
  final String property;

  /// Filter condition that should be applied
  final FilterOperation filter;
}

/// Filter condition based on a link.
class LinkFilter extends FilterOperation {
  /// Create a filter condition based on a link.
  const LinkFilter({
    required this.linkName,
    required FilterOperation filter,
  })  : filter = filter,
        lower = null,
        upper = null,
        super._();

  /// Create a filter condition based on the number of linked objects.
  const LinkFilter.length({
    required this.linkName,
    required int lower,
    required int upper,
  })  : filter = null,
        lower = lower,
        upper = upper,
        super._();

  /// Isar name of the link.
  final String linkName;

  /// Filter condition that should be applied
  final FilterOperation? filter;

  /// The minumum number of linked objects
  final int? lower;

  /// The maximum number of linked objects
  final int? upper;
}
