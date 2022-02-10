import 'dart:indexed_db';

import 'package:isar/isar.dart';

import 'bindings.dart';
import 'isar_collection_impl.dart';
import 'isar_web.dart';
import 'query_impl.dart';

Query<T> buildWebQuery<T>(
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
  final whereClausesJs =
      whereClauses.map((wc) => _buildWhereClause(col, wc)).toList();

  final filterJs = filter != null ? _buildFilter(col, filter) : null;
  final sortJs = sortBy.isNotEmpty ? _buildSort(sortBy) : null;
  final distinctJs = distinctBy.isNotEmpty ? _buildDistinct(distinctBy) : null;

  final queryJs = QueryJs(
    col.col,
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
    deserialize = (jsObj) => col.adapter.deserialize(col, jsObj);
  } else {
    deserialize = (jsObj) => col.adapter.deserializeProperty(jsObj, property);
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

WhereClauseJs _buildWhereClause(
    IsarCollectionImpl col, WhereClause whereClause) {
  final isComposite = col.isCompositeIndex[whereClause.indexName]!;

  if (whereClause.lower == null && whereClause.upper == null) {
    return WhereClauseJs()..indexName = whereClause.indexName;
  }

  dynamic lower = whereClause.lower;
  if (!isComposite && lower != null) {
    lower = lower[0];
  }
  lower = _valueToJs(lower);

  dynamic upper = whereClause.upper;
  if (!isComposite && upper != null) {
    upper = upper[0];
  }
  upper = _valueToJs(upper);

  KeyRange range;
  if (whereClause.lower != null) {
    if (whereClause.upper != null) {
      range = KeyRange.bound(
        lower,
        upper,
        !whereClause.includeLower,
        !whereClause.includeUpper,
      );
    } else {
      range = KeyRange.lowerBound(lower, !whereClause.includeLower);
    }
  } else {
    range = KeyRange.upperBound(upper, !whereClause.includeUpper);
  }

  return WhereClauseJs()
    ..indexName = whereClause.indexName
    ..range = range;
}

FilterJs? _buildFilter(IsarCollectionImpl col, FilterOperation filter) {
  final filterStr = _buildFilterOperation(col, filter);
  if (filterStr != null) {
    return FilterJs('obj', 'return $filterStr');
  }
}

String? _buildFilterOperation(
  IsarCollectionImpl col,
  FilterOperation filter,
) {
  if (filter is FilterGroup) {
    return _buildFilterGroup(col, filter);
  } else if (filter is LinkFilter) {
    unsupportedOnWeb();
  } else if (filter is FilterCondition) {
    return _buildCondition(col, filter);
  }
}

String? _buildFilterGroup(IsarCollectionImpl col, FilterGroup group) {
  final builtConditions = group.filters
      .map((op) => _buildFilterOperation(col, op))
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

String _buildCondition(IsarCollectionImpl col, FilterCondition condition) {
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
      col.listProperties.contains(condition.property);
  final accessor = 'obj.${condition.property}';
  final variable = isListOp ? 'e' : accessor;

  final cond = _buildConditionInternal(
    col: col,
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
  required IsarCollectionImpl col,
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
              : 'contains';
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
