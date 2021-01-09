part of isar_native;

NativeQuery<T> buildQuery<T extends IsarObject>(IsarCollection<T> collection,
    List<WhereClause> whereClauses, FilterGroup filter) {
  final col = collection as IsarCollectionImpl<T>;
  final colPtr = col.collectionPtr;
  final qbPtr = IC.isar_qb_create(col.isar.isarPtr, colPtr);
  for (var whereClause in whereClauses) {
    _addWhereClause(colPtr, qbPtr, whereClause);
  }
  final filterPtr = _buildFilter(colPtr, filter);
  if (filterPtr != null) {
    IC.isar_qb_set_filter(qbPtr, filterPtr);
  }

  final queryPtr = IC.isar_qb_build(qbPtr);
  return NativeQuery(col, queryPtr);
}

void _addWhereClause(Pointer colPtr, Pointer qbPtr, WhereClause wc) {
  final wcPtrPtr = allocate<Pointer<NativeType>>();
  nCall(IC.isar_wc_create(colPtr, wcPtrPtr, wc.index == null, wc.index ?? 999));
  final wcPtr = wcPtrPtr.value;

  final resolvedWc = resolveWhereClause(wc);
  for (var i = 0; i < wc.types.length; i++) {
    addWhereValue(
      wcPtr: wcPtr,
      type: resolvedWc.types[i],
      lower: resolvedWc.lower![i],
      upper: resolvedWc.upper![i],
    );
  }

  IC.isar_qb_add_where_clause(
    qbPtr,
    wcPtrPtr.value,
    wc.includeLower,
    wc.includeUpper,
  );
  free(wcPtrPtr);
}

WhereClause resolveWhereClause(WhereClause wc) {
  final lower = [];
  final upper = [];

  for (var i = 0; i < wc.types.length; i++) {
    var lowerValue = wc.lower?[i];
    var upperValue = wc.upper?[i];
    switch (wc.types[i]) {
      case 'Bool':
        lowerValue = boolToByte(lowerValue);
        if (wc.upper == null) {
          upperValue = maxBool;
        } else {
          upperValue = boolToByte(upperValue);
        }
        break;

      case 'Int':
        lowerValue ??= nullInt;
        if (wc.upper == null) {
          upperValue = maxInt;
        } else {
          upperValue ??= nullInt;
        }
        break;

      case 'Float':
        lowerValue ??= nullFloat;
        if (wc.upper == null) {
          upperValue = maxFloat;
        } else {
          upperValue ??= nullFloat;
        }
        break;

      case 'Long':
        lowerValue ??= nullLong;
        if (wc.upper == null) {
          upperValue = maxLong;
        } else {
          upperValue ??= nullLong;
        }
        break;

      case 'Double':
        lowerValue ??= nullDouble;
        if (wc.upper == null) {
          upperValue = maxDouble;
        } else {
          upperValue ??= nullDouble;
        }
        break;

      case 'String':
        break;
    }

    if (i != wc.types.length - 1) {
      requireEqual(lowerValue, upperValue);
    }

    lower.add(lowerValue);
    upper.add(upperValue);
  }

  return WhereClause(
    wc.index,
    wc.types,
    lower: lower,
    includeLower: wc.includeLower,
    upper: upper,
    includeUpper: wc.includeUpper,
  );
}

void requireEqual(dynamic v1, dynamic v2) {
  if (v1 is num && v2 is num) {
    if (v1.compareTo(v2) == 0) {
      return;
    }
  }
  if (v1 == v2) {
    return;
  }

  throw 'Only the last part of a composite index comparison may be a range.';
}

int boolToByte(bool? value) {
  if (value == null) {
    return nullBool;
  } else if (value) {
    return trueBool;
  } else {
    return falseBool;
  }
}

