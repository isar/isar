part of isar;

Pointer<CFilter> _buildFilter(Allocator alloc, Filter filter) {
  switch (filter) {
    case EqualToCondition():
      final value = filter.value;
      if (value is double) {
        return isar_filter_between(
          filter.property,
          _buildFilterValue(
            _adjustLowerFloatBound(value, true, filter.epsilon),
          ),
          true,
          _buildFilterValue(
            _adjustUpperFloatBound(value, true, filter.epsilon),
          ),
          true,
          filter.caseSensitive,
        );
      } else {
        return isar_filter_equal_to(
          filter.property,
          _buildFilterValue(filter.value),
          filter.caseSensitive,
        );
      }
    case GreaterThanCondition():
      final rawValue = filter.value;
      final value = rawValue is double
          ? _adjustLowerFloatBound(rawValue, filter.include, filter.epsilon)
          : rawValue;
      return isar_filter_greater_than(
        filter.property,
        _buildFilterValue(value),
        filter.include,
        filter.caseSensitive,
      );
    case LessThanCondition():
      final rawValue = filter.value;
      final value = rawValue is double
          ? _adjustUpperFloatBound(rawValue, filter.include, filter.epsilon)
          : rawValue;
      return isar_filter_less_than(
        filter.property,
        _buildFilterValue(value),
        filter.include,
        filter.caseSensitive,
      );
    case BetweenCondition():
      final rawLower = filter.lower;
      final lower = rawLower is double
          ? _adjustLowerFloatBound(
              rawLower,
              filter.includeLower,
              filter.epsilon,
            )
          : rawLower;
      final rawUpper = filter.upper;
      final upper = rawUpper is double
          ? _adjustUpperFloatBound(
              rawUpper,
              filter.includeUpper,
              filter.epsilon,
            )
          : rawUpper;
      return isar_filter_between(
        filter.property,
        _buildFilterValue(lower),
        filter.includeLower,
        _buildFilterValue(upper),
        filter.includeUpper,
        filter.caseSensitive,
      );
    case StartsWithCondition():
      return isar_filter_string_starts_with(
        filter.property,
        _buildFilterValue(filter.value),
        filter.caseSensitive,
      );
    case EndsWithCondition():
      return isar_filter_string_ends_with(
        filter.property,
        _buildFilterValue(filter.value),
        filter.caseSensitive,
      );
    case ContainsCondition():
      return isar_filter_string_contains(
        filter.property,
        _buildFilterValue(filter.value),
        filter.caseSensitive,
      );
    case MatchesCondition():
      return isar_filter_string_matches(
        filter.property,
        _buildFilterValue(filter.wildcard),
        filter.caseSensitive,
      );
    case IsNullCondition():
      return isar_filter_is_null(filter.property);
    case ListLengthCondition():
      throw UnimplementedError();
    case AndGroup():
      if (filter.filters.length == 1) {
        return _buildFilter(alloc, filter.filters[0]);
      } else {
        final filters = alloc<Pointer<CFilter>>(filter.filters.length);
        for (var i = 0; i < filter.filters.length; i++) {
          filters[i] = _buildFilter(alloc, filter.filters[i]);
        }
        return isar_filter_and(filters, filter.filters.length);
      }
    case OrGroup():
      if (filter.filters.length == 1) {
        return _buildFilter(alloc, filter.filters[0]);
      } else {
        final filters = alloc<Pointer<CFilter>>(filter.filters.length);
        for (var i = 0; i < filter.filters.length; i++) {
          filters[i] = _buildFilter(alloc, filter.filters[i]);
        }
        return isar_filter_or(filters, filter.filters.length);
      }
    case NotGroup():
      return isar_filter_not(_buildFilter(alloc, filter.filter));
    case ObjectFilter():
      throw UnimplementedError();
  }
}

Pointer<CIsarValue> _buildFilterValue(Object value) {
  if (value is int) {
    return isar_value_integer(value);
  } else if (value is String) {
    return isar_value_string(IsarCore.toNativeString(value));
  } else if (identical(value, Filter.nullString)) {
    return isar_value_string(nullptr);
  } else if (value is bool) {
    return isar_value_bool(value, false);
  } else if (identical(value, Filter.nullBool)) {
    return isar_value_bool(false, true);
  } else if (value is double) {
    return isar_value_real(value);
  } else if (value is DateTime) {
    return isar_value_integer(value.toUtc().microsecondsSinceEpoch);
  } else {
    throw UnimplementedError();
  }
}

double _adjustLowerFloatBound(double value, bool include, double epsilon) {
  if (value.isFinite) {
    if (include) {
      return value - epsilon;
    } else {
      return value + epsilon;
    }
  } else {
    return value;
  }
}

double _adjustUpperFloatBound(double value, bool include, double epsilon) {
  if (value.isFinite) {
    if (include) {
      return value + epsilon;
    } else {
      return value - epsilon;
    }
  } else {
    return value;
  }
}
