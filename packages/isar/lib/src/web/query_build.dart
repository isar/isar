import 'dart:indexed_db';

import '../../isar.dart';

import 'bindings.dart';
import 'isar_collection_impl.dart';
import 'isar_web.dart';
import 'query_impl.dart';

Query<T> buildWebQuery<T, OBJ>(
  IsarCollectionImpl<OBJ> col,
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
  final List<Object> whereClausesJs = whereClauses.map((WhereClause wc) {
    if (wc is IdWhereClause) {
      return _buildIdWhereClause(wc);
    } else if (wc is IndexWhereClause) {
      return _buildIndexWhereClause(col.schema, wc);
    } else {
      return _buildLinkWhereClause(col, wc as LinkWhereClause);
    }
  }).toList();

  final FilterJs? filterJs =
      filter != null ? _buildFilter(col.schema, filter) : null;
  final SortCmpJs? sortJs = sortBy.isNotEmpty ? _buildSort(sortBy) : null;
  final DistinctValueJs? distinctJs =
      distinctBy.isNotEmpty ? _buildDistinct(distinctBy) : null;

  final QueryJs queryJs = QueryJs(
    col.native,
    whereClausesJs,
    whereDistinct,
    whereSort == Sort.asc,
    filterJs,
    sortJs,
    distinctJs,
    offset,
    limit,
  );

  QueryDeserialize<T> deserialize;
  if (property == null) {
    deserialize = (Object jsObj) => col.schema.deserializeWeb(col, jsObj) as T;
  } else {
    deserialize =
        (Object jsObj) => col.schema.deserializePropWeb(jsObj, property) as T;
  }

  return QueryImpl<T>(col, queryJs, deserialize, property);
}

dynamic _valueToJs(dynamic value) {
  if (value == null) {
    return double.negativeInfinity;
  } else if (value == true) {
    return 1;
  } else if (value == false) {
    return 0;
  } else if (value is DateTime) {
    return value.toUtc().millisecondsSinceEpoch;
  } else if (value is List) {
    return value.map(_valueToJs).toList();
  } else {
    return value;
  }
}

IdWhereClauseJs _buildIdWhereClause(IdWhereClause wc) {
  return IdWhereClauseJs()
    ..range = _buildKeyRange(
      wc.lower != null ? _valueToJs(wc.lower) : null,
      wc.upper != null ? _valueToJs(wc.upper) : null,
      wc.includeLower,
      wc.includeUpper,
    );
}

IndexWhereClauseJs _buildIndexWhereClause(
    CollectionSchema<dynamic> schema, IndexWhereClause wc) {
  final bool isComposite = schema.indexValueTypes[wc.indexName]!.length > 1;

  dynamic lower = wc.lower;
  if (!isComposite && lower != null) {
    lower = lower[0];
  }

  dynamic upper = wc.upper;
  if (!isComposite && upper != null) {
    upper = upper[0];
  }

  return IndexWhereClauseJs()
    ..indexName = wc.indexName
    ..range = _buildKeyRange(
      wc.lower != null ? _valueToJs(lower) : null,
      wc.upper != null ? _valueToJs(upper) : null,
      wc.includeLower,
      wc.includeUpper,
    );
}

LinkWhereClauseJs _buildLinkWhereClause(
    IsarCollectionImpl<dynamic> col, LinkWhereClause wc) {
  final IsarCollectionImpl linkCol =
      // ignore: invalid_use_of_protected_member
      col.isar.getCollectionByNameInternal(wc.linkCollection)
          as IsarCollectionImpl;
  final String? backlinkLinkName =
      linkCol.schema.backlinkLinkNames[wc.linkName];
  return LinkWhereClauseJs()
    ..linkCollection = wc.linkCollection
    ..linkName = backlinkLinkName ?? wc.linkName
    ..backlink = backlinkLinkName != null
    ..id = wc.id;
}

KeyRange? _buildKeyRange(
    dynamic lower, dynamic upper, bool includeLower, bool includeUpper) {
  KeyRange? range;
  if (lower != null) {
    if (upper != null) {
      range = KeyRange.bound(
        lower,
        upper,
        !includeLower,
        !includeUpper,
      );
    } else {
      range = KeyRange.lowerBound(lower, !includeLower);
    }
  } else if (upper != null) {
    range = KeyRange.upperBound(upper, !includeUpper);
  }
  return range;
}

FilterJs? _buildFilter(
    CollectionSchema<dynamic> schema, FilterOperation filter) {
  final String? filterStr = _buildFilterOperation(schema, filter);
  if (filterStr != null) {
    return FilterJs('id', 'obj', 'return $filterStr');
  } else {
    return null;
  }
}

String? _buildFilterOperation(
  CollectionSchema<dynamic> schema,
  FilterOperation filter,
) {
  if (filter is FilterGroup) {
    return _buildFilterGroup(schema, filter);
  } else if (filter is LinkFilter) {
    unsupportedOnWeb();
  } else if (filter is FilterCondition) {
    return _buildCondition(schema, filter);
  } else {
    return null;
  }
}

String? _buildFilterGroup(CollectionSchema<dynamic> schema, FilterGroup group) {
  final List<String?> builtConditions = group.filters
      .map((FilterOperation op) => _buildFilterOperation(schema, op))
      .where((String? e) => e != null)
      .toList();

  if (builtConditions.isEmpty) {
    return null;
  }

  if (group.type == FilterGroupType.not) {
    return '!(${builtConditions[0]})';
  } else {
    final String op = group.type == FilterGroupType.or ? '||' : '&&';
    final String condition = builtConditions.join(op);
    return '($condition)';
  }
}

