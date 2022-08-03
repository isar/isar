// ignore_for_file: invalid_use_of_protected_member, public_member_api_docs

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'package:isar/isar.dart';
import 'package:isar/src/native/binary_writer.dart';
import 'package:isar/src/native/bindings.dart';
import 'package:isar/src/native/encode_string.dart';
import 'package:isar/src/native/index_key.dart';
import 'package:isar/src/native/isar_collection_impl.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/query_impl.dart';

final Pointer<Char> minStr = Pointer<Char>.fromAddress(0);
final Pointer<Char> maxStr = '\u{FFFFF}'.toNativeUtf8().cast<Char>();

Query<T> buildNativeQuery<T>(
  IsarCollectionImpl<dynamic> col,
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

  for (final whereClause in whereClauses) {
    if (whereClause is IdWhereClause) {
      _addIdWhereClause(qbPtr, whereClause, whereSort);
    } else if (whereClause is IndexWhereClause) {
      _addIndexWhereClause(
        col.schema,
        qbPtr,
        whereClause,
        whereDistinct,
        whereSort,
      );
    } else {
      _addLinkWhereClause(col.isar, qbPtr, whereClause as LinkWhereClause);
    }
  }

  if (filter != null) {
    final alloc = Arena(malloc);
    try {
      final filterPtr = _buildFilter(col, null, filter, alloc);
      if (filterPtr != null) {
        IC.isar_qb_set_filter(qbPtr, filterPtr);
      }
    } finally {
      alloc.releaseAll();
    }
  }

  for (final sortProperty in sortBy) {
    final property = col.schema.property(sortProperty.property);
    nCall(
      IC.isar_qb_add_sort_by(
        qbPtr,
        property.id,
        sortProperty.sort == Sort.asc,
      ),
    );
  }

  if (offset != null || limit != null) {
    IC.isar_qb_set_offset_limit(qbPtr, offset ?? -1, limit ?? -1);
  }

  for (final distinctByProperty in distinctBy) {
    final property = col.schema.property(distinctByProperty.property);
    nCall(
      IC.isar_qb_add_distinct_by(
        qbPtr,
        property.id,
        distinctByProperty.caseSensitive ?? true,
      ),
    );
  }

  QueryDeserialize<T> deserialize;
  int? propertyId;
  if (property == null) {
    deserialize = (col as IsarCollectionImpl<T>).deserializeObjects;
  } else {
    propertyId =
        property != col.schema.idName ? col.schema.property(property).id : null;
    deserialize =
        (CObjectSet cObjSet) => col.deserializeProperty(cObjSet, propertyId);
  }

  final queryPtr = IC.isar_qb_build(qbPtr);
  return QueryImpl(col, queryPtr, deserialize, propertyId);
}

void _addIdWhereClause(
  Pointer<CQueryBuilder> qbPtr,
  IdWhereClause wc,
  Sort sort,
) {
  final lower = (wc.lower ?? minLong) + (wc.includeLower ? 0 : 1);
  final upper = (wc.upper ?? maxLong) - (wc.includeUpper ? 0 : 1);
  nCall(
    IC.isar_qb_add_id_where_clause(
      qbPtr,
      sort == Sort.asc ? lower : upper,
      sort == Sort.asc ? upper : lower,
    ),
  );
}

void _addIndexWhereClause(
  CollectionSchema<dynamic> schema,
  Pointer<CQueryBuilder> qbPtr,
  IndexWhereClause wc,
  bool distinct,
  Sort sort,
) {
  Pointer<CIndexKey>? lowerPtr;
  if (wc.lower != null) {
    lowerPtr = buildIndexKey(
      schema,
      wc.indexName,
      wc.lower!,
      increase: !wc.includeLower,
    );
  } else {
    lowerPtr = buildLowerUnboundedIndexKey();
  }

  Pointer<CIndexKey>? upperPtr;
  if (wc.upper != null) {
    upperPtr = buildIndexKey(
      schema,
      wc.indexName,
      wc.upper!,
      addMaxComposite: true,
      decrease: !wc.includeUpper,
    );
  } else {
    upperPtr = buildUpperUnboundedIndexKey();
  }

  if (lowerPtr != null && upperPtr != null) {
    nCall(
      IC.isar_qb_add_index_where_clause(
        qbPtr,
        schema.index(wc.indexName).id,
        lowerPtr,
        upperPtr,
        sort == Sort.asc,
        distinct,
      ),
    );
  } else {
    nCall(
      IC.isar_qb_add_id_where_clause(
        qbPtr,
        Isar.autoIncrement,
        Isar.autoIncrement,
      ),
    );
  }
}