void addWhereValue({
  required Pointer wcPtr,
  required String type,
  required dynamic lower,
  required dynamic upper,
}) {
  switch (type) {
    case 'Bool':
      IC.isar_wc_add_byte(wcPtr, lower, upper);
      return;
    case 'Int':
      IC.isar_wc_add_int(wcPtr, lower, upper);
      return;
    case 'Float':
      IC.isar_wc_add_float(wcPtr, lower, upper);
      return;
    case 'Long':
      IC.isar_wc_add_long(wcPtr, lower, upper);
      return;
    case 'Double':
      IC.isar_wc_add_double(wcPtr, lower, upper);
      return;
    case 'String':
      var lowerPtr = Pointer<Int8>.fromAddress(0);
      var upperPtr = Pointer<Int8>.fromAddress(0);
      if (lower != null) {
        lowerPtr = Utf8.toUtf8(lower).cast();
      }
      if (upper != null) {
        upperPtr = Utf8.toUtf8(upper).cast();
      }
      //IC.isar_wc_add_string_value(wcPtr, lowerPtr, upperPtr);
      if (lower != null) {
        free(lowerPtr);
      }
      if (upper != null) {
        free(upperPtr);
      }
      return;
  }
}

Pointer<NativeType>? _buildFilter(Pointer colPtr, FilterGroup filter) {
  final builtConditions = filter.conditions
      .map((op) {
        if (op is FilterGroup) {
          return _buildFilter(colPtr, op);
        } else if (op is QueryCondition) {
          return _buildCondition(colPtr, op);
        }
      })
      .where((it) => it != null)
      .toList();

  if (builtConditions.isEmpty) {
    return null;
  }

  final conditionsPtrPtr =
      allocate<Pointer<NativeType>>(count: builtConditions.length);

  for (var i = 0; i < builtConditions.length; i++) {
    conditionsPtrPtr[i] = builtConditions[i]!;
  }

  final filterPtrPtr = allocate<Pointer<NativeType>>();
  nCall(IC.isar_filter_and_or(
    filterPtrPtr,
    filter.andOr == FilterAndOr.And,
    conditionsPtrPtr,
    filter.conditions.length,
  ));

  final filterPtr = filterPtrPtr.value;
  free(filterPtrPtr);
  return filterPtr;
}

