import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';

import 'isar_collection_impl.dart';
import 'isar_core.dart';
import 'index_key.dart';
import 'query_impl.dart';

final minStr = Pointer<Int8>.fromAddress(0);
final maxStr = '\u{FFFFF}'.toNativeUtf8().cast<Int8>();

Query<T> buildNativeQuery<T>(
  IsarCollectionImpl col,
  List<WhereClause> whereClauses,
  bool whereDistinct,
  Sort whereSort,
  FilterOperation? filter,
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
    final alloc = Arena(malloc);
    try {
      final filterPtr = _buildFilter(col, filter, alloc);
      if (filterPtr != null) {
        IC.isar_qb_set_filter(qbPtr, filterPtr);
      }
    } finally {
      alloc.releaseAll();
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

  if (offset != null || limit != null) {
    IC.isar_qb_set_offset_limit(qbPtr, offset ?? -1, limit ?? -1);
  }

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
  return QueryImpl(col, queryPtr, deserialize, propertyId);
}

void _addWhereClause(IsarCollectionImpl col, Pointer qbPtr, WhereClause wc,
    bool distinct, Sort sort) {
  if (wc.indexName == null) {
    if (wc.lower != null && wc.lower!.length != 1 || wc.lower?[0] is! int?) {
      throw 'Invalid WhereClause';
    }
    if (wc.upper != null && wc.upper!.length != 1 || wc.upper?[0] is! int?) {
      throw 'Invalid WhereClause';
    }
    nCall(IC.isar_qb_add_id_where_clause(
      qbPtr,
      sort == Sort.asc
          ? (wc.lower?[0] as int? ?? nullLong)
          : (wc.upper?[0] as int? ?? maxLong),
      sort == Sort.asc
          ? (wc.upper?[0] as int? ?? nullLong)
          : (wc.lower?[0] as int? ?? minLong),
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
      distinct,
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
  IsarCollectionImpl col,
  FilterOperation filter,
  Allocator alloc,
) {
  if (filter is FilterGroup) {
    return _buildFilterGroup(col, filter, alloc);
  } else if (filter is LinkFilter) {
    return _buildLink(col, filter, alloc);
  } else if (filter is FilterCondition) {
    return _buildCondition(col, filter, alloc);
  }
}

Pointer<NativeType>? _buildFilterGroup(
    IsarCollectionImpl col, FilterGroup group, Allocator alloc) {
  final builtConditions = group.filters
      .map((op) => _buildFilter(col, op, alloc))
      .where((it) => it != null)
      .toList();

  if (builtConditions.isEmpty) {
    return null;
  }

  final conditionsPtrPtr = alloc<Pointer<NativeType>>(builtConditions.length);

  for (var i = 0; i < builtConditions.length; i++) {
    conditionsPtrPtr[i] = builtConditions[i]!;
  }

  final filterPtrPtr = alloc<Pointer<NativeType>>();
  if (group.type == FilterGroupType.not) {
    IC.isar_filter_not(
      filterPtrPtr,
      builtConditions.first!,
    );
  } else {
    IC.isar_filter_and_or(
      filterPtrPtr,
      group.type == FilterGroupType.and,
      conditionsPtrPtr,
      group.filters.length,
    );
  }

  return filterPtrPtr.value;
}

Pointer<NativeType>? _buildLink(
    IsarCollectionImpl col, LinkFilter link, Allocator alloc) {
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

  final condition = _buildFilter(targetCol, link.filter, alloc);
  if (condition == null) return null;

  final filterPtrPtr = alloc<Pointer<NativeType>>();

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

  return filterPtrPtr.value;
}

Pointer<NativeType> _buildCondition(
    IsarCollectionImpl col, FilterCondition condition, Allocator alloc) {
  final val1Raw = condition.value1;
  final val1 =
      val1Raw is DateTime ? val1Raw.toUtc().microsecondsSinceEpoch : val1Raw;

  final val2Raw = condition.value2;
  final val2 =
      val2Raw is DateTime ? val2Raw.toUtc().microsecondsSinceEpoch : val2Raw;

  final propertyId = col.propertyIds[condition.property];
  if (propertyId == null && col.idName != condition.property) {
    throw 'Unknown property "${condition.property}"';
  }
  switch (condition.type) {
    case ConditionType.isNull:
      return _buildConditionIsNull(
          col: col, propertyId: propertyId, alloc: alloc);
    case ConditionType.eq:
      return _buildConditionEqual(
        col: col,
        propertyId: propertyId,
        val: val1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
    case ConditionType.between:
      return _buildConditionBetween(
        col: col,
        propertyId: propertyId,
        lower: val1,
        includeLower: condition.include1,
        upper: val2,
        includeUpper: condition.include2,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
    case ConditionType.lt:
      return _buildConditionLessThan(
        col: col,
        propertyId: propertyId,
        val: val1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
    case ConditionType.gt:
      return _buildConditionGreaterThan(
        col: col,
        propertyId: propertyId,
        val: val1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
    default:
      return _buildConditionStringOp(
        col: col,
        conditionType: condition.type,
        propertyId: propertyId,
        val: val1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
  }
}

Pointer<NativeType> _buildConditionIsNull({
  required IsarCollectionImpl col,
  required int? propertyId,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<Pointer<NativeType>>>();
  nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, propertyId!, false));
  return filterPtrPtr.value;
}

Pointer<NativeType> _buildConditionEqual({
  required IsarCollectionImpl col,
  required int? propertyId,
  required Object? val,
  required bool include,
  required bool caseSensitive,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<Pointer<NativeType>>>();
  if (val == null) {
    nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, propertyId!, true));
  } else if (val is bool) {
    final value = boolToByte(val);
    nCall(IC.isar_filter_byte(
        col.ptr, filterPtrPtr, value, true, value, true, propertyId!));
  } else if (val is int) {
    if (propertyId == null) {
      nCall(IC.isar_filter_id(filterPtrPtr, val, true, val, true));
    } else {
      nCall(IC.isar_filter_long(
          col.ptr, filterPtrPtr, val, true, val, true, propertyId));
    }
  } else if (val is String) {
    final strPtr = val.toNativeUtf8(allocator: alloc);
    nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, strPtr.cast(), true,
        strPtr.cast(), true, caseSensitive, propertyId!));
  } else {
    throw 'Unsupported type for condition';
  }
  return filterPtrPtr.value;
}

Pointer<NativeType> _buildConditionBetween({
  required IsarCollectionImpl col,
  required int? propertyId,
  required Object? lower,
  required bool includeLower,
  required Object? upper,
  required bool includeUpper,
  required bool caseSensitive,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<Pointer<NativeType>>>();
  if (lower == null && upper == null) {
    nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, propertyId!, true));
  } else if ((lower is int?) && upper is int?) {
    if (propertyId == null) {
      nCall(IC.isar_filter_id(filterPtrPtr, lower ?? nullLong, includeLower,
          upper ?? maxLong, includeUpper));
    } else {
      nCall(IC.isar_filter_long(col.ptr, filterPtrPtr, lower ?? nullLong,
          includeLower, upper ?? maxLong, includeUpper, propertyId));
    }
  } else if ((lower is double?) && upper is double?) {
    nCall(IC.isar_filter_double(col.ptr, filterPtrPtr, lower ?? nullDouble,
        upper ?? maxDouble, propertyId!));
  } else if ((lower is String?) && upper is String?) {
    final lowerPtr =
        lower?.toNativeUtf8(allocator: alloc).cast<Int8>() ?? minStr;
    final upperPtr =
        upper?.toNativeUtf8(allocator: alloc).cast<Int8>() ?? maxStr;
    nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, lowerPtr, includeLower,
        upperPtr, includeUpper, caseSensitive, propertyId!));
  } else {
    throw 'Unsupported type for condition';
  }
  return filterPtrPtr.value;
}

Pointer<NativeType> _buildConditionLessThan({
  required IsarCollectionImpl col,
  required int? propertyId,
  required Object? val,
  required bool include,
  required bool caseSensitive,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<Pointer<NativeType>>>();
  if (val == null) {
    if (include) {
      nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, propertyId!, true));
    } else {
      IC.isar_filter_static(filterPtrPtr, false);
    }
  } else if (val is int) {
    if (propertyId == null) {
      nCall(IC.isar_filter_id(filterPtrPtr, minLong, true, val, include));
    } else {
      nCall(IC.isar_filter_long(
          col.ptr, filterPtrPtr, minLong, true, val, include, propertyId));
    }
  } else if (val is double) {
    nCall(IC.isar_filter_double(
        col.ptr, filterPtrPtr, minDouble, val, propertyId!));
  } else if (val is String) {
    final value = val.toNativeUtf8(allocator: alloc);
    nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, minStr, true,
        value.cast(), include, caseSensitive, propertyId!));
  } else {
    throw 'Unsupported type for condition';
  }
  return filterPtrPtr.value;
}

