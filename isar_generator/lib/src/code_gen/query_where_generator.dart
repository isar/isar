import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';
import 'package:isar_generator/src/code_gen/util.dart';

String generateQueryWhere(ObjectInfo oi) {
  var whereSort = oi.indices.mapIndexed((indexIndex, index) {
    var properties =
        index.properties.map((it) => oi.getProperty(it.isarName)).toList();
    return generateSortedBy(indexIndex, oi.dartName, properties);
  }).join('\n');

  var where = oi.indices.mapIndexed((indexIndex, index) {
    var code = '';
    for (var n = 0; n < index.properties.length; n++) {
      var properties = index.properties
          .sublist(0, n + 1)
          .map((it) => oi.getProperty(it.isarName))
          .toList();

      if (properties.all((it) => !it.isarType.isFloatDouble)) {
        code += generateWhereEqualTo(indexIndex, oi.dartName, properties);
        code += generateWhereNotEqualTo(indexIndex, oi.dartName, properties);
      }

      if (properties.length == 1) {
        var property = properties.first;

        if (property.isarType != IsarType.Bool) {
          code += generateWhereBetween(indexIndex, oi, property);
        }

        if (!property.isarType.isFloatDouble) {
          code += generateWhereAnyOf(oi, property);
        }

        if (property.isarType == IsarType.Int ||
            property.isarType == IsarType.Long ||
            property.isarType.isFloatDouble) {
          code += generateWhereLowerThan(indexIndex, oi, property);
          code += generateWhereGreaterThan(indexIndex, oi, property);
        }

        //if (property.isarType == IsarType.String && !index.hashValue) {
        //code += generateWhereStartsWith(indexIndex, oi, property);
        //}

        if (property.nullable) {
          code += generateWhereIsNull(indexIndex, oi, property);
          code += generateWhereIsNotNull(indexIndex, oi, property);
        }
      }
    }
    return code;
  }).join('\n');

  return '''
  extension ${oi.dartName}QueryWhereSort on QueryBuilder<${oi.dartName}, 
    QNoWhere, dynamic, dynamic, dynamic, dynamic, dynamic> {
    $whereSort
  }
  
  extension ${oi.dartName}QueryWhere on QueryBuilder<${oi.dartName}, 
    QWhere, dynamic, dynamic, dynamic, dynamic, dynamic> {
    $where
  }
  ''';
}

String joinPropertiesToName(List<ObjectProperty> properties) {
  return properties
      .mapIndexed((i, f) =>
          i == 0 ? f.dartName.decapitalize() : f.dartName.capitalize())
      .join('');
}

String joinPropertiesToParams(List<ObjectProperty> properties,
    {String suffix = ''}) {
  return properties
      .map((it) => '${it.dartType} ${it.dartName}$suffix')
      .join(',');
}

String joinPropertiesToList(List<ObjectProperty> properties,
    [String suffix = '']) {
  return '[' + properties.map((it) => it.dartName + suffix).join(', ') + ']';
}

String joinPropertiesToTypes(List<ObjectProperty> properties) {
  return '[' +
      properties
          .map((it) => "'" + it.isarType.toString().substring(9) + "'")
          .join(', ') +
      ']';
}

String whereReturnParams(String whereType) {
  return '$whereType, QCanFilter, QCanGroupBy, QCanOffsetLimit, QCanSort, QCanExecute';
}

String whereReturn(String type, String whereType) {
  return 'QueryBuilder<$type, ${whereReturnParams(whereType)}>';
}

String generateSortedBy(
    int index, String type, List<ObjectProperty> properties) {
  final propertiesName = joinPropertiesToName(properties);
  return '''
  ${whereReturn(type, 'dynamic')} sortedBy${propertiesName.capitalize()}({bool distinct = false}) {
    return addWhereClause(WhereClause($index, [], skipDuplicates: distinct));
  }
  ''';
}

