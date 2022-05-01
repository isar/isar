// ignore_for_file: invalid_use_of_protected_member

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
    if (whereClause is IdWhereClause) {
      _addIdWhereClause(qbPtr, whereClause, whereSort);
    } else if (whereClause is IndexWhereClause) {
      _addIndexWhereClause(
          col.schema, qbPtr, whereClause, whereDistinct, whereSort);
    } else {
      _addLinkWhereClause(col.isar, qbPtr, whereClause as LinkWhereClause);
    }
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
    final propertyId = col.schema.propertyIdOrErr(sortProperty.property);
    nCall(IC.isar_qb_add_sort_by(
      qbPtr,
      propertyId,
      sortProperty.sort == Sort.asc,
    ));
  }

  if (offset != null || limit != null) {
    IC.isar_qb_set_offset_limit(qbPtr, offset ?? -1, limit ?? -1);
  }

  for (var distinctByProperty in distinctBy) {
    final propertyId = col.schema.propertyIdOrErr(distinctByProperty.property);
    nCall(IC.isar_qb_add_distinct_by(
      qbPtr,
      propertyId,
      distinctByProperty.caseSensitive ?? true,
    ));
  }

  QueryDeserialize<T> deserialize;
  int? propertyId;
  if (property == null) {
    deserialize = (col as IsarCollectionImpl<T>).deserializeObjects;
  } else {
    propertyId = col.schema.propertyIdOrErr(property);
    deserialize = (rawObjSet) => col.deserializeProperty(
          rawObjSet,
          propertyId!,
        );
  }

  final queryPtr = IC.isar_qb_build(qbPtr);
  return QueryImpl(col, queryPtr, deserialize, propertyId);
}

void _addIdWhereClause(Pointer qbPtr, IdWhereClause wc, Sort sort) {
  final lower = (wc.lower ?? minLong) + (wc.includeLower ? 0 : 1);
  final upper = (wc.upper ?? maxLong) - (wc.includeUpper ? 0 : 1);
  nCall(IC.isar_qb_add_id_where_clause(
    qbPtr,
    sort == Sort.asc ? lower : upper,
    sort == Sort.asc ? upper : lower,
  ));
}

void _addIndexWhereClause(CollectionSchema schema, Pointer qbPtr,
    IndexWhereClause wc, bool distinct, Sort sort) {
  late Pointer<NativeType> lowerPtr;
  if (wc.lower != null) {
    lowerPtr = buildIndexKey(schema, wc.indexName, wc.lower!);
  } else {
    lowerPtr = buildLowerUnboundedIndexKey();
  }

  late Pointer<NativeType> upperPtr;
  if (wc.upper != null) {
    upperPtr = buildIndexKey(schema, wc.indexName, wc.upper!);
  } else {
    upperPtr = buildUpperUnboundedIndexKey();
  }

  nCall(IC.isar_qb_add_index_where_clause(
    qbPtr,
    schema.indexIdOrErr(wc.indexName),
    sort == Sort.asc ? lowerPtr : upperPtr,
    sort == Sort.asc ? wc.includeLower : wc.includeUpper,
    sort == Sort.asc ? upperPtr : lowerPtr,
    sort == Sort.asc ? wc.includeUpper : wc.includeLower,
    distinct,
  ));
}

