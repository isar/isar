part of isar_native;

final MIN_STR = Pointer<Int8>.fromAddress(0);
final MAX_STR = '\u{FFFFF}'.toNativeUtf8().cast<Int8>();

Query<T> buildNativeQuery<T>(
  IsarCollectionImpl col,
  List<WhereClause> whereClauses,
  bool? whereDistinct,
  Sort? whereSort,
  FilterGroup? filter,
  List<SortProperty> sortBy,
  List<DistinctProperty> distinctBy,
  int? offset,
  int? limit,
  String? property,
) {
  final qbPtr = IC.isar_qb_create(col.ptr);

  for (var whereClause in whereClauses) {
    _addWhereClause(col, qbPtr, whereClause, whereDistinct, whereSort);
  }

  if (filter != null) {
    final filterPtr = _buildFilter(col, filter);
    if (filterPtr != null) {
      IC.isar_qb_set_filter(qbPtr, filterPtr);
    }
  }

  for (var sortProperty in sortBy) {
    final propertyId = col.propertyIds[sortProperty.property];
    if (propertyId != null) {
      nCall(IC.isar_qb_add_sort_by(
        col.ptr,
        qbPtr,
        propertyId,
        sortProperty.sort == Sort.Asc,
      ));
    } else {
      throw 'Unknown property "${sortProperty.property}"';
    }
  }

  IC.isar_qb_set_offset_limit(qbPtr, offset ?? 0, limit ?? 99999);
  for (var distinctByProperty in distinctBy) {
    final propertyId = col.propertyIds[distinctByProperty.property];
    if (propertyId != null) {
      nCall(IC.isar_qb_add_distinct_by(
        col.ptr,
        qbPtr,
        propertyId,
        distinctByProperty.caseSensitive ?? true,
      ));
    } else {
      throw 'Unknown property "${distinctByProperty.property}"';
    }
  }

  QueryDeserialize<T> deserialize;
  int? propertyId;
  if (property == null) {
    deserialize = col.deserializeObjects as QueryDeserialize<T>;
  } else {
    propertyId = col.propertyIds[property];
    if (propertyId != null) {
      deserialize =
          (rawObjSet) => col.deserializeProperty(rawObjSet, propertyId!);
    } else {
      throw 'Unknown property "$property"';
    }
  }

  final queryPtr = IC.isar_qb_build(qbPtr);
  return NativeQuery(col.isar, col.ptr, queryPtr, deserialize, propertyId);
}

