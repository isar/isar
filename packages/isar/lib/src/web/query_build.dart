import 'dart:indexed_db';

import 'package:isar/isar.dart';

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
  final whereClausesJs = whereClauses.map((wc) {
    if (wc is IdWhereClause) {
      return _buildIdWhereClause(wc);
    } else if (wc is IndexWhereClause) {
      return _buildIndexWhereClause(col.schema, wc);
    } else {
      return _buildLinkWhereClause(col, wc as LinkWhereClause);
    }
  }).toList();

  final filterJs = filter != null ? _buildFilter(col.schema, filter) : null;
  final sortJs = sortBy.isNotEmpty ? _buildSort(sortBy) : null;
  final distinctJs = distinctBy.isNotEmpty ? _buildDistinct(distinctBy) : null;

  final queryJs = QueryJs(
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
    deserialize = (jsObj) => col.schema.deserializeWeb(col, jsObj) as T;
  } else {
    deserialize = (jsObj) => col.schema.deserializePropWeb(jsObj, property);
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
    CollectionSchema schema, IndexWhereClause wc) {
  final isComposite = schema.indexValueTypes[wc.indexName]!.length > 1;

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
    IsarCollectionImpl col, LinkWhereClause wc) {
  final linkCol =
      col.isar.getCollectionInternal(wc.linkCollection) as IsarCollectionImpl;
  final backlinkLinkName = linkCol.schema.backlinkLinkNames[wc.linkName];
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

FilterJs? _buildFilter(CollectionSchema schema, FilterOperation filter) {
  final filterStr = _buildFilterOperation(schema, filter);
  if (filterStr != null) {
    return FilterJs('id', 'obj', 'return $filterStr');
  } else {
    return null;
  }
}

String? _buildFilterOperation(
  CollectionSchema schema,
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

String? _buildFilterGroup(CollectionSchema schema, FilterGroup group) {
  final builtConditions = group.filters
      .map((op) => _buildFilterOperation(schema, op))
      .where((e) => e != null)
      .toList();

  if (builtConditions.isEmpty) {
    return null;
  }

  if (group.type == FilterGroupType.not) {
    return '(!${builtConditions[0]})';
  } else {
    final op = group.type == FilterGroupType.or ? '||' : '&&';
    final condition = builtConditions.join(op);
    return '($condition)';
  }
}

String _buildCondition(CollectionSchema schema, FilterCondition condition) {
  dynamic _prepareFilterValue(dynamic value) {
    if (value == null) {
      return null;
    } else if (value is String) {
      return stringify(value);
    } else {
      return _valueToJs(value);
    }
  }

  final isListOp = condition.type != ConditionType.isNull &&
      schema.listProperties.contains(condition.property);
  final accessor =
      condition.property == schema.idName ? 'id' : 'obj.${condition.property}';
  final variable = isListOp ? 'e' : accessor;

  final cond = _buildConditionInternal(
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
  required ConditionType conditionType,
  required String variable,
  required Object? val1,
  required bool include1,
  required Object? val2,
  required bool include2,
  required bool caseSensitive,
}) {
  final isNull = '($variable == null || $variable === -Infinity)';
  switch (conditionType) {
    case ConditionType.eq:
      if (val1 == null) {
        return isNull;
      } else if (val1 is String && !caseSensitive) {
        return '$variable?.toLowerCase() === ${val1.toLowerCase()}';
      } else {
        return '$variable === $val1';
      }
    case ConditionType.between:
      final val = val1 ?? val2;
      final lowerOp = include1 ? '>=' : '>';
      final upperOp = include2 ? '<=' : '<';
      if (val == null) {
        return isNull;
      } else if ((val1 is String?) && (val2 is String?) && !caseSensitive) {
        final lower = val1?.toLowerCase() ?? '-Infinity';
        final upper = val2?.toLowerCase() ?? '-Infinity';
        final variableLc = '$variable?.toLowerCase() ?? -Infinity';
        final lowerCond = 'indexedDB.cmp($variableLc, $lower) $lowerOp 0';
        final upperCond = 'indexedDB.cmp($variableLc, $upper) $upperOp 0';
        return '($lowerCond && $upperCond)';
      } else {
        final lowerCond =
            'indexedDB.cmp($variable, ${val1 ?? '-Infinity'}) $lowerOp 0';
        final upperCond =
            'indexedDB.cmp($variable, ${val2 ?? '-Infinity'}) $upperOp 0';
        return '($lowerCond && $upperCond)';
      }
    case ConditionType.lt:
      if (val1 == null) {
        if (include1) {
          return isNull;
        } else {
          return 'false';
        }
      } else {
        final op = include1 ? '<=' : '<';
        if (val1 is String && !caseSensitive) {
          return 'indexedDB.cmp($variable?.toLowerCase() ?? -Infinity, ${val1.toLowerCase()}) $op 0';
        } else {
          return 'indexedDB.cmp($variable, $val1) $op 0';
        }
      }
    case ConditionType.gt:
      if (val1 == null) {
        if (include1) {
          return 'true';
        } else {
          return '!$isNull';
        }
      } else {
        final op = include1 ? '>=' : '>';
        if (val1 is String && !caseSensitive) {
          return 'indexedDB.cmp($variable?.toLowerCase() ?? -Infinity, ${val1.toLowerCase()}) $op 0';
        } else {
          return 'indexedDB.cmp($variable, $val1) $op 0';
        }
      }
    case ConditionType.startsWith:
    case ConditionType.endsWith:
    case ConditionType.contains:
      final op = conditionType == ConditionType.startsWith
          ? 'startsWith'
          : conditionType == ConditionType.endsWith
              ? 'endsWith'
              : 'includes';
      if (val1 is String) {
        final isString = 'typeof $variable == "string"';
        if (!caseSensitive) {
          return '($isString && $variable.toLowerCase().$op(${val1.toLowerCase()}))';
        } else {
          return '($isString && $variable.$op($val1))';
        }
      } else {
        throw 'Unsupported type for condition';
      }
    case ConditionType.matches:
      throw UnimplementedError();
    case ConditionType.isNull:
      return isNull;
  }
}

SortCmpJs _buildSort(List<SortProperty> properties) {
  final sort = properties.map((e) {
    final op = e.sort == Sort.asc ? '' : '-';
    return '${op}indexedDB.cmp(a.${e.property} ?? "-Infinity", b.${e.property} ?? "-Infinity")';
  }).join('||');
  return SortCmpJs('a', 'b', 'return $sort');
}

DistinctValueJs _buildDistinct(List<DistinctProperty> properties) {
  final distinct = properties.map((e) {
    if (e.caseSensitive == false) {
      return 'obj.${e.property}?.toLowerCase() ?? "-Infinity"';
    } else {
      return 'obj.${e.property}?.toString() ?? "-Infinity"';
    }
  }).join('+');
  return DistinctValueJs('obj', 'return $distinct');
}