String _buildCondition(
    CollectionSchema<dynamic> schema, FilterCondition condition) {
  // ignore: no_leading_underscores_for_local_identifiers
  dynamic _prepareFilterValue(dynamic value) {
    if (value == null) {
      return null;
    } else if (value is String) {
      return stringify(value);
    } else {
      return _valueToJs(value);
    }
  }

  final bool isListOp = condition.type != FilterConditionType.isNull &&
      schema.listProperties.contains(condition.property);
  final String accessor =
      condition.property == schema.idName ? 'id' : 'obj.${condition.property}';
  final String variable = isListOp ? 'e' : accessor;

  final String cond = _buildConditionInternal(
    conditionType: condition.type,
    variable: variable,
    val1: _prepareFilterValue(condition.value1),
    include1: condition.include1,
    val2: _prepareFilterValue(condition.value2),
    include2: condition.include2,
    caseSensitive: condition.caseSensitive,
  );

  if (isListOp) {
    return '(Array.isArray($accessor) && $accessor.some(e => $cond))';
  } else {
    return cond;
  }
}

String _buildConditionInternal({
  required FilterConditionType conditionType,
  required String variable,
  required Object? val1,
  required bool include1,
  required Object? val2,
  required bool include2,
  required bool caseSensitive,
}) {
  final String isNull = '($variable == null || $variable === -Infinity)';
  switch (conditionType) {
    case FilterConditionType.equalTo:
      if (val1 == null) {
        return isNull;
      } else if (val1 is String && !caseSensitive) {
        return '$variable?.toLowerCase() === ${val1.toLowerCase()}';
      } else {
        return '$variable === $val1';
      }
    case FilterConditionType.between:
      final Object? val = val1 ?? val2;
      final String lowerOp = include1 ? '>=' : '>';
      final String upperOp = include2 ? '<=' : '<';
      if (val == null) {
        return isNull;
      } else if ((val1 is String?) && (val2 is String?) && !caseSensitive) {
        final String lower = val1?.toLowerCase() ?? '-Infinity';
        final String upper = val2?.toLowerCase() ?? '-Infinity';
        final String variableLc = '$variable?.toLowerCase() ?? -Infinity';
        final String lowerCond =
            'indexedDB.cmp($variableLc, $lower) $lowerOp 0';
        final String upperCond =
            'indexedDB.cmp($variableLc, $upper) $upperOp 0';
        return '($lowerCond && $upperCond)';
      } else {
        final String lowerCond =
            'indexedDB.cmp($variable, ${val1 ?? '-Infinity'}) $lowerOp 0';
        final String upperCond =
            'indexedDB.cmp($variable, ${val2 ?? '-Infinity'}) $upperOp 0';
        return '($lowerCond && $upperCond)';
      }
    case FilterConditionType.lessThan:
      if (val1 == null) {
        if (include1) {
          return isNull;
        } else {
          return 'false';
        }
      } else {
        final String op = include1 ? '<=' : '<';
        if (val1 is String && !caseSensitive) {
          return 'indexedDB.cmp($variable?.toLowerCase() ?? -Infinity, ${val1.toLowerCase()}) $op 0';
        } else {
          return 'indexedDB.cmp($variable, $val1) $op 0';
        }
      }
    case FilterConditionType.greaterThan:
      if (val1 == null) {
        if (include1) {
          return 'true';
        } else {
          return '!$isNull';
        }
      } else {
        final String op = include1 ? '>=' : '>';
        if (val1 is String && !caseSensitive) {
          return 'indexedDB.cmp($variable?.toLowerCase() ?? -Infinity, ${val1.toLowerCase()}) $op 0';
        } else {
          return 'indexedDB.cmp($variable, $val1) $op 0';
        }
      }
    case FilterConditionType.startsWith:
    case FilterConditionType.endsWith:
    case FilterConditionType.contains:
      final String op = conditionType == FilterConditionType.startsWith
          ? 'startsWith'
          : conditionType == FilterConditionType.endsWith
              ? 'endsWith'
              : 'includes';
      if (val1 is String) {
        final String isString = 'typeof $variable == "string"';
        if (!caseSensitive) {
          return '($isString && $variable.toLowerCase().$op(${val1.toLowerCase()}))';
        } else {
          return '($isString && $variable.$op($val1))';
        }
      } else {
        // ignore: only_throw_errors
        throw 'Unsupported type for condition';
      }
    case FilterConditionType.matches:
      throw UnimplementedError();
    case FilterConditionType.isNull:
      return isNull;
  }
}

SortCmpJs _buildSort(List<SortProperty> properties) {
  final String sort = properties.map((SortProperty e) {
    final String op = e.sort == Sort.asc ? '' : '-';
    return '${op}indexedDB.cmp(a.${e.property} ?? "-Infinity", b.${e.property} ?? "-Infinity")';
  }).join('||');
  return SortCmpJs('a', 'b', 'return $sort');
}

DistinctValueJs _buildDistinct(List<DistinctProperty> properties) {
  final String distinct = properties.map((DistinctProperty e) {
    if (e.caseSensitive == false) {
      return 'obj.${e.property}?.toLowerCase() ?? "-Infinity"';
    } else {
      return 'obj.${e.property}?.toString() ?? "-Infinity"';
    }
  }).join('+');
  return DistinctValueJs('obj', 'return $distinct');
}
