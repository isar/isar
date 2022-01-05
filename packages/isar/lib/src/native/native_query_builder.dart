import 'package:isar/isar.dart';

import 'isar_collection_impl.dart';
import 'isar_core.dart';
import 'util/native_call.dart';
import 'index_key.dart';
import 'native_query.dart';

final minStr = Pointer<Int8>.fromAddress(0);
final maxStr = '\u{FFFFF}'.toNativeUtf8().cast<Int8>();

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
        sortProperty.sort == Sort.asc,
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
    deserialize = (col as IsarCollectionImpl<T>).deserializeObjects;
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
  return NativeQuery(col, queryPtr, deserialize, propertyId);
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
      sort == Sort.asc ? (wc.lower?[0] ?? minLong) : (wc.upper?[0] ?? maxLong),
      sort == Sort.asc ? (wc.upper?[0] ?? maxLong) : (wc.lower?[0] ?? minLong),
    ));
  } else {
    late Pointer<NativeType> lowerPtr;
    if (wc.lower != null) {
      lowerPtr = buildIndexKey(col, wc.indexName!, wc.lower!);
    } else {
      lowerPtr = buildLowerUnboundedIndexKey(col);
    }

    late Pointer<NativeType> upperPtr;
    if (wc.upper != null) {
      upperPtr = buildIndexKey(col, wc.indexName!, wc.upper!);
    } else {
      upperPtr = buildUpperUnboundedIndexKey(col);
    }

    nCall(IC.isar_qb_add_index_where_clause(
      qbPtr,
      col.indexIdOrErr(wc.indexName!),
      sort == Sort.asc ? lowerPtr : upperPtr,
      sort == Sort.asc ? wc.includeLower : wc.includeUpper,
      sort == Sort.asc ? upperPtr : lowerPtr,
      sort == Sort.asc ? wc.includeUpper : wc.includeLower,
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
  IC.isar_filter_and_or(
    filterPtrPtr,
    group.type == FilterGroupType.and,
    conditionsPtrPtr,
    group.filters.length,
  );

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
  IC.isar_filter_not(
    filterPtrPtr,
    filter,
  );

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
  final val1Raw = condition.value1;
  final val1 =
      val1Raw is DateTime ? val1Raw.toUtc().microsecondsSinceEpoch : val1Raw;

  final val2Raw = condition.value2;
  final val2 =
      val2Raw is DateTime ? val2Raw.toUtc().microsecondsSinceEpoch : val2Raw;

  final propertyId = col.propertyIds[condition.property];
  if (propertyId != null) {
    return _buildConditionInternal(
      col: col,
      conditionType: condition.type,
      propertyId: propertyId,
      val1: val1,
      val2: val2,
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
  required dynamic val1,
  required dynamic val2,
  required bool caseSensitive,
}) {
  final filterPtrPtr = malloc<Pointer<Pointer<NativeType>>>();

  switch (conditionType) {
    case ConditionType.eq:
      if (val1 == null) {
        nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, propertyId, true));
      } else if (val1 is bool) {
        final value = boolToByte(val1);
        nCall(IC.isar_filter_byte(
            col.ptr, filterPtrPtr, value, value, propertyId));
      } else if (val1 is int) {
        nCall(
            IC.isar_filter_long(col.ptr, filterPtrPtr, val1, val1, propertyId));
      } else if (val1 is String) {
        final strPtr = val1.toNativeUtf8();
        nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, strPtr.cast(),
            strPtr.cast(), caseSensitive, propertyId));
        malloc.free(strPtr);
      } else {
        throw 'Unsupported type for condition';
      }
      break;
    case ConditionType.between:
      final val = val1 ?? val2;
      if (val == null) {
        nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, propertyId, true));
      } else if (val is int) {
        nCall(IC.isar_filter_long(col.ptr, filterPtrPtr, val1 ?? nullLong,
            val2 ?? nullLong, propertyId));
      } else if (val is double) {
        nCall(IC.isar_filter_double(col.ptr, filterPtrPtr, val1 ?? nullDouble,
            val2 ?? nullDouble, propertyId));
      } else if (val is String) {
        late Pointer<Int8> lowerPtr;
        late Pointer<Int8> upperPtr;
        if (val1 is String) {
          lowerPtr = val1.toNativeUtf8().cast();
        } else {
          lowerPtr = minStr;
        }
        if (val2 is String) {
          upperPtr = val2.toNativeUtf8().cast();
        } else {
          upperPtr = minStr;
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
    case ConditionType.lt:
      if (val1 == null) {
        IC.isar_filter_static(filterPtrPtr, false);
      } else {
        if (val1 is int) {
          nCall(IC.isar_filter_long(
              col.ptr, filterPtrPtr, val1, maxLong, propertyId));
        } else if (val1 is double) {
          nCall(IC.isar_filter_double(
              col.ptr, filterPtrPtr, val1, maxDouble, propertyId));
        } else if (val1 is String) {
          final value = val1.toNativeUtf8();
          nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, value.cast(),
              maxStr, caseSensitive, propertyId));
          malloc.free(value);
        } else {
          throw 'Unsupported type for condition';
        }
        IC.isar_filter_not(filterPtrPtr, filterPtrPtr.value);
      }
      break;
    case ConditionType.lte:
      if (val1 == null) {
        nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, propertyId, true));
      } else if (val1 is int) {
        nCall(IC.isar_filter_long(
            col.ptr, filterPtrPtr, minLong, val1, propertyId));
      } else if (val1 is double) {
        nCall(IC.isar_filter_double(
            col.ptr, filterPtrPtr, minDouble, val1, propertyId));
      } else if (val1 is String) {
        final value = val1.toNativeUtf8();
        nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, minStr, value.cast(),
            caseSensitive, propertyId));
        malloc.free(value);
      } else {
        throw 'Unsupported type for condition';
      }
      break;
    case ConditionType.gt:
      if (val1 == null) {
        nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, propertyId, true));
      } else if (val1 is int) {
        nCall(IC.isar_filter_long(
            col.ptr, filterPtrPtr, minLong, val1, propertyId));
      } else if (val1 is double) {
        nCall(IC.isar_filter_double(
            col.ptr, filterPtrPtr, minDouble, val1, propertyId));
      } else if (val1 is String) {
        final value = val1.toNativeUtf8();
        nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, minStr, value.cast(),
            caseSensitive, propertyId));
        malloc.free(value);
      } else {
        throw 'Unsupported type for condition';
      }
      IC.isar_filter_not(filterPtrPtr, filterPtrPtr.value);
      break;
    case ConditionType.gte:
      if (val1 == null) {
        IC.isar_filter_static(filterPtrPtr, true);
      } else if (val1 is int) {
        nCall(IC.isar_filter_long(
            col.ptr, filterPtrPtr, minLong, val1, propertyId));
      } else if (val1 is double) {
        nCall(IC.isar_filter_double(
            col.ptr, filterPtrPtr, minDouble, val1, propertyId));
      } else if (val1 is String) {
        final value = val1.toNativeUtf8();
        nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, minStr, value.cast(),
            caseSensitive, propertyId));
        malloc.free(value);
      } else {
        throw 'Unsupported type for condition';
      }
      break;
    case ConditionType.startsWith:
      if (val1 is String) {
        final strPtr = val1.toNativeUtf8();
        nCall(IC.isar_filter_string_starts_with(
            col.ptr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId));
        malloc.free(strPtr);
      } else {
        throw 'Unsupported type for condition';
      }
      break;
    case ConditionType.endsWith:
      if (val1 is String) {
        final strPtr = val1.toNativeUtf8();
        nCall(IC.isar_filter_string_ends_with(
            col.ptr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId));
        malloc.free(strPtr);
      } else {
        throw 'Unsupported type for condition';
      }
      break;
    case ConditionType.contains:
      if (val1 is String) {
        final strPtr = val1.toNativeUtf8();
        nCall(IC.isar_filter_string_contains(
            col.ptr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId));
        malloc.free(strPtr);
      } else {
        throw 'Unsupported type for condition';
      }
      break;
    case ConditionType.matches:
      if (val1 is String) {
        final strPtr = val1.toNativeUtf8();
        nCall(IC.isar_filter_string_matches(
            col.ptr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId));
        malloc.free(strPtr);
      } else {
        throw 'Unsupported type for condition';
      }
      break;
    case ConditionType.isNull:
      nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, propertyId, false));
      break;
  }
  final filterPtr = filterPtrPtr.value;
  malloc.free(filterPtrPtr);
  return filterPtr;
}
