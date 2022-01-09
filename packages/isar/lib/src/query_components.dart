part of isar;

class WhereClause {
  final String? indexName;
  final List? lower;
  final bool includeLower;
  final List? upper;
  final bool includeUpper;

  const WhereClause({
    this.indexName,
    this.lower,
    this.includeLower = true,
    this.upper,
    this.includeUpper = true,
  });
}

abstract class FilterOperation {
  const FilterOperation();
}

class FilterCondition<T> extends FilterOperation {
  final ConditionType type;
  final String property;
  final T? value1;
  final bool include1;
  final T? value2;
  final bool include2;
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

enum FilterGroupType {
  and,
  or,
  not,
}

class FilterGroup extends FilterOperation {
  final List<FilterOperation> filters;
  final FilterGroupType type;

  const FilterGroup.and(this.filters) : type = FilterGroupType.and;

  const FilterGroup.or(this.filters) : type = FilterGroupType.or;

  FilterGroup.not(FilterOperation filter)
      : filters = [filter],
        type = FilterGroupType.or;
}

enum Sort {
  asc,
  desc,
}

class SortProperty {
  final String property;
  final Sort sort;

  const SortProperty({required this.property, required this.sort});
}

class DistinctProperty {
  final String property;
  final bool? caseSensitive;

  const DistinctProperty({required this.property, this.caseSensitive});
}

class LinkFilter extends FilterOperation {
  final IsarCollection targetCollection;
  final FilterOperation filter;
  final String linkName;

  const LinkFilter({
    required this.targetCollection,
    required this.filter,
    required this.linkName,
  });
}