Pointer<NativeType> _buildConditionGreaterThan({
  required IsarCollectionImpl col,
  required int? propertyId,
  required Object? val,
  required bool include,
  required bool caseSensitive,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<Pointer<NativeType>>>();
  if (val == null) {
    if (include) {
      IC.isar_filter_static(filterPtrPtr, true);
    } else {
      nCall(IC.isar_filter_null(col.ptr, filterPtrPtr, propertyId!, true));
      IC.isar_filter_not(filterPtrPtr, filterPtrPtr.value);
    }
  } else if (val is int) {
    if (propertyId == null) {
      nCall(IC.isar_filter_id(filterPtrPtr, val, include, maxLong, true));
    } else {
      nCall(IC.isar_filter_long(
          col.ptr, filterPtrPtr, val, include, maxLong, true, propertyId));
    }
  } else if (val is double) {
    nCall(IC.isar_filter_double(
        col.ptr, filterPtrPtr, val, maxDouble, propertyId!));
  } else if (val is String) {
    final value = val.toNativeUtf8(allocator: alloc);
    nCall(IC.isar_filter_string(col.ptr, filterPtrPtr, value.cast(), include,
        maxStr, true, caseSensitive, propertyId!));
  } else {
    throw 'Unsupported type for condition';
  }
  return filterPtrPtr.value;
}

Pointer<NativeType> _buildConditionStringOp({
  required IsarCollectionImpl col,
  required ConditionType conditionType,
  required int? propertyId,
  required Object? val,
  required bool include,
  required bool caseSensitive,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<Pointer<NativeType>>>();
  if (val is String) {
    final strPtr = val.toNativeUtf8(allocator: alloc);
    switch (conditionType) {
      case ConditionType.startsWith:
        nCall(IC.isar_filter_string_starts_with(
            col.ptr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId!));
        break;
      case ConditionType.endsWith:
        nCall(IC.isar_filter_string_ends_with(
            col.ptr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId!));
        break;
      case ConditionType.contains:
        nCall(IC.isar_filter_string_contains(
            col.ptr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId!));
        break;
      case ConditionType.matches:
        nCall(IC.isar_filter_string_matches(
            col.ptr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId!));
        break;
      default:
        throw 'Unsupported condition type';
    }
  } else {
    throw 'Unsupported type for condition';
  }

  return filterPtrPtr.value;
}
