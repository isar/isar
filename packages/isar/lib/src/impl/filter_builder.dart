import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/impl/bindings.dart';
import 'package:isar/src/impl/isar_core.dart';

Pointer<CFilter> buildFilter(Allocator alloc, Filter filter) {
  if (filter is FilterGroup) {
    return _buildGroup(alloc, filter);
  } else if (filter is FilterCondition) {
    return _buildCondition(alloc, filter);
  } else {
    throw UnimplementedError();
  }
}

Pointer<CFilter> _buildGroup(Allocator alloc, FilterGroup group) {
  final filters = alloc<Pointer<CFilter>>(group.filters.length);
  for (var i = 0; i < group.filters.length; i++) {
    final filter = group.filters[i];
    filters[i] = buildFilter(alloc, filter);
  }
  switch (group.type) {
    case FilterGroupType.and:
      return IC.isar_filter_and(filters, group.filters.length);
    case FilterGroupType.or:
      return IC.isar_filter_or(filters, group.filters.length);
    case FilterGroupType.not:
      return IC.isar_filter_not(filters[0]);
  }
}

Pointer<CFilter> _buildCondition(Allocator alloc, FilterCondition condition) {
  switch (condition.type) {
    case FilterConditionType.equalTo:
      return IC.isar_filter_equal_to(
        condition.property,
        _buildValue(alloc, condition.value1!),
        condition.caseSensitive,
      );
    case FilterConditionType.greaterThan:
      return IC.isar_filter_greater_than(
        condition.property,
        _buildValue(alloc, condition.value1!),
        condition.include1,
        condition.caseSensitive,
      );
    case FilterConditionType.lessThan:
      return IC.isar_filter_less_than(
        condition.property,
        _buildValue(alloc, condition.value1!),
        condition.include1,
        condition.caseSensitive,
      );
    case FilterConditionType.between:
      return IC.isar_filter_between(
        condition.property,
        _buildValue(alloc, condition.value1!),
        condition.include1,
        _buildValue(alloc, condition.value2!),
        condition.include2,
        condition.caseSensitive,
      );
    case FilterConditionType.startsWith:
      return IC.isar_filter_string_starts_with(
        condition.property,
        _buildValue(alloc, condition.value1!),
        condition.caseSensitive,
      );
    case FilterConditionType.endsWith:
      return IC.isar_filter_string_ends_with(
        condition.property,
        _buildValue(alloc, condition.value1!),
        condition.caseSensitive,
      );
    case FilterConditionType.contains:
      return IC.isar_filter_string_contains(
        condition.property,
        _buildValue(alloc, condition.value1!),
        condition.caseSensitive,
      );
    case FilterConditionType.matches:
      return IC.isar_filter_string_matches(
        condition.property,
        _buildValue(alloc, condition.value1!),
        condition.caseSensitive,
      );
    case FilterConditionType.isNull:
      return IC.isar_filter_is_null(condition.property);
    case FilterConditionType.listLength:
      throw UnimplementedError();
  }
}

Pointer<CFilterValue> _buildValue(Allocator alloc, Object value) {
  if (value is int) {
    return IC.isar_filter_value_integer(value);
  } else if (value is String) {
    return IC.isar_filter_value_string(
      value.toUtf16Pointer(alloc),
      value.length,
    );
  } else if (identical(value, FilterCondition.nullString)) {
    return IC.isar_filter_value_string(nullptr, 0);
  } else if (value is bool) {
    return IC.isar_filter_value_bool(value, false);
  } else if (identical(value, FilterCondition.nullBool)) {
    return IC.isar_filter_value_bool(false, true);
  } else if (value is double) {
    return IC.isar_filter_value_real(value);
  } else {
    throw UnimplementedError();
  }
}
