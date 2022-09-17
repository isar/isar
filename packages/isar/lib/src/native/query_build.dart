// ignore_for_file: invalid_use_of_protected_member, public_member_api_docs

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/native/bindings.dart';
import 'package:isar/src/native/encode_string.dart';
import 'package:isar/src/native/index_key.dart';
import 'package:isar/src/native/isar_collection_impl.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/isar_writer_impl.dart';
import 'package:isar/src/native/query_impl.dart';

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

  for (final wc in whereClauses) {
    if (wc is IdWhereClause) {
      _addIdWhereClause(qbPtr, wc, whereSort);
    } else if (wc is IndexWhereClause) {
      _addIndexWhereClause(
        col.schema,
        qbPtr,
        wc,
        whereDistinct,
        whereSort,
      );
    } else {
      _addLinkWhereClause(col.isar, qbPtr, wc as LinkWhereClause);
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

Pointer<CIndexKey>? _buildLowerIndexBound(
  CollectionSchema<dynamic> schema,
  IndexSchema index,
  IndexWhereClause wc,
) {
  if (wc.lower == null) {
    return buildLowerUnboundedIndexKey();
  }

  final firstVal = wc.lower!.length == 1 ? wc.lower!.first : null;
  if (firstVal is double) {
    final adjusted = adjustFloatBound(
      value: firstVal,
      lowerBound: true,
      include: wc.includeLower,
      epsilon: wc.epsilon,
    );
    if (adjusted == null) {
      return null;
    }

    return buildIndexKey(schema, index, [adjusted]);
  } else {
    final lowerPtr = buildIndexKey(schema, index, wc.lower!);

    if (!wc.includeLower) {
      if (!IC.isar_key_increase(lowerPtr)) {
        return null;
      }
    }

    return lowerPtr;
  }
}

Pointer<CIndexKey>? _buildUpperIndexBound(
  CollectionSchema<dynamic> schema,
  IndexSchema index,
  IndexWhereClause wc,
) {
  if (wc.upper == null) {
    return buildUpperUnboundedIndexKey();
  }

  final firstVal = wc.upper!.length == 1 ? wc.upper!.first : null;
  if (firstVal is double) {
    final adjusted = adjustFloatBound(
      value: firstVal,
      lowerBound: false,
      include: wc.includeUpper,
      epsilon: wc.epsilon,
    );
    if (adjusted == null) {
      return null;
    } else {
      return buildIndexKey(schema, index, [adjusted]);
    }
  } else {
    final upperPtr = buildIndexKey(schema, index, wc.upper!);

    if (!wc.includeUpper) {
      if (!IC.isar_key_decrease(upperPtr)) {
        return null;
      }
    }

    // Also include composite indexes for upper keys
    if (index.properties.length > wc.upper!.length) {
      IC.isar_key_add_long(upperPtr, maxLong);
    }

    return upperPtr;
  }
}

void _addIndexWhereClause(
  CollectionSchema<dynamic> schema,
  Pointer<CQueryBuilder> qbPtr,
  IndexWhereClause wc,
  bool distinct,
  Sort sort,
) {
  final index = schema.index(wc.indexName);
  final lowerPtr = _buildLowerIndexBound(schema, index, wc);
  final upperPtr = _buildUpperIndexBound(schema, index, wc);

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
    // this where clause does not match any objects
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
    return _buildObject(col, embeddedCol, filter, alloc);
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
  Schema<dynamic>? embeddedCol,
  ObjectFilter objectFilter,
  Allocator alloc,
) {
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

Object _prepareValue(
  Object? value,
  Allocator alloc,
  IsarType type,
  Map<String, dynamic>? enumMap,
) {
  if (value is bool) {
    return value.byteValue;
  } else if (value is DateTime) {
    return value.longValue;
  } else if (value is Enum) {
    return _prepareValue(enumMap![value.name], alloc, type, null);
  } else if (value is String) {
    return value.toCString(alloc);
  } else if (value == null) {
    switch (type) {
      case IsarType.bool:
      case IsarType.byte:
      case IsarType.boolList:
      case IsarType.byteList:
        return minByte;
      case IsarType.int:
      case IsarType.intList:
        return minInt;
      case IsarType.long:
      case IsarType.longList:
      case IsarType.dateTime:
      case IsarType.dateTimeList:
        return minLong;
      case IsarType.float:
      case IsarType.double:
      case IsarType.floatList:
      case IsarType.doubleList:
        return minDouble;
      case IsarType.string:
      case IsarType.stringList:
      case IsarType.object:
      case IsarType.objectList:
        return nullptr;
    }
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
  final property = condition.property != col.schema.idName
      ? (embeddedCol ?? col.schema).property(condition.property)
      : null;

  final value1 = _prepareValue(
    condition.value1,
    alloc,
    property?.type ?? IsarType.long,
    property?.enumMap,
  );
  final value2 = _prepareValue(
    condition.value2,
    alloc,
    property?.type ?? IsarType.long,
    property?.enumMap,
  );
  final filterPtr = alloc<Pointer<CFilter>>();

  switch (condition.type) {
    case FilterConditionType.equalTo:
      _buildConditionEqual(
        colPtr: col.ptr,
        filterPtr: filterPtr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        val: value1,
        caseSensitive: condition.caseSensitive,
        epsilon: condition.epsilon,
      );
      break;
    case FilterConditionType.between:
      _buildConditionBetween(
        colPtr: col.ptr,
        filterPtr: filterPtr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        lower: value1,
        includeLower: condition.include1,
        upper: value2,
        includeUpper: condition.include2,
        caseSensitive: condition.caseSensitive,
        epsilon: condition.epsilon,
      );
      break;
    case FilterConditionType.lessThan:
      _buildConditionLessThan(
        colPtr: col.ptr,
        filterPtr: filterPtr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        val: value1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        epsilon: condition.epsilon,
      );
      break;
    case FilterConditionType.greaterThan:
      _buildConditionGreaterThan(
        colPtr: col.ptr,
        filterPtr: filterPtr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        val: value1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
        epsilon: condition.epsilon,
      );
      break;
    case FilterConditionType.startsWith:
    case FilterConditionType.endsWith:
    case FilterConditionType.contains:
    case FilterConditionType.matches:
      _buildConditionStringOp(
        colPtr: col.ptr,
        filterPtr: filterPtr,
        conditionType: condition.type,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        val: value1,
        include: condition.include1,
        caseSensitive: condition.caseSensitive,
      );
      break;
    case FilterConditionType.isNull:
      _buildConditionIsNull(
        colPtr: col.ptr,
        filterPtr: filterPtr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
      );
      break;
    case FilterConditionType.isNotNull:
      _buildConditionIsNotNull(
        colPtr: col.ptr,
        filterPtr: filterPtr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        alloc: alloc,
      );
      break;
    case FilterConditionType.elementIsNull:
      _buildConditionElementIsNull(
        colPtr: col.ptr,
        filterPtr: filterPtr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        isObjectList: property?.type == IsarType.objectList,
        nullValue: value1,
      );
      break;
    case FilterConditionType.elementIsNotNull:
      _buildConditionElementIsNotNull(
        colPtr: col.ptr,
        filterPtr: filterPtr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        isObjectList: property?.type == IsarType.objectList,
        nullValue: value1,
        alloc: alloc,
      );
      break;
    case FilterConditionType.listLength:
      _buildListLength(
        colPtr: col.ptr,
        filterPtr: filterPtr,
        embeddedColId: embeddedCol?.id,
        propertyId: property?.id,
        lower: value1,
        upper: value2,
      );
      break;
  }

  return filterPtr.value;
}

void _buildConditionIsNull({
  required Pointer<CIsarCollection> colPtr,
  required Pointer<Pointer<CFilter>> filterPtr,
  required int? embeddedColId,
  required int? propertyId,
}) {
  if (propertyId != null) {
    nCall(
      IC.isar_filter_null(
        colPtr,
        filterPtr,
        embeddedColId ?? 0,
        propertyId,
      ),
    );
  } else {
    IC.isar_filter_static(filterPtr, false);
  }
}

void _buildConditionIsNotNull({
  required Pointer<CIsarCollection> colPtr,
  required Pointer<Pointer<CFilter>> filterPtr,
  required int? embeddedColId,
  required int? propertyId,
  required Allocator alloc,
}) {
  if (propertyId != null) {
    final conditionPtr = alloc<Pointer<CFilter>>();
    nCall(
      IC.isar_filter_null(
        colPtr,
        conditionPtr,
        embeddedColId ?? 0,
        propertyId,
      ),
    );
    IC.isar_filter_not(filterPtr, conditionPtr.value);
  } else {
    IC.isar_filter_static(filterPtr, true);
  }
}

void _buildConditionElementIsNull({
  required Pointer<CIsarCollection> colPtr,
  required Pointer<Pointer<CFilter>> filterPtr,
  required int? embeddedColId,
  required int? propertyId,
  required bool isObjectList,
  required Object nullValue,
}) {
  if (isObjectList) {
    IC.isar_filter_object(
      colPtr,
      filterPtr,
      nullptr,
      embeddedColId ?? 0,
      propertyId ?? 0,
    );
  } else {
    _buildConditionEqual(
      colPtr: colPtr,
      filterPtr: filterPtr,
      embeddedColId: embeddedColId,
      propertyId: propertyId,
      val: nullValue,
      epsilon: 0,
      caseSensitive: true,
    );
  }
}

void _buildConditionElementIsNotNull({
  required Pointer<CIsarCollection> colPtr,
  required Pointer<Pointer<CFilter>> filterPtr,
  required int? embeddedColId,
  required int? propertyId,
  required bool isObjectList,
  required Object nullValue,
  required Allocator alloc,
}) {
  if (isObjectList) {
    final objFilterPtrPtr = alloc<Pointer<CFilter>>();
    IC.isar_filter_static(objFilterPtrPtr, true);
    IC.isar_filter_object(
      colPtr,
      filterPtr,
      objFilterPtrPtr.value,
      embeddedColId ?? 0,
      propertyId ?? 0,
    );
  } else {
    _buildConditionGreaterThan(
      colPtr: colPtr,
      filterPtr: filterPtr,
      embeddedColId: embeddedColId,
      propertyId: propertyId,
      val: nullValue,
      include: false,
      epsilon: 0,
      caseSensitive: true,
    );
  }
}

void _buildConditionEqual({
  required Pointer<CIsarCollection> colPtr,
  required Pointer<Pointer<CFilter>> filterPtr,
  required int? embeddedColId,
  required int? propertyId,
  required Object val,
  required bool caseSensitive,
  required double epsilon,
}) {
  if (val is int) {
    if (propertyId == null) {
      IC.isar_filter_id(filterPtr, val, true, val, true);
    } else {
      nCall(
        IC.isar_filter_long(
          colPtr,
          filterPtr,
          val,
          true,
          val,
          true,
          embeddedColId ?? 0,
          propertyId,
        ),
      );
    }
  } else if (val is double) {
    final lower = adjustFloatBound(
      value: val,
      lowerBound: true,
      include: true,
      epsilon: epsilon,
    );
    final upper = adjustFloatBound(
      value: val,
      lowerBound: false,
      include: true,
      epsilon: epsilon,
    );
    if (lower == null || upper == null) {
      IC.isar_filter_static(filterPtr, false);
    } else {
      nCall(
        IC.isar_filter_double(
          colPtr,
          filterPtr,
          lower,
          upper,
          embeddedColId ?? 0,
          propertyId!,
        ),
      );
    }
  } else if (val is Pointer<Char>) {
    nCall(
      IC.isar_filter_string(
        colPtr,
        filterPtr,
        val,
        true,
        val,
        true,
        caseSensitive,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else {
    throw IsarError('Unsupported type for condition');
  }
}

void _buildConditionBetween({
  required Pointer<CIsarCollection> colPtr,
  required Pointer<Pointer<CFilter>> filterPtr,
  required int? embeddedColId,
  required int? propertyId,
  required Object lower,
  required bool includeLower,
  required Object upper,
  required bool includeUpper,
  required bool caseSensitive,
  required double epsilon,
}) {
  if (lower is int && upper is int) {
    if (propertyId == null) {
      IC.isar_filter_id(filterPtr, lower, includeLower, upper, includeUpper);
    } else {
      nCall(
        IC.isar_filter_long(
          colPtr,
          filterPtr,
          lower,
          includeLower,
          upper,
          includeUpper,
          embeddedColId ?? 0,
          propertyId,
        ),
      );
    }
  } else if (lower is double && upper is double) {
    final adjustedLower = adjustFloatBound(
      value: lower,
      lowerBound: true,
      include: includeLower,
      epsilon: epsilon,
    );
    final adjustedUpper = adjustFloatBound(
      value: upper,
      lowerBound: false,
      include: includeUpper,
      epsilon: epsilon,
    );
    if (adjustedLower == null || adjustedUpper == null) {
      IC.isar_filter_static(filterPtr, false);
    } else {
      nCall(
        IC.isar_filter_double(
          colPtr,
          filterPtr,
          adjustedLower,
          adjustedUpper,
          embeddedColId ?? 0,
          propertyId!,
        ),
      );
    }
  } else if (lower is Pointer<Char> && upper is Pointer<Char>) {
    nCall(
      IC.isar_filter_string(
        colPtr,
        filterPtr,
        lower,
        includeLower,
        upper,
        includeUpper,
        caseSensitive,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else {
    throw IsarError('Unsupported type for condition');
  }
}

void _buildConditionLessThan({
  required Pointer<CIsarCollection> colPtr,
  required Pointer<Pointer<CFilter>> filterPtr,
  required int? embeddedColId,
  required int? propertyId,
  required Object val,
  required bool include,
  required bool caseSensitive,
  required double epsilon,
}) {
  if (val is int) {
    if (propertyId == null) {
      IC.isar_filter_id(filterPtr, minLong, true, val, include);
    } else {
      nCall(
        IC.isar_filter_long(
          colPtr,
          filterPtr,
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
    final upper = adjustFloatBound(
      value: val,
      lowerBound: false,
      include: include,
      epsilon: epsilon,
    );
    if (upper == null) {
      IC.isar_filter_static(filterPtr, false);
    } else {
      nCall(
        IC.isar_filter_double(
          colPtr,
          filterPtr,
          minDouble,
          upper,
          embeddedColId ?? 0,
          propertyId!,
        ),
      );
    }
  } else if (val is Pointer<Char>) {
    nCall(
      IC.isar_filter_string(
        colPtr,
        filterPtr,
        nullptr,
        true,
        val,
        include,
        caseSensitive,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else {
    throw IsarError('Unsupported type for condition');
  }
}

void _buildConditionGreaterThan({
  required Pointer<CIsarCollection> colPtr,
  required Pointer<Pointer<CFilter>> filterPtr,
  required int? embeddedColId,
  required int? propertyId,
  required Object val,
  required bool include,
  required bool caseSensitive,
  required double epsilon,
}) {
  if (val is int) {
    if (propertyId == null) {
      IC.isar_filter_id(filterPtr, val, include, maxLong, true);
    } else {
      nCall(
        IC.isar_filter_long(
          colPtr,
          filterPtr,
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
    final lower = adjustFloatBound(
      value: val,
      lowerBound: true,
      include: include,
      epsilon: epsilon,
    );
    if (lower == null) {
      IC.isar_filter_static(filterPtr, false);
    } else {
      nCall(
        IC.isar_filter_double(
          colPtr,
          filterPtr,
          lower,
          maxDouble,
          embeddedColId ?? 0,
          propertyId!,
        ),
      );
    }
  } else if (val is Pointer<Char>) {
    nCall(
      IC.isar_filter_string(
        colPtr,
        filterPtr,
        val,
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
}

void _buildConditionStringOp({
  required Pointer<CIsarCollection> colPtr,
  required Pointer<Pointer<CFilter>> filterPtr,
  required FilterConditionType conditionType,
  required int? embeddedColId,
  required int? propertyId,
  required Object val,
  required bool include,
  required bool caseSensitive,
}) {
  if (val is Pointer<Char>) {
    if (val.isNull) {
      throw IsarError('String operation value must not be null');
    }

    // ignore: missing_enum_constant_in_switch
    switch (conditionType) {
      case FilterConditionType.startsWith:
        nCall(
          IC.isar_filter_string_starts_with(
            colPtr,
            filterPtr,
            val,
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
            filterPtr,
            val,
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
            filterPtr,
            val,
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
            filterPtr,
            val,
            caseSensitive,
            embeddedColId ?? 0,
            propertyId!,
          ),
        );
        break;
    }
  } else {
    throw IsarError('Unsupported type for condition');
  }
}

void _buildListLength({
  required Pointer<CIsarCollection> colPtr,
  required Pointer<Pointer<CFilter>> filterPtr,
  required int? embeddedColId,
  required int? propertyId,
  required Object? lower,
  required Object? upper,
}) {
  if (lower is int && upper is int) {
    nCall(
      IC.isar_filter_list_length(
        colPtr,
        filterPtr,
        lower,
        upper,
        embeddedColId ?? 0,
        propertyId!,
      ),
    );
  } else {
    throw IsarError('Unsupported type for condition');
  }
}
