part of isar_native;

const MIN_OID = -140737488355328;
const MAX_OID = 140737488355327;

Query<T> buildQuery<T>(
  IsarCollection collection,
  List<WhereClause> whereClauses,
  bool? whereDistinct,
  bool? whereAscending,
  FilterGroup filter,
  List<SortProperty> sortProperties,
  List<DistinctProperty> distinctByProperties,
  int? offset,
  int? limit,
  int? propertyIndex,
) {
  final col = collection as IsarCollectionImpl;
  final qbPtr = IC.isar_qb_create(col.ptr);

  if ((whereDistinct != null || whereAscending != null) &&
      whereClauses.length > 1) {
    throw IsarError('You can only use a single index for sorting or distinct.');
  }

  for (var whereClause in whereClauses) {
    _addWhereClause(col.ptr, qbPtr, whereClause, whereDistinct, whereAscending);
  }
  final filterPtr = _buildFilter(col.ptr, filter);
  if (filterPtr != null) {
    IC.isar_qb_set_filter(qbPtr, filterPtr);
  }

  for (var sortProperty in sortProperties) {
    nCall(IC.isar_qb_add_sort_by(
      col.ptr,
      qbPtr,
      sortProperty.propertyIndex,
      sortProperty.ascending,
    ));
  }

  IC.isar_qb_set_offset_limit(qbPtr, offset ?? 0, limit ?? 99999);
  for (var distinctByProperty in distinctByProperties) {
    nCall(IC.isar_qb_add_distinct_by(
      col.ptr,
      qbPtr,
      distinctByProperty.propertyIndex,
      distinctByProperty.caseSensitive ?? true,
    ));
  }

  QueryDeserialize<T> deserialize;
  if (propertyIndex == null) {
    deserialize = (col as IsarCollectionImpl<T>).deserializeObjects
        as QueryDeserialize<T>;
  } else {
    deserialize =
        (rawObjSet) => collection.deserializeProperty(rawObjSet, propertyIndex);
  }

  final queryPtr = IC.isar_qb_build(qbPtr);
  return NativeQuery(col.isar, col.ptr, queryPtr, deserialize, propertyIndex);
}

