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
  final T? value2;
  final bool caseSensitive;

  const FilterCondition({
    required this.type,
    required this.property,
    T? value,
    this.caseSensitive = true,
  })  : value1 = value,
        value2 = null,
        assert(type != ConditionType.Between);

  const FilterCondition.between({
    required this.property,
    T? lower,
    T? upper,
    this.caseSensitive = true,
  })  : value1 = lower,
        value2 = upper,
        type = ConditionType.Between;
}

enum ConditionType {
  Eq,
  Gt,
  Gte,
  Lt,
  Lte,
  Between,
  StartsWith,
  EndsWith,
  Contains,
  Matches,
  IsNull,
}

enum FilterGroupType {
  And,
  Or,
}

class FilterGroup extends FilterOperation {
  final List<FilterOperation> filters;
  final FilterGroupType type;

  const FilterGroup({
    required this.filters,
    required this.type,
  });
}

class FilterNot extends FilterOperation {
  final FilterOperation filter;

  const FilterNot({
    required this.filter,
  });
}

enum Sort {
  Asc,
  Desc,
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
