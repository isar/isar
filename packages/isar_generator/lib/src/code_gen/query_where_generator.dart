import 'package:isar/isar.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryWhere(ObjectInfo oi) {
  final primaryIndex = ObjectIndex(
    unique: true,
    replace: true,
    properties: [
      ObjectIndexProperty(
        property: oi.oidProperty,
        indexType: IndexType.value,
        caseSensitive: true,
      ),
    ],
  );

  var code =
      'extension ${oi.dartName}QueryWhereSort on QueryBuilder<${oi.dartName}, QWhere> {';

  for (var i = -1; i < oi.indexes.length; i++) {
    final index = i == -1 ? primaryIndex : oi.indexes[i];
    if (index.properties!.all((p) => p.indexType == IndexType.value)) {
      code += generateAny(i, index, oi);
    }
  }

  code += '''
  }

  extension ${oi.dartName}QueryWhere on QueryBuilder<${oi.dartName}, QWhereClause> {
  ''';

  for (var indexId = -1; indexId < oi.indexes.length; indexId++) {
    final index = indexId == -1 ? primaryIndex : oi.indexes[indexId];
    for (var n = 0; n < index.properties!.length; n++) {
      var properties = index.properties!.sublist(0, n + 1);

      if (!properties.any((it) => it.property.isarType.isFloatDouble)) {
        code += generateWhereEqualTo(indexId, oi, properties);
        if (!properties.any((it) => it.indexType == IndexType.words)) {
          code += generateWhereNotEqualTo(indexId, oi, properties);
        }
      }

      if (properties.length == 1) {
        var property = properties.first;

        if (property.property.isarType != IsarType.Bool &&
            property.property.isarType != IsarType.String) {
          code += generateWhereBetween(indexId, oi, property);
        }

        if (!property.property.isarType.isFloatDouble &&
            property.property.isarType != IsarType.Bool) {
          code += generateWhereIn(oi, property);
        }

        if (property.property.isarType == IsarType.Int ||
            property.property.isarType == IsarType.Long ||
            property.property.isarType.isFloatDouble) {
          code += generateWhereGreaterThan(indexId, oi, property);
          code += generateWhereLessThan(indexId, oi, property);
        }

        if (property.property.isarType == IsarType.String &&
            property.indexType != IndexType.hash) {
          code += generateWhereStartsWith(indexId, oi, property);
        }

        if (property.property.nullable &&
            property.indexType != IndexType.words) {
          code += generateWhereIsNull(indexId, oi, property);
          code += generateWhereIsNotNull(indexId, oi, property);
        }
      }
    }
  }

  return '$code}';
}

String joinPropertiesToName(List<ObjectIndexProperty> properties) {
  return properties.mapIndexed((i, p) {
    final name =
        p.property.dartName + (p.indexType == IndexType.words ? 'Word' : '');
    if (i == 0) {
      return name.decapitalize();
    } else {
      return name.capitalize();
    }
  }).join('');
}

String joinPropertiesToParams(List<ObjectIndexProperty> indexProperties,
    {String suffix = ''}) {
  return indexProperties
      .map((it) => '${it.property.dartType} ${it.property.dartName}$suffix')
      .join(',');
}

String joinPropertiesToValues(
    ObjectInfo oi, List<ObjectIndexProperty> indexProperties,
    [String suffix = '']) {
  final values = indexProperties.map((it) {
    return it.property.toIsar('${it.property.dartName}$suffix', oi);
  }).join(', ');
  return '[$values]';
}

String joinPropertiesToTypes(List<ObjectIndexProperty> indexProperties) {
  var types = indexProperties.map((indexProperty) {
    String? type;
    if (indexProperty.property.isarType == IsarType.String) {
      final lc = indexProperty.caseSensitive! ? '' : 'LC';
      switch (indexProperty.indexType) {
        case IndexType.value:
          type = 'StringValue$lc';
          break;
        case IndexType.hash:
          type = 'StringHash$lc';
          break;
        case IndexType.words:
          type = 'StringWords$lc';
          break;
      }
    } else {
      type = indexProperty.property.isarType.toString().substring(9);
    }
    return "'$type'";
  }).join(',');
  return '[$types]';
}