void _addLinkWhereClause(Isar isar, Pointer qbPtr, LinkWhereClause wc) {
  final linkCol =
      isar.getCollectionInternal(wc.linkCollection) as IsarCollectionImpl;
  final linkId = linkCol.schema.linkIdOrErr(wc.linkName);
  nCall(IC.isar_qb_add_link_where_clause(qbPtr, linkCol.ptr, linkId, wc.id));
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
  } else {
    return null;
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
  final linkTargetCol = col.isar.getCollectionInternal(link.targetCollection)!
      as IsarCollectionImpl;
  final linkId = col.schema.linkIdOrErr(link.linkName);

  final condition = _buildFilter(linkTargetCol, link.filter, alloc);
  if (condition == null) return null;

  final filterPtrPtr = alloc<Pointer<NativeType>>();

  nCall(IC.isar_filter_link(
    linkTargetCol.ptr,
    filterPtrPtr,
    condition,
    linkId,
  ));

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

  final propertyId = condition.property != col.schema.idName
      ? col.schema.propertyIdOrErr(condition.property)
      : null;
  switch (condition.type) {
    case ConditionType.isNull:
      return _buildConditionIsNull(
          colPtr: col.ptr, propertyId: propertyId, alloc: alloc);
    case ConditionType.eq:
      return _buildConditionEqual(
        colPtr: col.ptr,
        propertyId: propertyId,
        val: val1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
    case ConditionType.between:
      return _buildConditionBetween(
        colPtr: col.ptr,
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
        colPtr: col.ptr,
        propertyId: propertyId,
        val: val1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
    case ConditionType.gt:
      return _buildConditionGreaterThan(
        colPtr: col.ptr,
        propertyId: propertyId,
        val: val1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
    default:
      return _buildConditionStringOp(
        colPtr: col.ptr,
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
  required Pointer<NativeType> colPtr,
  required int? propertyId,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<Pointer<NativeType>>>();
  nCall(IC.isar_filter_null(colPtr, filterPtrPtr, propertyId!, false));
  return filterPtrPtr.value;
}

Pointer<NativeType> _buildConditionEqual({
  required Pointer<NativeType> colPtr,
  required int? propertyId,
  required Object? val,
  required bool include,
  required bool caseSensitive,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<Pointer<NativeType>>>();
  if (val == null) {
    nCall(IC.isar_filter_null(colPtr, filterPtrPtr, propertyId!, true));
  } else if (val is bool) {
    final value = boolToByte(val);
    nCall(IC.isar_filter_byte(
        colPtr, filterPtrPtr, value, true, value, true, propertyId!));
  } else if (val is int) {
    if (propertyId == null) {
      nCall(IC.isar_filter_id(filterPtrPtr, val, true, val, true));
    } else {
      nCall(IC.isar_filter_long(
          colPtr, filterPtrPtr, val, true, val, true, propertyId));
    }
  } else if (val is String) {
    final strPtr = val.toNativeUtf8(allocator: alloc);
    nCall(IC.isar_filter_string(colPtr, filterPtrPtr, strPtr.cast(), true,
        strPtr.cast(), true, caseSensitive, propertyId!));
  } else {
    throw 'Unsupported type for condition';
  }
  return filterPtrPtr.value;
}

Pointer<NativeType> _buildConditionBetween({
  required Pointer<NativeType> colPtr,
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
    nCall(IC.isar_filter_null(colPtr, filterPtrPtr, propertyId!, true));
  } else if ((lower is int?) && upper is int?) {
    if (propertyId == null) {
      nCall(IC.isar_filter_id(filterPtrPtr, lower ?? nullLong, includeLower,
          upper ?? maxLong, includeUpper));
    } else {
      nCall(IC.isar_filter_long(colPtr, filterPtrPtr, lower ?? nullLong,
          includeLower, upper ?? maxLong, includeUpper, propertyId));
    }
  } else if ((lower is double?) && upper is double?) {
    nCall(IC.isar_filter_double(colPtr, filterPtrPtr, lower ?? nullDouble,
        upper ?? maxDouble, propertyId!));
  } else if ((lower is String?) && upper is String?) {
    final lowerPtr =
        lower?.toNativeUtf8(allocator: alloc).cast<Int8>() ?? minStr;
    final upperPtr =
        upper?.toNativeUtf8(allocator: alloc).cast<Int8>() ?? maxStr;
    nCall(IC.isar_filter_string(colPtr, filterPtrPtr, lowerPtr, includeLower,
        upperPtr, includeUpper, caseSensitive, propertyId!));
  } else {
    throw 'Unsupported type for condition';
  }
  return filterPtrPtr.value;
}

Pointer<NativeType> _buildConditionLessThan({
  required Pointer<NativeType> colPtr,
  required int? propertyId,
  required Object? val,
  required bool include,
  required bool caseSensitive,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<Pointer<NativeType>>>();
  if (val == null) {
    if (include) {
      nCall(IC.isar_filter_null(colPtr, filterPtrPtr, propertyId!, true));
    } else {
      IC.isar_filter_static(filterPtrPtr, false);
    }
  } else if (val is int) {
    if (propertyId == null) {
      nCall(IC.isar_filter_id(filterPtrPtr, minLong, true, val, include));
    } else {
      nCall(IC.isar_filter_long(
          colPtr, filterPtrPtr, minLong, true, val, include, propertyId));
    }
  } else if (val is double) {
    nCall(IC.isar_filter_double(
        colPtr, filterPtrPtr, minDouble, val, propertyId!));
  } else if (val is String) {
    final value = val.toNativeUtf8(allocator: alloc);
    nCall(IC.isar_filter_string(colPtr, filterPtrPtr, minStr, true,
        value.cast(), include, caseSensitive, propertyId!));
  } else {
    throw 'Unsupported type for condition';
  }
  return filterPtrPtr.value;
}

Pointer<NativeType> _buildConditionGreaterThan({
  required Pointer<NativeType> colPtr,
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
      nCall(IC.isar_filter_null(colPtr, filterPtrPtr, propertyId!, true));
      IC.isar_filter_not(filterPtrPtr, filterPtrPtr.value);
    }
  } else if (val is int) {
    if (propertyId == null) {
      nCall(IC.isar_filter_id(filterPtrPtr, val, include, maxLong, true));
    } else {
      nCall(IC.isar_filter_long(
          colPtr, filterPtrPtr, val, include, maxLong, true, propertyId));
    }
  } else if (val is double) {
    nCall(IC.isar_filter_double(
        colPtr, filterPtrPtr, val, maxDouble, propertyId!));
  } else if (val is String) {
    final value = val.toNativeUtf8(allocator: alloc);
    nCall(IC.isar_filter_string(colPtr, filterPtrPtr, value.cast(), include,
        maxStr, true, caseSensitive, propertyId!));
  } else {
    throw 'Unsupported type for condition';
  }
  return filterPtrPtr.value;
}

Pointer<NativeType> _buildConditionStringOp({
  required Pointer<NativeType> colPtr,
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
            colPtr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId!));
        break;
      case ConditionType.endsWith:
        nCall(IC.isar_filter_string_ends_with(
            colPtr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId!));
        break;
      case ConditionType.contains:
        nCall(IC.isar_filter_string_contains(
            colPtr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId!));
        break;
      case ConditionType.matches:
        nCall(IC.isar_filter_string_matches(
            colPtr, filterPtrPtr, strPtr.cast(), caseSensitive, propertyId!));
        break;
      default:
        throw 'Unsupported condition type';
    }
  } else {
    throw 'Unsupported type for condition';
  }

  return filterPtrPtr.value;
}
