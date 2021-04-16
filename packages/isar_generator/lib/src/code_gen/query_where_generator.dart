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
      code += generateAny(oi, index.properties);
    }
  }

  code += '''
  }

  extension ${oi.dartName}QueryWhere on QueryBuilder<${oi.dartName}, QWhereClause> {
  ''';

  for (var index in oi.indexes) {
    for (var n = 0; n < index.properties.length; n++) {
      var properties = index.properties.sublist(0, n + 1);

      final firstProperties = index.properties.sublist(0, n);
      final lastProperty = index.properties.last;
      if (!firstProperties.any((it) => it.property.isarType.isFloatDouble)) {
        code += generateWhereEqualTo(oi, properties);
        if (!properties.any((it) => it.indexType == IndexType.words)) {
          code += generateWhereNotEqualTo(oi, properties);
        }
      }

      if (lastProperty.property.isarType == IsarType.Int ||
          lastProperty.property.isarType == IsarType.Long ||
          lastProperty.property.isarType.isFloatDouble) {
        code += generateWhereGreaterThan(oi, properties);
        code += generateWhereLessThan(oi, properties);
      }

      if (lastProperty.property.isarType == IsarType.String &&
          lastProperty.indexType != IndexType.hash) {
        code += generateWhereStartsWith(oi, properties);
      }

      if (lastProperty.property.isarType != IsarType.Bool &&
          lastProperty.property.isarType != IsarType.String) {
        code += generateWhereBetween(oi, properties);
      }

      if (index.properties.length == 1 &&
          lastProperty.property.nullable &&
          lastProperty.indexType != IndexType.words) {
        code += generateWhereIsNull(oi, lastProperty);
        code += generateWhereIsNotNull(oi, lastProperty);
      }
    }
  }

  return '$code}';
}

String joinPropertiesToName(
    List<ObjectIndexProperty> properties, bool firstEqualTo) {
  String propertyName(ObjectIndexProperty p, int i) {
    final name =
        p.property.dartName + (p.indexType == IndexType.words ? 'Word' : '');
    if (i == 0) {
      return name.decapitalize();
    } else {
      return name.capitalize();
    }
  }

  var firstPropertiesName = properties
      .sublist(0, properties.length - 1)
      .mapIndexed((i, p) => propertyName(p, i))
      .join('');

  if (firstPropertiesName.isNotEmpty && firstEqualTo) {
    firstPropertiesName += 'EqualTo';
  }

  firstPropertiesName += propertyName(properties.last, properties.lastIndex);

  return firstPropertiesName;
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
  return values;
}

String generateAny(ObjectInfo oi, List<ObjectIndexProperty> indexProperties) {
  final name = joinPropertiesToName(indexProperties, false);
  final indexName = indexProperties.first.property.dartName;
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhere> any${name.capitalize()}() {
    return addWhereClause(WhereClause(indexName: '$indexName'));
  }
  ''';
}

String generateWhereEqualTo(
    ObjectInfo oi, List<ObjectIndexProperty> indexProperties) {
  final name = joinPropertiesToName(indexProperties, false);
  final indexName = indexProperties.first.property.dartName;
  final values = joinPropertiesToValues(oi, indexProperties);
  final params = joinPropertiesToParams(indexProperties);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}EqualTo($params) {
    return addWhereClause(WhereClause(
      indexName: '$indexName',
      lower: [$values],
      includeLower: true,
      upper: [$values],
      includeUpper: true,
    ));
  }
  ''';
}