void _addWhereClause(IsarCollectionImpl col, Pointer qbPtr, WhereClause wc,
    bool? distinct, Sort? sort) {
  if (wc.indexName == null) {
    if (wc.lower != null && wc.lower!.length != 1 || wc.lower![0] is! int?) {
      throw 'Invalid WhereClause';
    }
    if (wc.upper != null && wc.upper!.length != 1 || wc.upper![0] is! int?) {
      throw 'Invalid WhereClause';
    }
    nCall(IC.isar_qb_add_id_where_clause(
      qbPtr,
      sort == Sort.Asc
          ? (wc.lower?[0] ?? Isar.minId)
          : (wc.upper?[0] ?? Isar.maxId),
      sort == Sort.Asc
          ? (wc.upper?[0] ?? Isar.maxId)
          : (wc.lower?[0] ?? Isar.minId),
    ));
  } else {
    late Pointer<NativeType> lowerPtr;
    if (wc.lower != null) {
      lowerPtr = buildIndexKey(col, wc.indexName!, wc.lower!);
    } else {
      lowerPtr = buildLowerUnboundedIndexKey(col, wc.indexName!);
    }

    late Pointer<NativeType> upperPtr;
    if (wc.upper != null) {
      upperPtr = buildIndexKey(col, wc.indexName!, wc.upper!);
    } else {
      upperPtr = buildUpperUnboundedIndexKey(col, wc.indexName!);
    }

    nCall(IC.isar_qb_add_index_where_clause(
      qbPtr,
      sort == Sort.Asc ? lowerPtr : upperPtr,
      sort == Sort.Asc ? wc.includeLower : wc.includeUpper,
      sort == Sort.Asc ? upperPtr : lowerPtr,
      sort == Sort.Asc ? wc.includeUpper : wc.includeLower,
      distinct ?? false,
    ));
  }
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

Pointer<NativeType>? _buildFilter(
    IsarCollectionImpl col, FilterOperation filter) {
  if (filter is FilterGroup) {
    return _buildFilterGroup(col, filter);
  } else if (filter is FilterNot) {
    return _buildFilterNot(col, filter);
  } else if (filter is LinkFilter) {
    return _buildLink(col, filter);
  } else if (filter is FilterCondition) {
    return _buildCondition(col, filter);
  }
}

Pointer<NativeType>? _buildFilterGroup(
    IsarCollectionImpl col, FilterGroup group) {
  final builtConditions = group.filters
      .map((op) => _buildFilter(col, op))
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
  nCall(IC.isar_filter_and_or(
    filterPtrPtr,
    group.type == FilterGroupType.And,
    conditionsPtrPtr,
    group.filters.length,
  ));

  final filterPtr = filterPtrPtr.value;
  malloc.free(conditionsPtrPtr);
  malloc.free(filterPtrPtr);
  return filterPtr;
}

Pointer<NativeType>? _buildFilterNot(IsarCollectionImpl col, FilterNot not) {
  final filter = _buildFilter(col, not.filter);

  if (filter == null) {
    return null;
  }

  final filterPtrPtr = malloc<Pointer<NativeType>>();
  nCall(IC.isar_filter_not(
    filterPtrPtr,
    filter,
  ));

  final filterPtr = filterPtrPtr.value;
  malloc.free(filterPtrPtr);
  return filterPtr;
}

Pointer<NativeType>? _buildLink(IsarCollectionImpl col, LinkFilter link) {
  final targetCol = link.targetCollection as IsarCollectionImpl;

  var backlink = false;
  var linkId = col.linkIds[link.linkName];
  if (linkId == null) {
    linkId = col.backlinkIds[link.linkName];
    backlink = true;

    if (linkId == null) {
      throw 'Unknown link property "${link.linkName}"';
    }
  }

  final condition = _buildFilter(targetCol, link.filter);
  if (condition == null) return null;

  final filterPtrPtr = malloc<Pointer<NativeType>>();

  if (backlink) {
    nCall(IC.isar_filter_link(
      targetCol.ptr,
      filterPtrPtr,
      condition,
      linkId,
      true,
    ));
  } else {
    nCall(IC.isar_filter_link(
      col.ptr,
      filterPtrPtr,
      condition,
      linkId,
      false,
    ));
  }

  final filterPtr = filterPtrPtr.value;
  malloc.free(filterPtrPtr);
  return filterPtr;
}

Pointer<NativeType> _buildCondition(
    IsarCollectionImpl col, FilterCondition condition) {
  final lowerRaw = condition.lower;
  final lower =
      lowerRaw is DateTime ? lowerRaw.toUtc().microsecondsSinceEpoch : lowerRaw;

  final upperRaw = condition.upper;
  final upper =
      upperRaw is DateTime ? upperRaw.toUtc().microsecondsSinceEpoch : upperRaw;

  final propertyId = col.propertyIds[condition.property];
  if (propertyId != null) {
    return _buildConditionInternal(
      col: col,
      conditionType: condition.type,
      propertyId: propertyId,
      lower: lower,
      upper: upper,
      caseSensitive: condition.caseSensitive,
    );
  } else {
    throw 'Unknown property "${condition.property}"';
  }
}

Pointer<NativeType> _buildConditionInternal({
  required IsarCollectionImpl col,
  required ConditionType conditionType,
  required int propertyId,
  required dynamic lower,
  required dynamic upper,
  required bool caseSensitive,
}) {
  final filterPtrPtr = malloc<Pointer<Pointer<NativeType>>>();

  switch (conditionType) {
    case ConditionType.Eq:
      if (lower == null) {
        nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, false, propertyId));
      } else if (lower is bool) {
        final value = boolToByte(lower);
        nCall(IC.isar_filter_byte(
            col.ptr, filterPtrPtr, value, value, propertyId));
      } else if (lower is int) {
        nCall(IC.isar_filter_long(
            col.ptr, filterPtrPtr, lower, lower, propertyId));
      } else if (lower is String) {
        final strPtr = lower.toNativeUtf8();
        nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, strPtr.cast(),
            strPtr.cast(), caseSensitive, propertyId));
        malloc.free(strPtr);
      } else {
        throw 'Unsupported type for condition';
      }
      break;
    case ConditionType.Between:
      final val = lower ?? upper;
      if (val == null) {
        nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, false, propertyId));
      } else if (val is int) {
        nCall(IC.isar_filter_long(col.ptr, filterPtrPtr, lower ?? nullLong,
            upper ?? nullLong, propertyId));
      } else if (val is double) {
        nCall(IC.isar_filter_double(col.ptr, filterPtrPtr, lower ?? nullDouble,
            upper ?? nullDouble, propertyId));
      } else if (val is String) {
        late Pointer<Int8> lowerPtr;
        late Pointer<Int8> upperPtr;
        if (lower is String) {
          lowerPtr = lower.toNativeUtf8().cast();
        } else {
          lowerPtr = MIN_STR;
        }
        if (upper is String) {
          upperPtr = upper.toNativeUtf8().cast();
        } else {
          upperPtr = MIN_STR;
        }
        nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, lowerPtr, upperPtr,
            caseSensitive, propertyId));
        if (!lowerPtr.isNull) {
          malloc.free(lowerPtr);
        }
        if (!upperPtr.isNull) {
          malloc.free(upperPtr);
        }
      } else {
        throw 'Unsupported type for condition';
      }
      break;
    case ConditionType.Lt:
      if (lower == null) {
        nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, true, propertyId));
      } else if (lower is int) {
        nCall(IC.isar_filter_long(
            col.ptr, filterPtrPtr, lower, maxLong, propertyId));
      } else if (lower is double) {
        nCall(IC.isar_filter_double(
            col.ptr, filterPtrPtr, lower, maxDouble, propertyId));
      } else if (lower is String) {
        final value = lower.toNativeUtf8();
        nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, value.cast(),
            MAX_STR, caseSensitive, propertyId));
        malloc.free(value);
      } else {
        throw 'Unsupported type for condition';
      }
      nCall(IC.isar_filter_not(filterPtrPtr, filterPtrPtr.value));
      break;
    case ConditionType.Gt:
      if (lower == null) {
        nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, false, propertyId));
      } else if (lower is int) {
        nCall(IC.isar_filter_long(
            col.ptr, filterPtrPtr, minLong, lower, propertyId));
      } else if (lower is double) {
        nCall(IC.isar_filter_double(
            col.ptr, filterPtrPtr, minDouble, lower, propertyId));
      } else if (lower is String) {
        final value = lower.toNativeUtf8();
        nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, MIN_STR,
            value.cast(), caseSensitive, propertyId));
        malloc.free(value);
      } else {
        throw 'Unsupported type for condition';
      }
      nCall(IC.isar_filter_not(filterPtrPtr, filterPtrPtr.value));
      break;
    case ConditionType.StartsWith:
      if (lower is String) {
        final strPtr = lower.toNativeUtf8();
        nCall(IC.isar_filter_string_starts_with(
            col.ptr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId));
        malloc.free(strPtr);
      } else {
        throw 'Unsupported type for condition';
      }
      break;
    case ConditionType.EndsWith:
      if (lower is String) {
        final strPtr = lower.toNativeUtf8();
        nCall(IC.isar_filter_string_ends_with(
            col.ptr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId));
        malloc.free(strPtr);
      } else {
        throw 'Unsupported type for condition';
      }
      break;
    case ConditionType.Matches:
      if (lower is String) {
        final strPtr = lower.toNativeUtf8();
        nCall(IC.isar_filter_string_matches(
            col.ptr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId));
        malloc.free(strPtr);
      } else {
        throw 'Unsupported type for condition';
      }
      break;
    default:
      throw 'Unreachable';
  }
  final filterPtr = filterPtrPtr.value;
  malloc.free(filterPtrPtr);
  return filterPtr;
}