void _addWhereClause(Pointer colPtr, Pointer qbPtr, WhereClause wc,
    bool? distinct, bool? ascending) {
  if (wc.index == null) {
    nCall(IC.isar_qb_add_id_where_clause(
      colPtr,
      qbPtr,
      wc.lower?[0] ?? MIN_OID,
      wc.upper?[0] ?? MAX_OID,
      ascending ?? true,
    ));
  } else {
    final wcPtrPtr = malloc<Pointer<NativeType>>();
    nCall(IC.isar_wc_create(
      colPtr,
      wcPtrPtr,
      wc.index!,
      distinct ?? false,
      ascending ?? true,
    ));
    final wcPtr = wcPtrPtr.value;

    for (var i = 0; i < wc.types.length; i++) {
      addWhereValue(
        wcPtr: wcPtr,
        type: wc.types[i],
        lower: wc.lower?[i],
        upper: wc.upper?[i],
        lowerUnbound: wc.lower == null,
        upperUnbound: wc.upper == null,
      );
    }

    nCall(IC.isar_qb_add_index_where_clause(
      qbPtr,
      wcPtrPtr.value,
      wc.includeLower,
      wc.includeUpper,
    ));
    malloc.free(wcPtrPtr);
  }
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
  required bool lowerUnbound,
  required dynamic upper,
  required bool upperUnbound,
}) {
  switch (type) {
    case 'Bool':
      lower = boolToByte(lower);
      if (upperUnbound) {
        upper = maxBool;
      } else {
        upper = boolToByte(upper);
      }
      IC.isar_wc_add_byte(wcPtr, lower, upper);
      return;
    case 'Int':
      lower ??= nullInt;
      if (upperUnbound) {
        upper = maxInt;
      } else {
        upper ??= nullInt;
      }
      IC.isar_wc_add_int(wcPtr, lower, upper);
      return;
    case 'Float':
      lower ??= nullFloat;
      if (upperUnbound) {
        upper = maxFloat;
      } else {
        upper ??= nullFloat;
      }
      IC.isar_wc_add_float(wcPtr, lower, upper);
      return;
    case 'Long':
      lower ??= nullLong;
      if (upperUnbound) {
        upper = maxLong;
      } else {
        upper ??= nullLong;
      }
      IC.isar_wc_add_long(wcPtr, lower, upper);
      return;
    case 'Double':
      lower ??= nullDouble;
      if (upperUnbound) {
        upper = maxDouble;
      } else {
        upper ??= nullDouble;
      }
      IC.isar_wc_add_double(wcPtr, lower, upper);
      return;
    default:
      if (type.startsWith('String')) {
        var lowerPtr = Pointer<Int8>.fromAddress(0);
        var upperPtr = Pointer<Int8>.fromAddress(0);
        if (lower != null) {
          lowerPtr = (lower as String).toNativeUtf8().cast();
        }
        if (upper != null) {
          upperPtr = (upper as String).toNativeUtf8().cast();
        }
        final caseSensitive = !type.endsWith('LC');
        late int indexType;
        switch (type) {
          case 'StringValue':
          case 'StringValueLC':
            indexType = IndexType.value.index;
            break;
          case 'StringHash':
          case 'StringHashLC':
            indexType = IndexType.hash.index;
            break;
          case 'StringWords':
          case 'StringWordsLC':
            assert(
                upper != null &&
                    upper.isNotEmpty &&
                    lower != null &&
                    lower.isNotEmpty,
                'Null or empty words are unsupported');
            indexType = IndexType.words.index;
            break;
          case 'StringObjectId':
          case 'StringObjectIdLC':
            //IC.isar_wc_add_string_word(wcPtr, lowerPtr,upperPtr,caseSensitive);
            break;
          default:
            throw UnimplementedError();
        }

        IC.isar_wc_add_string(wcPtr, lowerPtr, upperPtr, lowerUnbound,
            upperUnbound, caseSensitive, indexType);

        if (lower != null) {
          malloc.free(lowerPtr);
        }
        if (upper != null) {
          malloc.free(upperPtr);
        }
      }
      return;
  }
}

Pointer<NativeType>? _buildFilter(Pointer colPtr, QueryOperation filter) {
  if (filter is FilterGroup) {
    return _buildFilterGroup(colPtr, filter);
  } else if (filter is LinkOperation) {
    return _buildLink(colPtr, filter);
  } else {
    return _buildCondition(colPtr, filter as QueryCondition);
  }
}

Pointer<NativeType>? _buildFilterGroup(Pointer colPtr, FilterGroup group) {
  final builtConditions = group.conditions
      .map((op) => _buildFilter(colPtr, op))
      .where((it) => it != null)
      .toList();

  if (builtConditions.isEmpty) {
    return null;
  }

  final conditionsPtrPtr = malloc<Pointer<NativeType>>(builtConditions.length);

  for (var i = 0; i < builtConditions.length; i++) {
    conditionsPtrPtr[i] = builtConditions[i]!;
  }

  final filterPtrPtr = malloc<Pointer<NativeType>>();
  if (group.groupType == FilterGroupType.Not) {
    nCall(IC.isar_filter_not(
      filterPtrPtr,
      conditionsPtrPtr.elementAt(0),
    ));
  } else {
    nCall(IC.isar_filter_and_or(
      filterPtrPtr,
      group.groupType == FilterGroupType.And,
      conditionsPtrPtr,
      group.conditions.length,
    ));
  }

  final filterPtr = filterPtrPtr.value;
  malloc.free(conditionsPtrPtr);
  malloc.free(filterPtrPtr);
  return filterPtr;
}