void _addLinkWhereClause(
  Isar isar,
  Pointer<CQueryBuilder> qbPtr,
  LinkWhereClause wc,
) {
  final linkCol = isar.getCollectionByNameInternal(wc.linkCollection)!;
  linkCol as IsarCollectionImpl;

  final linkId = linkCol.schema.link(wc.linkName).id;
  nCall(IC.isar_qb_add_link_where_clause(qbPtr, linkCol.ptr, linkId, wc.id));
}

Pointer<CFilter>? _buildFilter(
  IsarCollectionImpl<dynamic> col,
  Schema<dynamic>? embeddedCol,
  FilterOperation filter,
  Allocator alloc,
) {
  if (filter is FilterGroup) {
    return _buildFilterGroup(col, embeddedCol, filter, alloc);
  } else if (filter is LinkFilter) {
    return _buildLink(col, filter, alloc);
  } else if (filter is ObjectFilter) {
    return _buildObject(col, filter, alloc);
  } else if (filter is FilterCondition) {
    return _buildCondition(col, embeddedCol, filter, alloc);
  } else {
    return null;
  }
}

Pointer<CFilter>? _buildFilterGroup(
  IsarCollectionImpl<dynamic> col,
  Schema<dynamic>? embeddedCol,
  FilterGroup group,
  Allocator alloc,
) {
  final builtConditions = group.filters
      .map((FilterOperation op) => _buildFilter(col, embeddedCol, op, alloc))
      .where((Pointer<CFilter>? it) => it != null)
      .toList();

  if (builtConditions.isEmpty) {
    return null;
  }

  final filterPtrPtr = alloc<Pointer<CFilter>>();
  if (group.type == FilterGroupType.not) {
    IC.isar_filter_not(
      filterPtrPtr,
      builtConditions.first!,
    );
  } else if (builtConditions.length == 1) {
    return builtConditions[0];
  } else {
    final conditionsPtrPtr = alloc<Pointer<CFilter>>(builtConditions.length);
    for (var i = 0; i < builtConditions.length; i++) {
      conditionsPtrPtr[i] = builtConditions[i]!;
    }
    IC.isar_filter_and_or_xor(
      filterPtrPtr,
      group.type == FilterGroupType.and,
      group.type == FilterGroupType.xor,
      conditionsPtrPtr,
      builtConditions.length,
    );
  }

  return filterPtrPtr.value;
}

Pointer<CFilter>? _buildLink(
  IsarCollectionImpl<dynamic> col,
  LinkFilter link,
  Allocator alloc,
) {
  final linkSchema = col.schema.link(link.linkName);
  final linkTargetCol =
      col.isar.getCollectionByNameInternal(linkSchema.target)!;
  final linkId = col.schema.link(link.linkName).id;

  final filterPtrPtr = alloc<Pointer<CFilter>>();

  if (link.filter != null) {
    final condition = _buildFilter(
      linkTargetCol as IsarCollectionImpl,
      null,
      link.filter!,
      alloc,
    );
    if (condition == null) {
      return null;
    }

    nCall(
      IC.isar_filter_link(
        col.ptr,
        filterPtrPtr,
        condition,
        linkId,
      ),
    );
  } else {
    nCall(
      IC.isar_filter_link_length(
        col.ptr,
        filterPtrPtr,
        link.lower!,
        link.upper!,
        linkId,
      ),
    );
  }

  return filterPtrPtr.value;
}

Pointer<CFilter>? _buildObject(
  IsarCollectionImpl<dynamic> col,
  ObjectFilter objectFilter,
  Allocator alloc, {
  Schema<dynamic>? embeddedCol,
}) {
  final property = (embeddedCol ?? col.schema).property(objectFilter.property);

  final condition = _buildFilter(
    col,
    col.schema.embeddedSchemas[property.target],
    objectFilter.filter,
    alloc,
  );
  if (condition == null) {
    return null;
  }

  final filterPtrPtr = alloc<Pointer<CFilter>>();
  nCall(
    IC.isar_filter_object(
      col.ptr,
      filterPtrPtr,
      condition,
      embeddedCol?.id ?? 0,
      property.id,
    ),
  );

  return filterPtrPtr.value;
}

dynamic _prepareValue(dynamic value) {
  if (value is bool) {
    return value.byteValue;
  } else if (value is DateTime) {
    return value.longValue;
  } else if (value is Enum) {
    return value.byteValue;
  } else {
    return value;
  }
}

