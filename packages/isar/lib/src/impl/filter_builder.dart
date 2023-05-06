import 'dart:ffi';

import 'package:isar/isar.dart';
import 'package:isar/src/impl/bindings.dart';

Pointer<CFilter> buildFilter(Allocator alloc, Filter filter) {
  switch (filter) {
    case EqualToCondition():
      return IsarCore.isar_filter_equal_to(
        filter.property,
        _buildValue(alloc, filter.value),
        filter.caseSensitive,
      );
    case GreaterThanCondition():
      return IsarCore.isar_filter_greater_than(
        filter.property,
        _buildValue(alloc, filter.value),
        filter.include,
        filter.caseSensitive,
      );
    case LessThanCondition():
      return IsarCore.isar_filter_less_than(
        filter.property,
        _buildValue(alloc, filter.value),
        filter.include,
        filter.caseSensitive,
      );
    case BetweenCondition():
      return IsarCore.isar_filter_between(
        filter.property,
        _buildValue(alloc, filter.lower),
        filter.includeLower,
        _buildValue(alloc, filter.upper),
        filter.includeUpper,
        filter.caseSensitive,
      );
    case StartsWithCondition():
      return IsarCore.isar_filter_string_starts_with(
        filter.property,
        _buildValue(alloc, filter.value),
        filter.caseSensitive,
      );
    case EndsWithCondition():
      return IsarCore.isar_filter_string_ends_with(
        filter.property,
        _buildValue(alloc, filter.value),
        filter.caseSensitive,
      );
    case ContainsCondition():
      return IsarCore.isar_filter_string_contains(
        filter.property,
        _buildValue(alloc, filter.value),
        filter.caseSensitive,
      );
    case MatchesCondition():
      return IsarCore.isar_filter_string_matches(
        filter.property,
        _buildValue(alloc, filter.wildcard),
        filter.caseSensitive,
      );
    case IsNullCondition():
      return IsarCore.isar_filter_is_null(filter.property);
    case ListLengthCondition():
      throw UnimplementedError();
    case AndGroup():
      final filters = alloc<Pointer<CFilter>>(filter.filters.length);
      for (var i = 0; i < filter.filters.length; i++) {
        filters[i] = buildFilter(alloc, filter.filters[i]);
      }
      return IsarCore.isar_filter_and(filters, filter.filters.length);
    case OrGroup():
      final filters = alloc<Pointer<CFilter>>(filter.filters.length);
      for (var i = 0; i < filter.filters.length; i++) {
        filters[i] = buildFilter(alloc, filter.filters[i]);
      }
      return IsarCore.isar_filter_or(filters, filter.filters.length);
    case NotGroup():
      return IsarCore.isar_filter_not(buildFilter(alloc, filter.filter));
    case ObjectFilter():
      throw UnimplementedError();
  }
}

Pointer<CFilterValue> _buildValue(Allocator alloc, Object value) {
  if (value is int) {
    return IsarCore.isar_filter_value_integer(value);
  } else if (value is String) {
    return IsarCore.isar_filter_value_string(IsarCore.toNativeString(value));
  } else if (identical(value, Filter.nullString)) {
    return IsarCore.isar_filter_value_string(nullptr);
  } else if (value is bool) {
    return IsarCore.isar_filter_value_bool(value, false);
  } else if (identical(value, Filter.nullBool)) {
    return IsarCore.isar_filter_value_bool(false, true);
  } else if (value is double) {
    return IsarCore.isar_filter_value_real(value);
  } else {
    throw UnimplementedError();
  }
}