Pointer<NativeType>? _buildLink(Pointer colPtr, LinkOperation link) {
  final condition = _buildFilter(colPtr, link.filter);
  if (condition == null) return null;

  final targetCol = link.targetCollection as IsarCollectionImpl;
  final filterPtrPtr = malloc<Pointer<NativeType>>();

  if (link.backlink) {
    nCall(IC.isar_filter_link(
      targetCol.ptr,
      colPtr,
      filterPtrPtr,
      condition,
      link.linkIndex,
      true,
    ));
  } else {
    nCall(IC.isar_filter_link(
      colPtr,
      targetCol.ptr,
      filterPtrPtr,
      condition,
      link.linkIndex,
      false,
    ));
  }

  final filterPtr = filterPtrPtr.value;
  malloc.free(filterPtrPtr);
  return filterPtr;
}

Pointer<NativeType> _buildCondition(Pointer colPtr, QueryCondition condition) {
  final propertyType =
      condition.propertyType == 'DateTime' ? 'Long' : condition.propertyType;

  final lower = condition.propertyType == 'DateTime'
      ? (condition.lower as DateTime?)?.toUtc().microsecondsSinceEpoch
      : condition.lower;

  final upper = condition.propertyType == 'DateTime'
      ? (condition.upper as DateTime?)?.toUtc().microsecondsSinceEpoch
      : condition.upper;

  return _buildConditionInternal(
    colPtr: colPtr,
    conditionType: condition.conditionType,
    pIndex: condition.propertyIndex,
    propertyType: propertyType,
    lower: lower,
    includeLower: condition.includeLower,
    upper: upper,
    includeUpper: condition.includeUpper,
    caseSensitive: condition.caseSensitive,
  );
}

