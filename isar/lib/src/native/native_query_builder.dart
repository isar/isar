part of isar_native;

NativeQuery<T> buildQuery<T extends IsarObjectMixin>(
    IsarCollection<T> collection,
    List<WhereClause> whereClauses,
    FilterGroup filter) {
  final col = collection as IsarCollectionImpl<T>;
  final colPtr = col.collectionPtr;
  final qbPtr = IsarCore.isar_qb_create(col.isar.isarPtr, colPtr);
  for (var whereClause in whereClauses) {
    _addWhereClause(colPtr, qbPtr, whereClause);
  }
  final queryPtr = IsarCore.isar_qb_build(qbPtr);
  return NativeQuery(col, queryPtr);
}

void _addWhereClause(Pointer colPtr, Pointer qbPtr, WhereClause wc) {
  final wcPtrPtr = allocate<Pointer<NativeType>>();
  nativeCall(IsarCore.isar_wc_create(
      colPtr, wcPtrPtr, wc.index == null, wc.index ?? 999));
  final wcPtr = wcPtrPtr.value;
  if (wc.lower != null) {
    for (var i = 0; i < wc.lower!.length; i++) {
      final lowerValue = wc.lower![i];
      final upperValue = wc.upper?[i];
      addWhereValue(
        wcPtr: wcPtr,
        type: wc.types[i],
        hasLower: true,
        lower: lowerValue,
        includeLower: wc.includeLower ?? true,
        hasUpper: wc.upper != null,
        upper: upperValue,
        includeUpper: wc.includeUpper ?? true,
      );
    }
  } else if (wc.upper != null) {
    for (var i = 0; i < wc.upper!.length; i++) {
      final lowerValue = wc.lower?[i];
      final upperValue = wc.upper![i];
      addWhereValue(
        wcPtr: wcPtr,
        type: wc.types[i],
        hasLower: wc.lower != null,
        lower: lowerValue,
        includeLower: wc.includeLower ?? true,
        hasUpper: true,
        upper: upperValue,
        includeUpper: wc.includeUpper ?? true,
      );
    }
  }
  IsarCore.isar_qb_add_where_clause(qbPtr, wcPtrPtr.value);
  free(wcPtrPtr);
}

void addWhereValue({
  required Pointer wcPtr,
  required String type,
  required bool hasLower,
  required dynamic? lower,
  required bool includeLower,
  required bool hasUpper,
  required dynamic? upper,
  required bool includeUpper,
}) {
  if (!hasLower) {
    includeLower = true;
  }
  if (!hasUpper) {
    includeUpper = true;
  }
  switch (type) {
    case 'Bool':
      final value = lower == null ? nullBool : (lower ? trueBool : falseBool);
      IsarCore.isar_wc_add_bool(wcPtr, value);
      return;
    case 'Int':
      if (!hasLower) {
        lower = minInt;
      }
      if (!hasUpper) {
        upper = maxInt;
      }
      IsarCore.isar_wc_add_lower_int(wcPtr, lower ?? nullInt, includeLower);
      IsarCore.isar_wc_add_upper_int(wcPtr, upper ?? nullInt, includeUpper);
      return;
    case 'Float':
      if (!hasLower) {
        lower = minFloat;
      }
      if (!hasUpper) {
        upper = maxFloat;
      }
      IsarCore.isar_wc_add_lower_float(
          wcPtr, lower ?? double.nan, includeLower);
      IsarCore.isar_wc_add_upper_int(wcPtr, upper ?? double.nan, includeUpper);
      return;
    case 'Long':
      if (!hasLower) {
        lower = minLong;
      }
      if (!hasUpper) {
        upper = maxLong;
      }
      IsarCore.isar_wc_add_lower_long(wcPtr, lower ?? nullLong, includeLower);
      IsarCore.isar_wc_add_upper_long(wcPtr, upper ?? nullLong, includeUpper);
      return;
    case 'Double':
      if (!hasLower) {
        lower = minDouble;
      }
      if (!hasUpper) {
        upper = maxDouble;
      }
      IsarCore.isar_wc_add_lower_double(
          wcPtr, lower ?? double.nan, includeLower);
      IsarCore.isar_wc_add_upper_double(
          wcPtr, upper ?? double.nan, includeUpper);
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
      IsarCore.isar_wc_add_lower_string_value(wcPtr, lowerPtr, includeLower);
      IsarCore.isar_wc_add_upper_string_value(wcPtr, upperPtr, includeUpper);
      if (lower != null) {
        free(lowerPtr);
      }
      if (upper != null) {
        free(upperPtr);
      }
      return;
  }
}
