part of '../../isar.dart';

Pointer<CFilter> _buildFilter(Filter filter, List<Pointer<void>> pointers) {
  switch (filter) {
    case IsNullCondition():
      return IsarCore.b.isar_filter_is_null(filter.property);
    case EqualCondition():
      final value = filter.value;
      if (value is double) {
        return IsarCore.b.isar_filter_between(
          filter.property,
          _isarValue(_adjustLowerFloatBound(value, true, filter.epsilon)),
          _isarValue(_adjustUpperFloatBound(value, true, filter.epsilon)),
          filter.caseSensitive,
        );
      } else {
        return IsarCore.b.isar_filter_equal(
          filter.property,
          _isarValue(filter.value),
          filter.caseSensitive,
        );
      }
    case GreaterCondition():
      final rawValue = filter.value;
      final value =
          rawValue is double
              ? _adjustLowerFloatBound(rawValue, false, filter.epsilon)
              : rawValue;
      return IsarCore.b.isar_filter_greater(
        filter.property,
        _isarValue(value),
        filter.caseSensitive,
      );
    case GreaterOrEqualCondition():
      final rawValue = filter.value;
      final value =
          rawValue is double
              ? _adjustLowerFloatBound(rawValue, true, filter.epsilon)
              : rawValue;
      return IsarCore.b.isar_filter_greater_or_equal(
        filter.property,
        _isarValue(value),
        filter.caseSensitive,
      );
    case LessCondition():
      final rawValue = filter.value;
      final value =
          rawValue is double
              ? _adjustUpperFloatBound(rawValue, false, filter.epsilon)
              : rawValue;
      return IsarCore.b.isar_filter_less(
        filter.property,
        _isarValue(value),
        filter.caseSensitive,
      );
    case LessOrEqualCondition():
      final rawValue = filter.value;
      final value =
          rawValue is double
              ? _adjustUpperFloatBound(rawValue, true, filter.epsilon)
              : rawValue;
      return IsarCore.b.isar_filter_less_or_equal(
        filter.property,
        _isarValue(value),
        filter.caseSensitive,
      );
    case BetweenCondition():
      final rawLower = filter.lower;
      final lower =
          rawLower is double
              ? _adjustLowerFloatBound(rawLower, true, filter.epsilon)
              : rawLower;
      final rawUpper = filter.upper;
      final upper =
          rawUpper is double
              ? _adjustUpperFloatBound(rawUpper, true, filter.epsilon)
              : rawUpper;
      return IsarCore.b.isar_filter_between(
        filter.property,
        _isarValue(lower),
        _isarValue(upper),
        filter.caseSensitive,
      );
    case StartsWithCondition():
      return IsarCore.b.isar_filter_string_starts_with(
        filter.property,
        _isarValue(filter.value),
        filter.caseSensitive,
      );
    case EndsWithCondition():
      return IsarCore.b.isar_filter_string_ends_with(
        filter.property,
        _isarValue(filter.value),
        filter.caseSensitive,
      );
    case ContainsCondition():
      return IsarCore.b.isar_filter_string_contains(
        filter.property,
        _isarValue(filter.value),
        filter.caseSensitive,
      );
    case MatchesCondition():
      return IsarCore.b.isar_filter_string_matches(
        filter.property,
        _isarValue(filter.wildcard),
        filter.caseSensitive,
      );
    case RegexCondition():
      return IsarCore.b.isar_filter_string_matches(
        filter.property,
        _isarValue(filter.regex),
        filter.caseSensitive,
      );
    case IsInCondition():
      final values = _isarValues(filter.values);
      return IsarCore.b.isar_filter_in(
        filter.property,
        values,
        filter.values.length,
        filter.caseSensitive,
      );
    case AndGroup():
      if (filter.filters.length == 1) {
        return _buildFilter(filter.filters[0], pointers);
      } else {
        final filtersPtrPtr = malloc<Pointer<CFilter>>(filter.filters.length);
        pointers.add(filtersPtrPtr);
        for (var i = 0; i < filter.filters.length; i++) {
          filtersPtrPtr.setPtrAt(i, _buildFilter(filter.filters[i], pointers));
        }
        return IsarCore.b.isar_filter_and(filtersPtrPtr, filter.filters.length);
      }
    case OrGroup():
      if (filter.filters.length == 1) {
        return _buildFilter(filter.filters[0], pointers);
      } else {
        final filtersPtrPtr = malloc<Pointer<CFilter>>(filter.filters.length);
        pointers.add(filtersPtrPtr);
        for (var i = 0; i < filter.filters.length; i++) {
          filtersPtrPtr.setPtrAt(i, _buildFilter(filter.filters[i], pointers));
        }
        return IsarCore.b.isar_filter_or(filtersPtrPtr, filter.filters.length);
      }
    case NotGroup():
      return IsarCore.b.isar_filter_not(_buildFilter(filter.filter, pointers));
    case ObjectFilter():
      return IsarCore.b.isar_filter_nested(
        filter.property,
        _buildFilter(filter.filter, pointers),
      );
  }
}

Pointer<CIsarValue> _isarValue(Object? value) {
  if (value == null) {
    return nullptr;
  } else if (value is double) {
    return IsarCore.b.isar_value_real(value);
    // ignore: avoid_double_and_int_checks
  } else if (value is int) {
    return IsarCore.b.isar_value_integer(value);
  } else if (value is String) {
    return IsarCore.b.isar_value_string(IsarCore._toNativeString(value));
  } else if (value is bool) {
    return IsarCore.b.isar_value_bool(value);
  } else if (value is DateTime) {
    return IsarCore.b.isar_value_integer(value.toUtc().microsecondsSinceEpoch);
  } else {
    throw ArgumentError('Unsupported filter value type: ${value.runtimeType}');
  }
}

Pointer<COption_IsarValue> _isarValues(List<Object?> values) {
  final valuesPtr = IsarCore.b.isar_values_new(values.length);
  for (var i = 0; i < values.length; i++) {
    final value = values[i];
    switch (value) {
      case bool():
        IsarCore.b.isar_values_set_bool(valuesPtr, i, value);
      case int():
        IsarCore.b.isar_values_set_integer(valuesPtr, i, value);
      case double():
        IsarCore.b.isar_values_set_real(valuesPtr, i, value);
      case String():
        IsarCore.b.isar_values_set_string(
          valuesPtr,
          i,
          IsarCore._toNativeString(value),
        );
      case DateTime():
        IsarCore.b.isar_values_set_integer(
          valuesPtr,
          i,
          value.toUtc().microsecondsSinceEpoch,
        );
      case null:
      // do nothing
      default:
        throw ArgumentError(
          'Unsupported filter value type: ${value.runtimeType}',
        );
    }
  }
  return valuesPtr;
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