Pointer<CFilter> _buildCondition(
  IsarCollectionImpl<dynamic> col,
  Schema<dynamic>? embeddedCol,
  FilterCondition condition,
  Allocator alloc,
) {
  final value1 = _prepareValue(condition.value1);
  final value2 = _prepareValue(condition.value2);

  final property = condition.property != col.schema.idName
      ? (embeddedCol ?? col.schema).property(condition.property)
      : null;
  switch (condition.type) {
    case FilterConditionType.isNull:
      return _buildConditionIsNull(
        colPtr: col.ptr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        alloc: alloc,
      );
    case FilterConditionType.equalTo:
      return _buildConditionEqual(
        colPtr: col.ptr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        val: value1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
    case FilterConditionType.between:
      return _buildConditionBetween(
        colPtr: col.ptr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        lower: value1,
        includeLower: condition.include1,
        upper: value2,
        includeUpper: condition.include2,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
    case FilterConditionType.lessThan:
      return _buildConditionLessThan(
        colPtr: col.ptr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        val: value1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
    case FilterConditionType.greaterThan:
      return _buildConditionGreaterThan(
        colPtr: col.ptr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        val: value1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
    case FilterConditionType.startsWith:
    case FilterConditionType.endsWith:
    case FilterConditionType.contains:
    case FilterConditionType.matches:
      return _buildConditionStringOp(
        colPtr: col.ptr,
        conditionType: condition.type,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        val: value1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        alloc: alloc,
      );
    case FilterConditionType.listLength:
      return _buildListLength(
        colPtr: col.ptr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        lower: value1 as int,
        upper: value2 as int,
        alloc: alloc,
      );
  }
}

Pointer<CFilter> _buildConditionIsNull({
  required Pointer<CIsarCollection> colPtr,
  required int? embeddedColId,
  required int? propertyId,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<CFilter>>();
  if (propertyId != null) {
    nCall(
      IC.isar_filter_null(
        colPtr,
        filterPtrPtr,
        false,
        embeddedColId ?? 0,
        propertyId,
      ),
    );
  } else {
    IC.isar_filter_static(filterPtrPtr, false);
  }
  return filterPtrPtr.value;
}

Pointer<CFilter> _buildConditionEqual({
  required Pointer<CIsarCollection> colPtr,
  required int? embeddedColId,
  required int? propertyId,
  required Object? val,
  required bool include,
  required bool caseSensitive,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<CFilter>>();
  if (val == null) {
    nCall(
      IC.isar_filter_null(
        colPtr,
        filterPtrPtr,
        true,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else if (val is int) {
    if (propertyId == null) {
      IC.isar_filter_id(filterPtrPtr, val, true, val, true);
    } else {
      nCall(
        IC.isar_filter_long(
          colPtr,
          filterPtrPtr,
          val,
          true,
          val,
          true,
          embeddedColId ?? 0,
          propertyId,
        ),
      );
    }
  } else if (val is String) {
    final strPtr = val.toCString(alloc);
    nCall(
      IC.isar_filter_string(
        colPtr,
        filterPtrPtr,
        strPtr,
        true,
        strPtr,
        true,
        caseSensitive,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else {
    throw IsarError('Unsupported type for condition');
  }
  return filterPtrPtr.value;
}

Pointer<CFilter> _buildConditionBetween({
  required Pointer<CIsarCollection> colPtr,
  required int? embeddedColId,
  required int? propertyId,
  required Object? lower,
  required bool includeLower,
  required Object? upper,
  required bool includeUpper,
  required bool caseSensitive,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<CFilter>>();
  if (lower == null && upper == null) {
    nCall(
      IC.isar_filter_null(
        colPtr,
        filterPtrPtr,
        true,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else if ((lower is int?) && upper is int?) {
    if (propertyId == null) {
      IC.isar_filter_id(
        filterPtrPtr,
        lower ?? nullLong,
        includeLower,
        upper ?? maxLong,
        includeUpper,
      );
    } else {
      nCall(
        IC.isar_filter_long(
          colPtr,
          filterPtrPtr,
          lower ?? nullLong,
          includeLower,
          upper ?? maxLong,
          includeUpper,
          embeddedColId ?? 0,
          propertyId,
        ),
      );
    }
  } else if ((lower is double?) && upper is double?) {
    nCall(
      IC.isar_filter_double(
        colPtr,
        filterPtrPtr,
        lower ?? nullDouble,
        upper ?? maxDouble,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else if ((lower is String?) && upper is String?) {
    final lowerPtr = lower?.toCString(alloc) ?? minStr;
    final upperPtr = upper?.toCString(alloc) ?? maxStr;
    nCall(
      IC.isar_filter_string(
        colPtr,
        filterPtrPtr,
        lowerPtr,
        includeLower,
        upperPtr,
        includeUpper,
        caseSensitive,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else {
    throw IsarError('Unsupported type for condition');
  }
  return filterPtrPtr.value;
}

Pointer<CFilter> _buildConditionLessThan({
  required Pointer<CIsarCollection> colPtr,
  required int? embeddedColId,
  required int? propertyId,
  required Object? val,
  required bool include,
  required bool caseSensitive,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<CFilter>>();
  if (val == null) {
    if (include) {
      nCall(
        IC.isar_filter_null(
          colPtr,
          filterPtrPtr,
          true,
          embeddedColId ?? 0,
          propertyId!,
        ),
      );
    } else {
      IC.isar_filter_static(filterPtrPtr, false);
    }
  } else if (val is int) {
    if (propertyId == null) {
      IC.isar_filter_id(filterPtrPtr, minLong, true, val, include);
    } else {
      nCall(
        IC.isar_filter_long(
          colPtr,
          filterPtrPtr,
          minLong,
          true,
          val,
          include,
          embeddedColId ?? 0,
          propertyId,
        ),
      );
    }
  } else if (val is double) {
    nCall(
      IC.isar_filter_double(
        colPtr,
        filterPtrPtr,
        minDouble,
        val,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else if (val is String) {
    final value = val.toCString(alloc);
    nCall(
      IC.isar_filter_string(
        colPtr,
        filterPtrPtr,
        minStr,
        true,
        value,
        include,
        caseSensitive,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else {
    throw IsarError('Unsupported type for condition');
  }
  return filterPtrPtr.value;
}

Pointer<CFilter> _buildConditionGreaterThan({
  required Pointer<CIsarCollection> colPtr,
  required int? embeddedColId,
  required int? propertyId,
  required Object? val,
  required bool include,
  required bool caseSensitive,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<CFilter>>();
  if (val == null) {
    if (include) {
      IC.isar_filter_static(filterPtrPtr, true);
    } else {
      nCall(
        IC.isar_filter_null(
          colPtr,
          filterPtrPtr,
          true,
          embeddedColId ?? 0,
          propertyId!,
        ),
      );
      IC.isar_filter_not(filterPtrPtr, filterPtrPtr.value);
    }
  } else if (val is int) {
    if (propertyId == null) {
      IC.isar_filter_id(filterPtrPtr, val, include, maxLong, true);
    } else {
      nCall(
        IC.isar_filter_long(
          colPtr,
          filterPtrPtr,
          val,
          include,
          maxLong,
          true,
          embeddedColId ?? 0,
          propertyId,
        ),
      );
    }
  } else if (val is double) {
    nCall(
      IC.isar_filter_double(
        colPtr,
        filterPtrPtr,
        val,
        maxDouble,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else if (val is String) {
    final value = val.toCString(alloc);
    nCall(
      IC.isar_filter_string(
        colPtr,
        filterPtrPtr,
        value,
        include,
        maxStr,
        true,
        caseSensitive,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else {
    throw IsarError('Unsupported type for condition');
  }
  return filterPtrPtr.value;
}

Pointer<CFilter> _buildConditionStringOp({
  required Pointer<CIsarCollection> colPtr,
  required FilterConditionType conditionType,
  required int? embeddedColId,
  required int? propertyId,
  required Object? val,
  required bool include,
  required bool caseSensitive,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<CFilter>>();
  if (val is String) {
    final strPtr = val.toCString(alloc);
    switch (conditionType) {
      case FilterConditionType.startsWith:
        nCall(
          IC.isar_filter_string_starts_with(
            colPtr,
            filterPtrPtr,
            strPtr,
            caseSensitive,
            embeddedColId ?? 0,
            propertyId!,
          ),
        );
        break;
      case FilterConditionType.endsWith:
        nCall(
          IC.isar_filter_string_ends_with(
            colPtr,
            filterPtrPtr,
            strPtr,
            caseSensitive,
            embeddedColId ?? 0,
            propertyId!,
          ),
        );
        break;
      case FilterConditionType.contains:
        nCall(
          IC.isar_filter_string_contains(
            colPtr,
            filterPtrPtr,
            strPtr,
            caseSensitive,
            embeddedColId ?? 0,
            propertyId!,
          ),
        );
        break;
      case FilterConditionType.matches:
        nCall(
          IC.isar_filter_string_matches(
            colPtr,
            filterPtrPtr,
            strPtr,
            caseSensitive,
            embeddedColId ?? 0,
            propertyId!,
          ),
        );
        break;
      // ignore: no_default_cases
      default:
        throw IsarError('Unsupported condition type');
    }
  } else {
    throw IsarError('Unsupported type for condition');
  }

  return filterPtrPtr.value;
}

Pointer<CFilter> _buildListLength({
  required Pointer<CIsarCollection> colPtr,
  required int? embeddedColId,
  required int? propertyId,
  required int lower,
  required int upper,
  required Allocator alloc,
}) {
  final filterPtrPtr = alloc<Pointer<CFilter>>();
  nCall(
    IC.isar_filter_list_length(
      colPtr,
      filterPtrPtr,
      lower,
      upper,
      embeddedColId ?? 0,
      propertyId!,
    ),
  );
  return filterPtrPtr.value;
}
