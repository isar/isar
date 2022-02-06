import 'dart:indexed_db';

import 'package:isar/isar.dart';
import 'package:js/js.dart';

import 'bindings.dart';
import 'isar_collection_impl.dart';
import 'query_impl.dart';

@JS('JSON.stringify')
external String _escape(String value);

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
  );

  return QueryImpl<T>(col, queryJs, property);
}

WhereClauseJs _buildWhereClause(
    IsarCollectionImpl col, WhereClause whereClause) {
  final isComposite = col.isCompositeIndex[whereClause.indexName]!;

  if (whereClause.lower == null && whereClause.upper == null) {
    return WhereClauseJs(whereClause.indexName, null);
  }

  dynamic lower =
      whereClause.lower?.map((e) => e ?? double.negativeInfinity).toList();
  if (isComposite && lower != null) {
    lower = lower[0];
  }

  dynamic upper =
      whereClause.upper?.map((e) => e ?? double.negativeInfinity).toList();
  if (isComposite && upper != null) {
    upper = upper[0];
  }

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

  return WhereClauseJs(whereClause.indexName, range);
}

FilterJs? _buildFilter(IsarCollectionImpl col, FilterOperation filter) {
  final filterStr = _buildFilterOperation(col, filter);
  if (filterStr != null) {
    return FilterJs('obj', 'cmp', filterStr);
  }
}

String? _buildFilterOperation(
  IsarCollectionImpl col,
  FilterOperation filter,
) {
  if (filter is FilterGroup) {
    return _buildFilterGroup(col, filter);
  } else if (filter is LinkFilter) {
    return _buildLink(col, filter);
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

String? _buildLink(IsarCollectionImpl col, LinkFilter link) {
  throw UnimplementedError();
}

dynamic _prepareValue(dynamic value) {
  if (value is DateTime) {
    return value.toUtc().millisecondsSinceEpoch;
  } else if (value is String) {
    return _escape(value);
  } else {
    return value;
  }
}

String _buildCondition(IsarCollectionImpl col, FilterCondition condition) {
  return _buildConditionInternal(
    col: col,
    conditionType: condition.type,
    propertyName: condition.property,
    val1: _prepareValue(condition.value1),
    include1: condition.include1,
    val2: _prepareValue(condition.value2),
    include2: condition.include2,
    caseSensitive: condition.caseSensitive,
  );
}

String _buildConditionInternal({
  required IsarCollectionImpl col,
  required ConditionType conditionType,
  required String propertyName,
  required Object? val1,
  required bool include1,
  required Object? val2,
  required bool include2,
  required bool caseSensitive,
}) {
  final isNull =
      '(obj.$propertyName == null || obj.$propertyName === -Infinity)';
  switch (conditionType) {
    case ConditionType.eq:
      if (val1 == null) {
        return isNull;
      } else if (val1 is String && !caseSensitive) {
        return 'obj.$propertyName?.toLowerCase() === "${val1.toLowerCase()}"';
      } else {
        return 'obj.$propertyName === $val1';
      }
    case ConditionType.between:
      final val = val1 ?? val2;
      if (val == null) {
        return isNull;
      } else {
        throw UnimplementedError();
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
          return 'cmp($propertyName?.toLowerCase() ?? -Infinity, "${val1.toLowerCase()}") $op 0';
        } else {
          return 'cmp(obj.$propertyName, $val1) $op 0';
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
          return 'cmp($propertyName?.toLowerCase() ?? -Infinity, "${val1.toLowerCase()}") $op 0';
        } else {
          return 'cmp(obj.$propertyName, $val1) $op 0';
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
        final isString = 'obj.$propertyName instanceof String';
        if (caseSensitive) {
          return '($isString && obj.$propertyName.$op("$val1"))';
        } else {
          return '($isString && obj.$propertyName.toLowerCase().$op("${val1.toLowerCase()}"))';
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
    return '${op}cmp(a.${e.property} ?? "-Infinity", b.${e.property} ?? "-Infinity")';
  }).join('||');
  return SortCmpJs('a', 'b', 'cmp', 'return $sort');
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