Pointer<NativeType> _buildCondition(Pointer colPtr, QueryCondition condition) {
  final filterPtrPtr = allocate<Pointer<Pointer<NativeType>>>();
  final pIndex = condition.propertyIndex;
  final include = condition.includeValue;
  final include2 = condition.includeValue2;
  switch (condition.conditionType) {
    case ConditionType.IsNull:
      nCall(IC.isar_filter_is_null(colPtr, filterPtrPtr, true, pIndex));
      break;
    case ConditionType.IsNotNull:
      nCall(IC.isar_filter_is_null(colPtr, filterPtrPtr, false, pIndex));
      break;
    case ConditionType.Eq:
      switch (condition.propertyType) {
        case 'Bool':
          final value = boolToByte(condition.value);
          nCall(IC.isar_filter_byte_between(
              colPtr, filterPtrPtr, value, true, value, true, pIndex));
          break;
        case 'Int':
          final value = condition.value ?? nullInt;
          nCall(IC.isar_filter_int_between(
              colPtr, filterPtrPtr, value, true, value, true, pIndex));
          break;
        case 'Long':
          final value = condition.value ?? nullLong;
          nCall(IC.isar_filter_long_between(
              colPtr, filterPtrPtr, value, true, value, true, pIndex));
          break;
        default:
          throw UnimplementedError();
      }
      break;
    case ConditionType.NEq:
      switch (condition.propertyType) {
        case 'Bool':
          final value = boolToByte(condition.value);
          nCall(IC.isar_filter_byte_not_equal(
              colPtr, filterPtrPtr, value, pIndex));
          break;
        case 'Int':
          final value = condition.value ?? nullInt;
          nCall(IC.isar_filter_int_not_equal(
              colPtr, filterPtrPtr, value, pIndex));
          break;
        case 'Long':
          final value = condition.value ?? nullLong;
          nCall(IC.isar_filter_long_not_equal(
              colPtr, filterPtrPtr, value, pIndex));
          break;
        default:
          throw UnimplementedError();
      }
      break;
    case ConditionType.Gt:
      switch (condition.propertyType) {
        case 'Bool':
          final value = boolToByte(condition.value);
          nCall(IC.isar_filter_byte_between(
              colPtr, filterPtrPtr, value, include, maxBool, true, pIndex));
          break;
        case 'Int':
          final value = condition.value ?? nullInt;
          nCall(IC.isar_filter_int_between(
              colPtr, filterPtrPtr, value, include, maxInt, true, pIndex));
          break;
        case 'Float':
          final value = condition.value ?? nullFloat;
          nCall(IC.isar_filter_float_between(
              colPtr, filterPtrPtr, value, include, maxFloat, true, pIndex));
          break;
        case 'Long':
          final value = condition.value ?? nullLong;
          nCall(IC.isar_filter_long_between(
              colPtr, filterPtrPtr, value, include, maxLong, true, pIndex));
          break;
        case 'Double':
          final value = condition.value ?? nullDouble;
          nCall(IC.isar_filter_double_between(
              colPtr, filterPtrPtr, value, include, maxDouble, true, pIndex));
          break;
        default:
          throw UnimplementedError();
      }
      break;
    case ConditionType.Lt:
      switch (condition.propertyType) {
        case 'Bool':
          final value = boolToByte(condition.value);
          IC.isar_filter_byte_between(
              colPtr, filterPtrPtr, minBool, true, value, include, pIndex);
          break;
        case 'Int':
          final value = condition.value ?? nullInt;
          IC.isar_filter_int_between(
              colPtr, filterPtrPtr, minInt, true, value, include, pIndex);
          break;
        case 'Float':
          final value = condition.value ?? nullFloat;
          IC.isar_filter_float_between(
              colPtr, filterPtrPtr, minFloat, true, value, include, pIndex);
          break;
        case 'Long':
          final value = condition.value ?? nullLong;
          IC.isar_filter_long_between(
              colPtr, filterPtrPtr, minLong, true, value, include, pIndex);
          break;
        case 'Double':
          final value = condition.value ?? nullDouble;
          IC.isar_filter_double_between(
              colPtr, filterPtrPtr, minDouble, true, value, include, pIndex);
          break;
        default:
          throw UnimplementedError();
      }
      break;
    case ConditionType.Between:
      switch (condition.propertyType) {
        case 'Bool':
          final lower = boolToByte(condition.value);
          final upper = boolToByte(condition.value2);
          IC.isar_filter_byte_between(
              colPtr, filterPtrPtr, lower, include, upper, include2, pIndex);
          break;
        case 'Int':
          final lower = condition.value ?? nullInt;
          final upper = condition.value2 ?? nullInt;
          IC.isar_filter_int_between(
              colPtr, filterPtrPtr, lower, include, upper, include2, pIndex);
          break;
        case 'Float':
          final lower = condition.value ?? nullFloat;
          final upper = condition.value2 ?? nullFloat;
          IC.isar_filter_float_between(
              colPtr, filterPtrPtr, lower, include, upper, include2, pIndex);
          break;
        case 'Long':
          final lower = condition.value ?? nullLong;
          final upper = condition.value2 ?? nullLong;
          IC.isar_filter_long_between(
              colPtr, filterPtrPtr, lower, include, upper, include2, pIndex);
          break;
        case 'Double':
          final lower = condition.value ?? nullDouble;
          final upper = condition.value2 ?? nullDouble;
          IC.isar_filter_double_between(
              colPtr, filterPtrPtr, lower, include, upper, include2, pIndex);
          break;
        default:
          throw UnimplementedError();
      }
      break;
    case ConditionType.StartsWith:
      // TODO: Handle this case.
      break;
    case ConditionType.Contains:
      // TODO: Handle this case.
      break;
  }
  final filterPtr = filterPtrPtr.value;
  free(filterPtrPtr);
  return filterPtr;
}
