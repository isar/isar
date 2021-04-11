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
    if (index.properties.all((p) => p.indexType == IndexType.value)) {
      code += generateAny(oi, index.properties.first);
    }
  }

  code += '''
  }

  extension ${oi.dartName}QueryWhere on QueryBuilder<${oi.dartName}, QWhereClause> {
  ''';

  for (var index in oi.indexes) {
    for (var n = 0; n < index.properties.length; n++) {
      var properties = index.properties.sublist(0, n + 1);

      if (!properties.any((it) => it.property.isarType.isFloatDouble)) {
        code += generateWhereEqualTo(oi, properties);
        if (!properties.any((it) => it.indexType == IndexType.words)) {
          code += generateWhereNotEqualTo(oi, properties);
        }
      }

      if (properties.length == 1) {
        var property = properties.first;

        if (property.property.isarType != IsarType.Bool &&
            property.property.isarType != IsarType.String) {
          code += generateWhereBetween(oi, property);
        }

        if (property.property.isarType == IsarType.Int ||
            property.property.isarType == IsarType.Long ||
            property.property.isarType.isFloatDouble) {
          code += generateWhereGreaterThan(oi, property);
          code += generateWhereLessThan(oi, property);
        }

        if (property.property.isarType == IsarType.String &&
            property.indexType != IndexType.hash) {
          code += generateWhereStartsWith(oi, property);
        }

        if (property.property.nullable &&
            property.indexType != IndexType.words) {
          code += generateWhereIsNull(oi, property);
          code += generateWhereIsNotNull(oi, property);
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

String generateAny(ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final propertiesName = joinPropertiesToName([indexProperty]);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhere> any${propertiesName.capitalize()}() {
    return addWhereClause(WhereClause(indexName: '${indexProperty.property.dartName}'));
  }
  ''';
}

String generateWhereEqualTo(
    ObjectInfo oi, List<ObjectIndexProperty> indexProperties) {
  final name = joinPropertiesToName(indexProperties);
  final values = joinPropertiesToValues(oi, indexProperties);
  final params = joinPropertiesToParams(indexProperties);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}EqualTo($params) {
    return addWhereClause(WhereClause(
      indexName: '${indexProperties.first.property.dartName}',
      upper: $values,
      includeUpper: true,
      lower: $values,
      includeLower: true,
    ));
  }
  ''';
}

String generateWhereNotEqualTo(
    ObjectInfo oi, List<ObjectIndexProperty> indexProperties) {
  final name = joinPropertiesToName(indexProperties);
  final values = joinPropertiesToValues(oi, indexProperties);
  final params = joinPropertiesToParams(indexProperties);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}NotEqualTo($params) {
    return addWhereClause(WhereClause(
      indexName: '${indexProperties.first.property.dartName}',
      upper: $values,
      includeUpper: false,
    )).addWhereClause(WhereClause(
      indexName: '${indexProperties.first.property.dartName}',
      lower: $values,
      includeLower: false,
    ));
  }
  ''';
}

String generateWhereGreaterThan(
    ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  final name = joinPropertiesToName([indexProperty]);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}GreaterThan(${p.dartType} value, {bool include = false}) {
    return addWhereClause(WhereClause(
      indexName: '${indexProperty.property.dartName}',
      lower: [${p.toIsar('value', oi)}],
      includeLower: include,
    ));
  }
  ''';
}

String generateWhereLessThan(ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  final name = joinPropertiesToName([indexProperty]);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}LessThan(${p.dartType} value, {bool include = false}) {
    return addWhereClause(WhereClause(
      indexName: '${indexProperty.property.dartName}',
      upper: [${p.toIsar('value', oi)}],
      includeUpper: include,
    ));
  }
  ''';
}

String generateWhereBetween(ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  final name = joinPropertiesToName([indexProperty]);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}Between(${p.dartType} lower, ${p.dartType} upper, {bool includeLower = true, bool includeUpper = true}) {
    return addWhereClause(WhereClause(
      indexName: '${indexProperty.property.dartName}',
      upper: [${p.toIsar('upper', oi)}],
      includeUpper: includeUpper,
      lower: [${p.toIsar('lower', oi)}],
      includeLower: includeLower,
    ));
  }
  ''';
}

String generateWhereIsNull(ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final name = joinPropertiesToName([indexProperty]);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}IsNull() {
    return addWhereClause(WhereClause(
      indexName: '${indexProperty.property.dartName}',
      upper: [null],
      includeUpper: true,
      lower: [null],
      includeLower: true,
    ));
  }
  ''';
}

String generateWhereIsNotNull(
    ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final name = joinPropertiesToName([indexProperty]);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}IsNotNull() {
    return addWhereClause(WhereClause(
      indexName: '${indexProperty.property.dartName}',
      lower: [null],
      includeLower: false,
    ));
  }
  ''';
}

String generateWhereStartsWith(
    ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
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
      indexName: '${indexProperty.property.dartName}',
      lower: [convertedValue],
      upper: ['\$convertedValue$maxChar'],
      includeLower: true,
      includeUpper: true,
    ));
  }
  ''';
  return code;
}
