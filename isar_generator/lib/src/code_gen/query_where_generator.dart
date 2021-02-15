import 'package:isar_annotation/isar_annotation.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryWhere(ObjectInfo oi) {
  final primaryIndex = ObjectIndex(
    unique: true,
    properties: [
      ObjectIndexProperty(
        property: oi.oidProperty,
        indexType: IndexType.value,
        caseSensitive: true,
      ),
    ],
  );

  var code = '''
  extension ${oi.dartName}QueryWhereSort on QueryBuilder<${oi.dartName}, 
    QNoWhere, dynamic, dynamic, dynamic, dynamic, dynamic> {''';

  for (var i = -1; i < oi.indexes.length; i++) {
    final index = i == -1 ? primaryIndex : oi.indexes[i];
    code += generateSortedBy(i, index, oi);
  }

  code += '''
  }
  extension ${oi.dartName}QueryWhere on QueryBuilder<${oi.dartName}, 
    QWhere, dynamic, dynamic, dynamic, dynamic, dynamic> {
  ''';

  for (var indexId = -1; indexId < oi.indexes.length; indexId++) {
    final index = indexId == -1 ? primaryIndex : oi.indexes[indexId];
    for (var n = 0; n < index.properties.length; n++) {
      var properties = index.properties.sublist(0, n + 1);

      if (!properties.any((it) => it.property.isarType.isFloatDouble)) {
        code += generateWhereEqualTo(indexId, oi, properties);
        code += generateWhereNotEqualTo(indexId, oi, properties);
      }

      if (properties.length == 1) {
        var property = properties.first;

        if (property.property.isarType != IsarType.Bool) {
          code += generateWhereBetween(indexId, oi, property);
        }

        if (!property.property.isarType.isFloatDouble) {
          code += generateWhereAnyOf(oi, property);
        }

        if (property.property.isarType == IsarType.Int ||
            property.property.isarType == IsarType.Long ||
            property.property.isarType.isFloatDouble) {
          code += generateWhereLowerThan(indexId, oi, property);
          code += generateWhereGreaterThan(indexId, oi, property);
        }

        //if (property.isarType == IsarType.String && !index.hashValue) {
        //code += generateWhereStartsWith(indexIndex, oi, property);
        //}

        if (property.property.nullable) {
          code += generateWhereIsNull(indexId, oi, property);
          code += generateWhereIsNotNull(indexId, oi, property);
        }
      }
    }
  }

  return '$code}';
}

String joinPropertiesToName(List<ObjectIndexProperty> properties) {
  return properties.mapIndexed((i, f) {
    if (i == 0) {
      return f.property.dartName.decapitalize();
    } else {
      return f.property.dartName.capitalize();
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
    String type;
    if (indexProperty.property.isarType == IsarType.String) {
      final lc = indexProperty.caseSensitive ? '' : 'LC';
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

String whereReturn(String type, String whereType) {
  return 'QueryBuilder<$type, $whereType, QCanFilter, QCanDistinctBy,'
      'QCanOffsetLimit, QCanSort, QCanExecute>';
}

String generateSortedBy(int indexId, ObjectIndex index, ObjectInfo oi) {
  final propertiesName = joinPropertiesToName(index.properties);
  return '''
  ${whereReturn(oi.dartName, 'dynamic')} sortedBy${propertiesName.capitalize()}(${index.unique ? '' : '{bool distinct = false}'}) {
    return addWhereClause(WhereClause($indexId, [], skipDuplicates: ${index.unique ? false : 'distinct'}));
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
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${name}EqualTo($params) {
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
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${name}NotEqualTo($params) {
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

String generateWhereLowerThan(
    int indexId, ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  final types = joinPropertiesToTypes([indexProperty]);
  return '''
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${p.dartName.decapitalize()}LowerThan(${p.dartType} value, {bool include = false, bool distinct = false}) {
    return addWhereClause(WhereClause(
      $indexId,
      $types,
      upper: [${p.toIsar('value', oi)}],
      includeUpper: include,
      skipDuplicates: distinct,
    ));
  }
  ''';
}

String generateWhereGreaterThan(
    int indexId, ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  final types = joinPropertiesToTypes([indexProperty]);
  return '''
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${p.dartName.decapitalize()}GreaterThan(${p.dartType} value, {bool include = false, bool distinct = false}) {
    return addWhereClause(WhereClause(
      $indexId,
      $types,
      lower: [${p.toIsar('value', oi)}],
      includeLower: include,
      skipDuplicates: distinct,
    ));
  }
  ''';
}

String generateWhereBetween(
    int indexId, ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  final types = joinPropertiesToTypes([indexProperty]);
  return '''
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${p.dartName.decapitalize()}Between(${p.dartType} lower, ${p.dartType} upper, {bool includeLower = true, bool includeUpper = true, bool distinct = false}) {
    return addWhereClause(WhereClause(
      $indexId,
      $types,
      upper: [${p.toIsar('upper', oi)}],
      includeUpper: includeUpper,
      lower: [${p.toIsar('lower', oi)}],
      includeLower: includeLower,
      skipDuplicates: distinct,
    ));
  }
  ''';
}

String generateWhereIsNull(
    int indexId, ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  final types = joinPropertiesToTypes([indexProperty]);
  return '''
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${p.dartName.decapitalize()}IsNull() {
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
  final p = indexProperty.property;
  final types = joinPropertiesToTypes([indexProperty]);
  return '''
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${p.dartName.decapitalize()}IsNotNull() {
    final cloned = addWhereClause(WhereClause(
      $indexId,
      $types,
      upper: [null],
      includeUpper: false,
    ));
    return cloned.addWhereClause(WhereClause(
      $indexId,
      $types,
      lower: [null],
      includeLower: false,
    ));
  }
  ''';
}

String generateWhereAnyOf(ObjectInfo oi, ObjectIndexProperty indexProperty) {
  final p = indexProperty.property;
  return '''
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${p.dartName.decapitalize()}AnyOf(List<${p.dartType}> values) {
    var q = this;
    for (var i = 0; i < values.length; i++) {
      if (i == values.length - 1) {
        return q.${p.dartName.decapitalize()}EqualTo(values[i]);
      } else {
        q = q.${p.dartName.decapitalize()}EqualTo(values[i]).or();
      }
    }
    throw UnimplementedError();
  }
  ''';
}

/*String generateWhereStartsWith(
    int index, String type, ObjectProperty property) {
  final propertiesName = joinPropertiesToName([property]);
  return '''
  ${whereReturn(type, 'QWhereProperty')} ${propertiesName}StartsWith(String prefix) {
    return addWhereCondition(QueryCondition(ConditionType.StartsWith, $index, [prefix]));
  }
  ''';
}
*/