String generateWhereNotEqualTo(
    ObjectInfo oi, List<ObjectIndexProperty> indexProperties) {
  final name = joinPropertiesToName(indexProperties, false);
  final indexName = indexProperties.first.property.dartName;
  final values = joinPropertiesToValues(oi, indexProperties);
  final params = joinPropertiesToParams(indexProperties);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}NotEqualTo($params) {
    return addWhereClause(WhereClause(
      indexName: '$indexName',
      upper: [$values],
      includeUpper: false,
    )).addWhereClause(WhereClause(
      indexName: '$indexName',
      lower: [$values],
      includeLower: false,
    ));
  }
  ''';
}

String generateWhereGreaterThan(
    ObjectInfo oi, List<ObjectIndexProperty> indexProperties) {
  final name = joinPropertiesToName(indexProperties, true);
  final indexName = indexProperties.first.property.dartName;
  final values = joinPropertiesToValues(oi, indexProperties);
  final params = joinPropertiesToParams(indexProperties);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}GreaterThan($params) {
    return addWhereClause(WhereClause(
      indexName: '$indexName',
      lower: [$values],
      includeLower: false,
    ));
  }
  ''';
}

String generateWhereLessThan(
    ObjectInfo oi, List<ObjectIndexProperty> indexProperties) {
  final name = joinPropertiesToName(indexProperties, true);
  final indexName = indexProperties.first.property.dartName;
  final params = joinPropertiesToParams(indexProperties);
  final values = joinPropertiesToValues(oi, indexProperties);
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}LessThan($params) {
    return addWhereClause(WhereClause(
      indexName: '$indexName',
      upper: [$values],
      includeUpper: false,
    ));
  }
  ''';
}

String generateWhereBetween(
    ObjectInfo oi, List<ObjectIndexProperty> indexProperties) {
  final firstPs = indexProperties.sublist(0, indexProperties.length - 1);
  final lastP = indexProperties.last.property;
  final lowerName = 'lower${lastP.dartName.capitalize()}';
  final upperName = 'upper${lastP.dartName.capitalize()}';

  final name = joinPropertiesToName(indexProperties, true);
  final indexName = indexProperties.first.property.dartName;
  var params = joinPropertiesToParams(firstPs);
  if (params.isNotEmpty) {
    params += ',';
  }
  params += '${lastP.dartType} $lowerName, ${lastP.dartType} $upperName';
  var values = joinPropertiesToValues(oi, firstPs);
  if (values.isNotEmpty) {
    values += ',';
  }
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}Between($params) {
    return addWhereClause(WhereClause(
      indexName: '$indexName',
      lower: [$values $lowerName],
      includeLower: true,
      upper: [$values $upperName],
      includeUpper: true,
      
    ));
  }
  ''';
}

String generateWhereIsNull(ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final name = joinPropertiesToName([indexProperty], false);
  final indexName = indexProperty.property.dartName;
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}IsNull() {
    return addWhereClause(WhereClause(
      indexName: '$indexName',
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
  final name = joinPropertiesToName([indexProperty], false);
  final indexName = indexProperty.property.dartName;
  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}IsNotNull() {
    return addWhereClause(WhereClause(
      indexName: '$indexName',
      lower: [null],
      includeLower: false,
    ));
  }
  ''';
}

String generateWhereStartsWith(
    ObjectInfo oi, List<ObjectIndexProperty> indexProperties) {
  final firsPs = indexProperties.sublist(0, indexProperties.length - 1);
  final lastP = indexProperties.last.property;
  final name = joinPropertiesToName(indexProperties, true);
  final indexName = indexProperties.first.property.dartName;
  var params = joinPropertiesToParams(firsPs);
  if (params.isNotEmpty) {
    params += ',';
  }
  final lastName = '${lastP.dartName}Prefix';
  params += '${lastP.converter == null ? 'String' : lastP.dartType} $lastName';
  var values = joinPropertiesToValues(oi, firsPs);
  if (values.isNotEmpty) {
    values += ',';
  }

  return '''
  QueryBuilder<${oi.dartName}, QAfterWhereClause> ${name}StartsWith($params) {
    return addWhereClause(WhereClause(
      indexName: '$indexName',
      lower: [$values '\$$lastName'],
      includeLower: true,
      upper: [$values '\$$lastName\\u{FFFFF}'],
      includeUpper: true,
    ));
  }
  ''';
}