Pointer<NativeType> _buildConditionInternal({
  required Pointer colPtr,
  required ConditionType conditionType,
  required int pIndex,
  required String propertyType,
  required dynamic? lower,
  required bool includeLower,
  required dynamic? upper,
  required bool includeUpper,
  required bool caseSensitive,
}) {
  final filterPtrPtr = malloc<Pointer<Pointer<NativeType>>>();

  switch (conditionType) {
    case ConditionType.Eq:
      if (lower == null) {
        nCall(IC.isar_filter_is_null(colPtr, filterPtrPtr, pIndex));
        break;
      }
      switch (propertyType) {
        case 'Bool':
          final value = boolToByte(lower!);
          nCall(IC.isar_filter_byte_between(
              colPtr, filterPtrPtr, value, true, value, true, pIndex));
          break;
        case 'Int':
          nCall(IC.isar_filter_int_between(
              colPtr, filterPtrPtr, lower!, true, lower, true, pIndex));
          break;
        case 'Long':
          nCall(IC.isar_filter_long_between(
              colPtr, filterPtrPtr, lower!, true, lower, true, pIndex));
          break;
        case 'String':
          final strPtr = (lower as String).toNativeUtf8();
          nCall(IC.isar_filter_string_equal(
              colPtr, filterPtrPtr, strPtr.cast(), caseSensitive, pIndex));
          malloc.free(strPtr);
          break;
        default:
          throw UnimplementedError();
      }
      break;
    case ConditionType.Gt:
      switch (propertyType) {
        case 'Int':
          nCall(IC.isar_filter_int_between(colPtr, filterPtrPtr,
              lower ?? nullInt, includeLower, maxInt, true, pIndex));
          break;
        case 'Float':
          nCall(IC.isar_filter_float_between(colPtr, filterPtrPtr,
              lower ?? nullFloat, includeLower, maxFloat, true, pIndex));
          break;
        case 'Long':
          nCall(IC.isar_filter_long_between(colPtr, filterPtrPtr,
              lower ?? nullLong, includeLower, maxLong, true, pIndex));
          break;
        case 'Double':
          nCall(IC.isar_filter_double_between(colPtr, filterPtrPtr,
              lower ?? nullDouble, includeLower, maxDouble, true, pIndex));
          break;
        default:
          throw UnimplementedError();
      }
      break;
    case ConditionType.Lt:
      switch (propertyType) {
        case 'Int':
          IC.isar_filter_int_between(colPtr, filterPtrPtr, minInt, true,
              upper ?? nullInt, includeUpper, pIndex);
          break;
        case 'Float':
          IC.isar_filter_float_between(colPtr, filterPtrPtr, minFloat, true,
              upper ?? nullFloat, includeUpper, pIndex);
          break;
        case 'Long':
          IC.isar_filter_long_between(colPtr, filterPtrPtr, minLong, true,
              upper ?? nullLong, includeUpper, pIndex);
          break;
        case 'Double':
          IC.isar_filter_double_between(colPtr, filterPtrPtr, minDouble, true,
              upper ?? nullDouble, includeUpper, pIndex);
          break;
        default:
          throw UnimplementedError();
      }
      break;
    case ConditionType.Between:
      switch (propertyType) {
        case 'Int':
          IC.isar_filter_int_between(colPtr, filterPtrPtr, lower ?? nullInt,
              includeLower, upper ?? nullInt, includeUpper, pIndex);
          break;
        case 'Float':
          IC.isar_filter_float_between(colPtr, filterPtrPtr, lower ?? nullFloat,
              includeLower, upper ?? nullFloat, includeUpper, pIndex);
          break;
        case 'Long':
          IC.isar_filter_long_between(colPtr, filterPtrPtr, lower ?? nullLong,
              includeLower, upper ?? nullLong, includeUpper, pIndex);
          break;
        case 'Double':
          IC.isar_filter_double_between(
              colPtr,
              filterPtrPtr,
              lower ?? nullDouble,
              includeLower,
              upper ?? nullDouble,
              includeUpper,
              pIndex);
          break;
        default:
          throw UnimplementedError();
      }
      break;
    case ConditionType.StartsWith:
      if (propertyType == 'String') {
        final strPtr = (lower as String).toNativeUtf8();
        nCall(IC.isar_filter_string_starts_with(
            colPtr, filterPtrPtr, strPtr.cast(), caseSensitive, pIndex));
        malloc.free(strPtr);
      } else {
        throw UnimplementedError();
      }
      break;
    case ConditionType.EndsWith:
      if (propertyType == 'String') {
        final strPtr = (lower as String).toNativeUtf8();
        nCall(IC.isar_filter_string_ends_with(
            colPtr, filterPtrPtr, strPtr.cast(), caseSensitive, pIndex));
        malloc.free(strPtr);
      } else {
        throw UnimplementedError();
      }
      break;
    case ConditionType.Contains:
      switch (propertyType) {
        case 'String':
          final strPtr = '*$lower*'.toNativeUtf8();
          nCall(IC.isar_filter_string_matches(
              colPtr, filterPtrPtr, strPtr.cast(), caseSensitive, pIndex));
          malloc.free(strPtr);
          break;
        case 'IntList':
          IC.isar_filter_int_list_contains(
              colPtr, filterPtrPtr, lower ?? nullInt, pIndex);
          break;
        case 'LongList':
          IC.isar_filter_long_list_contains(
              colPtr, filterPtrPtr, lower ?? nullLong, pIndex);
          break;
        case 'StringList':
          final strPtr = (lower as String).toNativeUtf8();
          nCall(IC.isar_filter_string_list_contains(
              colPtr, filterPtrPtr, strPtr.cast(), caseSensitive, pIndex));
          malloc.free(strPtr);
          break;
        default:
          throw UnimplementedError();
      }
      break;
    case ConditionType.Matches:
      switch (propertyType) {
        case 'String':
          final strPtr = (lower as String).toNativeUtf8();
          nCall(IC.isar_filter_string_matches(
              colPtr, filterPtrPtr, strPtr.cast(), caseSensitive, pIndex));
          malloc.free(strPtr);
          break;
        default:
          throw UnimplementedError();
      }
      break;
  }
  final filterPtr = filterPtrPtr.value;
  malloc.free(filterPtrPtr);
  return filterPtr;
}
