part of isar;

Pointer<CFilter> _buildFilter(Allocator alloc, Filter filter) {
  switch (filter) {
    case EqualCondition():
      final value = filter.value;
      if (value is double) {
        return isar_filter_between(
          filter.property,
          _isarValue(
            _adjustLowerFloatBound(value, true, filter.epsilon),
          ),
          _isarValue(
            _adjustUpperFloatBound(value, true, filter.epsilon),
          ),
          filter.caseSensitive,
        );
      } else {
        return isar_filter_equal(
          filter.property,
          _isarValue(filter.value),
          filter.caseSensitive,
        );
      }
    case NotEqualCondition():
      throw UnimplementedError();
    case GreaterCondition():
      final rawValue = filter.value;
      final value = rawValue is double
          ? _adjustLowerFloatBound(rawValue, false, filter.epsilon)
          : rawValue;
      return isar_filter_greater(
        filter.property,
        _isarValue(value),
        filter.caseSensitive,
      );
    case GreaterOrEqualCondition():
      final rawValue = filter.value;
      final value = rawValue is double
          ? _adjustLowerFloatBound(rawValue, true, filter.epsilon)
          : rawValue;
      return isar_filter_greater_or_equal(
        filter.property,
        _isarValue(value),
        filter.caseSensitive,
      );
    case LessCondition():
      final rawValue = filter.value;
      final value = rawValue is double
          ? _adjustUpperFloatBound(rawValue, false, filter.epsilon)
          : rawValue;
      return isar_filter_less(
        filter.property,
        _isarValue(value),
        filter.caseSensitive,
      );
    case LessOrEqualCondition():
      final rawValue = filter.value;
      final value = rawValue is double
          ? _adjustUpperFloatBound(rawValue, true, filter.epsilon)
          : rawValue;
      return isar_filter_less_or_equal(
        filter.property,
        _isarValue(value),
        filter.caseSensitive,
      );
    case BetweenCondition():
      final rawLower = filter.lower;
      final lower = rawLower is double
          ? _adjustLowerFloatBound(rawLower, true, filter.epsilon)
          : rawLower;
      final rawUpper = filter.upper;
      final upper = rawUpper is double
          ? _adjustUpperFloatBound(rawUpper, true, filter.epsilon)
          : rawUpper;
      return isar_filter_between(
        filter.property,
        _isarValue(lower),
        _isarValue(upper),
        filter.caseSensitive,
      );
    case StartsWithCondition():
      return isar_filter_string_starts_with(
        filter.property,
        _isarValue(filter.value),
        filter.caseSensitive,
      );
    case EndsWithCondition():
      return isar_filter_string_ends_with(
        filter.property,
        _isarValue(filter.value),
        filter.caseSensitive,
      );
    case ContainsCondition():
      return isar_filter_string_contains(
        filter.property,
        _isarValue(filter.value),
        filter.caseSensitive,
      );
    case MatchesCondition():
      return isar_filter_string_matches(
        filter.property,
        _isarValue(filter.wildcard),
        filter.caseSensitive,
      );
    case IsNullCondition():
      return isar_filter_is_null(filter.property);
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
      return isar_filter_nested(
        filter.property,
        _buildFilter(alloc, filter.filter),
      );
  }
}

Pointer<CIsarValue> _isarValue(Object? value) {
  if (value == null) {
    return nullptr;
  } else if (value is int) {
    return isar_value_integer(value);
  } else if (value is String) {
    return isar_value_string(IsarCore.toNativeString(value));
  } else if (value is bool) {
    return isar_value_bool(value);
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