String generateWhereEqualTo(
    int index, String type, List<ObjectProperty> properties) {
  final propertiesName = joinPropertiesToName(properties);
  final propertyTypes = joinPropertiesToTypes(properties);
  final propertiesList = joinPropertiesToList(properties);
  return '''
  ${whereReturn(type, 'QWhereProperty')} ${propertiesName}EqualTo(${joinPropertiesToParams(properties)}) {
    return addWhereClause(WhereClause(
      $index,
      $propertyTypes,
      upper: $propertiesList,
      includeUpper: true,
      lower: $propertiesList,
      includeLower: true,
    ));
  }
  ''';
}

String generateWhereNotEqualTo(
    int index, String type, List<ObjectProperty> properties) {
  final propertiesName = joinPropertiesToName(properties);
  final propertyTypes = joinPropertiesToTypes(properties);
  final propertiesList = joinPropertiesToList(properties);
  return '''
  ${whereReturn(type, 'QWhereProperty')} ${propertiesName}NotEqualTo(${joinPropertiesToParams(properties)}) {
    final cloned = addWhereClause(WhereClause(
      $index,
      $propertyTypes,
      upper: $propertiesList,
      includeUpper: false,
    ));
    return cloned.addWhereClause(WhereClause(
      $index,
      $propertyTypes,
      lower: $propertiesList,
      includeLower: false,
    ));
  }
  ''';
}

String generateWhereLowerThan(int index, ObjectInfo oi, ObjectProperty p) {
  return '''
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${p.dartName.decapitalize()}LowerThan(${p.dartType} value, {bool include = false, bool distinct = false}) {
    return addWhereClause(WhereClause(
      $index,
      ['${p.isarType.name}'],
      upper: [${p.toIsar('value', oi)}],
      includeUpper: include,
      skipDuplicates: distinct,
    ));
  }
  ''';
}

String generateWhereGreaterThan(int index, ObjectInfo oi, ObjectProperty p) {
  return '''
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${p.dartName.decapitalize()}GreaterThan(${p.dartType} value, {bool include = false, bool distinct = false}) {
    return addWhereClause(WhereClause(
      $index,
      ['${p.isarType.name}'],
      lower: [${p.toIsar('value', oi)}],
      includeLower: include,
      skipDuplicates: distinct,
    ));
  }
  ''';
}

String generateWhereBetween(int index, ObjectInfo oi, ObjectProperty p) {
  return '''
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${p.dartName.decapitalize()}Between(${p.dartType} lower, ${p.dartType} upper, {bool includeLower = true, bool includeUpper = true, bool distinct = false,}) {
    return addWhereClause(WhereClause(
      $index,
      ['${p.isarType.name}'],
      upper: [${p.toIsar('upper', oi)}],
      includeUpper: includeUpper,
      lower: [${p.toIsar('lower', oi)}],
      includeLower: includeLower,
      skipDuplicates: distinct,
    ));
  }
  ''';
}

String generateWhereIsNull(int index, ObjectInfo oi, ObjectProperty p) {
  return '''
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${p.dartName.decapitalize()}IsNull() {
    return addWhereClause(WhereClause(
      $index,
      ['${p.isarType.name}'],
      upper: [null],
      includeUpper: true,
      lower: [null],
      includeLower: true,
    ));
  }
  ''';
}

String generateWhereIsNotNull(int index, ObjectInfo oi, ObjectProperty p) {
  return '''
  ${whereReturn(oi.dartName, 'QWhereProperty')} ${p.dartName.decapitalize()}IsNotNull() {
    final cloned = addWhereClause(WhereClause(
      $index,
      ['${p.isarType.name}'],
      upper: [null],
      includeUpper: false,
    ));
    return cloned.addWhereClause(WhereClause(
      $index,
      ['${p.isarType.name}'],
      lower: [null],
      includeLower: false,
    ));
  }
  ''';
}

String generateWhereAnyOf(ObjectInfo oi, ObjectProperty p) {
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