String generateAny(int indexId, ObjectIndex index, ObjectInfo oi) {
  final propertiesName = joinPropertiesToName(index.properties!);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhere> any${propertiesName.capitalize()}() {
    return addWhereClause(WhereClause($indexId, []));
  }
  ''';
}

String generateWhereEqualTo(
    int indexId, ObjectInfo oi, List<ObjectIndexProperty> indexProperties) {
  final name = joinPropertiesToName(indexProperties);
  final types = joinPropertiesToTypes(indexProperties);
  final values = joinPropertiesToValues(oi, indexProperties);
  final params = joinPropertiesToParams(indexProperties);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}EqualTo($params) {
    return addWhereClause(WhereClause(
      $indexId,
      $types,
      upper: $values,
      includeUpper: true,
      lower: $values,
      includeLower: true,
    ));
  }
  ''';
}

String generateWhereNotEqualTo(
    int indexId, ObjectInfo oi, List<ObjectIndexProperty> indexProperties) {
  final name = joinPropertiesToName(indexProperties);
  final types = joinPropertiesToTypes(indexProperties);
  final values = joinPropertiesToValues(oi, indexProperties);
  final params = joinPropertiesToParams(indexProperties);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}NotEqualTo($params) {
    final cloned = addWhereClause(WhereClause(
      $indexId,
      $types,
      upper: $values,
      includeUpper: false,
    ));
    return cloned.addWhereClause(WhereClause(
      $indexId,
      $types,
      lower: $values,
      includeLower: false,
    ));
  }
  ''';
}

String generateWhereGreaterThan(
    int indexId, ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  final types = joinPropertiesToTypes([indexProperty]);
  final name = joinPropertiesToName([indexProperty]);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}GreaterThan(${p.dartType} value, {bool include = false}) {
    return addWhereClause(WhereClause(
      $indexId,
      $types,
      lower: [${p.toIsar('value', oi)}],
      includeLower: include,
    ));
  }
  ''';
}

String generateWhereLessThan(
    int indexId, ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  final types = joinPropertiesToTypes([indexProperty]);
  final name = joinPropertiesToName([indexProperty]);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}LessThan(${p.dartType} value, {bool include = false}) {
    return addWhereClause(WhereClause(
      $indexId,
      $types,
      upper: [${p.toIsar('value', oi)}],
      includeUpper: include,
    ));
  }
  ''';
}

String generateWhereBetween(
    int indexId, ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  final types = joinPropertiesToTypes([indexProperty]);
  final name = joinPropertiesToName([indexProperty]);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}Between(${p.dartType} lower, ${p.dartType} upper, {bool includeLower = true, bool includeUpper = true}) {
    return addWhereClause(WhereClause(
      $indexId,
      $types,
      upper: [${p.toIsar('upper', oi)}],
      includeUpper: includeUpper,
      lower: [${p.toIsar('lower', oi)}],
      includeLower: includeLower,
    ));
  }
  ''';
}

String generateWhereIsNull(
    int indexId, ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final types = joinPropertiesToTypes([indexProperty]);
  final name = joinPropertiesToName([indexProperty]);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}IsNull() {
    return addWhereClause(WhereClause(
      $indexId,
      $types,
      upper: [null],
      includeUpper: true,
      lower: [null],
      includeLower: true,
    ));
  }
  ''';
}

String generateWhereIsNotNull(
    int indexId, ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final name = joinPropertiesToName([indexProperty]);
  final types = joinPropertiesToTypes([indexProperty]);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}IsNotNull() {
    return addWhereClause(WhereClause(
      $indexId,
      $types,
      lower: [null],
      includeLower: false,
    ));
  }
  ''';
}

String generateWhereIn(ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  final name = joinPropertiesToName([indexProperty]);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}In(List<${p.dartType}> values) {
    var q = this;
    for (var i = 0; i < values.length; i++) {
      if (i == values.length - 1) {
        return q.${name}EqualTo(values[i]);
      } else {
        q = q.${name}EqualTo(values[i]).or();
      }
    }
    throw 'Empty values is unsupported.';
  }
  ''';
}

String generateWhereStartsWith(
    int indexId, ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  final types = joinPropertiesToTypes([indexProperty]);
  final name = joinPropertiesToName([indexProperty]);
  final maxChar = '\\u{FFFFF}';
  var code = '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}StartsWith(${p.dartType} value) {
    final convertedValue = ${p.toIsar('value', oi)};
  ''';
  if (indexProperty.property.nullable) {
    code += "assert(convertedValue != null, 'Null values are not allowed');";
  }
  code += '''
    return addWhereClause(WhereClause(
      $indexId,
      $types,
      lower: [convertedValue],
      upper: ['\$convertedValue$maxChar'],
      includeLower: true,
      includeUpper: true,
    ));
  }
  ''';
  return code;
}
